package objects;

import shaders.ColorSwap;
import shaders.RGBPalette;
import shaders.PixelSplashShader.PixelSplashShaderRef;
import flixel.graphics.frames.FlxFrame;

typedef NoteSplashConfig =
{
	anim:String,
	minFps:Int,
	maxFps:Int,
	offsets:Array<Array<Float>>
}

class NoteSplash extends FlxSprite
{
	public var colorSwap:ColorSwap = null;
	public var rgbShader:PixelSplashShaderRef;

	private var idleAnim:String;
	private var _textureLoaded:String = null;
	private var _configLoaded:String = null;

	public static var usePixelTextures(default, set):Null<Bool>;

	public static var defaultNoteSplash(get, never):String;
	public static var configs:Map<String, NoteSplashConfig> = new Map<String, NoteSplashConfig>();

	public static var mainGroup:FlxTypedGroup<NoteSplash>;

	public function new(x:Float = 0, y:Float = 0)
	{
		if (usePixelTextures == null)
			usePixelTextures = PlayState.isPixelStage;

		super(x, y);

		var skin:String = null;
		if (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0)
			skin = PlayState.SONG.splashSkin;
		else
			skin = defaultNoteSplash + getSplashSkinPostfix();

		if (ClientPrefs.data.disableRGBNotes)
		{
			colorSwap = new ColorSwap();
			shader = colorSwap.shader;
		}
		else
		{
			rgbShader = new PixelSplashShaderRef();
			shader = rgbShader.shader;
		}

		precacheConfig(skin);
		_configLoaded = skin;
		scrollFactor.set();
		setupNoteSplash(x, y, 0);
	}

	override function destroy()
	{
		configs.clear();
		super.destroy();
	}

	var maxAnims:Int = 2;

	public function setupNoteSplash(x:Float, y:Float, direction:Int = 0, ?note:Note = null)
	{
		setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);
		aliveTime = 0;

		var texture:String = null;
		if (note != null && note.noteSplashData.texture != null)
			texture = note.noteSplashData.texture;
		else if (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0)
			texture = PlayState.SONG.splashSkin;
		else
			texture = defaultNoteSplash + getSplashSkinPostfix();

		var config:NoteSplashConfig = null;
		if (_textureLoaded != texture)
			config = loadAnims((usePixelTextures ? 'pixelUI/' : '') + texture);
		else
			config = precacheConfig(_configLoaded);

		var tempShader:RGBPalette = null;
		if (ClientPrefs.data.disableRGBNotes)
		{
			var hue:Float = 0;
			var saturation:Float = 0;
			var brightness:Float = 0;

			if (direction > -1 && direction < ClientPrefs.data.arrowHSV.length)
			{
				hue = ClientPrefs.data.arrowHSV[direction][0] / 360;
				saturation = ClientPrefs.data.arrowHSV[direction][1] / 100;
				brightness = ClientPrefs.data.arrowHSV[direction][2] / 100;

				if (note != null)
				{
					hue = note.noteSplashHue;
					saturation = note.noteSplashSaturation;
					brightness = note.noteSplashBrightness;
				}
			}

			colorSwap.hue = hue;
			colorSwap.saturation = saturation;
			colorSwap.brightness = brightness;
		}
		else
		{
			if ((note == null || note.noteSplashData.useRGBShader) && (PlayState.SONG == null || !PlayState.SONG.disableNoteCustomColor))
			{
				if (note != null && !note.noteSplashData.useGlobalShader)
				{
					if (note.noteSplashData.r != -1)
						note.rgbShader.r = note.noteSplashData.r;
					if (note.noteSplashData.g != -1)
						note.rgbShader.g = note.noteSplashData.g;
					if (note.noteSplashData.b != -1)
						note.rgbShader.b = note.noteSplashData.b;
					tempShader = note.rgbShader.parent;
				}
				else
					tempShader = Note.globalRgbShaders[direction];
			}
		}

		alpha = ClientPrefs.data.splashAlpha;
		if (note != null)
			alpha = note.noteSplashData.a;
		if (!ClientPrefs.data.disableRGBNotes)
			rgbShader.copyValues(tempShader);

		if (note != null)
			antialiasing = note.noteSplashData.antialiasing;
		if (usePixelTextures || !ClientPrefs.data.antialiasing)
			antialiasing = false;

