package backend;

import flixel.FlxState;
import flixel.FlxSubState;
import flixel.util.FlxSave;
import haxe.io.Path;

class MusicBeatSubstate extends FlxSubState implements IMusicState
{
	public var stateInstance:FlxState = null;
	public static var instance:MusicBeatSubstate;

	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;

	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScript> = [];
	public final hscriptExtensions:Array<String> = ['hx', 'hscript', 'hxs', 'hxc'];
	public var instancesExclude:Array<String> = [];
	#end

	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, FlxText> = new Map<String, FlxText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	public var modchartCameras:Map<String, FlxCamera> = new Map<String, FlxCamera>();

	#if LUA_ALLOWED
	public var luaArray:Array<FunkinLua> = [];
	#end

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	private var luaDebugGroup:FlxTypedGroup<psychlua.DebugLuaText>;
	private var luaDebugCam:FlxCamera;
	private var currentClassName:String;
	#end

	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var controls(get, never):Controls;

	private function get_controls():Controls
		return Controls.instance;

	public var touchPad:TouchPad;
	public var touchPadCam:FlxCamera;
	public var luaTouchPad:TouchPad;
	public var luaTouchPadCam:FlxCamera;
	public var mobileControls:IMobileControls;
	public var mobileControlsCam:FlxCamera;

	public function addTouchPad(DPad:String, Action:String)
	{
		touchPad = new TouchPad(DPad, Action);
		add(touchPad);
	}

	public function removeTouchPad()
	{
		if (touchPad != null)
		{
			remove(touchPad);
			touchPad = FlxDestroyUtil.destroy(touchPad);
		}

		if (touchPadCam != null)
		{
			FlxG.cameras.remove(touchPadCam);
			touchPadCam = FlxDestroyUtil.destroy(touchPadCam);
		}
	}

	public function addMobileControls(defaultDrawTarget:Bool = false):Void
	{
		var extraMode = MobileData.extraActions.get(ClientPrefs.data.extraButtons);

		switch (MobileData.mode)
		{
			case 0: // RIGHT_FULL
				mobileControls = new TouchPad('RIGHT_FULL', 'NONE', extraMode);
			case 1: // LEFT_FULL
				mobileControls = new TouchPad('LEFT_FULL', 'NONE', extraMode);
			case 2: // CUSTOM
				mobileControls = MobileData.getTouchPadCustom(new TouchPad('RIGHT_FULL', 'NONE', extraMode));
			case 3: // HITBOX
				mobileControls = new Hitbox(extraMode);
		}

		mobileControls.instance = MobileData.setButtonsColors(mobileControls.instance);
		mobileControlsCam = new FlxCamera();
		mobileControlsCam.bgColor.alpha = 0;
		FlxG.cameras.add(mobileControlsCam, defaultDrawTarget);

		mobileControls.instance.cameras = [mobileControlsCam];
		mobileControls.instance.visible = false;
		add(mobileControls.instance);
	}

	public function removeMobileControls()
	{
		if (mobileControls != null)
		{
			remove(mobileControls.instance);
			mobileControls.instance = FlxDestroyUtil.destroy(mobileControls.instance);
			mobileControls = null;
		}

		if (mobileControlsCam != null)
		{
			FlxG.cameras.remove(mobileControlsCam);
			mobileControlsCam = FlxDestroyUtil.destroy(mobileControlsCam);
		}
	}

	public function addTouchPadCamera(defaultDrawTarget:Bool = false):Void
	{
		if (touchPad != null)
		{
			touchPadCam = new FlxCamera();
			touchPadCam.bgColor.alpha = 0;
			FlxG.cameras.add(touchPadCam, defaultDrawTarget);
			touchPad.cameras = [touchPadCam];
		}
	}

	public function makeLuaTouchPad(DPadMode:String, ActionMode:String)
	{
		if (members.contains(luaTouchPad))
			return;

		if (!variables.exists("luaTouchPad"))
			variables.set("luaTouchPad", luaTouchPad);

		luaTouchPad = new TouchPad(DPadMode, ActionMode, NONE);
		luaTouchPad.alpha = ClientPrefs.data.controlsAlpha;
	}

	public function addLuaTouchPad()
	{
		if (luaTouchPad == null || members.contains(luaTouchPad))
			return;

		var target = LuaUtils.getTargetInstance();
		target.insert(target.members.length + 1, luaTouchPad);
	}

