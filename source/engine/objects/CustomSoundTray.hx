package objects;

import flixel.FlxG;
import flixel.system.frontEnds.SoundFrontEnd;
import flixel.system.ui.FlxSoundTray;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.media.Sound;

class CustomSoundTray extends FlxSoundTray
{
	var graphicScale:Float = 0.3;
	var lerpYPos:Float = 0;
	var alphaTarget:Float = 0;
	var volumeMaxSound:String;
	var _lastVolume:Int = -1;

	var bg:Bitmap;
	var backingBar:Bitmap;
	var bgPath:String;
	var backingPath:String;
	var barPaths:Array<String> = [];

	public function new()
	{
		super();
		removeChildren();

		bg = new Bitmap();
		backingBar = new Bitmap();
		bgPath = "";
		backingPath = "";
		barPaths = [];
		
		loadImages();
		
		y = -height;
		visible = false;
		screenCenter();

		_lastVolume = Math.round(MathTools.logToLinear(FlxG.sound.volume) * 10);
	}

	function loadImages():Void
	{
		removeChildren();
		
		bgPath = getImagePath('soundtray/volumebox');
		if (FileSystem.exists(bgPath))
		{
			bg = new Bitmap(BitmapData.fromBytes(File.getBytes(bgPath)));
			bg.scaleX = graphicScale;
			bg.scaleY = graphicScale;
			bg.smoothing = true;
			addChild(bg);
		}

		backingPath = getImagePath('soundtray/bars_10');
		if (FileSystem.exists(backingPath))
		{
			backingBar = new Bitmap(BitmapData.fromBytes(File.getBytes(backingPath)));
			backingBar.x = 9;
			backingBar.y = 5;
			backingBar.scaleX = graphicScale;
			backingBar.scaleY = graphicScale;
			backingBar.smoothing = true;
			addChild(backingBar);
			backingBar.alpha = 0.4;
		}

		_bars = [];
		barPaths = [];
		
		for (i in 1...11)
		{
			var barPath:String = getImagePath('soundtray/bars_$i');
			barPaths.push(barPath);
			
			if (FileSystem.exists(barPath))
			{
				var bar:Bitmap = new Bitmap(BitmapData.fromBytes(File.getBytes(barPath)));
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
	}

	function getImagePath(key:String):String
	{
		#if FEATURE_MODS
		var modPath:String = Paths.modsImages(key);
		if (FileSystem.exists(modPath))
			return modPath;
		#end

		#if USING_GPU_TEXTURES
		var gpuPath:String = Paths.getPath('images/$key.${Paths.GPU_IMAGE_EXT}', Paths.getImageAssetType(Paths.GPU_IMAGE_EXT));
		if (FileSystem.exists(gpuPath))
			return gpuPath;
		#end

		return Paths.getPath('images/$key.${Paths.IMAGE_EXT}', Paths.getImageAssetType(Paths.IMAGE_EXT));
	}

	function getSoundPath(key:String):String
	{
		#if FEATURE_MODS
		var modSound:String = Paths.modsSounds('sounds', key);
		if (FileSystem.exists(modSound))
			return modSound;
		#end
		
		return Paths.getPath('sounds/$key.ogg');
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
		loadImages();
		
		var globalVolume:Int = Math.round(MathTools.logToLinear(FlxG.sound.volume) * 10);

		if (up)
			if (_lastVolume == 10 && globalVolume == 10)
				volumeMaxSound = getSoundPath('soundtray/VolMAX');
			else
				volumeUpSound = getSoundPath('soundtray/Volup');
		else
			volumeDownSound = getSoundPath('soundtray/Voldown');

		_timer = 1;
		lerpYPos = 10;
		visible = true;
		active = true;

		if (FlxG.sound.muted || FlxG.sound.volume == 0)
			globalVolume = 0;

		if (!silent)
		{
			var sound = up ? volumeUpSound : volumeDownSound;

			if (_lastVolume == 10 && globalVolume == 10)
				sound = volumeMaxSound;

			if (sound != null)
				FlxG.sound.play(Sound.fromBytes(File.getBytes(sound)));
		}

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
