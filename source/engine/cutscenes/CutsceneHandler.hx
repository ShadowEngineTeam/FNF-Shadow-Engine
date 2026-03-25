package cutscenes;

import flixel.FlxBasic;
import flixel.util.FlxSort;

@:nullSafety
class CutsceneHandler extends FlxBasic
{
	public var timedEvents:Array<Dynamic> = [];
	public var finishCallback:Null<Void->Void> = null;
	public var finishCallback2:Null<Void->Void> = null;
	public var onStart:Null<Void->Void> = null;
	public var endTime:Float = 0;
	public var objects:Array<FlxSprite> = [];
	public var music:Null<String> = null;

	public function new()
	{
		super();

		timer(0, function()
		{
			if (music != null)
			{
				var musicPath = Paths.music(music);
				if (musicPath != null)
					FlxG.sound.playMusic(musicPath, 0, false);
				var musicSound = FlxG.sound.music;
				if (musicSound != null)
					musicSound.fadeIn();
			}
			if (onStart != null)
				onStart();
		});
		var playState = PlayState.instance;
		if (playState != null)
			playState.add(this);
	}

	private var cutsceneTime:Float = 0;
	private var firstFrame:Bool = false;

	override function update(elapsed)
	{
		super.update(elapsed);

		var playState = PlayState.instance;
		if (FlxG.state != playState || !firstFrame)
		{
			firstFrame = true;
			return;
		}

		cutsceneTime += elapsed;
		if (endTime <= cutsceneTime)
		{
			if (finishCallback != null)
				finishCallback();
			if (finishCallback2 != null)
				finishCallback2();

			for (spr in objects)
			{
				var pState = PlayState.instance;
				if (pState != null)
					pState.remove(spr);
				spr.kill();
				spr.destroy();
			}

			kill();
			destroy();
			if (playState != null)
				playState.remove(this);
		}

		while (timedEvents.length > 0 && timedEvents[0][0] <= cutsceneTime)
		{
			var event:Array<Dynamic> = timedEvents[0];
			if (event != null && event[1] != null)
			{
				var func:Void->Void = cast event[1];
				func();
			}
			timedEvents.shift();
		}
	}

	public function push(spr:FlxSprite)
	{
		objects.push(spr);
	}

	public function timer(time:Float, func:Void->Void)
	{
		timedEvents.push([time, func]);
		timedEvents.sort(sortByTime);
	}

	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}
}
