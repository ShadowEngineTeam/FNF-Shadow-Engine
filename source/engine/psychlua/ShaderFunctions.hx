package psychlua;

import openfl.filters.ShaderFilter;
import flixel.addons.display.FlxRuntimeShader;

class ShaderFunctions
{
	private static var storedFilters:Map<String, ShaderFilter> = [];

	public static function implement(funk:FunkinLua)
	{
		// shader shit
		funk.addLocalCallback("initLuaShader", function(name:String)
		{
			if (!ClientPrefs.data.shaders)
				return false;

			return funk.initLuaShader(name);
		});

		funk.addLocalCallback("addShaderToCam", function(cam:String, shader:String, ?index:String)
		{
			if (!ClientPrefs.data.shaders)
				return false;

			if (index == null || index.length < 1)
				index = shader;

			if (!funk.runtimeShaders.exists(shader) && !funk.initLuaShader(shader))
			{
				FunkinLua.luaTrace('addShaderToCam: Shader $shader is missing!', false, false, FlxColor.RED);
				return false;
			}

			var arr:Array<String> = funk.runtimeShaders.get(shader);
			// Both FlxGame and FlxCamera has a _filters array and a setFilters function
			// We should maybe make an interface for that?
			var camera = getCam(cam);
			@:privateAccess {
				if (camera._filters == null)
					camera._filters = [];
				var filter = new ShaderFilter(new FlxRuntimeShader(arr[0], arr[1]));
				storedFilters.set(index, filter);
				camera._filters.push(filter);
			}
			return true;
		});

		funk.addLocalCallback("removeCamShader", function(cam:String, shader:String)
		{
			var camera = getCam(cam);
			@:privateAccess {
				if (!storedFilters.exists(shader))
				{
					FunkinLua.luaTrace('removeCamShader: $shader does not exist!', false, false, FlxColor.YELLOW);
					return false;
				}

				if (camera._filters == null)
				{
					FunkinLua.luaTrace('removeCamShader: camera $cam does not have any shaders!', false, false, FlxColor.YELLOW);
					return false;
				}

				camera._filters.remove(storedFilters.get(shader));
				storedFilters.remove(shader);
				return true;
			}
			return false;
		});

		funk.addLocalCallback("clearCamShaders", function(cam:String) getCam(cam).setFilters([]));

		funk.addLocalCallback("setSpriteShader", function(obj:String, shader:String)
		{
			if (!ClientPrefs.data.shaders)
				return false;

			if (!funk.runtimeShaders.exists(shader) && !funk.initLuaShader(shader))
			{
				FunkinLua.luaTrace('setSpriteShader: Shader $shader is missing!', false, false, FlxColor.RED);
				return false;
			}

			var split:Array<String> = obj.split('.');
			var leObj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (leObj != null)
			{
				var arr:Array<String> = funk.runtimeShaders.get(shader);
				leObj.shader = new FlxRuntimeShader(arr[0], arr[1]);
				return true;
			}
			return false;
		});

		funk.set("removeSpriteShader", function(obj:String)
		{
			var split:Array<String> = obj.split('.');
			var leObj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (leObj != null)
			{
				leObj.shader = null;
				return true;
			}
			return false;
		});

		funk.set("getShaderBool", function(obj:String, prop:String)
		{
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderBool: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getBool(prop);
		});

		funk.set("getShaderBoolArray", function(obj:String, prop:String)
		{
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderBoolArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getBoolArray(prop);
		});
		funk.set("getShaderInt", function(obj:String, prop:String)
		{
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderInt: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getInt(prop);
		});
		funk.set("getShaderIntArray", function(obj:String, prop:String)
		{
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderIntArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getIntArray(prop);
		});
		funk.set("getShaderFloat", function(obj:String, prop:String)
		{
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderFloat: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getFloat(prop);
		});
		funk.set("getShaderFloatArray", function(obj:String, prop:String)
		{
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderFloatArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getFloatArray(prop);
		});

		funk.set("setShaderBool", function(obj:String, prop:String, value:Bool)
		{
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("setShaderBool: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setBool(prop, value);
			return true;
		});
		funk.set("setShaderBoolArray", function(obj:String, prop:String, values:Dynamic)
		{
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("setShaderBoolArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setBoolArray(prop, values);
			return true;
		});
		funk.set("setShaderInt", function(obj:String, prop:String, value:Int)
		{
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("setShaderInt: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setInt(prop, value);
			return true;
		});
		funk.set("setShaderIntArray", function(obj:String, prop:String, values:Dynamic)
		{
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("setShaderIntArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setIntArray(prop, values);
			return true;
		});
		funk.set("setShaderFloat", function(obj:String, prop:String, value:Float)
		{
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("setShaderFloat: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setFloat(prop, value);
			return true;
		});
		funk.set("setShaderFloatArray", function(obj:String, prop:String, values:Dynamic)
		{
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("setShaderFloatArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}

			shader.setFloatArray(prop, values);
			return true;
		});

		funk.set("setShaderSampler2D", function(obj:String, prop:String, bitmapdataPath:String)
		{
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("setShaderSampler2D: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}

			// trace('bitmapdatapath: $bitmapdataPath');
			var value = Paths.image(bitmapdataPath);
			if (value != null && value.bitmap != null)
			{
				// trace('Found bitmapdata. Width: ${value.bitmap.width} Height: ${value.bitmap.height}');
				shader.setBitmapData(prop, value.bitmap);
				return true;
			}
			return false;
		});
	}

	public static function getShader(obj:String):FlxRuntimeShader
	{
		if (storedFilters.exists(obj))
			return cast(storedFilters[obj].shader, FlxRuntimeShader);

		var split:Array<String> = obj.split('.');
		var target:FlxSprite = null;
		if (split.length > 1)
			target = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
		else
			target = LuaUtils.getObjectDirectly(split[0]);

		if (target == null)
		{
			FunkinLua.luaTrace('Error on getting shader: Object $obj not found', false, false, FlxColor.RED);
			return null;
		}
		return cast(target.shader, FlxRuntimeShader);
	}

	public static function getCam(obj:String):Dynamic
	{
		if (obj.toLowerCase().trim() == "global")
			return FlxG.game;
		return LuaUtils.cameraFromString(obj);
	}
}
