package psychlua;

import flixel.FlxObject;

class CustomSubstate extends MusicBeatSubstate
{
	public static var name:String = 'unnamed';
	public static var instance:CustomSubstate;

	#if LUA_ALLOWED
	public static function implement(funk:FunkinLua)
	{
		var lua = funk.lua;
		funk.set("openCustomSubstate", openCustomSubstate);
		funk.set("closeCustomSubstate", closeCustomSubstate);
		funk.set("insertToCustomSubstate", insertToCustomSubstate);
	}
	#end

	public static function openCustomSubstate(name:String, ?pauseGame:Bool = false)
	{
		if (pauseGame)
		{
			FlxG.camera.followLerp = 0;
			FunkinLua.getCurrentMusicState().persistentUpdate = false;
			FunkinLua.getCurrentMusicState().persistentDraw = true;
			FunkinLua.getCurrentMusicState().paused = true;
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				PlayState.instance.vocals.pause();
			}
		}
		FunkinLua.getCurrentMusicState().openSubState(new CustomSubstate(name));
		FunkinLua.getCurrentMusicState().setOnHScript('customSubstate', instance);
		FunkinLua.getCurrentMusicState().setOnHScript('customSubstateName', name);
	}

	public static function closeCustomSubstate()
	{
		if (instance != null)
		{
			PlayState.instance.closeSubState();
			instance = null;
			return true;
		}
		return false;
	}

	public static function insertToCustomSubstate(tag:String, ?pos:Int = -1)
	{
		if (instance != null)
		{
			var tagObject:FlxObject = cast(FunkinLua.getCurrentMusicState().variables.get(tag), FlxObject);
			#if LUA_ALLOWED
			if (tagObject == null)
				tagObject = cast(FunkinLua.getCurrentMusicState().modchartSprites.get(tag), FlxObject);
			#end

			if (tagObject != null)
			{
				if (pos < 0)
					instance.add(tagObject);
				else
					instance.insert(pos, tagObject);
				return true;
			}
		}
		return false;
	}

	public static function insertLuaTpad(?pos:Int = -1)
	{
		if (instance != null)
		{
			var tagObject:FlxObject = FunkinLua.getCurrentMusicState().luaTouchPad;

			if (tagObject != null)
			{
				if (pos < 0)
					instance.add(tagObject);
				else
					instance.insert(pos, tagObject);
				return true;
			}
		}
		return false;
	}

	override function create()
	{
		instance = this;

		FunkinLua.getCurrentMusicState().callOnScripts('onCustomSubstateCreate', [name]);
		super.create();
		FunkinLua.getCurrentMusicState().callOnScripts('onCustomSubstateCreatePost', [name]);
	}

	public function new(name:String)
	{
		CustomSubstate.name = name;
		super();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float)
	{
		final args:Array<Dynamic> = [name, elapsed];
		FunkinLua.getCurrentMusicState().callOnScripts('onCustomSubstateUpdate', args);
		super.update(elapsed);
		FunkinLua.getCurrentMusicState().callOnScripts('onCustomSubstateUpdatePost', args);
	}

	override function destroy()
	{
		FunkinLua.getCurrentMusicState().callOnScripts('onCustomSubstateDestroy', [name]);
		name = 'unnamed';

		FunkinLua.getCurrentMusicState().setOnHScript('customSubstate', null);
		FunkinLua.getCurrentMusicState().setOnHScript('customSubstateName', name);
		super.destroy();
	}
}
