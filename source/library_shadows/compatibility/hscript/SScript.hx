package hscript;

import haxe.ds.*;
import haxe.Constraints.IMap;
import haxe.Exception;
import haxe.Timer;
import hscriptBase.*;
#if !macro
import backend.io.File;
import backend.io.FileSystem;
#end

using StringTools;


/**
	The base class for dynamic Haxe scripts.
**/
@:structInit
@:access(hscriptBase.Interp)
@:access(hscriptBase.Parser)
@:keepSub
class SScript {
	/**
		Ignore return value 
	**/
	public static var IGNORE_RETURN(default, never):Dynamic = "###SSCRIPT_IGNORE_RETURN";

	/**
		Stop return value
	**/
	public static var STOP_RETURN(default, never):Dynamic = "###SSCRIPT_STOP_RETURN";

	/**
		If not null, assigns all scripts to check or ignore type declarations.
	**/
	public static var defaultTypeCheck(default, set):Null<Bool> = true;

	/**
		If not null, switches traces from `doString` and `new()`. 
	**/
	public static var defaultDebug(default, set):Null<Bool> = #if debug true #else null #end;

	/**
		Variables in this map will be set to every SScript instance. 
	**/
	public static var globalVariables:SScriptGlobalMap = new SScriptGlobalMap();

	/**
		Every created SScript will be mapped to this map. 
	**/
	public static var global(default, null):Map<String, SScript> = [];

	static var IDCount(default, null):Int = 0;

	static var BlankReg(get, never):EReg;

	/**
		This is a custom origin you can set.

		If not null, this will act as file path.
	**/
	public var customOrigin(default, set):String;

	/**
		Script's own return value.

		This is not to be messed up with function's return value.
	**/
	public var returnValue(default, null):Null<Dynamic>;

	/**
		ID for this script, used for scripts with no script file.
	**/
	public var ID(default, null):Null<Int> = null;

	/**
		Whether the type checker should be enabled.
	**/
	public var typeCheck:Bool = false;

	/**
		Reports how many seconds it took to execute this script. 

		It will be -1 if it failed to execute.
	**/
	public var lastReportedTime(default, null):Float = -1;

	/**
		Report how many seconds it took to call the latest function in this script.

		It will be -1 if it failed to execute.
	**/
	public var lastReportedCallTime(default, null):Float = -1;

	/**
		Used in `set`. If a class is set in this script while being in this array, an exception will be thrown.
	**/
	public var notAllowedClasses(default, null):Array<Class<Dynamic>> = [];

	/**
		Use this to access to interpreter's variables!
	**/
	public var variables(get, never):Map<String, Dynamic>;

	/**
		Main interpreter and executer. 

		Do not use `interp.variables.set` to set variables!
		Instead, use `set`.
	**/
	public var interp(default, null):Interp;

	/**
		An unique parser for the script to parse strings.
	**/
	public var parser(default, null):Parser;

	/**
		The script to execute. Gets set automatically if you create a `new` SScript.
	**/
	public var script(default, null):String = "";

	/**
		This variable tells if this script is active or not.

		Set this to false if you do not want your script to get executed!
	**/
	public var active:Bool = true;

	/**
		This string tells you the path of your script file as a read-only string.
	**/
	public var scriptFile(default, null):String = "";

	/**
		If true, enables error traces from the functions.
	**/
	public var traces:Bool = false;

	/**
		If true, enables some traces from `doString` and `new()`.
	**/
	public var debugTraces:Bool = false;

	/**
		Latest error in this script in parsing. Will be null if there aren't any errors.
	**/
	public var parsingException(default, null):SScriptException;

	/**
		Package path of this script. Gets set automatically when you use `package`.
	**/
	public var packagePath(get, null):String = "";

	@:noPrivateAccess public static final defaultDefines:Map<String, String> = #if macro null #else hscript.backend.Macro.buildDefaultDefines()#end;

	@:noPrivateAccess static var defines(default, null):Map<String, String>;

	@:deprecated("parsingExceptions are deprecated, use parsingException instead")
	var parsingExceptions(get, never):Array<Exception>;

	@:noPrivateAccess var _destroyed(default, null):Bool;

