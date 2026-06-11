package objects;

import shaders.ColorSwap;
import backend.NoteTypesConfig;
import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;
import objects.StrumNote;
import flixel.addons.effects.FlxSkewedSprite;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxRect;

using StringTools;
using backend.CoolUtil;

typedef EventNote =
{
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

typedef NoteSplashData =
{
	disabled:Bool,
	texture:String,
	useGlobalShader:Bool, // breaks r/g/b/a but makes it copy default colors for your custom note
	useRGBShader:Bool,
	antialiasing:Bool,
	r:FlxColor,
	g:FlxColor,
	b:FlxColor,
	a:Float
}

/**
 * The note object used as a data structure to spawn and manage notes during gameplay.
 *
 * If you want to make a custom note type, search for: `applyNoteType`.
**/
class Note extends FlxSkewedSprite
{
	// ─── Static configuration ───────────────────────────────────────────────
	public static var SUSTAIN_SIZE:Int = 44;
	public static var swagWidth:Float = 160 * 0.7;
	public static var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
	public static var defaultNoteSkin(get, never):String;

	/** Pixels of travel per ms per songSpeed unit — shared by `followStrumNote` and the sustain stretcher so pieces butt up at any BPM. **/
	public static inline var TRAVEL_SPEED:Float = 0.45;

	/**
	 * Extra display pixels added to every hold piece's height beyond the perfect-tile size,
	 * so the bottom edge of piece N+1 lands inside piece N's solid body rather than on its
	 * top row. Without this, sub-pixel rounding from `followStrumNote`'s Float y + the
	 * Float→pixel render pipeline can shave ~1 px off the overlap and reveal a 1-pixel
	 * background row between pieces (the classic "BPM-dependent sustain seam"). 6 px is
	 * generous enough to survive that loss at any BPM; tune lower if you've added pixel-perfect
	 * snapping, or higher if you ever see seams come back.
	**/
	public static var SUSTAIN_PIECE_OVERLAP_PX:Float = 0.95;

	public static var globalRgbShaders:Array<RGBPalette> = [];
	public static var usePixelTextures(default, set):Null<Bool>;

	private static var _activeNotes:Array<Note> = [];

	// ─── Identity / chart data ──────────────────────────────────────────────
	public var strumTime:Float = 0;
	public var noteData:Int = 0;
	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;
	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	// ─── Linked list (for sustains) ─────────────────────────────────────────
	public var prevNote:Note;
	public var nextNote:Note;
	public var parent:Note;
	public var tail:Array<Note> = [];

	// ─── Gameplay state ─────────────────────────────────────────────────────
	public var mustPress:Bool = false;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var blockHit:Bool = false; // only works for player
	public var missed:Bool = false;
	public var spawned:Bool = false;
	public var inEditor:Bool = false;

	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;
	public var earlyHitMult:Float = 1;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;

	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; // 9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var hitsoundDisabled:Bool = false;
	public var hitsoundChartEditor:Bool = true;
	public var hitsound:String = 'hitsound';

	// ─── Event-note data (chart events repurpose Note) ──────────────────────
	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	// ─── Rendering / animation ──────────────────────────────────────────────
	public var colorSwap:ColorSwap;
	public var rgbShader:RGBShaderReference;
	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var texture(default, set):String = null;

	public var noteSplashHue:Float = 0;
	public var noteSplashSaturation:Float = 0;
	public var noteSplashBrightness:Float = 0;

	public var noteSplashData:NoteSplashData = {
		disabled: false,
		texture: null,
		antialiasing: ClientPrefs.data.antialiasing && !PlayState.isPixelStage.priorityBool(usePixelTextures),
		useGlobalShader: false,
		useRGBShader: (PlayState.SONG != null) ? !(PlayState.SONG.disableNoteCustomColor == true) : true,
		r: -1,
		g: -1,
		b: -1,
		a: ClientPrefs.data.splashAlpha
	};

	// ─── Follow / clip offsets ──────────────────────────────────────────────
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var distance:Float = 2000; // plan on doing scroll directions soon -bb
	public var originalHeight:Float = 6;
	public var correctionOffset:Float = 0; // dont mess with this

	var _lastNoteOffX:Float = 0;

	// ─── Construction ───────────────────────────────────────────────────────

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?createdFrom:Dynamic = null)
	{
		super();
		_activeNotes.push(this);

		if (createdFrom == null) createdFrom = PlayState.instance;
		if (prevNote == null) prevNote = this;

		this.prevNote = prevNote;
		this.isSustainNote = sustainNote;
		this.inEditor = inEditor;
		this.noteData = noteData;
		this.moves = false;
		this.antialiasing = ClientPrefs.data.antialiasing;

		this.strumTime = strumTime + (inEditor ? 0 : ClientPrefs.data.noteOffset);

		// Spawn far off-screen so it never flashes before followStrumNote
		x += (ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		y -= 2000;

		if (noteData > -1)
			initVisuals(noteData);

		if (prevNote != null)
			prevNote.nextNote = this;

		if (isSustainNote && prevNote != null)
			initSustainTail(prevNote, createdFrom);
		else if (!isSustainNote)
		{
			centerOffsets();
			centerOrigin();
		}

		x += offsetX;
	}

	function initVisuals(noteData:Int):Void
	{
		texture = '';

		if (ClientPrefs.data.disableRGBNotes)
		{
			colorSwap = new ColorSwap();
			shader = colorSwap.shader;
		}
		else
		{
			rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData));
			if (PlayState.SONG != null && PlayState.SONG.disableNoteCustomColor)
				rgbShader.enabled = false;
		}

		x += swagWidth * noteData;

		// 'if' guard fixes warnings on Senpai-style 9k+ songs that overflow colArray
		if (!isSustainNote && noteData < colArray.length)
			animation.play(colArray[noteData % colArray.length] + 'Scroll');
	}

	function initSustainTail(prevNote:Note, createdFrom:Dynamic):Void
	{
		alpha = 0.6;
		multAlpha = 0.6;
		hitsoundDisabled = true;
		copyAngle = false;
		earlyHitMult = 0;

		if (ClientPrefs.data.downScroll)
			flipY = true;

		// width-relative offset has to bracket animation.play so updateHitbox sees the right size
		offsetX += width / 2;
		animation.play(colArray[noteData % colArray.length] + 'holdend');
		updateHitbox();
		offsetX -= width / 2;

		if (isPixel)
			offsetX += 30;

		if (prevNote.isSustainNote)
			stretchPrevHoldPiece(prevNote, createdFrom);

		if (isPixel)
		{
			scale.y *= PlayState.daPixelZoom;
			updateHitbox();
		}
	}

	function stretchPrevHoldPiece(prev:Note, createdFrom:Dynamic):Void
	{
		prev.animation.play(colArray[prev.noteData % colArray.length] + 'hold');

		final songSpeed:Float = (createdFrom != null && createdFrom.songSpeed != null) ? createdFrom.songSpeed : 1;

		if (isPixel)
		{
			// Pixel keeps the legacy multiplier path — its texture layout & pixelZoom math are different.
			prev.scale.y *= Conductor.stepCrochet / 100 * 1.05 * songSpeed * 1.19 * (6 / height);
		}
		else
		{
			// Size the piece so its TOP edge is flush against the next piece's BOTTOM at every BPM:
			//   distance_per_step = TRAVEL_SPEED * stepCrochet * songSpeed / playbackRate    (from followStrumNote)
			// We pad the height by SUSTAIN_PIECE_OVERLAP_PX so the seam falls inside the next
			// piece's solid body (past its top-edge AA) instead of right on its sampled edge.
			final playbackRate:Float = (createdFrom != null && createdFrom.playbackRate != null) ? createdFrom.playbackRate : 1;
			final targetHeight:Float = Conductor.stepCrochet * TRAVEL_SPEED * songSpeed / playbackRate + SUSTAIN_PIECE_OVERLAP_PX;
			prev.scale.y = targetHeight / prev.frameHeight;
		}
		prev.updateHitbox();
	}

	// ─── Property setters ───────────────────────────────────────────────────

	static function set_usePixelTextures(value:Null<Bool>):Null<Bool>
	{
		if (usePixelTextures != value)
		{
			usePixelTextures = value;
			for (note in _activeNotes)
				note.reloadNote(note.texture);
		}
		return value;
	}

	function set_multSpeed(value:Float):Float
	{
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		return value;
	}

	function set_texture(value:String):String
	{
		if (texture != value)
			reloadNote(value);
		texture = value;
		return value;
	}

	function set_noteType(value:String):String
	{
		noteSplashData.texture = PlayState.SONG != null ? PlayState.SONG.splashSkin : 'noteSplashes';

		if (ClientPrefs.data.disableRGBNotes)
		{
			if (noteData > -1 && noteData < ClientPrefs.data.arrowHSV.length)
			{
				colorSwap.hue = noteSplashHue = ClientPrefs.data.arrowHSV[noteData][0] / 360;
				colorSwap.saturation = noteSplashSaturation = ClientPrefs.data.arrowHSV[noteData][1] / 100;
				colorSwap.brightness = noteSplashBrightness = ClientPrefs.data.arrowHSV[noteData][2] / 100;
			}
		}
		else
			defaultRGB();

		if (noteData > -1 && noteType != value)
		{
			applyBuiltinNoteType(value);

			if (value != null && value.length > 1)
				NoteTypesConfig.applyNoteTypeData(this, value);
			if (hitsound != 'hitsound' && ClientPrefs.data.hitsoundVolume > 0)
				Paths.sound(hitsound); // precache new sound for being idiot-proof

			noteType = value;
		}
		return value;
	}

	function applyBuiltinNoteType(value:String):Void
	{
		switch (value)
		{
			case 'Hurt Note':
				ignoreNote = mustPress;

				if (ClientPrefs.data.disableRGBNotes)
				{
					reloadNote('HURTNOTE_assets');
					colorSwap.hue = noteSplashHue = 0;
					colorSwap.saturation = noteSplashSaturation = 0;
					colorSwap.brightness = noteSplashBrightness = 0;
					noteSplashData.texture = 'HURTnoteSplashes';
				}
				else
				{
					rgbShader.r = 0xFF101010;
					rgbShader.g = 0xFFFF0000;
					rgbShader.b = 0xFF990022;

					noteSplashData.r = 0xFFFF0000;
					noteSplashData.g = 0xFF101010;
					noteSplashData.texture = 'noteSplashes/noteSplashes-electric';
				}

				lowPriority = true;
				missHealth = isSustainNote ? 0.25 : 0.1;
				hitCausesMiss = true;
				hitsound = 'cancelMenu';
				hitsoundChartEditor = false;

			case 'Alt Animation':
				animSuffix = '-alt';

			case 'No Animation':
				noAnimation = true;
				noMissAnimation = true;

			case 'GF Sing':
				gfNote = true;
		}
	}

	public function defaultRGB():Void
	{
		var arr:Array<FlxColor> = isPixel ? ClientPrefs.data.arrowRGBPixel[noteData] : ClientPrefs.data.arrowRGB[noteData];

		if (noteData > -1 && noteData <= arr.length)
		{
			rgbShader.r = arr[0];
			rgbShader.g = arr[1];
			rgbShader.b = arr[2];
		}
	}

	public function resizeByRatio(ratio:Float):Void // haha funny twitter shit
	{
		if (isSustainNote && animation.curAnim != null && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	// ─── Texture loading ────────────────────────────────────────────────────

	public function reloadNote(texture:String = '', postfix:String = ''):Void
	{
		if (texture == null) texture = '';
		if (postfix == null) postfix = '';

		final lastAnim:String = (animation.curAnim != null) ? animation.curAnim.name : null;
		final lastScaleY:Float = scale.y;

		final skin:String = resolveSkinName(texture);

		if (isPixel)
			loadPixelTexture(skin);
		else
			loadSparrowTexture(skin);

		if (isSustainNote)
			scale.y = lastScaleY;

		updateHitbox();

		if (lastAnim != null)
			animation.play(lastAnim, true);
	}

	function resolveSkinName(texture:String):String
	{
		var skin:String = texture;
		if (skin.length < 1)
		{
			skin = (PlayState.SONG != null) ? PlayState.SONG.playerArrowSkin : null;
			if (skin == null || skin.length < 1)
				skin = defaultNoteSkin;
		}

		final postfix:String = getNoteSkinPostfix();
		final customSkin:String = skin + postfix;
		final folder:String = isPixel ? 'pixelUI/' : '';
		final fullPath:String = 'images/' + folder + customSkin;

		if (Paths.fileExists(fullPath + '.${Paths.IMAGE_EXT}', Paths.getImageAssetType(Paths.IMAGE_EXT)))
			return customSkin;
		return skin;
	}

	function loadPixelTexture(skin:String):Void
	{
		final imgPath:String = 'pixelUI/' + skin;
		var graphic:FlxGraphic;

		if (isSustainNote)
		{
			graphic = Paths.image(imgPath + 'ENDS');
			loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 2));
			originalHeight = graphic.height / 2;
		}
		else
		{
			graphic = Paths.image(imgPath);
			loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 5));
		}

		setGraphicSize(Std.int(width * PlayState.daPixelZoom));
		loadPixelNoteAnims();
		antialiasing = false;

		if (isSustainNote)
		{
			offsetX += _lastNoteOffX;
			_lastNoteOffX = (width - 7) * (PlayState.daPixelZoom / 2);
			offsetX -= _lastNoteOffX;
		}
	}

	function loadSparrowTexture(skin:String):Void
	{
		frames = Paths.getSparrowAtlas(skin);
		loadNoteAnims();
		if (!isSustainNote)
		{
			centerOffsets();
			centerOrigin();
		}
	}

	function loadNoteAnims():Void
	{
		if (isSustainNote)
		{
			attemptToAddAnimationByPrefix('purpleholdend', 'pruple end hold', 24, true); // typo in the original .fla
			animation.addByPrefix(colArray[noteData] + 'holdend', colArray[noteData] + ' hold end', 24, true);
			animation.addByPrefix(colArray[noteData] + 'hold', colArray[noteData] + ' hold piece', 24, true);
		}
		else
			animation.addByPrefix(colArray[noteData] + 'Scroll', colArray[noteData] + '0');

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}

	function loadPixelNoteAnims():Void
	{
		if (isSustainNote)
		{
			animation.add(colArray[noteData] + 'holdend', [noteData + 4], 24, true);
			animation.add(colArray[noteData] + 'hold', [noteData], 24, true);
		}
		else
			animation.add(colArray[noteData] + 'Scroll', [noteData + 4], 24, true);
	}

	function attemptToAddAnimationByPrefix(name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true):Void
	{
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, prefix);
		if (animFrames.length < 1) return;

		animation.addByPrefix(name, prefix, framerate, doLoop);
	}

	// ─── Per-frame update ───────────────────────────────────────────────────

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (mustPress)
		{
			final safe:Float = Conductor.safeZoneOffset;
			canBeHit = strumTime > Conductor.songPosition - safe * lateHitMult
				&& strumTime < Conductor.songPosition + safe * earlyHitMult;

			if (strumTime < Conductor.songPosition - safe && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;
			if (strumTime < Conductor.songPosition + Conductor.safeZoneOffset * earlyHitMult)
			{
				if ((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition)
					wasGoodHit = true;
			}
		}

		if (tooLate && !inEditor && alpha > 0.3)
			alpha = 0.3;
	}

	// ─── Strum-following / clipping ─────────────────────────────────────────

	public function followStrumNote(myStrum:StrumNote, fakeCrochet:Float, songSpeed:Float = 1):Void
	{
		distance = TRAVEL_SPEED * (Conductor.songPosition - strumTime) * songSpeed * multSpeed;
		if (!myStrum.downScroll)
			distance *= -1;

		final angleDir:Float = myStrum.direction * Math.PI / 180;

		if (copyAngle)
			angle = myStrum.direction - 90 + myStrum.angle + offsetAngle;

		if (copyAlpha)
			alpha = myStrum.alpha * multAlpha;

		if (copyX)
			x = myStrum.x + offsetX + Math.cos(angleDir) * distance;

		if (copyY)
		{
			y = myStrum.y + offsetY + correctionOffset + Math.sin(angleDir) * distance;
			if (myStrum.downScroll && isSustainNote)
			{
				if (isPixel)
					y -= PlayState.daPixelZoom * 9.5;
				y -= (frameHeight * scale.y) - (swagWidth / 2);
			}
		}
	}

	public function clipToStrumNote(myStrum:StrumNote):Void
	{
		final center:Float = myStrum.y + offsetY + swagWidth / 2;
		final eligible:Bool = isSustainNote
			&& (mustPress || !ignoreNote)
			&& (!mustPress || wasGoodHit || (prevNote.wasGoodHit && !canBeHit));

		if (!eligible) return;

		var swagRect:FlxRect = clipRect;
		if (swagRect == null)
			swagRect = new FlxRect(0, 0, frameWidth, frameHeight);

		if (myStrum.downScroll)
		{
			if (y - offset.y * scale.y + height >= center)
			{
				swagRect.width = frameWidth;
				swagRect.height = (center - y) / scale.y;
				swagRect.y = frameHeight - swagRect.height;
			}
		}
		else if (y + offset.y * scale.y <= center)
		{
			swagRect.y = (center - y) / scale.y;
			swagRect.width = width / scale.x;
			swagRect.height = (height / scale.y) - swagRect.y;
		}
		clipRect = swagRect;
	}

	// ─── Lifecycle / overrides ──────────────────────────────────────────────

	override function destroy():Void
	{
		_activeNotes.remove(this);
		super.destroy();
	}

	@:noCompletion
	override function set_clipRect(rect:FlxRect):FlxRect
	{
		clipRect = rect;
		if (frames != null)
			frame = frames.frames[animation.frameIndex];
		return rect;
	}

	// ─── Helpers ────────────────────────────────────────────────────────────

	inline function get_isPixel():Bool
		return PlayState.isPixelStage.priorityBool(usePixelTextures);

	public var isPixel(get, never):Bool;

	public static function initializeGlobalRGBShader(noteData:Int):RGBPalette
	{
		if (globalRgbShaders[noteData] == null)
		{
			final newRGB:RGBPalette = new RGBPalette();
			globalRgbShaders[noteData] = newRGB;

			final arr:Array<FlxColor> = !PlayState.isPixelStage.priorityBool(usePixelTextures)
				? ClientPrefs.data.arrowRGB[noteData]
				: ClientPrefs.data.arrowRGBPixel[noteData];
			if (noteData > -1 && noteData <= arr.length)
			{
				newRGB.r = arr[0];
				newRGB.g = arr[1];
				newRGB.b = arr[2];
			}
		}
		return globalRgbShaders[noteData];
	}

	public static function getNoteSkinPostfix():String
	{
		if (ClientPrefs.data.noteSkin == ClientPrefs.defaultData.noteSkin) return '';
		return '-' + ClientPrefs.data.noteSkin.trim().toLowerCase().replace(' ', '_');
	}

	static function get_defaultNoteSkin():String
		return !ClientPrefs.data.disableRGBNotes ? 'noteSkins/NOTE_assets' : 'NOTE_assets';
}
