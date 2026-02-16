package psychlua;

import flixel.FlxObject;

class CustomSubstate extends MusicBeatSubstate
{
	public static var name:String = 'unnamed';
	public static var instance:CustomSubstate;

	#if FEATURE_LUA
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
			PlayState.instance.paused = true;
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				if (PlayState.instance.vocals != null)
					PlayState.instance.vocals.pause();
			}
		}
		FunkinLua.getCurrentMusicState().openSubState(new CustomSubstate(name, FunkinLua.getCurrentMusicState()));
		FunkinLua.getCurrentMusicState().setOnHScript('customSubstate', instance);
		FunkinLua.getCurrentMusicState().setOnHScript('customSubstateName', name);
	}

	public static function closeCustomSubstate()
	{
		if (instance != null)
		{
			FunkinLua.getCurrentMusicState().closeSubState();
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
			#if FEATURE_LUA
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

	#if FEATURE_MOBILE_CONTROLS
	public static function insertLuaTpad(?pos:Int = -1)
	{
		if (instance != null)
		{
			var tagObject:TouchPad = cast(FunkinLua.getCurrentMusicState().luaTouchPad, TouchPad);

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
	#end

	override function create()
	{
		parent.callOnScripts('onCustomSubstateCreate', [name]);
		super.create();
		parent.callOnScripts('onCustomSubstateCreatePost', [name]);
	}

	public var parent:Dynamic = null;
	public function new(name:String, parent:Dynamic)
	{
		instance = this;
		this.parent = parent;
		CustomSubstate.name = name;
		super();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float)
	{
		final args:Array<Dynamic> = [name, elapsed];
		parent.callOnScripts('onCustomSubstateUpdate', args);
		super.update(elapsed);
		parent.callOnScripts('onCustomSubstateUpdatePost', args);
	}

	override function destroy()
	{
		parent.callOnScripts('onCustomSubstateDestroy', [name]);
		name = 'unnamed';

		parent.setOnHScript('customSubstate', null);
		parent.setOnHScript('customSubstateName', name);
		parent = null;
		super.destroy();
	}
}