	/**
		Creates a new SScript instance.

		@param scriptPath The script path or the script itself (Files are recommended).
		@param preset If true, SScript will set some useful variables to interp. Override `preset` to customize the settings.
		@param startExecute If true, script will execute itself. If false, it will not execute.	
	**/
	public function new(?scriptPath:String = "", ?preset:Bool = true, ?startExecute:Bool = true) {
		var time = Timer.stamp();

		if (defines == null)
			if (defaultDefines != null) 
				defines = defaultDefines.copy();
			else 
				defines = new Map();

		defines["true"] = "1";
		defines["false"] = "0";
		defines["haxe"] = "1";
		#if sys
		defines["sys"] = "1";
		#end

		if (defaultTypeCheck != null)
			typeCheck = defaultTypeCheck;
		if (defaultDebug != null)
			debugTraces = defaultDebug;

		interp = new Interp();
		interp.setScr(this);

		parser = new Parser();

		if (preset)
			this.preset();

		for (i => k in globalVariables) {
			if (i != null)
				set(i, k);
		}

		try {
			doFile(scriptPath);
			if (startExecute)
				execute();
			lastReportedTime = Timer.stamp() - time;

			if (debugTraces && scriptPath != null && scriptPath.length > 0) {
				if (lastReportedTime == 0)
					trace('SScript instance created instantly (0s)');
				else
					trace('SScript instance created in ${lastReportedTime}s');
			}
		} catch (e) {
			lastReportedTime = -1;
		}
	}

	/**
		Executes this script once.

		Executing scripts with classes will not do anything.
	**/
	public function execute():Void {
		if (_destroyed)
			return;

		if (interp == null || !active)
			return;

		var origin:String = {
			if (customOrigin != null && customOrigin.length > 0)
				customOrigin;
			else if (scriptFile != null && scriptFile.length > 0)
				scriptFile;
			else
				"SScript";
		};

		if (script != null && script.length > 0) {
			resetInterp();

			try {
				var expr:Expr = parser.parseString(script, origin);
				var r = interp.execute(expr);
				returnValue = r;
			} catch (e) {
				parsingException = e;
				returnValue = null;
			}
		}
	}

	/**
		Sets a variable to this script. 

		If `key` already exists it will be replaced.
		@param key Variable name.
		@param obj The object to set. If the object is a macro class, function will be aborted.
		@return Returns this instance for chaining.
	**/
	public function set(key:String, obj:Dynamic):SScript {
		if (_destroyed)
			return null;

		if (obj != null && (obj is Class) && notAllowedClasses.contains(obj))
			throw 'Tried to set ${Type.getClassName(obj)} which is not allowed.';

		function setVar(key:String, obj:Dynamic):Void {
			if (key == null)
				return;

			if (Tools.keys.contains(key))
				throw '$key is a keyword, set something else';
			else if (obj != null && hscript.backend.Macro.macroClasses.contains(obj))
				throw '$key cannot be a Macro class (tried to set ${Type.getClassName(obj)})';

			if (!active)
				return;

			if (interp == null || !active) {
				if (traces) {
					if (interp == null)
						trace("This script is unusable!");
					else
						trace("This script is not active!");
				}
			} else
				interp.variables[key] = obj;
		}

		setVar(key, obj);
		return this;
	}

	/**
		This is a helper function to set classes easily.
		For example; if `cl` is `sys.io.File` class, it'll be set as `File`.
		@param cl The class to set. It cannot be macro classes.
		@return this instance for chaining.
	**/
	public function setClass(cl:Class<Dynamic>):SScript {
		if (_destroyed)
			return null;

		if (cl == null) {
			if (traces) {
				trace('Class cannot be null');
			}

			return null;
		}

		var clName:String = Type.getClassName(cl);
		if (clName != null) {
			var splitCl:Array<String> = clName.split('.');
			if (splitCl.length > 1) {
				clName = splitCl[splitCl.length - 1];
			}

			set(clName, cl);
		}
		return this;
	}

	/**
		Sets a class to this script from a string.
		`cl` will be formatted, for example: `sys.io.File` -> `File`.
		@param cl The class to set. It cannot be macro classes.
		@return this instance for chaining.
	**/
	public function setClassString(cl:String):SScript {
		if (_destroyed)
			return null;

		if (cl == null || cl.length < 1) {
			if (traces)
				trace('Class cannot be null');

			return null;
		}

		var cls:Class<Dynamic> = Type.resolveClass(cl);
		if (cls != null) {
			if (cl.split('.').length > 1) {
				cl = cl.split('.')[cl.split('.').length - 1];
			}

			set(cl, cls);
		}
		return this;
	}

