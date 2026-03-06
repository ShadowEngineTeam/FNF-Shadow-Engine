// this class is a rewriten and polished version of https://github.com/Psych-Slice/P-Slice/blob/master/source/objects/SustainSplash.hx

package objects;

import shaders.ColorSwap;
import shaders.RGBPalette;
import shaders.PixelSplashShader.PixelSplashShaderRef;

using backend.CoolUtil;

class SustainSplash extends FlxSprite
{
	public static var DEFAULT_TEXTURE(get, never):String;

	public static var startCrochet:Float;
	public static var frameRate:Int;
	public static var mainGroup:FlxTypedGroup<SustainSplash>;
	@:isVar
	public static var texture(get, set):String = null;
	public static var useRGBShader:Bool = true;
	public static var usePixelTextures(default, set):Null<Bool>;
	public static var noRGBTextures(default, null):Array<String> = [];

	public static var playerTexture:String = null;
	public static var opponentTexture:String = null;

	public var strumNote(default, set):StrumNote;
	public var noteData(default, null):Int;
	public var targetStrumTime(default, null):Float;
	public var mustPress(default, null):Bool = true;
	public var colorSwap:ColorSwap;
	public var rgbShaders(default, null):Array<Array<PixelSplashShaderRef>> = [[], []];

	private var curTexture:String = null;
	private var reachedEnd:Bool = false;
	private var rgbShader:PixelSplashShaderRef;

	public static function init(group:FlxTypedGroup<SustainSplash>, startCrochet:Float, frameRate:Int):Void
	{
		SustainSplash.startCrochet = startCrochet;
		SustainSplash.frameRate = frameRate;
		SustainSplash.mainGroup = group;

		final textures:Array<String> = [];
		if (!useRGBShader || ClientPrefs.data.disableRGBNotes)
		{
			textures.push('${texture}Purple');
			textures.push('${texture}Blue');
			textures.push('${texture}Green');
			textures.push('${texture}Red');
		}
		else
			textures.push(texture);

		if (PlayState.isPixelStage.priorityBool(usePixelTextures))
			for (i in 0...textures.length)
				textures[i] = 'pixelUI/' + textures[i];

		for (img in textures)
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
		SustainSplash.usePixelTextures = null;
		SustainSplash.mainGroup.destroy();
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

		reloadSustainSplash(getTextureNameFromData(noteData, mustPress));
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

		if (PlayState.isPixelStage.priorityBool(usePixelTextures))
			texture = 'pixelUI/' + texture;

		frames = Paths.getSparrowAtlas(texture);
		animation.onFinish.add((name:String) ->
		{
			switch (name)
			{
				case 'start':
					animation.play('hold', true);
				case 'end':
					kill();
			}
		});
		animation.addByPrefix('start', 'holdCoverStart0', 24, false);
		animation.addByPrefix('hold', 'holdCover0', SustainSplash.frameRate, true);
		animation.addByPrefix('end', 'holdCoverEnd0', 24, false);
		animation.play('start', true, false, 0);

		if (PlayState.isPixelStage.priorityBool(usePixelTextures))
		{
			setGraphicSize(Std.int(width * PlayState.daPixelZoom / 2.5));
			updateHitbox();
		}

		antialiasing = PlayState.isPixelStage.priorityBool(usePixelTextures) ? false : ClientPrefs.data.antialiasing;
		offset.set(PlayState.isPixelStage.priorityBool(usePixelTextures) ? -46 : 106.25, PlayState.isPixelStage.priorityBool(usePixelTextures) ? -40 : 100);
	}

	private function initRGBShader():Void
	{
		if (strumNote != null)
		{
			if (PlayState.SONG != null && PlayState.SONG.disableNoteCustomColor)
				useRGBShader = false;

			var shaderID:Int = mustPress ? 0 : 1;

			if (ClientPrefs.data.disableRGBNotes)
			{
				if (colorSwap == null)
					colorSwap = new ColorSwap();
				shader = colorSwap.shader;
				if (noteData > -1 && noteData < ClientPrefs.data.arrowHSV.length)
				{
					colorSwap.hue = ClientPrefs.data.arrowHSV[noteData][0] / 360;
					colorSwap.saturation = ClientPrefs.data.arrowHSV[noteData][1] / 100;
					colorSwap.brightness = ClientPrefs.data.arrowHSV[noteData][2] / 100;
				}
			}
			else
			{
				if (rgbShaders[shaderID][noteData] == null)
				{
					rgbShader = new PixelSplashShaderRef();
					rgbShaders[shaderID][noteData] = rgbShader;
				}

				if (rgbShader != null)
					rgbShader.shader.mult.value[0] = 0.0;

				rgbShader = rgbShaders[shaderID][noteData];
				shader = rgbShader.shader;
				rgbShader.copyValues(useRGBShader ? Note.initializeGlobalRGBShader(noteData) : null);
			}
		}
	}

	private function precacheSustainSplash():Void
	{
		final textures:Array<String> = [];
		var texToUse:String = texture;
		if (mustPress && playerTexture != null)
			texToUse = playerTexture;
		else if (!mustPress && opponentTexture != null)
			texToUse = opponentTexture;

		if (!useRGBShader || ClientPrefs.data.disableRGBNotes)
		{
			textures.push('${texToUse}Purple');
			textures.push('${texToUse}Blue');
			textures.push('${texToUse}Green');
			textures.push('${texToUse}Red');
		}
		else
			textures.push(texToUse);

		if (PlayState.isPixelStage.priorityBool(usePixelTextures))
			for (i in 0...textures.length)
				textures[i] = 'pixelUI/' + textures[i];

		for (img in textures)
			Paths.getSparrowAtlas(img);
	}

	private static function getTextureNameFromData(noteData:Int, mustPress:Bool):String
	{
		var tex:String = mustPress ? playerTexture : opponentTexture;
		if (tex == null)
			tex = texture;

		if (!useRGBShader || ClientPrefs.data.disableRGBNotes)
		{
			return switch (noteData)
			{
				case 0: '${tex}Purple';
				case 1: '${tex}Blue';
				case 2: '${tex}Green';
				case 3: '${tex}Red';
				default: tex;
			}
		}
		else
			return tex;
	}

	override function update(elapsed:Float)
	{
		if (strumNote != null)
		{
			if (animation.curAnim.name != 'end')
				alpha = strumNote.alpha;
			else
				alpha = ClientPrefs.data.splashAlpha;
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
				splash.reloadSustainSplash(getTextureNameFromData(splash.noteData, splash.mustPress), true);

		return value;
	}

	@:noCompletion
	private static function set_usePixelTextures(value:Null<Bool>):Null<Bool>
	{
		if (usePixelTextures != value)
		{		
			#if !haxe5
			@:bypassAccessor
			#end
			usePixelTextures = value;
	
			for (splash in SustainSplash.mainGroup.members)
				if (splash.exists && splash.alive)
					splash.reloadSustainSplash(getTextureNameFromData(splash.noteData, splash.mustPress), true);
		}

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
			alpha = strumNote.alpha;
			setPosition(strumNote.x, strumNote.y);
		}

		return strumNote = value;
	}

	@:noCompletion
	override function set_angle(value:Float):Float
		return value;

	public static function get_DEFAULT_TEXTURE():String
		return 'holdCovers/holdCover';
}