	public function addLuaTouchPadCamera(defaultDrawTarget:Bool = false)
	{
		if (luaTouchPad != null)
		{
			luaTouchPadCam = new FlxCamera();
			luaTouchPadCam.bgColor.alpha = 0;
			FlxG.cameras.add(luaTouchPadCam, defaultDrawTarget);
			luaTouchPad.cameras = [luaTouchPadCam];
		}
	}

	public function removeLuaTouchPad()
	{
		if (luaTouchPad != null)
		{
			luaTouchPad.kill();
			luaTouchPad.destroy();
			remove(luaTouchPad);
			luaTouchPad = null;
		}
	}

	public function luaTouchPadPressed(button:Dynamic):Bool
	{
		if (luaTouchPad != null)
		{
			if (Std.isOfType(button, String))
				return luaTouchPad.buttonPressed(MobileInputID.fromString(button));
			else if (Std.isOfType(button, Array))
			{
				var FUCK:Array<String> = button; // haxe said "You Can't Iterate On A Dyanmic Value Please Specificy Iterator or Iterable *insert nerd emoji*" so that's the only i found to fix
				var idArray:Array<MobileInputID> = [];
				for (strId in FUCK)
					idArray.push(MobileInputID.fromString(strId));
				return luaTouchPad.anyPressed(idArray);
			}
			else
				return false;
		}
		return false;
	}

	public function luaTouchPadJustPressed(button:Dynamic):Bool
	{
		if (luaTouchPad != null)
		{
			if (Std.isOfType(button, String))
				return luaTouchPad.buttonJustPressed(MobileInputID.fromString(button));
			else if (Std.isOfType(button, Array))
			{
				var FUCK:Array<String> = button;
				var idArray:Array<MobileInputID> = [];
				for (strId in FUCK)
					idArray.push(MobileInputID.fromString(strId));
				return luaTouchPad.anyJustPressed(idArray);
			}
			else
				return false;
		}
		return false;
	}

	public function luaTouchPadJustReleased(button:Dynamic):Bool
	{
		if (luaTouchPad != null)
		{
			if (Std.isOfType(button, String))
				return luaTouchPad.buttonJustReleased(MobileInputID.fromString(button));
			else if (Std.isOfType(button, Array))
			{
				var FUCK:Array<String> = button;
				var idArray:Array<MobileInputID> = [];
				for (strId in FUCK)
					idArray.push(MobileInputID.fromString(strId));
				return luaTouchPad.anyJustReleased(idArray);
			}
			else
				return false;
		}
		return false;
	}

	public function luaTouchPadReleased(button:Dynamic):Bool
	{
		if (luaTouchPad != null)
		{
			if (Std.isOfType(button, String))
				return luaTouchPad.buttonJustReleased(MobileInputID.fromString(button));
			else if (Std.isOfType(button, Array))
			{
				var FUCK:Array<String> = button;
				var idArray:Array<MobileInputID> = [];
				for (strId in FUCK)
					idArray.push(MobileInputID.fromString(strId));
				return luaTouchPad.anyReleased(idArray);
			}
			else
				return false;
		}
		return false;
	}

