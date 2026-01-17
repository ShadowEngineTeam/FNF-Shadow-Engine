package psychlua;

import backend.WeekData;
import objects.Character;
import objects.Note;
import openfl.display.BlendMode;
import Type.ValueType;
import substates.GameOverSubstate;

typedef LuaTweenOptions =
{
	type:FlxTweenType,
	startDelay:Float,
	onUpdate:Null<String>,
	onStart:Null<String>,
	onComplete:Null<String>,
	loopDelay:Float,
	ease:EaseFunction
}

class LuaUtils
{
	public static final Function_Stop:Dynamic = "##PSYCHLUA_FUNCTIONSTOP";
	public static final Function_Continue:Dynamic = "##PSYCHLUA_FUNCTIONCONTINUE";
	public static final Function_StopLua:Dynamic = "##PSYCHLUA_FUNCTIONSTOPLUA";
	public static final Function_StopHScript:Dynamic = "##PSYCHLUA_FUNCTIONSTOPHSCRIPT";
	public static final Function_StopAll:Dynamic = "##PSYCHLUA_FUNCTIONSTOPALL";

	public static function getLuaTween(options:Dynamic)
	{
		return {
			type: getTweenTypeByString(options.type),
			startDelay: options.startDelay,
			onUpdate: options.onUpdate,
			onStart: options.onStart,
			onComplete: options.onComplete,
			loopDelay: options.loopDelay,
			ease: getTweenEaseByString(options.ease)
		};
	}

	public static function setVarInArray(instance:Dynamic, variable:String, value:Dynamic, allowMaps:Bool = false):Any
	{
		var splitProps:Array<String> = variable.split('[');
		if (splitProps.length > 1)
		{
			var target:Dynamic = null;
			if (FunkinLua.getCurrentMusicState().variables.exists(splitProps[0]))
			{
				var retVal:Dynamic = FunkinLua.getCurrentMusicState().variables.get(splitProps[0]);
				if (retVal != null)
					target = retVal;
			}
			else
				target = Reflect.getProperty(instance, splitProps[0]);

			for (i in 1...splitProps.length)
			{
				var j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
				if (i >= splitProps.length - 1) // Last array
					target[j] = value;
				else // Anything else
					target = target[j];
			}
			return target;
		}

		if (allowMaps && isMap(instance))
		{
			// trace(instance);
			instance.set(variable, value);
			return value;
		}

		if (FunkinLua.getCurrentMusicState().variables.exists(variable))
		{
			FunkinLua.getCurrentMusicState().variables.set(variable, value);
			return value;
		}
		Reflect.setProperty(instance, variable, value);
		return value;
	}

	public static function getVarInArray(instance:Dynamic, variable:String, allowMaps:Bool = false):Any
	{
		var splitProps:Array<String> = variable.split('[');
		if (splitProps.length > 1)
		{
			var target:Dynamic = null;
			if (FunkinLua.getCurrentMusicState().variables.exists(splitProps[0]))
			{
				var retVal:Dynamic = cast(FunkinLua.getCurrentMusicState().variables.get(splitProps[0]));
				if (retVal != null)
					target = retVal;
			}
			else
				target = Reflect.getProperty(instance, splitProps[0]);

			for (i in 1...splitProps.length)
			{
				var j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
				target = target[j];
			}
			return target;
		}

		if (allowMaps && isMap(instance))
		{
			// trace(instance);
			return instance.get(variable);
		}

		if (FunkinLua.getCurrentMusicState().variables.exists(variable))
		{
			var retVal:Dynamic = cast(FunkinLua.getCurrentMusicState().variables.get(variable));
			if (retVal != null)
				return retVal;
		}
		return Reflect.getProperty(instance, variable);
	}

