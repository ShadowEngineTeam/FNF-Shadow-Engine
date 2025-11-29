package objects;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

class SustainSplash extends FlxSprite
{
	public static var DEFAULT_TEXTURE:String = 'holdCover';

	public static var startCrochet:Float;
	public static var frameRate:Int;
	public static var mainGroup:FlxTypedGroup<SustainSplash>;

	@:isVar
	public var texture(get, set):String = null;
	public var strumNote(default, set):StrumNote;
	public var noteData(default, null):Int;
	public var targetStrumTime(default, null):Float;
	public var mustPress(default, null):Bool = true;
	public var useRGBShader:Bool = true;

	private var noRGBTextures:Array<String> = [];
	private var curTexture:String = null;
	private var reachedEnd:Bool = false;
	private var rgbShader:RGBShaderReference;
	private var rgbShaders:Array<RGBShaderReference> = [];

	public static function init(group:FlxTypedGroup<SustainSplash>, startCrochet:Float, frameRate:Int):Void
	{
		SustainSplash.startCrochet = startCrochet;
		SustainSplash.frameRate = frameRate;
		SustainSplash.mainGroup = group;

		for (img in [DEFAULT_TEXTURE, '${DEFAULT_TEXTURE}Purple', '${DEFAULT_TEXTURE}Blue', '${DEFAULT_TEXTURE}Green', '${DEFAULT_TEXTURE}Red'])
			Paths.getSparrowAtlas(img);
	}

	public static function generateSustainSplash(strumNote:StrumNote, targetStrumTime:Float, mustPress:Bool = true):SustainSplash
	{
		var splash:SustainSplash = SustainSplash.mainGroup.recycle(null, () -> new SustainSplash(), false, true);
		splash.resetSustainSplash(strumNote, targetStrumTime, mustPress);

		return splash;
	}

	public static function hideAtData(noteData:Int):Void
	{
		for (splash in SustainSplash.mainGroup.members)
		{
			if (splash.exists && splash.alive && splash.noteData == noteData && splash.mustPress)
				splash.visible = false;
		}
	}

	public static function showAtData(noteData:Int):Void
	{
		for (splash in SustainSplash.mainGroup.members)
		{
			if (splash.exists && splash.alive && splash.noteData == noteData && splash.mustPress)
				splash.visible = true;
		}
	}

	public static function close():Void
	{
		SustainSplash.startCrochet = 0;
		SustainSplash.frameRate = 0;
		SustainSplash.mainGroup.destroy();
	}

	public function new():Void
	{
		super();
	}

	public function resetSustainSplash(strumNote:StrumNote, targetStrumTime:Float, mustPress:Bool = true):Void
	{
		@:privateAccess
		this.noteData = strumNote.noteData;
		this.strumNote = strumNote;
		this.targetStrumTime = targetStrumTime;
		this.mustPress = mustPress;
		this.reachedEnd = false;
		this.visible = true;

		initRGBShader();

		if (this.rgbShader != null)
			this.rgbShader.enabled = useRGBShader;

		noRGBTextures = ['${texture}Purple', '${texture}Blue', '${texture}Green', '${texture}Red'];

		reloadSustainSplash(useRGBShader ? texture : noRGBTextures[noteData]);
	}

	public function reloadSustainSplash(texture:String, force:Bool = false):Void
	{
		if (texture != null && texture != DEFAULT_TEXTURE)
			precacheSustainSplash();

		if (texture == null)
			texture = DEFAULT_TEXTURE;

		if (curTexture == texture && !force)
		{
			animation.play('start', true, false, 0);
			return;
		}

		curTexture = texture;

		//var postfix:String = switch (noteData)
		//{
		// case 0: "Purple";
		// case 1: "Blue";
		// case 2: "Green";
		// case 3: "Red";
		// default: "";
		//}

		frames = Paths.getSparrowAtlas(texture);
		animation.finishCallback = (name:String) ->
		{
			switch (name)
			{
				case 'start':
					animation.play('hold', true);
				case 'end':
					kill();
			}
		};
		animation.addByPrefix('start', 'holdCoverStart0', 24, false);
		animation.addByPrefix('hold', 'holdCover0', SustainSplash.frameRate, true);
		animation.addByPrefix('end', 'holdCoverEnd0', 24, false);
		animation.play('start', true, false, 0);

		antialiasing = ClientPrefs.data.antialiasing;
		offset.set(PlayState.isPixelStage ? 112.5 : 106.25, 100);
	}

	private function initRGBShader():Void
	{
		if (strumNote != null)
		{
			if (PlayState.SONG != null && PlayState.SONG.disableNoteRGB)
				useRGBShader = false;

			if (rgbShaders[noteData] == null)
			{
				var rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(noteData));
				rgbShader.enabled = false;
				rgbShaders[noteData] = rgbShader;
			}

			if (rgbShader != null)
				rgbShader.enabled = false;

			rgbShader = rgbShaders[noteData];
		}
	}

	private function precacheSustainSplash():Void
	{
		for (img in [texture, '${texture}Purple', '${texture}Blue', '${texture}Green', '${texture}Red'])
			Paths.getSparrowAtlas(img);
	}

	override function update(elapsed:Float)
	{
		if (strumNote != null)
		{
			alpha = strumNote.alpha * ClientPrefs.data.splashAlpha;
			setPosition(strumNote.x, strumNote.y);

			if (angle != strumNote.angle)
				angle = strumNote.angle;
		}

		if (Conductor.songPosition >= targetStrumTime && !reachedEnd)
		{
			reachedEnd = true;
			if (mustPress)
			{
				animation.play('end', true);
			}
			else
			{
				kill();
			}
		}

		super.update(elapsed);
	}

	override public function kill():Void
	{
		super.kill();

		if (rgbShader != null)
			rgbShader.enabled = false;
		targetStrumTime = 0;
		strumNote = null;
	}

	@:noCompletion
	private function set_texture(value:String):String
	{
		noRGBTextures = ['${value}Purple', '${value}Blue', '${value}Green', '${value}Red'];
		reloadSustainSplash(value, true);
		return texture = value;
	}

	private function get_texture():String
	{
		return texture ?? DEFAULT_TEXTURE;
	}

	@:noCompletion
	private function set_strumNote(value:StrumNote):StrumNote
	{
		if (strumNote != null)
		{
			alpha = strumNote.alpha * ClientPrefs.data.splashAlpha;
			setPosition(strumNote.x, strumNote.y);

			if (angle != strumNote.angle)
				angle = strumNote.angle;
		}

		return strumNote = value;
	}
}
