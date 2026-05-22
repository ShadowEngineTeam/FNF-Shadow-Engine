package debug.codename;

import backend.codename.MathUtil;
import flixel.math.FlxPoint;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.KeyboardEvent;
import openfl.filters.DropShadowFilter;
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

	public static var offset:FlxPoint = new FlxPoint();

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

	#if mobile
	#if android public var presses:Int = 0; #end
	public var sillyTimer:FlxTimer = new FlxTimer();
	#end

	public function new()
	{
		super();
		if (instance != null)
			throw "Cannot create another instance";
		instance = this;
		textFormat = new TextFormat(fontName, 13, COLOR_FG);

		isLoaded = true;

		x = INSET;
		y = INSET;

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

		// Panel chrome lives in an unscaled container so the drop shadow's blur
		// isn't multiplied by the background bitmap's scale.
		panel = new Sprite();
		panel.filters = [panelShadow()];
		addChild(panel);

		bgSprite = new Bitmap(__bitmap);
		bgSprite.alpha = 0;
		panel.addChild(bgSprite);

		borderSprite = new Bitmap(__accentBitmap);
		borderSprite.alpha = 0;
		panel.addChild(borderSprite);

		__addToList(fpsCounter = new FramerateCounter());
		__addToList(memoryCounter = new MemoryCounter());
		__addCategory(new SystemInfo());
	}

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
		__addToList(category);
	}

	private var __lastAddedSprite:DisplayObject = null;

	private function __addToList(spr:DisplayObject)
	{
		spr.x = 0;
		spr.y = __lastAddedSprite != null ? (__lastAddedSprite.y + __lastAddedSprite.height) : 0;
		// spr.y += offset.y;
		__lastAddedSprite = spr;
		addChild(spr);
	}

	var debugAlpha:Float = 0;
	var boardAlpha:Float = 0;

	public override function __enterFrame(t:Float)
	{
		alpha = CoolUtil.fpsLerp(alpha, debugMode > 0 ? 1 : 0, 0.5);
		boardAlpha = CoolUtil.fpsLerp(boardAlpha, debugMode > 0 ? 1 : 0, 0.5);
		debugAlpha = CoolUtil.fpsLerp(debugAlpha, debugMode > 1 ? 1 : 0, 0.5);
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
			if (pos.x >= FlxG.game.x + 10 + offset.x
				&& pos.x <= FlxG.game.x + offset.x + 80
				&& pos.y >= FlxG.game.y + 2 + offset.y
				&& pos.y <= FlxG.game.y
					+ 2
					+ offset.y
					+ 60)
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

		if (alpha < 0.05)
			return;
		super.__enterFrame(t);

		x = INSET + offset.x;
		y = INSET + offset.y;

		// Content metrics (the floating text block).
		var contentW = MathUtil.maxSmart(fpsCounter.width, memoryCounter.width);
		var contentH = memoryCounter.y + memoryCounter.height;

		// Panel wraps the content with padding; left edge sits PAD_X left of the text.
		var panelW = contentW + PAD_X * 2;
		var panelH = contentH + PAD_Y * 2;

		// Slide the board in from / out past the left edge as it appears / disappears.
		var boardSlide = FlxMath.lerp(-(panelW + INSET) - offset.x, 0, boardAlpha);
		panel.x = fpsCounter.x = memoryCounter.x = boardSlide;

		panel.visible = boardAlpha > 0.05;
		bgSprite.alpha = boardAlpha * 0.82;
		bgSprite.x = -PAD_X;
		bgSprite.y = -PAD_Y;
		bgSprite.scaleX = panelW;
		bgSprite.scaleY = panelH;

		borderSprite.alpha = boardAlpha;
		borderSprite.x = -PAD_X;
		borderSprite.y = -PAD_Y;
		borderSprite.scaleX = 2;
		borderSprite.scaleY = panelH;

		var selectable = debugMode >= 2;
		{
			memoryCounter.memLabel.selectable = memoryCounter.memoryText.selectable = memoryCounter.memoryPeakText.selectable = fpsCounter.fpsNum.selectable = fpsCounter.fpsLabel.selectable = selectable;
		}

		var y:Float = (contentH + PAD_Y) + 8;
		for (c in categories)
		{
			c.title.selectable = c.text.selectable = selectable;
			c.alpha = debugAlpha;
			c.x = FlxMath.lerp(-c.width - offset.x, -PAD_X, debugAlpha);
			c.y = y;
			y = c.y + c.height + 8;
		}
	}

	public inline function setScale(?scale:Float)
	{
		if (scale == null)
			scale = Math.min(FlxG.stage.window.width / FlxG.width, FlxG.stage.window.height / FlxG.height);
		scaleX = scaleY = #if ios scale #else (scale < 1 ? scale : 1) #end;
	}
}
