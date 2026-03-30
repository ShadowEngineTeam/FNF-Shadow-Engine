package objects;

import flixel.FlxG;
import flixel.system.frontEnds.SoundFrontEnd;
import flixel.system.ui.FlxSoundTray;
import openfl.display.Bitmap;
import backend.Paths;

@:nullSafety
class CustomSoundTray extends FlxSoundTray
{
	var graphicScale:Float = 0.3;
	var lerpYPos:Float = 0;
	var alphaTarget:Float = 0;
	var _lastVolume:Int = -1;

	var bg:Null<Bitmap> = null;
	var backingBar:Null<Bitmap> = null;
	var imagesLoaded:Bool = false;

	public function new()
	{
		super();

		bg = new Bitmap();
		backingBar = new Bitmap();

		removeChildren();
		loadImages();

		y = -height;
		visible = false;
		screenCenter();

		_lastVolume = Math.round(MathTools.logToLinear(FlxG.sound.volume) * 10);
	}

	function loadImages():Void
	{
		if (imagesLoaded)
			return;
		
		removeChildren();

		var bgGraphic = Paths.image('soundtray/volumebox', 'shared');
		if (bgGraphic != null)
		{
			bg = new Bitmap(bgGraphic.bitmap);
			bg.scaleX = graphicScale;
			bg.scaleY = graphicScale;
			bg.smoothing = true;
			addChild(bg);
		}

		var backingGraphic = Paths.image('soundtray/bars_10', 'shared');
		if (backingGraphic != null)
		{
			backingBar = new Bitmap(backingGraphic.bitmap);
			backingBar.x = 9;
			backingBar.y = 5;
			backingBar.scaleX = graphicScale;
			backingBar.scaleY = graphicScale;
			backingBar.smoothing = true;
			addChild(backingBar);
			backingBar.alpha = 0.4;
		}

		_bars = [];

		for (i in 1...11)
		{
			var barGraphic = Paths.image('soundtray/bars_$i', 'shared');
			if (barGraphic != null)
			{
				var bar:Bitmap = new Bitmap(barGraphic.bitmap);
				bar.x = 9;
				bar.y = 5;
				bar.scaleX = graphicScale;
				bar.scaleY = graphicScale;
				bar.smoothing = true;
				addChild(bar);
				_bars.push(bar);
			}
			else
			{
				var emptyBar:Bitmap = new Bitmap();
				_bars.push(emptyBar);
			}
		}

		imagesLoaded = true;
	}

	function coolLerp(base:Float, target:Float, ratio:Float):Float
	{
		return base + (ratio * (FlxG.elapsed / (1 / 60))) * (target - base);
	}

	override function update(MS:Float):Void
	{
		y = coolLerp(y, lerpYPos, 0.1);
		alpha = coolLerp(alpha, alphaTarget, 0.1);

		var shouldHide = (FlxG.sound.muted == false && FlxG.sound.volume > 0);

		if (_timer > 0)
		{
			if (shouldHide)
				_timer -= (MS / 1000);
			alphaTarget = 1;
		}
		else if (y >= -height)
		{
			lerpYPos = -height - 10;
			alphaTarget = 0;
		}

		if (y <= -height)
		{
			visible = false;
			active = false;
		}
	}

	override public function show(up:Bool = false):Void
	{
		var globalVolume:Int = Math.round(MathTools.logToLinear(FlxG.sound.volume) * 10);

		if (!silent)
		{
			var soundKey:Null<String> = null;
			if (up)
			{
				if (_lastVolume == 10 && globalVolume == 10)
					soundKey = 'soundtray/VolMAX';
				else
					soundKey = 'soundtray/Volup';
			}
			else
				soundKey = 'soundtray/Voldown';

			if (soundKey != null)
			{
				var sound = Paths.sound(soundKey, 'shared');
				if (sound != null)
					FlxG.sound.play(sound);
			}
		}

		_timer = 1;
		lerpYPos = 10;
		visible = true;
		active = true;

		if (FlxG.sound.muted || FlxG.sound.volume == 0)
			globalVolume = 0;

		_lastVolume = globalVolume;

		FlxG.save.data.volume = FlxG.sound.volume;
		FlxG.save.data.mute = FlxG.sound.muted;

		for (i in 0..._bars.length)
			_bars[i].visible = i < globalVolume;
	}
}

class CustomSoundFrontEnd extends SoundFrontEnd
{
	@:privateAccess
	override function changeVolume(amount:Float):Void
	{
		muted = false;
		volume = MathTools.logToLinear(volume);
		volume += amount;
		volume = MathTools.linearToLog(volume);
		showSoundTray(amount > 0);
	}
}

private class MathTools
{
	public static function linearToLog(x:Float, minValue:Float = 0.001):Float
	{
		x = Math.max(0, Math.min(1, x));
		return Math.exp(Math.log(minValue) * (1 - x));
	}

	public static function logToLinear(x:Float, minValue:Float = 0.001):Float
	{
		x = Math.max(minValue, Math.min(1, x));
		return 1 - (Math.log(x) / Math.log(minValue));
	}
}