		_textureLoaded = (usePixelTextures ? 'pixelUI/' : '') + texture;
		offset.set(10, 10);

		var animNum:Int = FlxG.random.int(1, maxAnims);
		animation.play('note' + direction + '-' + animNum, true);

		var minFps:Int = 22;
		var maxFps:Int = 26;
		if (config != null)
		{
			var animID:Int = direction + ((animNum - 1) * Note.colArray.length);
			// trace('anim: ${animation.curAnim.name}, $animID');
			var offs:Array<Float> = config.offsets[FlxMath.wrap(animID, 0, config.offsets.length - 1)];
			offset.x += offs[0];
			offset.y += offs[1];
			minFps = config.minFps;
			maxFps = config.maxFps;
		}
		else
		{
			offset.x += -58;
			offset.y += -55;
		}

		if (animation.curAnim != null)
			animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);
	}

	public static function getSplashSkinPostfix()
	{
		var skin:String = '';
		if (ClientPrefs.data.splashSkin != ClientPrefs.defaultData.splashSkin)
			skin = '-' + ClientPrefs.data.splashSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}

	function loadAnims(skin:String, ?animName:String = null):NoteSplashConfig
	{
		maxAnims = 0;
		frames = Paths.getSparrowAtlas(skin);
		var config:NoteSplashConfig = null;
		if (frames == null)
		{
			skin = defaultNoteSplash + getSplashSkinPostfix();
			frames = Paths.getSparrowAtlas(skin);
			if (frames == null) // if you really need this, you really fucked something up
			{
				skin = defaultNoteSplash;
				frames = Paths.getSparrowAtlas(skin);
			}
		}
		config = precacheConfig(skin);
		_configLoaded = skin;

		if (animName == null)
			animName = config != null ? config.anim : 'note splash';

		while (true)
		{
			var animID:Int = maxAnims + 1;
			for (i in 0...Note.colArray.length)
			{
				if (!addAnimAndCheck('note$i-$animID', '$animName ${Note.colArray[i]} $animID', 24, false))
				{
					// trace('maxAnims: $maxAnims');
					return config;
				}
			}
			maxAnims++;
			// trace('currently: $maxAnims');
		}
	}

	public static function precacheConfig(skin:String)
	{
		if (configs.exists(skin))
			return configs.get(skin);

		var path:String = Paths.getPath('images/$skin.txt', TEXT, true);
		var configFile:Array<String> = CoolUtil.coolTextFile(path);
		if (configFile.length < 1)
			return null;

		var framerates:Array<String> = configFile[1].split(' ');
		var offs:Array<Array<Float>> = [];
		for (i in 2...configFile.length)
		{
			var animOffs:Array<String> = configFile[i].split(' ');
			offs.push([Std.parseFloat(animOffs[0]), Std.parseFloat(animOffs[1])]);
		}

		var config:NoteSplashConfig = {
			anim: configFile[0],
			minFps: Std.parseInt(framerates[0]),
			maxFps: Std.parseInt(framerates[1]),
			offsets: offs
		};
		configs.set(skin, config);
		return config;
	}

	function addAnimAndCheck(name:String, anim:String, ?framerate:Int = 24, ?loop:Bool = false)
	{
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, anim); // adds valid frames to animFrames

		if (animFrames.length < 1)
			return false;

		animation.addByPrefix(name, anim, framerate, loop);
		return true;
	}

	static var aliveTime:Float = 0;
	static var buggedKillTime:Float = 0.5; // automatically kills note splashes if they break to prevent it from flooding your HUD

	override function update(elapsed:Float)
	{
		aliveTime += elapsed;
		if ((animation.curAnim != null && animation.curAnim.finished) || (animation.curAnim == null && aliveTime >= buggedKillTime))
			kill();

		super.update(elapsed);
	}

	@:noCompletion
	private static function get_defaultNoteSplash():String
		return !ClientPrefs.data.disableRGBNotes ? 'noteSplashes/noteSplashes' : 'noteSplashes';

	@:noCompletion
	private static function set_usePixelTextures(value:Bool):Bool
	{
		usePixelTextures = value;
		if (mainGroup != null)
		{
			mainGroup.forEachAlive(function(splash:NoteSplash)
			{
				splash._textureLoaded = null;
				splash._configLoaded = null;
			});
		}
		return value;
	}
}
