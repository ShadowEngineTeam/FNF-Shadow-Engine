package objects;

import flixel.system.ui.FlxSoundTray;
import flixel.system.FlxAssets.FlxSoundAsset;
import openfl.display.Bitmap;
import openfl.display.BitmapData;

class CustomSoundTray extends FlxSoundTray
{
	var graphicScale:Float = 0.30;
	var lerpYPos:Float = 0;
	var alphaTarget:Float = 0;

	var volumeMaxSound:FlxSoundAsset;
	var _lastVolume:Int = -1;
	var _wasMuted:Bool = false;

	var bg:Bitmap;
	var backingBar:Bitmap;
	var imagesLoaded:Bool = false;

	public function new()
	{
		super();
		removeChildren();

		bg = new Bitmap();
		backingBar = new Bitmap();

		loadImages();

		y = -height;
		visible = false;

		volumeUpSound = Paths.sound("soundtray/Volup");
		volumeDownSound = Paths.sound("soundtray/Voldown");
		volumeMaxSound = Paths.sound("soundtray/VolMAX");

		_lastVolume = Math.round(FlxG.sound.logToLinear(FlxG.sound.volume) * 10);
	}

	function loadImages():Void
	{
		if (imagesLoaded)
			return;

		removeChildren();

		var bgPath:String = getImagePath('soundtray/volumebox');
		if (FileSystem.exists(bgPath))
		{
			bg.bitmapData = BitmapData.fromBytes(File.getBytes(bgPath));
			bg.scaleX = graphicScale;
			bg.scaleY = graphicScale;
			bg.smoothing = true;
			addChild(bg);
		}

		var backingPath:String = getImagePath('soundtray/bars_10');
		if (FileSystem.exists(backingPath))
		{
			backingBar.bitmapData = BitmapData.fromBytes(File.getBytes(backingPath));
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
			var barPath:String = getImagePath('soundtray/bars_' + i);

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

		imagesLoaded = true;
	}

	function getImagePath(key:String):String
	{
		#if FEATURE_MODS
		var modPath:String = Paths.modsImages(key);
		if (FileSystem.exists(modPath))
			return modPath;
		#end

		return Paths.getPath('images/$key.${Paths.IMAGE_EXT}', Paths.getImageAssetType(Paths.IMAGE_EXT));
	}

	override public function update(ms:Float):Void
	{
		var elapsed = ms / 1000.0;

		var isMuted = (FlxG.sound.muted || FlxG.sound.volume == 0);

		if (_timer > 0)
		{
			_timer -= elapsed;
			if (_timer <= 0)
			{
				lerpYPos = -height - 10;
				alphaTarget = 0;
			}
		}
		else if (y <= -height)
		{
			visible = false;
			active = false;
		}

		if (isMuted != _wasMuted)
		{
			if (isMuted)
				showTray();
			_wasMuted = isMuted;
		}

		y = smoothLerpPrecision(y, lerpYPos, elapsed, 0.768);
		alpha = smoothLerpPrecision(alpha, alphaTarget, elapsed, 0.307);
		screenCenter();
	}

	override function showIncrement():Void
	{
		moveTrayMakeVisible(true);
		saveVolumePreferences();
	}

	override function showDecrement():Void
	{
		moveTrayMakeVisible(false);
		saveVolumePreferences();
	}

	function moveTrayMakeVisible(up:Bool = false):Void
	{
		showTray();

		if (!silent)
		{
			var globalVolume:Int = Math.round(FlxG.sound.logToLinear(FlxG.sound.volume) * 10);
			var sound:Null<FlxSoundAsset> = null;

			if (up)
			{
				if (_lastVolume == 10 && globalVolume == 10)
					sound = volumeMaxSound;
				else
					sound = volumeUpSound;
			}
			else
				sound = volumeDownSound;

			if (sound != null)
				FlxG.sound.play(sound);
		}

		_lastVolume = Math.round(FlxG.sound.logToLinear(FlxG.sound.volume) * 10);
	}

	function showTray():Void
	{
		_timer = 1;
		lerpYPos = 10;
		visible = true;
		active = true;
		alphaTarget = 1;

		updateBars();
	}

	function updateBars():Void
	{
		var globalVolume:Int = FlxG.sound.muted || FlxG.sound.volume == 0 ? 0 : Math.round(FlxG.sound.logToLinear(FlxG.sound.volume) * 10);

		for (i in 0..._bars.length)
			_bars[i].visible = i < globalVolume;
	}

	function saveVolumePreferences():Void
	{
		#if FLX_SAVE
		if (FlxG.save.isBound)
		{
			FlxG.save.data.mute = FlxG.sound.muted;
			FlxG.save.data.volume = FlxG.sound.volume;
			FlxG.save.flush();
		}
		#end
	}

	static function smoothLerpPrecision(base:Float, target:Float, deltaTime:Float, duration:Float, precision:Float = 1 / 100):Float
	{
		function lerp(base:Float, target:Float, alpha:Float):Float
		{
			if (alpha == 0)
				return base;
			if (alpha == 1)
				return target;
			return base + alpha * (target - base);
		}

		if (deltaTime == 0)
			return base;
		if (base == target)
			return target;
		return lerp(target, base, Math.pow(precision, deltaTime / duration));
	}
}
