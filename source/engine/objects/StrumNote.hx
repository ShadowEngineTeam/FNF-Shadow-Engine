package objects;

import flixel.addons.effects.FlxSkewedSprite;
import shaders.ColorSwap;
import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

using backend.CoolUtil;

/**
 * One of the four (or more) static arrows that live at the top/bottom of the strumline.
 *
 * Animation layout is data-driven (see `SPARROW_DIRS` / `PIXEL_DIR_FRAMES`) so adding
 * directions later only needs entries in those tables.
**/
class StrumNote extends FlxSkewedSprite
{
	// ─── Direction tables (drives reloadNote) ───────────────────────────────
	// Index = noteData % 4, matching Note.colArray order.

	static inline var SPARROW_FPS:Int = 24;
	static inline var PIXEL_PRESSED_FPS:Int = 12;

	// Sparrow atlas suffixes per direction
	static final SPARROW_DIRS:Array<String> = ['left', 'down', 'up', 'right'];
	static final SPARROW_STATIC:Array<String> = ['arrowLEFT', 'arrowDOWN', 'arrowUP', 'arrowRIGHT'];

	// Generic color-name aliases that the engine relies on elsewhere
	static final COLOR_TO_SPARROW:Array<{name:String, prefix:String}> = [
		{name: 'purple', prefix: 'arrowLEFT'},
		{name: 'blue',   prefix: 'arrowDOWN'},
		{name: 'green',  prefix: 'arrowUP'},
		{name: 'red',    prefix: 'arrowRIGHT'}
	];

	// Pixel sprite-sheet frame layout. For each noteData % 4:
	// static, pressed, confirm, confirmFps (the original had case 2 at 12fps — preserved)
	static final PIXEL_DIR_FRAMES:Array<{statics:Array<Int>, pressed:Array<Int>, confirm:Array<Int>, confirmFps:Int}> = [
		{statics: [0], pressed: [4,  8], confirm: [12, 16], confirmFps: 24},
		{statics: [1], pressed: [5,  9], confirm: [13, 17], confirmFps: 24},
		{statics: [2], pressed: [6, 10], confirm: [14, 18], confirmFps: 12},
		{statics: [3], pressed: [7, 11], confirm: [15, 19], confirmFps: 24}
	];

	// Generic single-frame color aliases on the pixel sheet
	static final COLOR_TO_PIXEL_FRAME:Array<{name:String, frame:Int}> = [
		{name: 'purple', frame: 4},
		{name: 'blue',   frame: 5},
		{name: 'green',  frame: 6},
		{name: 'red',    frame: 7}
	];

	// ─── Public state ───────────────────────────────────────────────────────
	public var colorSwap:ColorSwap = null;
	public var rgbShader:RGBShaderReference;
	public var resetAnim:Float = 0;

	public var direction:Float = 90; // plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;

	public var useRGBShader:Bool = true;
	public var texture(default, set):String = null;

	public static var _activeStrumNotes:Array<StrumNote> = [];
	public static var usePixelTextures(default, set):Null<Bool>;

	// ─── Private state ──────────────────────────────────────────────────────
	var noteData:Int = 0;
	var player:Int;

	// ─── Construction ───────────────────────────────────────────────────────

	public function new(x:Float, y:Float, leData:Int, player:Int, daTexture:String)
	{
		super(x, y);

		this.noteData = leData;
		this.player = player;

		_activeStrumNotes.push(this);

		initShader(leData);
		texture = resolveSkin(daTexture); // setter triggers reloadNote
		scrollFactor.set();
	}

