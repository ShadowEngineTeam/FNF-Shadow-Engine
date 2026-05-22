package debug.codename;

import backend.codename.MathUtil;
import flixel.math.FlxPoint;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.KeyboardEvent;
import openfl.filters.DropShadowFilter;
import openfl.geom.Point;
import openfl.text.TextFormat;
import openfl.ui.Keyboard;
import flixel.util.FlxTimer;

class Framerate extends Sprite
{
	public static var instance:Framerate;
	public static var isLoaded:Bool = false;

	public static var textFormat:TextFormat;
	public static var fpsCounter:FramerateCounter;
	public static var memoryCounter:MemoryCounter;

	public static var fontName:String = #if windows '${Sys.getEnv("windir")}\\Fonts\\consola.ttf' #else "_typewriter" #end;

	public static inline var COLOR_FG:Int = 0xE8E2D6; // foreground
	public static inline var COLOR_DIM:Int = 0x8A7E72; // dim text
	public static inline var COLOR_ACCENT:Int = 0xE23A4A; // red accent / bad
	public static inline var COLOR_WARN:Int = 0xF0A04B; // warn
	public static inline var COLOR_PANEL:Int = 0x160E12; // panel background

	public static inline var PAD_X:Float = 12;
	public static inline var PAD_Y:Float = 6;
	public static inline var INSET:Float = 14;

	/**
	 * 0: INVISIBLE
	 * 1: BOARD      (text wrapped in a panel)
	 * 2: BOARD + SYSTEM INFO
	 */
	public static var debugMode:Int = 1;

	public static var offset:FlxPoint = new FlxPoint(INSET, INSET);

	// Hold to drag either object with the mouse.
	public static var draggable:Bool = true;

	public var board:Sprite;
	public var panel:Sprite;
	public var bgSprite:Bitmap;
	public var borderSprite:Bitmap;

	public var categories:Array<FramerateCategory> = [];

	@:isVar public static var __bitmap(get, null):BitmapData = null;

	private static function get___bitmap():BitmapData
	{
		if (__bitmap == null)
			__bitmap = new BitmapData(1, 1, 0xFF000000 | COLOR_PANEL);
		return __bitmap;
	}

	@:isVar public static var __accentBitmap(get, null):BitmapData = null;

	private static function get___accentBitmap():BitmapData
	{
		if (__accentBitmap == null)
			__accentBitmap = new BitmapData(1, 1, 0xFF000000 | COLOR_ACCENT);
		return __accentBitmap;
	}

	@:isVar public static var __darkBitmap(get, null):BitmapData = null;

	private static function get___darkBitmap():BitmapData
	{
		if (__darkBitmap == null)
			__darkBitmap = new BitmapData(1, 1, 0xFF000000);
		return __darkBitmap;
	}

	public static inline function panelShadow():DropShadowFilter
		return new DropShadowFilter(6, 90, 0x000000, 0.45, 20, 20, 1, 2, false, false, false);

	public static inline function screenW():Float
	{
		var s = (instance != null && instance.scaleX > 0) ? instance.scaleX : 1;
		return FlxG.stage.stageWidth / s;
	}

	public static inline function screenH():Float
	{
		var s = (instance != null && instance.scaleY > 0) ? instance.scaleY : 1;
		return FlxG.stage.stageHeight / s;
	}

	public static function computeSlideFrom(restX:Float, restY:Float, w:Float, h:Float):Point
	{
		var sw = screenW();
		var sh = screenH();

		var left = restX;
		var right = sw - (restX + w);
		var top = restY;
		var bottom = sh - (restY + h);

		var m = Math.min(Math.min(left, right), Math.min(top, bottom));
		if (m == left)
			return new Point(-(restX + w) - INSET, 0);
		if (m == right)
			return new Point((sw - restX) + INSET, 0);
		if (m == top)
			return new Point(0, -(restY + h) - INSET);
		return new Point(0, (sh - restY) + INSET);
	}

	#if mobile
	#if android public var presses:Int = 0; #end
	public var sillyTimer:FlxTimer = new FlxTimer();
	#end