	public static function getModSetting(saveTag:String, ?modName:String = null)
	{
		#if MODS_ALLOWED
		if (FlxG.save.data.modSettings == null)
			FlxG.save.data.modSettings = new Map<String, Dynamic>();

		var settings:Map<String, Dynamic> = FlxG.save.data.modSettings.get(modName);
		var path:String = Paths.mods('$modName/data/settings.json');
		if (FileSystem.exists(path))
		{
			if (settings == null || !settings.exists(saveTag))
			{
				if (settings == null)
					settings = new Map<String, Dynamic>();
				var data:String = File.getContent(path);
				try
				{
					// FunkinLua.luaTrace('getModSetting: Trying to find default value for "$saveTag" in Mod: "$modName"');
					var parsedJson:Dynamic = Json.parse(data, path);
					for (i in 0...parsedJson.length)
					{
						var sub:Dynamic = parsedJson[i];
						if (sub != null && sub.save != null && (!settings.exists(sub.save) || settings.get(sub.save) != sub.value))
						{
							if (sub.type != 'keybind' && sub.type != 'key')
							{
								if (sub.value != null)
								{
									// FunkinLua.luaTrace('getModSetting: Found unsaved value "${sub.save}" in Mod: "$modName"');
									settings.set(sub.save, sub.value);
								}
							}
							else
							{
								// FunkinLua.luaTrace('getModSetting: Found unsaved keybind "${sub.save}" in Mod: "$modName"');
								settings.set(sub.save,
									{keyboard: (sub.keyboard != null ? sub.keyboard : 'NONE'), gamepad: (sub.gamepad != null ? sub.gamepad : 'NONE')});
							}
						}
					}
					FlxG.save.data.modSettings.set(modName, settings);
				}
				catch (e:Dynamic)
				{
					var errorTitle = 'Mod name: ' + Mods.currentModDirectory;
					var errorMsg = 'An error occurred: $e';
					CoolUtil.showPopUp(errorMsg, errorTitle);
				}
			}
		}
		else
		{
			FlxG.save.data.modSettings.remove(modName);
			#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
			FunkinLua.getCurrentMusicState().addTextToDebug('getModSetting: $path could not be found!', FlxColor.RED);
			#else
			FlxG.log.warn('getModSetting: $path could not be found!');
			#end
			return null;
		}

		if (settings.exists(saveTag))
			return settings.get(saveTag);
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		FunkinLua.getCurrentMusicState().addTextToDebug('getModSetting: "$saveTag" could not be found inside $modName\'s settings!', FlxColor.RED);
		#else
		FlxG.log.warn('getModSetting: "$saveTag" could not be found inside $modName\'s settings!');
		#end
		#end
		return null;
	}

	public static function isMap(variable:Dynamic)
	{
		/*switch(Type.typeof(variable)){
			case ValueType.TClass(haxe.ds.StringMap) | ValueType.TClass(haxe.ds.ObjectMap) | ValueType.TClass(haxe.ds.IntMap) | ValueType.TClass(haxe.ds.EnumValueMap):
				return true;
			default:
				return false;
		}*/

		// trace(variable);
		if (variable.exists != null && variable.keyValueIterator != null)
			return true;
		return false;
	}

	public static function setGroupStuff(leArray:Dynamic, variable:String, value:Dynamic, ?allowMaps:Bool = false):Dynamic
	{
		if (Std.isOfType(leArray, Note))
		{
			var note:Note = cast leArray;
			switch (variable)
			{
				case "noteSplashDisabled":
					note.noteSplashData.disabled = value;
					return value;
				case "noteSplashTexture":
					note.noteSplashData.texture = value;
					return value;
				case "noteSplashUseGlobalShader":
					note.noteSplashData.useGlobalShader = value;
					return value;
				case "noteSplashR":
					note.noteSplashData.r = value;
					return value;
				case "noteSplashG":
					note.noteSplashData.g = value;
					return value;
				case "noteSplashB":
					note.noteSplashData.b = value;
					return value;
				case "noteSplashA":
					note.noteSplashData.a = value;
					return value;
			}
		}

		var split:Array<String> = variable.split('.');
		if (split.length > 1)
		{
			var obj:Dynamic = Reflect.getProperty(leArray, split[0]);
			for (i in 1...split.length - 1)
				obj = Reflect.getProperty(obj, split[i]);

			leArray = obj;
			variable = split[split.length - 1];
		}
		if (allowMaps && isMap(leArray))
			leArray.set(variable, value);
		else
			Reflect.setProperty(leArray, variable, value);
		return value;
	}