	function initShader(leData:Int):Void
	{
		if (ClientPrefs.data.disableRGBNotes)
		{
			colorSwap = new ColorSwap();
			shader = colorSwap.shader;
			return;
		}

		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData));
		rgbShader.enabled = false;

		if (PlayState.SONG != null && PlayState.SONG.disableNoteCustomColor)
			useRGBShader = false;

		final arr:Array<FlxColor> = isPixel ? ClientPrefs.data.arrowRGBPixel[leData] : ClientPrefs.data.arrowRGB[leData];
		if (leData <= arr.length)
		{
			@:bypassAccessor
			{
				rgbShader.r = arr[0];
				rgbShader.g = arr[1];
				rgbShader.b = arr[2];
			}
		}
	}

	function resolveSkin(daTexture:String):String
	{
		final postfix:String = Note.getNoteSkinPostfix();
		final base:String = (daTexture != null && daTexture.length > 1) ? daTexture : Note.defaultNoteSkin;
		final customSkin:String = base + postfix;
		final folder:String = isPixel ? 'pixelUI/' : '';

		if (Paths.fileExists('images/$folder$customSkin.${Paths.IMAGE_EXT}', Paths.getImageAssetType(Paths.IMAGE_EXT)))
			return customSkin;
		return Note.defaultNoteSkin;
	}

	// ─── Setters ────────────────────────────────────────────────────────────

	function set_texture(value:String):String
	{
		if (texture != value)
		{
			texture = value;
			reloadNote();
		}
		return value;
	}

	static function set_usePixelTextures(value:Null<Bool>):Null<Bool>
	{
		if (usePixelTextures != value)
		{
			usePixelTextures = value;
			for (note in _activeStrumNotes)
				note.reloadNote();
		}
		return value;
	}

	// ─── Texture loading ────────────────────────────────────────────────────

	public function reloadNote():Void
	{
		final lastAnim:String = (animation.curAnim != null) ? animation.curAnim.name : null;

		if (isPixel)
			loadPixelGraphics();
		else
			loadSparrowGraphics();

		updateHitbox();

		if (lastAnim != null)
			playAnim(lastAnim, true);
	}

	function loadPixelGraphics():Void
	{
		// Two-pass load: the first call reads the source dimensions so we can
		// figure out cell size for the second call.
		loadGraphic(Paths.image('pixelUI/' + texture));
		width = width / 4;
		height = height / 5;
		loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));

		antialiasing = false;
		setGraphicSize(Std.int(width * PlayState.daPixelZoom));

		for (entry in COLOR_TO_PIXEL_FRAME)
			animation.add(entry.name, [entry.frame]);

		final dir = PIXEL_DIR_FRAMES[Std.int(Math.abs(noteData)) % 4];
		animation.add('static',  dir.statics);
		animation.add('pressed', dir.pressed, PIXEL_PRESSED_FPS, false);
		animation.add('confirm', dir.confirm, dir.confirmFps, false);
	}

	function loadSparrowGraphics():Void
	{
		frames = Paths.getSparrowAtlas(texture);
		antialiasing = ClientPrefs.data.antialiasing;
		setGraphicSize(Std.int(width * 0.7));

		for (entry in COLOR_TO_SPARROW)
			animation.addByPrefix(entry.name, entry.prefix);

		final dirIdx:Int = Std.int(Math.abs(noteData)) % 4;
		final dirName:String = SPARROW_DIRS[dirIdx];
		animation.addByPrefix('static',  SPARROW_STATIC[dirIdx]);
		animation.addByPrefix('pressed', '$dirName press',   SPARROW_FPS, false);
		animation.addByPrefix('confirm', '$dirName confirm', SPARROW_FPS, false);
	}

	// ─── Group / animation lifecycle ────────────────────────────────────────

	public function postAddedToGroup():Void
	{
		playAnim('static');
		x += Note.swagWidth * noteData;
		x += 50;
		x += (FlxG.width / 2) * player;
		ID = noteData;
	}

	override function update(elapsed:Float):Void
	{
		if (resetAnim > 0)
		{
			resetAnim -= elapsed;
			if (resetAnim <= 0)
			{
				playAnim('static');
				resetAnim = 0;
			}
		}
		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false):Void
	{
		animation.play(anim, force);
		if (animation.curAnim != null)
		{
			centerOffsets();
			centerOrigin();
		}

		if (ClientPrefs.data.disableRGBNotes)
			updateColorSwapForAnim();
		else if (useRGBShader)
			rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static');
	}

	function updateColorSwapForAnim():Void
	{
		final cur = animation.curAnim;
		if (cur == null || cur.name == 'static')
		{
			colorSwap.hue = 0;
			colorSwap.saturation = 0;
			colorSwap.brightness = 0;
			return;
		}

		if (noteData > -1 && noteData < ClientPrefs.data.arrowHSV.length)
		{
			colorSwap.hue        = ClientPrefs.data.arrowHSV[noteData][0] / 360;
			colorSwap.saturation = ClientPrefs.data.arrowHSV[noteData][1] / 100;
			colorSwap.brightness = ClientPrefs.data.arrowHSV[noteData][2] / 100;
		}

		if (cur.name == 'confirm' && !isPixel)
			centerOrigin();
	}

	override function destroy():Void
	{
		_activeStrumNotes.remove(this);
		super.destroy();
	}

	// ─── Helpers ────────────────────────────────────────────────────────────

	public var isPixel(get, never):Bool;

	inline function get_isPixel():Bool
		return PlayState.isPixelStage.priorityBool(usePixelTextures);
}