	/**
		A special object is the object that'll get checked if a variable is not found in a Tea.

		Special object can't be basic types like Int, String, Float, Array and Bool.

		Instead, use it if you have a state instance.
		@param obj The special object. 
		@param includeFunctions If false, functions will be ignored in the special object. 
		@param exclusions Optional array of fields you want it to be excluded.
		@return Returns this instance for chaining.
	**/
	public function setSpecialObject(obj:Dynamic, ?includeFunctions:Bool = true, ?exclusions:Array<String>):SScript {
		if (_destroyed)
			return null;
		if (!active)
			return this;
		if (obj == null)
			return this;
		if (exclusions == null)
			exclusions = new Array();

		var types:Array<Dynamic> = [Int, String, Float, Bool, Array];
		for (i in types)
			if (Std.isOfType(obj, i))
				throw 'Special object cannot be ${i}';

		if (interp.specialObject == null)
			interp.specialObject = {obj: null, includeFunctions: null, exclusions: null};

		interp.specialObject.obj = obj;
		interp.specialObject.exclusions = exclusions.copy();
		interp.specialObject.includeFunctions = includeFunctions;
		return this;
	}

	/**
		Returns the local variables in this script as a fresh map.

		Changing any value in returned map will not change the script's variables.
	**/
	public function locals():Map<String, Dynamic> {
		if (_destroyed)
			return null;

		if (!active)
			return [];

		var newMap:Map<String, Dynamic> = new Map();
		for (i in interp.locals.keys()) {
			var v = interp.locals[i];
			if (v != null)
				newMap[i] = v.r;
		}
		return newMap;
	}

	/**
		Removes a variable from this script. 

		If a variable named `key` doesn't exist, unsetting won't do anything.
		@param key Variable name to remove.
		@return Returns this instance for chaining.
	**/
	public function unset(key:String):SScript {
		if (_destroyed)
			return null;

		if (interp == null || !active || key == null || !interp.variables.exists(key))
			return null;

		interp.variables.remove(key);
		return this;
	}

	/**
		Gets a variable by name. 

		If a variable named as `key` does not exists return is null.
		@param key Variable name.
		@return The object got by name.
	**/
	public function get(key:String):Dynamic {
		if (_destroyed)
			return null;

		if (interp == null || !active) {
			if (traces) {
				if (interp == null)
					trace("This script is unusable!");
				else
					trace("This script is not active!");
			}

			return null;
		}

		var l = locals();
		if (l.exists(key))
			return l[key];

		return if (exists(key)) interp.variables[key] else null;
	}

	/**
		Calls a function the script.

		`WARNING:` You MUST execute the script at least once to get the functions to script's interpreter.
		If you do not execute this script and `call` a function, script will ignore your call.

		@param func Function name in script file. 
		@param args Arguments for the `func`. If the function does not require arguments, leave it null.
		@return Returns an unique structure that contains called function, returned value etc. Returned value is at `returnValue`.
	**/
	public function call(func:String, ?args:Array<Dynamic>):TeaCall {
		if (_destroyed)
			return {
				exceptions: [
					new SScriptException(new Exception((if (scriptFile != null && scriptFile.length > 0) scriptFile else "SScript instance")
						+ " is destroyed."))
				],
				calledFunction: func,
				succeeded: false,
				returnValue: null
			};

		if (!active)
			return {
				exceptions: [
					new SScriptException(new Exception((if (scriptFile != null && scriptFile.length > 0) scriptFile else "SScript instance")
						+ " is not active."))
				],
				calledFunction: func,
				succeeded: false,
				returnValue: null
			};

		var time:Float = Timer.stamp();

		var scriptFile:String = if (scriptFile != null && scriptFile.length > 0) scriptFile else "";
		var caller:TeaCall = {
			exceptions: [],
			calledFunction: func,
			succeeded: false,
			returnValue: null
		}

		if (scriptFile != null && scriptFile.length > 0)
			Reflect.setField(caller, "fileName", scriptFile);

		if (args == null)
			args = new Array();

		var pushedExceptions:Array<String> = new Array();
		function pushException(e:String) {
			if (!pushedExceptions.contains(e))
				caller.exceptions.push(new SScriptException(new Exception(e)));

			pushedExceptions.push(e);
		}
		if (func == null) {
			if (traces)
				trace('Function name cannot be null for $scriptFile!');

			pushException('Function name cannot be null for $scriptFile!');
			return caller;
		}

		var fun = get(func);
		if (exists(func) && Type.typeof(fun) != TFunction) {
			if (traces)
				trace('$func is not a function');

			pushException('$func is not a function');
		} else if (interp == null || !exists(func)) {
			if (interp == null) {
				if (traces)
					trace('Interpreter is null!');

				pushException('Interpreter is null!');
			} else {
				if (traces)
					trace('Function $func does not exist in $scriptFile.');

				if (scriptFile != null && scriptFile.length > 1)
					pushException('Function $func does not exist in $scriptFile.');
				else
					pushException('Function $func does not exist in SScript instance.');
			}
		} else {
			var oldCaller = caller;
			try {
				var functionField:Dynamic = Reflect.callMethod(this, fun, args);
				caller = {
					exceptions: caller.exceptions,
					calledFunction: func,
					succeeded: true,
					returnValue: functionField
				};
				if (scriptFile != null && scriptFile.length > 0)
					Reflect.setField(caller, "fileName", scriptFile);
			} catch (e) {
				caller = oldCaller;
				caller.exceptions.insert(0, new SScriptException(e));
			}
		}
		lastReportedCallTime = Timer.stamp() - time;

		return caller;
	}