	public static function getGroupStuff(leArray:Dynamic, variable:String, ?allowMaps:Bool = false):Dynamic
	{
		if (Std.isOfType(leArray, Note))
		{
			var note:Note = cast leArray;
			switch (variable)
			{
				case "noteSplashDisabled":
					return note.noteSplashData.disabled;
				case "noteSplashTexture":
					return note.noteSplashData.texture;
				case "noteSplashUseGlobalShader":
					return note.noteSplashData.useGlobalShader;
				case "noteSplashR":
					return note.noteSplashData.r;
				case "noteSplashG":
					return note.noteSplashData.g;
				case "noteSplashB":
					return note.noteSplashData.b;
				case "noteSplashA":
					return note.noteSplashData.a;
			}
		}

		var split:Array<String> = variable.split('.');
		if (split.length > 1)
		{
			var obj:Dynamic = Reflect.getProperty(leArray, split[0]);
			for (i in 1...split.length - 1)
				obj = Reflect.getProperty(obj, split[i]);

			leArray = obj;
			variable = split[split.length - 1];
		}

		if (allowMaps && isMap(leArray))
			return leArray.get(variable);
		return Reflect.getProperty(leArray, variable);
	}

	public static function getPropertyLoop(split:Array<String>, ?checkForTextsToo:Bool = true, ?getProperty:Bool = true, ?allowMaps:Bool = false):Dynamic
	{
		var obj:Dynamic = getObjectDirectly(split[0], checkForTextsToo);
		var end = split.length;
		if (getProperty)
			end = split.length - 1;

		for (i in 1...end)
			obj = getVarInArray(obj, split[i], allowMaps);
		return obj;
	}