	var dragging:Bool = false;
	var dragBoard:Bool = false;
	var dragCat:FramerateCategory = null;
	var dragStartLocal:Point = new Point();
	var dragStartOffset:FlxPoint = new FlxPoint();

	var boardW:Float = 0;
	var boardH:Float = 0;

	// Board appear/disappear animation.
	var boardVisT:Float = 0; // alpha (eases both ways)
	var boardSlideT:Float = 1; // 0 = off-edge, 1 = at rest (only animates on appear)
	var boardSlideFromX:Float = 0;
	var boardSlideFromY:Float = 0;
	var boardLastVisible:Bool = false;

	public function new()
	{
		super();
		if (instance != null)
			throw "Cannot create another instance";
		instance = this;
		textFormat = new TextFormat(fontName, 13, COLOR_FG);

		isLoaded = true;

		x = y = 0;

		FlxG.signals.gameResized.add(function(w, h)
		{
			setScale(Math.min(openfl.Lib.current.stage.stageWidth / FlxG.width, openfl.Lib.current.stage.stageHeight / FlxG.height));
		});

		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, function(e:KeyboardEvent)
		{
			if (Controls.instance.justReleased('fpsCounter'))
			{
				debugMode = (debugMode + 1) % 3;
				@:privateAccess
				{
					memoryCounter.refreshText(memoryCounter.memory, memoryCounter.memoryPeak);
				}
			}
		});

		board = new Sprite();
		addChild(board);

		// Panel chrome lives in an unscaled container so the drop shadow's blur
		// isn't multiplied by the background bitmap's scale.
		panel = new Sprite();
		panel.filters = [panelShadow()];
		board.addChild(panel);

		bgSprite = new Bitmap(__bitmap);
		bgSprite.alpha = 0.82;
		panel.addChild(bgSprite);

		borderSprite = new Bitmap(__accentBitmap);
		borderSprite.alpha = 1;
		panel.addChild(borderSprite);

		board.addChild(fpsCounter = new FramerateCounter());
		board.addChild(memoryCounter = new MemoryCounter());