	/**
		Clears all of the keys assigned to this script.

		@return Returns this instance for chaining.
	**/
	public function clear():SScript {
		if (_destroyed)
			return null;
		if (!active)
			return this;

		if (interp == null)
			return this;

		var importantThings:Array<String> = ['true', 'false', 'null', 'trace'];

		for (i in interp.variables.keys())
			if (!importantThings.contains(i))
				interp.variables.remove(i);

		return this;
	}

	/**
		Tells if the `key` exists in this script's interpreter.
		@param key The string to look for.
		@return Returns true if `key` is found in interpreter.
	**/
	public function exists(key:String):Bool {
		if (_destroyed)
			return false;
		if (!active)
			return false;

		if (interp == null)
			return false;
		var l = locals();
		if (l.exists(key))
			return l.exists(key);

		return interp.variables.exists(key);
	}

	/**
		Sets some useful variables to interp to make easier using this script.
		Override this function to set your custom sets aswell.
	**/
	public function preset():Void {
		if (_destroyed)
			return;
		if (!active)
			return;

		setClass(Date);
		setClass(DateTools);
		setClass(EReg);
		setClass(Math);
		setClass(Reflect);
		setClass(Std);
		setClass(SScript);
		setClass(StringTools);
		setClass(Type);
		setClass(List);
		setClass(StringBuf);
		setClass(Xml);
		setClass(haxe.Http);
		setClass(haxe.Json);
		setClass(haxe.Log);
		setClass(haxe.Serializer);
		setClass(haxe.Unserializer);
		setClass(haxe.Timer);
		#if sys
		setClass(Sys);
		setClass(haxe.SysTools);
		setClass(sys.FileSystem);
		setClass(sys.io.File);
		setClass(sys.io.Process);
		setClass(sys.io.FileInput);
		setClass(sys.io.FileOutput);
		#end

		#if SUPERLATIVE_INCLUDE_ALL
		for (i => k in tea.backend.Macro.allClassesAvailable)
			if (!tea.backend.Macro.macroClasses.contains(k))
				set(i, k);
		#end
	}

	function resetInterp():Void {
		if (_destroyed)
			return;
		if (interp == null)
			return;

		interp.locals = new Map();
		while (interp.declared.length > 0)
			interp.declared.pop();
	}

	function doFile(scriptPath:String):Void {
		parsingException = null;

		if (_destroyed)
			return;

		if (scriptPath == null || scriptPath.length < 1 || BlankReg.match(scriptPath)) {
			ID = IDCount + 1;
			IDCount++;
			global[Std.string(ID)] = this;
			return;
		}

		#if !macro
		if (scriptPath != null && scriptPath.length > 0) {
			if (FileSystem.exists(scriptPath)) {
				scriptFile = scriptPath;
				script = File.getContent(scriptPath);
			} else {
				scriptFile = "";
				script = scriptPath;
			}

			if (scriptFile != null && scriptFile.length > 0)
				global[scriptFile] = this;
			else if (script != null && script.length > 0)
				global[script] = this;
		}
		#end
	}