	public static function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true, ?allowMaps:Bool = false):Dynamic
	{
		switch (objectName)
		{
			case 'this' | 'instance' | 'game':
				return FunkinLua.getCurrentMusicState();

			default:
				var obj:Dynamic = cast(FunkinLua.getCurrentMusicState().getLuaObject(objectName, checkForTextsToo));
				if (obj == null)
					obj = getVarInArray(getTargetInstance(), objectName, allowMaps);
				return obj;
		}
	}

	inline public static function getTextObject(name:String):FlxText
	{
		return #if LUA_ALLOWED FunkinLua.getCurrentMusicState().modchartTexts.exists(name) ? FunkinLua.getCurrentMusicState().modchartTexts.get(name) : #end
		Reflect.getProperty(FunkinLua.getCurrentMusicState(), name);
	}

	public static function isOfTypes(value:Any, types:Array<Dynamic>)
	{
		for (type in types)
		{
			if (Std.isOfType(value, type))
				return true;
		}
		return false;
	}

	public static inline function getTargetInstance()
	{
		return FunkinLua.getCurrentMusicState() is PlayState ? PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance : FunkinLua.getCurrentMusicState().stateInstance;
	}

	public static inline function getLowestCharacterGroup():FlxSpriteGroup
	{
		var group:FlxSpriteGroup = PlayState.instance.gfGroup;
		var pos:Int = PlayState.instance.members.indexOf(group);

		var newPos:Int = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
		if (newPos < pos)
		{
			group = PlayState.instance.boyfriendGroup;
			pos = newPos;
		}

		newPos = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);
		if (newPos < pos)
		{
			group = PlayState.instance.dadGroup;
			pos = newPos;
		}
		return group;
	}

	public static function addAnimByIndices(obj:String, name:String, prefix:String, indices:Any = null, framerate:Int = 24, loop:Bool = false)
	{
		var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
		if (obj != null && obj.animation != null)
		{
			if (indices == null)
				indices = [0];
			else if (Std.isOfType(indices, String))
			{
				var strIndices:Array<String> = cast(indices, String).trim().split(',');
				var myIndices:Array<Int> = [];
				for (i in 0...strIndices.length)
				{
					myIndices.push(Std.parseInt(strIndices[i]));
				}
				indices = myIndices;
			}

			obj.animation.addByIndices(name, prefix, indices, '', framerate, loop);
			if (obj.animation.curAnim == null)
			{
				if (obj.playAnim != null)
					obj.playAnim(name, true);
				else
					obj.animation.play(name, true);
			}
			return true;
		}
		return false;
	}

	public static function loadFrames(spr:FlxSprite, image:String, spriteType:String, ?animateSettings:{?swfMode:Bool, ?cacheOnLoad:Bool})
	{
		switch (spriteType.toLowerCase().trim())
		{
			// case "texture_noaa" | "textureatlas_noaa" | "tex_noaa":
			// spr.frames = AtlasFrameMaker.construct(image, null, true);

			case 'aseprite' | 'jsoni8':
				spr.frames = Paths.getAsepriteAtlas(image);

			case "packer" | "packeratlas" | "pac":
				spr.frames = Paths.getPackerAtlas(image);
			case "texture" | "textureatlas" | "tex":
				spr.frames = Paths.getTextureAtlas(image, animateSettings != null ? {swfMode: animateSettings.swfMode ?? false, cacheOnLoad: animateSettings.cacheOnLoad ?? false} : null);
			default:
				spr.frames = Paths.getSparrowAtlas(image);
		}
	}

	public static function resetTextTag(tag:String)
	{
		#if LUA_ALLOWED
		if (!FunkinLua.getCurrentMusicState().modchartTexts.exists(tag))
		{
			return;
		}

		var target:FlxText = cast(FunkinLua.getCurrentMusicState().modchartTexts.get(tag), FlxText);
		FunkinLua.getCurrentMusicState().remove(target, true);
		target.kill();
		target.destroy();
		FunkinLua.getCurrentMusicState().modchartTexts.remove(tag);
		#end
	}

	public static function resetSpriteTag(tag:String)
	{
		#if LUA_ALLOWED
		if (!FunkinLua.getCurrentMusicState().modchartSprites.exists(tag))
		{
			return;
		}

		var target:ModchartSprite = cast(FunkinLua.getCurrentMusicState().modchartSprites.get(tag), ModchartSprite);
		FunkinLua.getCurrentMusicState().remove(target, true);
		target.kill();
		target.destroy();
		FunkinLua.getCurrentMusicState().modchartSprites.remove(tag);
		#end
	}

	public static function cancelTween(tag:String)
	{
		#if LUA_ALLOWED
		if (FunkinLua.getCurrentMusicState().modchartTweens.exists(tag))
		{
			FunkinLua.getCurrentMusicState().modchartTweens.get(tag).cancel();
			FunkinLua.getCurrentMusicState().modchartTweens.get(tag).destroy();
			FunkinLua.getCurrentMusicState().modchartTweens.remove(tag);
		}
		#end
	}

	public static function tweenPrepare(tag:String, vars:String)
	{
		cancelTween(tag);
		var variables:Array<String> = vars.split('.');
		var sexyProp:Dynamic = LuaUtils.getObjectDirectly(variables[0]);
		if (variables.length > 1)
			sexyProp = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(variables), variables[variables.length - 1]);
		return sexyProp;
	}

	public static function cancelTimer(tag:String)
	{
		#if LUA_ALLOWED
		if (FunkinLua.getCurrentMusicState().modchartTimers.exists(tag))
		{
			var theTimer:FlxTimer = cast(FunkinLua.getCurrentMusicState().modchartTimers.get(tag), FlxTimer);
			theTimer.cancel();
			theTimer.destroy();
			FunkinLua.getCurrentMusicState().modchartTimers.remove(tag);
		}
		#end
	}

	public static function getBuildTarget():String
	{
		#if windows
		return 'windows';
		#elseif linux
		return 'linux';
		#elseif mac
		return 'mac';
		#elseif android
		return 'android';
		#elseif (ios || iphonesim)
		return 'ios';
		#else
		return 'unknown';
		#end
	}

	// buncho string stuffs
	public static function getTweenTypeByString(?type:String = '')
	{
		switch (type.toLowerCase().trim())
		{
			case 'backward':
				return FlxTweenType.BACKWARD;
			case 'looping' | 'loop':
				return FlxTweenType.LOOPING;
			case 'persist':
				return FlxTweenType.PERSIST;
			case 'pingpong':
				return FlxTweenType.PINGPONG;
		}
		return FlxTweenType.ONESHOT;
	}

	public static function getTweenEaseByString(?ease:String = '')
	{
		switch (ease.toLowerCase().trim())
		{
			case 'backin':
				return FlxEase.backIn;
			case 'backinout':
				return FlxEase.backInOut;
			case 'backout':
				return FlxEase.backOut;
			case 'bouncein':
				return FlxEase.bounceIn;
			case 'bounceinout':
				return FlxEase.bounceInOut;
			case 'bounceout':
				return FlxEase.bounceOut;
			case 'circin':
				return FlxEase.circIn;
			case 'circinout':
				return FlxEase.circInOut;
			case 'circout':
				return FlxEase.circOut;
			case 'cubein':
				return FlxEase.cubeIn;
			case 'cubeinout':
				return FlxEase.cubeInOut;
			case 'cubeout':
				return FlxEase.cubeOut;
			case 'elasticin':
				return FlxEase.elasticIn;
			case 'elasticinout':
				return FlxEase.elasticInOut;
			case 'elasticout':
				return FlxEase.elasticOut;
			case 'expoin':
				return FlxEase.expoIn;
			case 'expoinout':
				return FlxEase.expoInOut;
			case 'expoout':
				return FlxEase.expoOut;
			case 'quadin':
				return FlxEase.quadIn;
			case 'quadinout':
				return FlxEase.quadInOut;
			case 'quadout':
				return FlxEase.quadOut;
			case 'quartin':
				return FlxEase.quartIn;
			case 'quartinout':
				return FlxEase.quartInOut;
			case 'quartout':
				return FlxEase.quartOut;
			case 'quintin':
				return FlxEase.quintIn;
			case 'quintinout':
				return FlxEase.quintInOut;
			case 'quintout':
				return FlxEase.quintOut;
			case 'sinein':
				return FlxEase.sineIn;
			case 'sineinout':
				return FlxEase.sineInOut;
			case 'sineout':
				return FlxEase.sineOut;
			case 'smoothstepin':
				return FlxEase.smoothStepIn;
			case 'smoothstepinout':
				return FlxEase.smoothStepInOut;
			case 'smoothstepout':
				return FlxEase.smoothStepInOut;
			case 'smootherstepin':
				return FlxEase.smootherStepIn;
			case 'smootherstepinout':
				return FlxEase.smootherStepInOut;
			case 'smootherstepout':
				return FlxEase.smootherStepOut;
		}
		return FlxEase.linear;
	}

	public static function blendModeFromString(blend:String):BlendMode
	{
		switch (blend.toLowerCase().trim())
		{
			case 'add':
				return ADD;
			case 'alpha':
				return ALPHA;
			case 'darken':
				return DARKEN;
			case 'difference':
				return DIFFERENCE;
			case 'erase':
				return ERASE;
			case 'hardlight':
				return HARDLIGHT;
			case 'invert':
				return INVERT;
			case 'layer':
				return LAYER;
			case 'lighten':
				return LIGHTEN;
			case 'multiply':
				return MULTIPLY;
			case 'overlay':
				return OVERLAY;
			case 'screen':
				return SCREEN;
			case 'shader':
				return SHADER;
			case 'subtract':
				return SUBTRACT;
		}
		return NORMAL;
	}

	public static function typeToString(type:Int):String
	{
		#if LUA_ALLOWED
		switch (type)
		{
			case type if (type == Lua.TBOOLEAN):
				return "boolean";
			case type if (type == Lua.TNUMBER):
				return "number";
			case type if (type == Lua.TSTRING):
				return "string";
			case type if (type == Lua.TTABLE):
				return "table";
			case type if (type == Lua.TFUNCTION):
				return "function";
			case type if (type <= Lua.TNIL):
				return "nil";
		}
		#end
		return "unknown";
	}

	public static function cameraFromString(cam:String):FlxCamera
	{
		if (FunkinLua.getCurrentMusicState().modchartCameras.exists(cam))
			return FunkinLua.getCurrentMusicState().modchartCameras.get(cam);
		else
			return switch (cam.toLowerCase())
			{
				case 'camhud' | 'hud':
					PlayState.instance.camHUD;
				case 'camother' | 'other':
					PlayState.instance.camOther;
				default:
					PlayState.instance.camGame;
			}
	}
}