		__addCategory(new SystemInfo());
	}

	private function updateDrag():Void
	{
		if (!draggable)
		{
			dragging = false;
			return;
		}

		var m = globalToLocal(new Point(FlxG.stage.mouseX, FlxG.stage.mouseY));

		if (FlxG.mouse.justReleased)
		{
			dragging = false;
			dragBoard = false;
			dragCat = null;
		}

		var shift = #if mobile true #elseif FLX_KEYBOARD FlxG.keys.pressed.SHIFT #end;
		if (!dragging && FlxG.mouse.justPressed && shift)
		{
			// System Info panels are independent objects; check them first (they draw separately).
			if (debugMode > 1)
			{
				for (c in categories)
				{
					if (c.visible && hitTest(m, c.x, c.y, c.width, c.height))
					{
						dragging = true;
						dragCat = c;
						dragStartOffset.set(c.offset.x, c.offset.y);
						dragStartLocal.setTo(m.x, m.y);
						break;
					}
				}
			}
			if (!dragging && debugMode > 0 && board.visible && hitTest(m, board.x - PAD_X, board.y - PAD_Y, boardW, boardH))
			{
				dragging = true;
				dragBoard = true;
				dragStartOffset.set(offset.x, offset.y);
				dragStartLocal.setTo(m.x, m.y);
			}
		}

		if (dragging && FlxG.mouse.pressed)
		{
			var nx = dragStartOffset.x + (m.x - dragStartLocal.x);
			var ny = dragStartOffset.y + (m.y - dragStartLocal.y);
			if (dragBoard)
				offset.set(nx, ny);
			else if (dragCat != null)
			{
				dragCat.offset.set(nx, ny);
				dragCat.dragged = true;
			}
		}
	}

	private inline function hitTest(p:Point, x:Float, y:Float, w:Float, h:Float):Bool
		return p.x >= x && p.x <= x + w && p.y >= y && p.y <= y + h;

	public function reload()
	{
		for (c in categories)
			c.reload();
		memoryCounter.reload();
		fpsCounter.reload();
	}

	private function __addCategory(category:FramerateCategory)
	{
		categories.push(category);
		addChild(category);
	}

	public override function __enterFrame(t:Float)
	{
		super.__enterFrame(t);

		#if android
		if (FlxG.android.justReleased.BACK)
		{
			sillyTimer.cancel();
			++presses;
			if (presses >= 3)
			{
				debugMode = (debugMode + 1) % 3;
				presses = 0;
				return;
			}
			sillyTimer.start(0.3, (tmr:FlxTimer) -> presses = 0);
		}
		#elseif ios
		for (camera in FlxG.cameras.list)
		{
			var pos = FlxG.mouse.getScreenPosition(camera);
			if (pos.x >= FlxG.game.x + offset.x
				&& pos.x <= FlxG.game.x + offset.x + 80
				&& pos.y >= FlxG.game.y + offset.y
				&& pos.y <= FlxG.game.y + offset.y + 60)
			{
				if (FlxG.mouse.justPressed)
					sillyTimer.start(0.4, (tmr:FlxTimer) -> debugMode = (debugMode + 1) % 3);

				if (FlxG.mouse.justReleased)
					sillyTimer.cancel();
			}
			else if (sillyTimer.active && !sillyTimer.finished)
				sillyTimer.cancel();
		}
		#end

		// Drag uses last frame's board metrics, so resolve it before relaying out.
		updateDrag();

		// --- Board layout & metrics ---
		fpsCounter.x = fpsCounter.y = 0;
		memoryCounter.x = 0;
		memoryCounter.y = fpsCounter.height;

		var contentW = MathUtil.maxSmart(fpsCounter.width, memoryCounter.width);
		var contentH = memoryCounter.y + memoryCounter.height;
		boardW = contentW + PAD_X * 2;
		boardH = contentH + PAD_Y * 2;

		// --- Board appear / disappear ---
		var boardVisible = debugMode > 0;
		boardVisT = CoolUtil.fpsLerp(boardVisT, boardVisible ? 1 : 0, 0.5);

		if (boardVisible && !boardLastVisible) // just appeared: slide in from nearest edge
		{
			boardSlideT = 0;
			var sf = computeSlideFrom(offset.x, offset.y, boardW, boardH);
			boardSlideFromX = sf.x;
			boardSlideFromY = sf.y;
		}
		boardLastVisible = boardVisible;
		boardSlideT = CoolUtil.fpsLerp(boardSlideT, 1, 0.5);

		board.alpha = boardVisT;
		board.visible = boardVisT > 0.05;
		// Disappearing keeps the rest position (boardSlideT stays ~1, so the slide term is ~0)
		// and only fades via alpha; appearing rides the slide term in from the edge.
		board.x = offset.x + boardSlideFromX * (1 - boardSlideT);
		board.y = offset.y + boardSlideFromY * (1 - boardSlideT);

		// Panel chrome (local to the board container).
		bgSprite.x = -PAD_X;
		bgSprite.y = -PAD_Y;
		bgSprite.scaleX = boardW;
		bgSprite.scaleY = boardH;

		borderSprite.x = -PAD_X;
		borderSprite.y = -PAD_Y;
		borderSprite.scaleX = 2;
		borderSprite.scaleY = boardH;

		var selectable = debugMode >= 2;
		memoryCounter.memLabel.selectable = memoryCounter.memoryText.selectable = memoryCounter.memoryPeakText.selectable = fpsCounter.fpsNum.selectable = fpsCounter.fpsLabel.selectable = selectable;

		var stackY = offset.y + boardH + 8;
		for (c in categories)
		{
			if (!c.dragged) // until dragged, sit stacked under the board
				c.offset.set(offset.x, stackY);
			c.title.selectable = c.text.selectable = selectable;
			c.updateAnim(debugMode > 1);
			stackY = c.offset.y + c.height + 8;
		}
	}

	public inline function setScale(?scale:Float)
	{
		if (scale == null)
			scale = Math.min(FlxG.stage.window.width / FlxG.width, FlxG.stage.window.height / FlxG.height);
		scaleX = scaleY = #if ios scale #else (scale < 1 ? scale : 1) #end;
	}
}