	/**
		Executes a string once instead of a script file.

		This does not change your `scriptFile` but it changes `script`.

		Even though this function is faster,
		it should be avoided whenever possible.
		Always try to use a script file.
		@param string String you want to execute. If this argument is a file, this will act like `new` and will change `scriptFile`.
		@param origin Optional origin to use for this script, it will appear on traces.
		@return Returns this instance for chaining. Will return `null` if failed.
	**/
	public function doString(string:String, ?origin:String):SScript {
		if (_destroyed)
			return null;
		if (!active)
			return null;
		if (string == null || string.length < 1 || BlankReg.match(string))
			return this;

		parsingException = null;

		var time = Timer.stamp();
		try {
			var og:String = origin;
			if (og != null && og.length > 0)
				customOrigin = og;
			if (og == null || og.length < 1)
				og = customOrigin;
			if (og == null || og.length < 1)
				og = "SScript";

			if (!active || interp == null)
				return null;

			resetInterp();

			try {
				script = string;

				if (scriptFile != null && scriptFile.length > 0) {
					if (ID != null)
						global.remove(Std.string(ID));
					global[scriptFile] = this;
				} else if (script != null && script.length > 0) {
					if (ID != null)
						global.remove(Std.string(ID));
					global[script] = this;
				}

				var expr:Expr = parser.parseString(script, og);
				var r = interp.execute(expr);
				returnValue = r;
			} catch (e) {
				script = "";
				parsingException = e;
				returnValue = null;
			}

			lastReportedTime = Timer.stamp() - time;

			if (debugTraces) {
				if (lastReportedTime == 0)
					trace('SScript instance created instantly (0s)');
				else
					trace('SScript instance created in ${lastReportedTime}s');
			}
		} catch (e)
			lastReportedTime = -1;

		return this;
	}

	inline function toString():String {
		if (_destroyed)
			return "null";

		if (scriptFile != null && scriptFile.length > 0)
			return scriptFile;

		return "[SScript SScript]";
	}

	/**
		Checks for scripts in the provided path and returns them as an array.

		Make sure `path` is a directory!

		If `extensions` is not `null`, files' extensions will be checked.
		Otherwise, only files with the `.hx` extensions will be checked and listed.

		@param path The directory to check for. Nondirectory paths will be ignored.
		@param extensions Optional extension to check in file names.
		@return The script array.
	**/
	public static function listScripts(path:String, ?extensions:Array<String>):Array<SScript> {
		if (!path.endsWith('/'))
			path += '/';

		if (extensions == null || extensions.length < 1)
			extensions = ['hx'];

		var list:Array<SScript> = [];

		#if !macro
		if (FileSystem.exists(path) && FileSystem.isDirectory(path)) {
			var files:Array<String> = FileSystem.readDirectory(path);
			for (i in files) {
				var hasExtension:Bool = false;
				for (l in extensions) {
					if (i.endsWith(l)) {
						hasExtension = true;
						break;
					}
				}
				if (hasExtension && FileSystem.exists(path + i))
					list.push(new SScript(path + i));
			}
		}
		#end

		return list;
	}

	/**
		This function makes this script **COMPLETELY** unusable and unrestorable.

		If you don't want to destroy your script just yet, just set `active` to false!
	**/
	public function destroy():Void {
		if (_destroyed)
			return;

		if (global.exists(script) && script != null && script.length > 0)
			global.remove(script);
		if (global.exists(scriptFile) && scriptFile != null && scriptFile.length > 0)
			global.remove(scriptFile);

		clear();
		resetInterp();

		customOrigin = null;
		parser = null;
		interp = null;
		script = null;
		scriptFile = null;
		active = false;
		notAllowedClasses = null;
		lastReportedCallTime = -1;
		lastReportedTime = -1;
		ID = null;
		parsingException = null;
		returnValue = null;
		_destroyed = true;
	}

	function get_variables():Map<String, Dynamic> {
		if (_destroyed)
			return null;

		return interp.variables;
	}

	function setPackagePath(p):String {
		if (_destroyed)
			return null;

		return packagePath = p;
	}

	function get_packagePath():String {
		if (_destroyed)
			return null;

		return packagePath;
	}

	static function get_BlankReg():EReg {
		return ~/^[\n\r\t]$/;
	}

	function set_customOrigin(value:String):String {
		if (_destroyed)
			return null;

		@:privateAccess parser.origin = value;
		return customOrigin = value;
	}

