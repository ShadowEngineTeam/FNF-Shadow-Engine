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
 * If you want to make a custom note type, you should search for: "function set_noteType"
**/
class Note extends FlxSkewedSprite
{
	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var strumTime:Float = 0;
	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;

	public var spawned:Bool = false;

	public var tail:Array<Note> = []; // for sustains
	public var parent:Note;
	public var blockHit:Bool = false; // only works for player

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var colorSwap:ColorSwap;
	public var rgbShader:RGBShaderReference;

	public static var globalRgbShaders:Array<RGBPalette> = [];

	public var inEditor:Bool = false;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var earlyHitMult:Float = 1;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;

	public var noteSplashHue:Float = 0;
	public var noteSplashSaturation:Float = 0;
	public var noteSplashBrightness:Float = 0;

	public static var SUSTAIN_SIZE:Int = 44;
	public static var swagWidth:Float = 160 * 0.7;
	public static var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];

	public static var rankedManiaKeysList:Array<Int> = [4, 5, 6, 7, 8, 9];
	public static var maniaKeysList:Array<Int> = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 20, 21, 26, 50, 55, 61];
	public static var maniaKeysStringList:Array<String> = [for (keys in maniaKeysList) '${keys}k'];

	public static var maniaKeys(default, set):Int = 4;

	static function set_maniaKeys(value:Int):Int
	{
		maniaKeys = (maniaKeysList.contains(value) ? value : 4);
		colArray = getColArrayFromKeys();
		return value;
	}

	public static var swagScaledWidth(get, never):Float;

	static function get_swagScaledWidth():Float
		return swagWidth * noteScale;

	public static var noteScale(get, default):Float = 1;

	static function get_noteScale():Float
		return (swagWidth * 4) / (swagWidth * Math.max(4, maniaKeys)) * (1 + (0.1 * (Math.min(9, Math.max(4, maniaKeys)) - 4)));

	public static function getNoteOffsetX():Float
		return (swagScaledWidth / 30.0) * (Math.min(9, Math.max(4, maniaKeys)) - 4);

	public static function getColArrayFromKeys(?regularOnly:Bool = false, ?keys:Null<Int> = null):Array<String>
	{
		keys ??= Note.maniaKeys;
		var specialCol:String = regularOnly ? 'green' : 'odd';
		switch (keys)
		{
			case 5:
				return ['purple', 'blue', specialCol, 'green', 'red'];
			case 6:
				return ['purple', 'blue', 'red', 'purple', 'green', 'red'];
			case 7:
				return ['purple', 'blue', 'red', specialCol, 'purple', 'green', 'red'];
			case 8:
				return ['purple', 'blue', 'green', 'red', 'purple', 'blue', 'green', 'red'];
			case 9:
				return ['purple', 'blue', 'green', 'red', specialCol, 'purple', 'blue', 'green', 'red'];
			case 2:
				return ['purple', 'red'];
			case 3:
				return ['purple', specialCol, 'red'];
			default:
				{
					var isOdd:Bool = keys % 2 != 0;
					var arr:Array<String> = [];
					var ki:Int = 0;
					for (key in 0...keys)
					{
						if (isOdd && key == Std.int(keys / 2))
						{
							arr.push(specialCol);
							ki = 0;
							continue;
						}
						arr.push(['purple', 'blue', 'green', 'red'][ki % 4]);
						ki++;
					}
					return arr;
				}
		}
	}

	public static function colToIndex(col:String):Int
	{
		if (col == 'odd')
			return Note.colArray.contains('odd') ? 0 : 1;
		return ['purple', 'blue', 'green', 'red'].indexOf(col);
	}

	public static var defaultNoteSkin(get, never):String;

	public static var usePixelTextures(default, set):Null<Bool>;

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

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;
	public var missed:Bool = false;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; // 9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; // plan on doing scroll directions soon -bb

	public var hitsoundDisabled:Bool = false;
	public var hitsoundChartEditor:Bool = true;
	public var hitsound:String = 'hitsound';

	private static var _activeNotes:Array<Note> = [];
	private static var notePool:Array<Note> = [];

	public static function getNote(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?createdFrom:Dynamic = null):Note
	{
		var note = notePool.pop();
		if (note == null)
			note = new Note();
		note.resetNote(strumTime, noteData, prevNote, sustainNote, inEditor, createdFrom);
		return note;
	}

	public static function clearPool():Void
	{
		for (note in notePool)
			note.destroy();
		notePool = [];
		_activeNotes = [];
	}

	public function recycle():Void
	{
		_activeNotes.remove(this);
		kill();

		colorSwap = null;
		rgbShader = null;
		shader = null;

		notePool.push(this);
	}

	private static function set_usePixelTextures(value:Null<Bool>):Null<Bool>
	{
		if (usePixelTextures != value)
		{
			usePixelTextures = value;
			for (note in _activeNotes)
				note.reloadNote(note.texture);
		}
		
		return value;
	}

	private function set_multSpeed(value:Float):Float
	{
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		// trace('fuck cock');
		return value;
	}

	public function resizeByRatio(ratio:Float) // haha funny twitter shit
	{
		if (isSustainNote && animation.curAnim != null && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	private function set_texture(value:String):String
	{
		if (texture != value)
			reloadNote(value);

		texture = value;
		return value;
	}

	public function defaultRGB()
	{
		var colors:Array<Array<FlxColor>> = PlayState.isPixelStage.priorityBool(usePixelTextures) ? ClientPrefs.getArrowRGB(true) : ClientPrefs.getArrowRGB();
		var arr:Array<FlxColor> = (noteData > -1 && noteData < colors.length) ? colors[noteData] : null;

		if (arr != null && arr.length >= 3)
		{
			rgbShader.r = arr[0];
			rgbShader.g = arr[1];
			rgbShader.b = arr[2];
		}
	}

	private function set_noteType(value:String):String
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
			switch (value)
			{
				case 'Hurt Note':
					ignoreNote = mustPress;

					if (ClientPrefs.data.disableRGBNotes)
					{
						reloadNote('HURTNOTE_assets');
						// note and splash data colors
						colorSwap.hue = noteSplashHue = 0;
						colorSwap.saturation = noteSplashSaturation = 0;
						colorSwap.brightness = noteSplashBrightness = 0;

						noteSplashData.texture = 'HURTnoteSplashes';
					}
					else
					{
						// note colors
						rgbShader.r = 0xFF101010;
						rgbShader.g = 0xFFFF0000;
						rgbShader.b = 0xFF990022;

						// splash data and colors
						noteSplashData.r = 0xFFFF0000;
						noteSplashData.g = 0xFF101010;
						noteSplashData.texture = 'noteSplashes/noteSplashes-electric';
					}

					// gameplay data
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
			if (value != null && value.length > 1)
				NoteTypesConfig.applyNoteTypeData(this, value);
			if (hitsound != 'hitsound' && ClientPrefs.data.hitsoundVolume > 0)
				Paths.sound(hitsound); // precache new sound for being idiot-proof
			noteType = value;
		}

		return value;
	}

	public function new(?strumTime:Float = 0, ?noteData:Int = 0, ?prevNote:Note = null, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?createdFrom:Dynamic = null)
	{
		super();
		if (prevNote != null || sustainNote || inEditor || createdFrom != null)
			resetNote(strumTime, noteData, prevNote, sustainNote, inEditor, createdFrom);
	}

	function resetNote(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?createdFrom:Dynamic = null):Void
	{
		revive();
		_activeNotes.push(this);

		antialiasing = ClientPrefs.data.antialiasing;
		if (createdFrom == null)
			createdFrom = PlayState.instance;

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;
		this.moves = false;

		x += (ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if (!inEditor)
			this.strumTime += ClientPrefs.data.noteOffset;

		this.noteData = noteData;

		if (noteData > -1)
		{
			texture = '';
			if (ClientPrefs.data.disableRGBNotes)
			{
				if (colorSwap == null)
				{
					colorSwap = new ColorSwap();
					shader = colorSwap.shader;
				}
			}
			else
			{
				if (rgbShader == null)
					rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData));
				if (PlayState.SONG != null && PlayState.SONG.disableNoteCustomColor)
					rgbShader.enabled = false;
			}

			x += swagScaledWidth * (noteData);
			if (!isSustainNote && noteData < colArray.length) // Doing this 'if' check to fix the warnings on Senpai songs
			{
				var animToPlay:String = '';
				animToPlay = colArray[noteData % colArray.length];
				animation.play(animToPlay + 'Scroll');
			}
		}

		if (prevNote != null)
			prevNote.nextNote = this;

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			multAlpha = 0.6;
			hitsoundDisabled = true;
			if (ClientPrefs.data.downScroll)
				flipY = true;

			offsetX += width / 2;
			copyAngle = false;

			animation.play(colArray[noteData % colArray.length] + 'holdend');

			updateHitbox();

			offsetX -= width / 2;

			if (PlayState.isPixelStage.priorityBool(usePixelTextures))
				offsetX += 30;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(colArray[prevNote.noteData % colArray.length] + 'hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				if (createdFrom != null && createdFrom.songSpeed != null)
					prevNote.scale.y *= createdFrom.songSpeed;

				if (PlayState.isPixelStage.priorityBool(usePixelTextures))
				{
					prevNote.scale.y *= 1.19;
					prevNote.scale.y *= (6 / height); // Auto adjust note size
				}
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}

			if (PlayState.isPixelStage.priorityBool(usePixelTextures))
			{
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
			earlyHitMult = 0;
		}
		else if (!isSustainNote)
		{
			centerOffsets();
			centerOrigin();
		}
		x += offsetX;
	}

	public static function initializeGlobalRGBShader(noteData:Int)
	{
		if (globalRgbShaders[noteData] == null)
		{
			var newRGB:RGBPalette = new RGBPalette();
			globalRgbShaders[noteData] = newRGB;

			var colors:Array<Array<FlxColor>> = (!PlayState.isPixelStage.priorityBool(usePixelTextures)) ? ClientPrefs.getArrowRGB() : ClientPrefs.getArrowRGB(true);
			var arr:Array<FlxColor> = (noteData > -1 && noteData < colors.length) ? colors[noteData] : null;
			if (arr != null && arr.length >= 3)
			{
				newRGB.r = arr[0];
				newRGB.g = arr[1];
				newRGB.b = arr[2];
			}
		}
		return globalRgbShaders[noteData];
	}

	var _lastNoteOffX:Float = 0;

	public var originalHeight:Float = 6;
	public var correctionOffset:Float = 0; // dont mess with this

	public function reloadNote(texture:String = '', postfix:String = '')
	{
		if (texture == null)
			texture = '';
		if (postfix == null)
			postfix = '';

		var skin:String = texture;
		if (texture.length < 1)
		{
			skin = PlayState.SONG != null ? PlayState.SONG.playerArrowSkin : null;
			if (skin == null || skin.length < 1)
				skin = defaultNoteSkin;
		}

		var animName:String = null;
		if (animation.curAnim != null)
		{
			animName = animation.curAnim.name;
		}

		var skinPixel:String = skin;
		var lastScaleY:Float = scale.y;
		var skinPostfix:String = getNoteSkinPostfix();
		var customSkin:String = skin + skinPostfix;
		var path:String = (PlayState.isPixelStage.priorityBool(usePixelTextures)) ? 'pixelUI/' : '';

		var fullPath:String = 'images/' + path + customSkin;

		if (Paths.fileExists(fullPath + '.${Paths.IMAGE_EXT}', Paths.getImageAssetType(Paths.IMAGE_EXT)))
			skin = customSkin;

		Note.colArray = Note.getColArrayFromKeys();

		if (PlayState.isPixelStage.priorityBool(usePixelTextures))
		{
			var imgPath:String = 'pixelUI/' + skinPixel + (skinPostfix != '' ? skinPostfix : '');
			var graphic:Null<FlxGraphic> = null;
			if (isSustainNote)
			{
				graphic = Paths.image(imgPath + 'ENDS');
				if (graphic != null)
				{
					loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 2));
					originalHeight = graphic.height / 2;
				}
			}
			else if (colArray[noteData] == 'odd')
			{
				graphic = Paths.image(imgPath + '_ODD');
				if (graphic != null)
					loadGraphic(graphic, true, Math.floor(graphic.width), Math.floor(graphic.height / 5));
			}

			if (graphic == null)
			{
				Note.colArray = getColArrayFromKeys(true);
				graphic = Paths.image(imgPath);
				loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 5));
			}

			setGraphicSize(Std.int(width * PlayState.daPixelZoom * noteScale));
			loadPixelNoteAnims();
			antialiasing = false;

			if (isSustainNote)
			{
				offsetX += _lastNoteOffX;
				_lastNoteOffX = (width - 7) * (PlayState.daPixelZoom / 2) * noteScale;
				offsetX -= _lastNoteOffX;
			}
		}
		else
		{
			frames = Paths.getSparrowAtlas(skin + (colArray[noteData] == 'odd' ? '_ODD' : ''));
			if (frames == null && colArray[noteData] == 'odd')
				Note.colArray = getColArrayFromKeys(true);
			if (frames == null)
				frames = Paths.getSparrowAtlas(skin);
			loadNoteAnims();
			if (!isSustainNote)
			{
				centerOffsets();
				centerOrigin();
			}
		}

		if (isSustainNote)
			scale.y = lastScaleY;

		updateHitbox();

		if (animName != null)
			animation.play(animName, true);
	}

	public static function getNoteSkinPostfix()
	{
		var skin:String = '';
		if (ClientPrefs.data.noteSkin != ClientPrefs.defaultData.noteSkin)
			skin = '-' + ClientPrefs.data.noteSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}

	function loadNoteAnims()
	{
		if (isSustainNote)
		{
			attemptToAddAnimationByPrefix('purpleholdend', 'pruple end hold', 24, true); // this fixes some restarted typo from the original note fla
			animation.addByPrefix(colArray[noteData] + 'holdend', colArray[noteData] + ' hold end', 24, true);
			animation.addByPrefix(colArray[noteData] + 'hold', colArray[noteData] + ' hold piece', 24, true);
		}
		else
			animation.addByPrefix(colArray[noteData] + 'Scroll', colArray[noteData] + '0');

		setGraphicSize(Std.int(width * 0.7 * noteScale));
		updateHitbox();
	}

	function loadPixelNoteAnims()
	{
		if (isSustainNote)
		{
			animation.add(colArray[noteData] + 'holdend', [colToIndex(colArray[noteData]) + 4], 24, true);
			animation.add(colArray[noteData] + 'hold', [colToIndex(colArray[noteData])], 24, true);
		}
		else
			animation.add(colArray[noteData] + 'Scroll', [colToIndex(colArray[noteData]) + 4], 24, true);
	}

	function attemptToAddAnimationByPrefix(name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true)
	{
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if (animFrames.length < 1)
			return;

		animation.addByPrefix(name, prefix, framerate, doLoop);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			canBeHit = (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult)
				&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult));

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
			{
				if ((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition)
					wasGoodHit = true;
			}
		}

		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}

	public function followStrumNote(myStrum:StrumNote, fakeCrochet:Float, songSpeed:Float = 1)
	{
		var strumX:Float = myStrum.x;
		var strumY:Float = myStrum.y;
		var strumAngle:Float = myStrum.angle;
		var strumAlpha:Float = myStrum.alpha;
		var strumDirection:Float = myStrum.direction;

		distance = (0.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed);
		if (!myStrum.downScroll)
			distance *= -1;

		var angleDir = strumDirection * Math.PI / 180;
		if (copyAngle)
			angle = strumDirection - 90 + strumAngle + offsetAngle;

		if (copyAlpha)
			alpha = strumAlpha * multAlpha;

		if (copyX)
			x = strumX + offsetX + Math.cos(angleDir) * distance;

		if (copyY)
		{
			y = strumY + offsetY + correctionOffset + Math.sin(angleDir) * distance;
			if (myStrum.downScroll && isSustainNote)
			{
				if (PlayState.isPixelStage.priorityBool(usePixelTextures))
				{
					y -= PlayState.daPixelZoom * 9.5;
				}
				y -= (frameHeight * scale.y) - (Note.swagScaledWidth / 2);
			}
		}
	}

	public function clipToStrumNote(myStrum:StrumNote)
	{
		var center:Float = myStrum.y + offsetY + Note.swagScaledWidth / 2;
		if (isSustainNote && (mustPress || !ignoreNote) && (!mustPress || (wasGoodHit || (prevNote.wasGoodHit && !canBeHit))))
		{
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
	}

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

	private static function get_defaultNoteSkin():String
		return !ClientPrefs.data.disableRGBNotes ? 'noteSkins/NOTE_assets' : 'NOTE_assets';
}
