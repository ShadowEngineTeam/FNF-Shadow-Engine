package psychlua;

import backend.scripting.ScriptResult;
import flixel.FlxObject;
import substates.GameOverSubstate;

class LuaSpriteFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var game:Dynamic = FunkinLua.getCurrentMusicState();

		funk.set("makeLuaSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0)
		{
			tag = tag.replace('.', '');
			LuaUtils.resetSpriteTag(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			if (image != null && image.length > 0)
				leSprite.loadGraphic(Paths.image(image));

			game.modchartSprites.set(tag, leSprite);
			leSprite.active = true;
		});

		funk.set("makeAnimatedLuaSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0, ?spriteType:String = "sparrow",
				swfMode:Bool = false, cacheOnLoad:Bool = false)
		{
			tag = tag.replace('.', '');
			LuaUtils.resetSpriteTag(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			LuaUtils.loadFrames(leSprite, image, spriteType, {swfMode: swfMode, cacheOnLoad: cacheOnLoad});
			game.modchartSprites.set(tag, leSprite);
		});

		funk.set("makeGraphic", function(obj:String, width:Int = 256, height:Int = 256, color:String = 'FFFFFF')
		{
			var spr:FlxSprite = LuaUtils.getObjectDirectly(obj, false);
			if (spr != null)
				spr.makeGraphic(width, height, CoolUtil.colorFromString(color));
		});

		funk.set("addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true)
		{
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
			if (obj != null && obj.animation != null)
			{
				obj.animation.addByPrefix(name, prefix, framerate, loop);
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
		});

		funk.set("addAnimation", function(obj:String, name:String, frames:Array<Int>, framerate:Int = 24, loop:Bool = true)
		{
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
			if (obj != null && obj.animation != null)
			{
				obj.animation.add(name, frames, framerate, loop);
				if (obj.animation.curAnim == null)
					obj.animation.play(name, true);
				return true;
			}
			return false;
		});

		funk.set("addAnimationByIndices", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24, loop:Bool = false)
		{
			return LuaUtils.addAnimByIndices(obj, name, prefix, indices, framerate, loop);
		});

		funk.set("playAnim", function(obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0)
		{
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
			if (obj.playAnim != null)
			{
				obj.playAnim(name, forced, reverse, startFrame);
				return true;
			}
			else
			{
				obj.animation.play(name, forced, reverse, startFrame);
				return true;
			}
			return false;
		});

		funk.set("addOffset", function(obj:String, anim:String, x:Float, y:Float)
		{
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
			if (obj != null && obj.addOffset != null)
			{
				obj.addOffset(anim, x, y);
				return true;
			}
			return false;
		});

		funk.set("setScrollFactor", function(obj:String, scrollX:Float, scrollY:Float)
		{
			if (game.getLuaObject(obj, false) != null)
			{
				game.getLuaObject(obj, false).scrollFactor.set(scrollX, scrollY);
				return;
			}
			var object:FlxObject = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if (object != null)
				object.scrollFactor.set(scrollX, scrollY);
		});

		funk.set("addLuaSprite", function(tag:String, front:Bool = false)
		{
			var mySprite:FlxSprite = null;
			if (game.modchartSprites.exists(tag))
				mySprite = cast(game.modchartSprites.get(tag), FlxSprite);
			else if (game.variables.exists(tag))
				mySprite = cast(game.variables.get(tag), FlxSprite);

			if (mySprite == null)
				return false;

			if (front)
				LuaUtils.getTargetInstance().add(mySprite);
			else if (!game.isDead)
				game.insert(game.members.indexOf(LuaUtils.getLowestCharacterGroup()), mySprite);
			else
				GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), mySprite);
			return true;
		});

		funk.set("setGraphicSize", function(obj:String, x:Int, y:Int = 0, updateHitbox:Bool = true)
		{
			var spr:FlxSprite = resolveSprite(obj);
			if (spr != null)
			{
				spr.setGraphicSize(x, y);
				if (updateHitbox)
					spr.updateHitbox();
				return;
			}
			FunkinLua.luaTrace('setGraphicSize: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});

		funk.set("scaleObject", function(obj:String, x:Float, y:Float, updateHitbox:Bool = true)
		{
			var spr:FlxSprite = resolveSprite(obj);
			if (spr != null)
			{
				spr.scale.set(x, y);
				if (updateHitbox)
					spr.updateHitbox();
				return;
			}
			FunkinLua.luaTrace('scaleObject: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});

		funk.set("updateHitbox", function(obj:String)
		{
			var spr:FlxSprite = resolveSprite(obj);
			if (spr != null)
			{
				spr.updateHitbox();
				return;
			}
			FunkinLua.luaTrace('updateHitbox: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});

		funk.set("updateHitboxFromGroup", function(group:String, index:Int)
		{
			if (Std.isOfType(Reflect.getProperty(LuaUtils.getTargetInstance(), group), FlxTypedGroup))
				Reflect.getProperty(LuaUtils.getTargetInstance(), group).members[index].updateHitbox();
			else
				Reflect.getProperty(LuaUtils.getTargetInstance(), group)[index].updateHitbox();
		});

		funk.set("removeLuaSprite", function(tag:String, destroy:Bool = true)
		{
			if (!game.modchartSprites.exists(tag))
				return;

			var pee:ModchartSprite = cast(game.modchartSprites.get(tag), ModchartSprite);
			LuaUtils.getTargetInstance().remove(pee, true);
			if (destroy)
			{
				pee.kill();
				pee.destroy();
				game.modchartSprites.remove(tag);
			}
		});

		funk.set("luaSpriteExists", game.modchartSprites.exists);
		funk.set("luaTextExists", game.modchartTexts.exists);
		funk.set("luaSoundExists", game.modchartSounds.exists);

		funk.set("setObjectCamera", function(obj:String, camera:String = '')
		{
			var spr = resolveSprite(obj);
			if (spr != null)
			{
				spr.cameras = [LuaUtils.cameraFromString(camera)];
				return true;
			}
			FunkinLua.luaTrace("setObjectCamera: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});

		funk.set("setBlendMode", function(obj:String, blend:String = '')
		{
			var spr = resolveSprite(obj);
			if (spr != null)
			{
				spr.blend = LuaUtils.blendModeFromString(blend);
				return true;
			}
			FunkinLua.luaTrace("setBlendMode: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});

		funk.set("screenCenter", function(obj:String, pos:String = 'xy')
		{
			var spr = resolveSprite(obj);
			if (spr != null)
			{
				switch (pos.trim().toLowerCase())
				{
					case 'x':
						spr.screenCenter(X);
					case 'y':
						spr.screenCenter(Y);
					default:
						spr.screenCenter(XY);
				}
				return;
			}
			FunkinLua.luaTrace("screenCenter: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
		});

		funk.set("objectsOverlap", function(obj1:String, obj2:String)
		{
			var objs = [resolveSprite(obj1), resolveSprite(obj2)];
			if (!objs.contains(null) && FlxG.overlap(objs[0], objs[1]))
				return true;
			return false;
		});

		funk.set("getPixelColor", function(obj:String, x:Int, y:Int)
		{
			var spr = resolveSprite(obj);
			if (spr != null)
				return spr.pixels.getPixel32(x, y);
			return FlxColor.BLACK;
		});

		funk.set("makeLuaCamera", function(tag:String, ?ddt:Bool)
		{
			if (ddt == null)
				ddt = false;
			var camera:FlxCamera = new FlxCamera();
			camera.bgColor.alpha = 0;
			FlxG.cameras.add(camera, ddt);
			game.modchartCameras.set(tag, camera);
		});
	}

	static function resolveSprite(obj:String):FlxSprite
	{
		var spr:FlxSprite = cast FunkinLua.getCurrentMusicState().getLuaObject(obj, false);
		if (spr != null)
			return spr;

		var split = obj.split('.');
		spr = LuaUtils.getObjectDirectly(split[0]);
		if (split.length > 1)
			spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);

		return spr;
	}
}