	static function set_defaultTypeCheck(value:Null<Bool>):Null<Bool> {
		for (i in global) {
			i.typeCheck = value == null ? false : value;
			// i.execute();
		}

		return defaultTypeCheck = value;
	}

	static function set_defaultDebug(value:Null<Bool>):Null<Bool> {
		for (i in global) {
			i.debugTraces = value == null ? false : value;
			// i.execute();
		}

		return defaultDebug = value;
	}

	function get_parsingExceptions():Array<Exception> {
		if (_destroyed)
			return null;

		if (parsingException == null)
			return [];

		return @:privateAccess [parsingException.toException()];
	}
}

abstract SScriptException(Exception) {
	/**
		Exception message.
	**/
	public var message(get, never):String;

	public function new(exception:Exception)
		this = exception;

	@:from
	public static function fromException(exception:Exception):SScriptException
		return new SScriptException(exception);

	/**
		Returns exception message.
	**/
	@:to
	public function toString():String
		return message;

	/**
		Detailed exception description.

		Includes message, stack and the chain of previous exceptions (if set).
	**/
	public function details():String
		return this.details();

	function get_message():String
		return this.message;

	function toException():Exception
		return this;
}

/**
	A custom type of map which sets values to scripts in global.
**/
typedef SScriptGlobalMap = SScriptTypedGlobalMap<String, Dynamic>;

@:transitive
@:multiType(@:followWithAbstracts K)
abstract SScriptTypedGlobalMap<K, V>(IMap<K, V>) {
	public function new();

	public inline function set(key:K, value:V) {
		this.set(key, value);

		var key:String = cast key;
		var value:Dynamic = cast value;
		for (i in SScript.global) {
			@:privateAccess
			if (!i._destroyed)
				i.set(key, value);
		}
	}

	@:arrayAccess public inline function get(key:K)
		return this.get(key);

	public inline function exists(key:K)
		return this.exists(key);

	public inline function remove(key:K)
		return this.remove(key);

	public inline function keys():Iterator<K>
		return this.keys();

	public inline function iterator():Iterator<V>
		return this.iterator();

	public inline function keyValueIterator():KeyValueIterator<K, V>
		return this.keyValueIterator();

	public inline function copy():Map<K, V>
		return cast this.copy();

	public inline function toString():String
		return this.toString();

	public inline function clear():Void
		this.clear();

	@:arrayAccess @:noCompletion public inline function arrayWrite(k:K, v:V):V {
		this.set(k, v);
		var key:String = cast k;
		var value:Dynamic = cast v;
		for (i in SScript.global) {
			@:privateAccess
			if (!i._destroyed)
				i.set(key, value);
		}
		return v;
	}

	@:to static inline function toStringMap<K:String, V>(t:IMap<K, V>):StringMap<V>
		return new StringMap<V>();

	@:to static inline function toIntMap<K:Int, V>(t:IMap<K, V>):IntMap<V>
		return new IntMap<V>();

	@:to static inline function toEnumValueMapMap<K:EnumValue, V>(t:IMap<K, V>):EnumValueMap<K, V>
		return new EnumValueMap<K, V>();

	@:to static inline function toObjectMap<K:{}, V>(t:IMap<K, V>):ObjectMap<K, V>
		return new ObjectMap<K, V>();

	@:from static inline function fromStringMap<V>(map:StringMap<V>):SScriptTypedGlobalMap<String, V>
		return cast map;

	@:from static inline function fromIntMap<V>(map:IntMap<V>):SScriptTypedGlobalMap<Int, V>
		return cast map;

	@:from static inline function fromObjectMap<K:{}, V>(map:ObjectMap<K, V>):SScriptTypedGlobalMap<K, V>
		return cast map;
}


typedef TeaCall = {
	/**
		Script's file name. Will be null if the script is not from a file. 
	**/
	public var ?fileName(default, null):String;

	/**
		If call's been successful or not. 
	**/
	public var succeeded(default, null):Bool;

	/**
		Function's name that has been called. 
	**/
	public var calledFunction(default, null):String;

	/**
		Function's return value. Will be if null if there is no value.
	**/
	public var returnValue(default, null):Null<Dynamic>;

	/**
		Errors in this call. Will be empty if there are not any.
	**/
	public var exceptions(default, null):Array<SScriptException>;
}