	override function destroy()
	{
		controls.isInSubstate = false;
		removeTouchPad();
		removeLuaTouchPad();
		removeMobileControls();

		#if LUA_ALLOWED
		for (lua in luaArray)
		{
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = [];
		FunkinLua.customFunctions.clear();
		#end

		#if HSCRIPT_ALLOWED
		for (script in hscriptArray)
			if (script != null)
			{
				script.call('onDestroy');
				script.destroy();
			}

		while (hscriptArray.length > 0)
			hscriptArray.pop();
		#end

		super.destroy();
	}

	public function new()
	{
		instance = this;
		stateInstance = cast this;
		
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		currentClassName = Std.string(Type.getClassName(Type.getClass(this)))
			.replace('states.', '')
			.replace('substates.', '')
			.replace('.', '/');
		#end
		controls.isInSubstate = true;
		callOnScripts('onNew');
		super();
		callOnScripts('onNewPost');
	}

	override function create()
	{
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		luaDebugGroup = new FlxTypedGroup<psychlua.DebugLuaText>();
		luaDebugCam = new FlxCamera();
		luaDebugCam.bgColor.alpha = 0;
		FlxG.cameras.add(luaDebugCam, false);
		luaDebugGroup.cameras = [luaDebugCam];
		add(luaDebugGroup);
		#end
		#if LUA_ALLOWED
		startLuasNamed('substatescripts/' + currentClassName + '.lua');
		#end
		#if HSCRIPT_ALLOWED
		startHScriptsNamed('substatescripts/' + currentClassName);
		#end
		super.create();
		callOnScripts('onCreatePost');
	}

	override function openSubState(subState:FlxSubState)
	{
		controls.isInSubstate = true;
		callOnScripts('onOpenSubState');
		super.openSubState(subState);
	}

	override function closeSubState()
	{
		callOnScripts('onCloseSubState');
		super.closeSubState();
	}

	override function update(elapsed:Float)
	{
		// everyStep();
		if (!persistentUpdate)
			MusicBeatState.timePassedOnState += elapsed;
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (!controls.isInSubstate)
			controls.isInSubstate = true;

		if (oldStep != curStep)
		{
			if (curStep > 0)
				stepHit();

			if (PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		callOnScripts('onUpdate', [elapsed]);

		setOnScripts('curDecStep', curDecStep);
		setOnScripts('curDecBeat', curDecBeat);

		super.update(elapsed);

		callOnScripts('onUpdatePost', [elapsed]);
	}

	private function updateSection():Void
	{
		if (stepsToDo < 1)
			stepsToDo = Math.round(getBeatsOnSection() * 4);
		while (curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if (curStep < 0)
			return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if (stepsToDo > curStep)
					break;

				curSection++;
			}
		}

		if (curSection > lastSection)
			sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		// do literally nothing dumbass
	}

	public function sectionHit():Void
	{
		// yep, you guessed it, nothing again, dumbass
		// OR NOT!!!! - Homura (2025)
		setOnScripts('curSection', curSection);
		callOnScripts('onSectionHit');
	}

	public function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if (PlayState.SONG != null && PlayState.SONG.notes[curSection] != null)
			val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	public function addTextToDebug(text:String, color:FlxColor)
	{
		if (luaDebugGroup == null)
			return #if sys Sys.println(text) #else trace(text) #end;

		var newText:psychlua.DebugLuaText = luaDebugGroup.recycle(psychlua.DebugLuaText);
		newText.text = text;
		newText.color = color;
		newText.disableTime = 6;
		newText.alpha = 1;
		newText.setPosition(10, 8 - newText.height);

		luaDebugGroup.forEachAlive(function(spr:psychlua.DebugLuaText)
		{
			spr.y += newText.height + 2;
		});
		luaDebugGroup.add(newText);
		#if sys
		Sys.println(text);
		#else
		trace(text);
		#end
	}
	#end

	public function getLuaObject(tag:String, text:Bool = true):FlxSprite
	{
		#if LUA_ALLOWED
		if (modchartSprites.exists(tag))
			return modchartSprites.get(tag);
		if (text && modchartTexts.exists(tag))
			return modchartTexts.get(tag);
		if (variables.exists(tag))
			return variables.get(tag);
		#end
		return null;
	}

	#if LUA_ALLOWED
	public function startLuasNamed(luaFile:String)
	{
		var luaToLoad:String = '';
		#if MODS_ALLOWED
		luaToLoad = Paths.modFolders(luaFile);
		if (!FileSystem.exists(luaToLoad))
		#end
		luaToLoad = Paths.getSharedPath(luaFile);

		if (FileSystem.exists(luaToLoad))
		{
			for (script in luaArray)
				if (script.scriptName == luaToLoad)
					return false;

			new FunkinLua(luaToLoad);
			return true;
		}
		return false;
	}
	#end

	#if HSCRIPT_ALLOWED
	public function startHScriptsNamed(scriptFile:String, ?doFileMethod:String->Bool)
	{
		function doFile(file:String):Bool
		{
			if (!hscriptExtensions.contains(Path.extension(file)))
				return false;

			if (doFileMethod != null)
				return doFileMethod(scriptFile);

			var scriptToLoad:String = '';
			#if MODS_ALLOWED
			scriptToLoad = Paths.modFolders(file);
			if (!FileSystem.exists(scriptToLoad))
			#end
			scriptToLoad = Paths.getSharedPath(file);

			if (FileSystem.exists(scriptToLoad))
			{
				if (SScript.global.exists(scriptToLoad))
					return false;

				initHScript(scriptToLoad);
				return true;
			}
			else
				return false;
		}

		// if the script already has a set extension just load it directly
		var scriptFileExt:String = Path.extension(scriptFile);
		if (scriptFileExt != null && scriptFileExt.length > 0 && hscriptExtensions.contains(scriptFileExt))
			return doFile(scriptFile);

		// Try every ext and load what can be loaded
		var loadedScripts:Bool = false;
		for (ext in hscriptExtensions)
			if (doFile(Path.withExtension(scriptFile, ext)))
				loadedScripts = true;

		return loadedScripts;
	}

	public function initHScript(file:String)
	{
		try
		{
			var newScript:HScript = new HScript(null, file);
			if (newScript.parsingException != null)
			{
				addTextToDebug('ERROR ON LOADING: ${newScript.parsingException.message}', FlxColor.RED);
				newScript.destroy();
				return;
			}

			hscriptArray.push(newScript);
			if (newScript.exists('onCreate'))
			{
				var callValue = newScript.call('onCreate');
				if (!callValue.succeeded)
				{
					for (e in callValue.exceptions)
					{
						if (e != null)
						{
							var len:Int = e.message.indexOf('\n') + 1;
							if (len <= 0)
								len = e.message.length;
							addTextToDebug('ERROR ($file: onCreate) - ${e.message.substr(0, len)}', FlxColor.RED);
						}
					}

					newScript.destroy();
					hscriptArray.remove(newScript);
					trace('failed to initialize tea interp!!! ($file)');
				}
				else
					trace('initialized tea interp successfully: $file');
			}
		}
		catch (e)
		{
			var len:Int = e.message.indexOf('\n') + 1;
			if (len <= 0)
				len = e.message.length;
			addTextToDebug('ERROR - ' + e.message.substr(0, len), FlxColor.RED);
			var newScript:HScript = cast(SScript.global.get(file), HScript);
			if (newScript != null)
			{
				newScript.destroy();
				hscriptArray.remove(newScript);
			}
		}
	}
	#end

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null,
			excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		if (args == null)
			args = [];
		if (exclusions == null)
			exclusions = [];
		if (excludeValues == null)
			excludeValues = [LuaUtils.Function_Continue];

		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if (result == null || excludeValues.contains(result))
			result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}

	public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null,
			excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		#if LUA_ALLOWED
		if (args == null)
			args = [];
		if (exclusions == null)
			exclusions = [];
		if (excludeValues == null)
			excludeValues = [LuaUtils.Function_Continue];

		var arr:Array<FunkinLua> = [];
		for (script in luaArray)
		{
			if (script.closed)
			{
				arr.push(script);
				continue;
			}

			if (exclusions.contains(script.scriptName))
				continue;

			var myValue:Dynamic = script.call(funcToCall, args);
			if ((myValue == LuaUtils.Function_StopLua || myValue == LuaUtils.Function_StopAll)
				&& !excludeValues.contains(myValue)
				&& !ignoreStops)
			{
				returnVal = myValue;
				break;
			}

			if (myValue != null && !excludeValues.contains(myValue))
				returnVal = myValue;

			if (script.closed)
				arr.push(script);
		}

		if (arr.length > 0)
			for (script in arr)
				luaArray.remove(script);
		#end
		return returnVal;
	}

	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null,
			excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = LuaUtils.Function_Continue;

