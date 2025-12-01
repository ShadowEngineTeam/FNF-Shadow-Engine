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
	public static var texture(get, set):String = null;
	public static var useRGBShader:Bool = true;
	public static var noRGBTextures(default, null):Array<String> = [];

	public var strumNote(default, set):StrumNote;
	public var noteData(default, null):Int;
	public var targetStrumTime(default, null):Float;
	public var mustPress(default, null):Bool = true;
	public var rgbShaders(default, null):Array<Array<RGBShaderReference>> = [[], []];

	private var curTexture:String = null;
	private var reachedEnd:Bool = false;
	private var rgbShader:RGBShaderReference;

	public static function init(group:FlxTypedGroup<SustainSplash>, startCrochet:Float, frameRate:Int):Void
	{
		SustainSplash.startCrochet = startCrochet;
		SustainSplash.frameRate = frameRate;
		SustainSplash.mainGroup = group;

		for (img in [texture, '${texture}Purple', '${texture}Blue', '${texture}Green', '${texture}Red'])
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
			if (splashIsValid(splash, noteData) && splash.mustPress && splash.animation.curAnim.name != 'end')
				splash.visible = false;
		}
	}

	public static function showAtData(noteData:Int):Void
	{
		for (splash in SustainSplash.mainGroup.members)
		{
			if (splashIsValid(splash, noteData) && splash.mustPress)
				splash.visible = true;
		}
	}

	public static function hasSplashAtData(noteData:Int, mustPess:Bool):Bool
	{
		for (splash in SustainSplash.mainGroup.members)
		{
			if (splashIsValid(splash, noteData) && splash.mustPress == mustPess)
				return true;
		}

		return false;
	}

	public static function splashIsValid(splash:SustainSplash, ?noteData:Null<Int>)
	{
		return splash != null && splash.exists && splash.alive && (noteData == null || splash.noteData == noteData);
	}

	public static function close():Void
	{
		SustainSplash.startCrochet = 0;
		SustainSplash.frameRate = 0;
		SustainSplash.texture = DEFAULT_TEXTURE;
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

		reloadSustainSplash(getTextureNameFromData(noteData));

		if (this.rgbShader != null)
			this.rgbShader.enabled = useRGBShader;
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

		// SHADOW TODO: This breaks offsets need to figure it out later
		// flipY = ClientPrefs.data.downScroll;

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

			var shaderID:Int = mustPress ? 0 : 1;

			if (rgbShaders[shaderID][noteData] == null)
			{
				var rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(noteData));
				rgbShader.enabled = false;
				rgbShaders[shaderID][noteData] = rgbShader;
			}

			if (rgbShader != null)
				rgbShader.enabled = false;

			rgbShader = rgbShaders[shaderID][noteData];
		}
	}

	private function precacheSustainSplash():Void
		for (img in [texture, '${texture}Purple', '${texture}Blue', '${texture}Green', '${texture}Red'])
			Paths.getSparrowAtlas(img);

	private static function getTextureNameFromData(noteData:Int):String
	{
		if (useRGBShader)
			return texture;
		else
			return switch (noteData)
			{
				case 0: '${texture}Purple';
				case 1: '${texture}Blue';
				case 2: '${texture}Green';
				case 3: '${texture}Red';
				default: texture;
			}
	}

	override function update(elapsed:Float)
	{
		if (strumNote != null)
		{
			alpha = strumNote.alpha * ClientPrefs.data.splashAlpha;
			setPosition(strumNote.x, strumNote.y);
		}

		if (Conductor.songPosition >= targetStrumTime && !reachedEnd)
		{
			reachedEnd = true;
			if (mustPress)
				animation.play('end', true);
			else
				kill();
		}

		super.update(elapsed);
	}

	override public function draw():Void
	{
		if (strumNote == null)
			return;

		if ((x != strumNote.x || y != strumNote.y) && visible && active && alive && exists)
			update(FlxG.elapsed);

		super.draw();
	}

	override public function kill():Void
	{
		super.kill();

		for (arr in rgbShaders)
			for (shader in arr)
				if (shader != null)
					shader.enabled = false;

		noteData = -1;
		targetStrumTime = 0;
		strumNote = null;
		visible = false;
	}

	override public function destroy():Void
	{
		rgbShaders = [[], []];
		super.destroy();
	}

	@:noCompletion
	private static function set_texture(value:String):String
	{
		#if !haxe5
		@:bypassAccessor
		#end
		texture = value;

		for (splash in SustainSplash.mainGroup.members)
			if (splash.exists && splash.alive)
				splash.reloadSustainSplash(getTextureNameFromData(splash.noteData), true);

		return value;
	}

	@:noCompletion
	private static function get_texture():String
		return texture ?? DEFAULT_TEXTURE;

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
