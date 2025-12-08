package psychlua;

import Type.ValueType;
import haxe.Constraints;
import substates.GameOverSubstate;

// Functions that use a high amount of Reflections, which are somewhat CPU intensive
// These functions are held together by duct tape
class ReflectionFunctions
{
	static final instanceStr:Dynamic = "##PSYCHLUA_STRINGTOOBJ";

	public static function implement(funk:FunkinLua)
	{
		funk.set("getProperty", function(variable:String, ?allowMaps:Bool = false)
		{
			/*switch (variable)
			{
				case 'camFollowPos.x':
					return PlayState.instance.camFollow.x;
				case 'camFollowPos.y':
					return PlayState.instance.camFollow.y;
			}*/
			var split:Array<String> = variable.split('.');
			if (split.length > 1)
				return LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split, true, true, allowMaps), split[split.length - 1], allowMaps);
			return LuaUtils.getVarInArray(LuaUtils.getTargetInstance(), variable, allowMaps);
		});
		funk.set("setProperty", function(variable:String, value:Dynamic, allowMaps:Bool = false)
		{
			/*switch (variable)
			{
				case 'camFollowPos.x':
					return PlayState.instance.camFollow.x;
				case 'camFollowPos.y':
					return PlayState.instance.camFollow.y;
			}*/
			var split:Array<String> = variable.split('.');
			if (split.length > 1)
			{
				LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(split, true, true, allowMaps), split[split.length - 1], value, allowMaps);
				return value;
			}
			LuaUtils.setVarInArray(LuaUtils.getTargetInstance(), variable, value, allowMaps);
			return value;
		});
		funk.set("getPropertyFromClass", function(classVar:String, variable:String, ?allowMaps:Bool = false)
		{
			if (classVar == 'ClientPrefs')
			{
				classVar = 'backend.ClientPrefs';
				if (variable == 'globalAntialiasing')
					variable = 'antialiasing';
				variable = 'data.' + variable;
			}
			else if (classVar == 'Conductor')
				classVar = 'backend.Conductor';
			else if (classVar == 'GameOverSubstate')
				classVar = 'substates.GameOverSubstate';
			else if (classVar == 'PlayState') // I swear why people use PlayState??? wtf
				classVar = 'states.PlayState';

			var myClass:Dynamic = Type.resolveClass(classVar);
			if (myClass == null)
			{
				FunkinLua.luaTrace('getPropertyFromClass: Class $classVar not found', false, false, FlxColor.RED);
				return null;
			}

			var split:Array<String> = variable.split('.');
			if (split.length > 1)
			{
				var obj:Dynamic = LuaUtils.getVarInArray(myClass, split[0], allowMaps);
				for (i in 1...split.length - 1)
					obj = LuaUtils.getVarInArray(obj, split[i], allowMaps);

				return LuaUtils.getVarInArray(obj, split[split.length - 1], allowMaps);
			}
			return LuaUtils.getVarInArray(myClass, variable, allowMaps);
		});
		funk.set("setPropertyFromClass", function(classVar:String, variable:String, value:Dynamic, ?allowMaps:Bool = false)
		{
			if (classVar == 'ClientPrefs')
			{
				classVar = 'backend.ClientPrefs';
				if (variable == 'globalAntialiasing')
					variable = 'antialiasing';
				variable = 'data.' + variable;
			}
			else if (classVar == 'Conductor')
				classVar = 'backend.Conductor';
			else if (classVar == 'GameOverSubstate')
				classVar = 'substates.GameOverSubstate';
			else if (classVar == 'PlayState') // I swear why people use PlayState??? wtf
				classVar = 'states.PlayState';

			var myClass:Dynamic = Type.resolveClass(classVar);
			if (myClass == null)
			{
				FunkinLua.luaTrace('getPropertyFromClass: Class $classVar not found', false, false, FlxColor.RED);
				return null;
			}

			var split:Array<String> = variable.split('.');
			if (split.length > 1)
			{
				var obj:Dynamic = LuaUtils.getVarInArray(myClass, split[0], allowMaps);
				for (i in 1...split.length - 1)
					obj = LuaUtils.getVarInArray(obj, split[i], allowMaps);

				LuaUtils.setVarInArray(obj, split[split.length - 1], value, allowMaps);
				return value;
			}
			LuaUtils.setVarInArray(myClass, variable, value, allowMaps);
			return value;
		});
		funk.set("getPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, ?allowMaps:Bool = false)
		{
			var split:Array<String> = obj.split('.');
			var realObject:Dynamic = null;
			if (split.length > 1)
				realObject = LuaUtils.getPropertyLoop(split, true, false, allowMaps);
			else
				realObject = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);

			if (Std.isOfType(realObject, FlxTypedGroup))
			{
				var result:Dynamic = LuaUtils.getGroupStuff(realObject.members[index], variable, allowMaps);
				return result;
			}

			var leArray:Dynamic = realObject[index];
			if (leArray != null)
			{
				var result:Dynamic = null;
				if (Type.typeof(variable) == ValueType.TInt)
					result = leArray[variable];
				else
					result = LuaUtils.getGroupStuff(leArray, variable, allowMaps);
				return result;
			}
			FunkinLua.luaTrace("getPropertyFromGroup: Object #" + index + " from group: " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});
		funk.set("setPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, value:Dynamic, ?allowMaps:Bool = false)
		{
			var split:Array<String> = obj.split('.');
			var realObject:Dynamic = null;
			if (split.length > 1)
				realObject = LuaUtils.getPropertyLoop(split, true, false, allowMaps);
			else
				realObject = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);

			if (Std.isOfType(realObject, FlxTypedGroup))
			{
				LuaUtils.setGroupStuff(realObject.members[index], variable, value, allowMaps);
				return value;
			}

			var leArray:Dynamic = realObject[index];
			if (leArray != null)
			{
				if (Type.typeof(variable) == ValueType.TInt)
				{
					leArray[variable] = value;
					return value;
				}
				LuaUtils.setGroupStuff(leArray, variable, value, allowMaps);
			}
			return value;
		});
		funk.set("addToGroup", function(group:String, tag:String, ?index:Int = -1)
		{
			var obj:FlxSprite = LuaUtils.getObjectDirectly(tag);
			if (obj == null || obj.destroy == null)
			{
				FunkinLua.luaTrace('addToGroup: Object $tag is not valid!', false, false, FlxColor.RED);
				return;
			}

			if (['comboGroup', 'uiGroup', 'noteGroup'].contains(group))
			{
				PlayState.instance.add(obj);
				return;
			}

			var groupOrArray:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), group);
			if (groupOrArray == null)
			{
				FunkinLua.luaTrace('addToGroup: Group/Array $group is not valid!', false, false, FlxColor.RED);
				return;
			}

			if (index < 0)
			{
				switch (Type.typeof(groupOrArray))
				{
					case TClass(Array): // Array
						groupOrArray.push(obj);
					default: // Group
						groupOrArray.add(obj);
				}
			}
			else
				groupOrArray.insert(index, obj);
		});
		funk.set("removeFromGroup", function(obj:String, index:Int, dontDestroy:Bool = false)
		{
			var groupOrArray:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if (Std.isOfType(groupOrArray, FlxTypedGroup))
			{
				var sex = groupOrArray.members[index];
				groupOrArray.remove(sex, true);
				if (!dontDestroy)
					sex.destroy();
				return;
			}
			groupOrArray.remove(groupOrArray[index]);
		});

		funk.set("callMethod", function(funcToRun:String, ?args:Array<Dynamic> = null)
		{
			return callMethodFromObject(FunkinLua.getCurrentMusicState(), funcToRun, parseInstances(args));
		});
		funk.set("callMethodFromClass", function(className:String, funcToRun:String, ?args:Array<Dynamic> = null)
		{
			return callMethodFromObject(Type.resolveClass(className), funcToRun, parseInstances(args));
		});

		funk.set("createInstance", function(variableToSave:String, className:String, ?args:Array<Dynamic> = null)
		{
			variableToSave = variableToSave.trim().replace('.', '');
			if (!FunkinLua.getCurrentMusicState().variables.exists(variableToSave))
			{
				if (args == null)
					args = [];
				var myType:Dynamic = Type.resolveClass(className);

				if (myType == null)
				{
					FunkinLua.luaTrace('createInstance: Variable $variableToSave is already being used and cannot be replaced!', false, false, FlxColor.RED);
					return false;
				}

				var obj:Dynamic = Type.createInstance(myType, args);
				if (obj != null)
					FunkinLua.getCurrentMusicState().variables.set(variableToSave, obj);
				else
					FunkinLua.luaTrace('createInstance: Failed to create $variableToSave, arguments are possibly wrong.', false, false, FlxColor.RED);

				return (obj != null);
			}
			else
				FunkinLua.luaTrace('createInstance: Variable $variableToSave is already being used and cannot be replaced!', false, false, FlxColor.RED);
			return false;
		});
		funk.set("addInstance", function(objectName:String, ?inFront:Bool = false)
		{
			if (FunkinLua.getCurrentMusicState().variables.exists(objectName))
			{
				var obj:Dynamic = FunkinLua.getCurrentMusicState().variables.get(objectName);
				if (FunkinLua.getCurrentMusicState() is PlayState && !inFront)
				{
					if (!PlayState.instance.isDead)
						PlayState.instance.insert(PlayState.instance.members.indexOf(LuaUtils.getLowestCharacterGroup()), obj);
					else
						GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), obj);
				}
				else
					LuaUtils.getTargetInstance().add(obj);
			}
			else
				FunkinLua.luaTrace('addInstance: Can\'t add what doesn\'t exist~ ($objectName)', false, false, FlxColor.RED);
		});
		funk.set("instanceArg", function(instanceName:String, ?className:String = null)
		{
			var retStr:String = '$instanceStr::$instanceName';
			if (className != null)
				retStr += '::$className';
			return retStr;
		});
	}

	static function parseInstances(args:Array<Dynamic>)
	{
		for (i in 0...args.length)
		{
			var myArg:String = cast args[i];
			if (myArg != null && myArg.length > instanceStr.length)
			{
				var index:Int = myArg.indexOf('::');
				if (index > -1)
				{
					myArg = myArg.substring(index + 2);
					// trace('Op1: $myArg');
					var lastIndex:Int = myArg.lastIndexOf('::');

					var split:Array<String> = myArg.split('.');
					args[i] = (lastIndex > -1) ? Type.resolveClass(myArg.substring(0, lastIndex)) : FunkinLua.getCurrentMusicState();
					for (j in 0...split.length)
					{
						// trace('Op2: ${Type.getClass(args[i])}, ${split[j]}');
						args[i] = LuaUtils.getVarInArray(args[i], split[j].trim());
						// trace('Op3: ${args[i] != null ? Type.getClass(args[i]) : null}');
					}
				}
			}
		}
		return args;
	}

	static function callMethodFromObject(classObj:Dynamic, funcStr:String, args:Array<Dynamic> = null)
	{
		if (args == null)
			args = [];

		var split:Array<String> = funcStr.split('.');
		var funcToRun:Function = null;
		var obj:Dynamic = classObj;
		// trace('start: ' + obj);
		if (obj == null)
		{
			return null;
		}

		for (i in 0...split.length)
		{
			obj = LuaUtils.getVarInArray(obj, split[i].trim());
			// trace(obj, split[i]);
		}

		funcToRun = cast obj;
		// trace('end: $obj');
		return funcToRun != null ? Reflect.callMethod(obj, funcToRun, args) : null;
	}
}