		#if HSCRIPT_ALLOWED
		if (exclusions == null)
			exclusions = new Array();
		if (excludeValues == null)
			excludeValues = new Array();
		excludeValues.push(LuaUtils.Function_Continue);

		var len:Int = hscriptArray.length;
		if (len < 1)
			return returnVal;
		for (i in 0...len)
		{
			var script:HScript = hscriptArray[i];
			if (script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
				continue;

			var myValue:Dynamic = null;
			try
			{
				var callValue = script.call(funcToCall, args);
				if (!callValue.succeeded)
				{
					var e = callValue.exceptions[0];
					if (e != null)
					{
						var len:Int = e.message.indexOf('\n') + 1;
						if (len <= 0)
							len = e.message.length;
						addTextToDebug('ERROR (${callValue.calledFunction}) - ' + e.message.substr(0, len), FlxColor.RED);
					}
				}
				else
				{
					myValue = callValue.returnValue;
					if ((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll)
						&& !excludeValues.contains(myValue)
						&& !ignoreStops)
					{
						returnVal = myValue;
						break;
					}

					if (myValue != null && !excludeValues.contains(myValue))
						returnVal = myValue;
				}
			}
		}
		#end

		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null)
	{
		if (exclusions == null)
			exclusions = [];
		setOnLuas(variable, arg, exclusions);
		setOnHScript(variable, arg, exclusions);
	}

	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null)
	{
		#if LUA_ALLOWED
		if (exclusions == null)
			exclusions = [];
		for (script in luaArray)
		{
			if (exclusions.contains(script.scriptName))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null)
	{
		#if HSCRIPT_ALLOWED
		if (exclusions == null)
			exclusions = [];
		for (script in hscriptArray)
		{
			if (exclusions.contains(script.origin))
				continue;

			if (!instancesExclude.contains(variable))
				instancesExclude.push(variable);
			script.set(variable, arg);
		}
		#end
	}
}
