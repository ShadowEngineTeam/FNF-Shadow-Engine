package backend;

import backend.CoolUtil;
import openfl.Assets;
import openfl.utils.Promise;
import lime.app.Future;
import openfl.events.MouseEvent;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.Lib;
import flixel.system.FlxBasePreloader;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import shaders.VFDOverlay;
import backend.Paths;

using StringTools;

class FunkinPreloader extends FlxBasePreloader
{
	static final BASE_WIDTH:Float = 1280;
	static final BAR_PADDING:Float = 20;
	static final BAR_HEIGHT:Int = 12;
	static final LOGO_FADE_TIME:Float = 2.5;
	static final TOTAL_STEPS:Int = 2;
	static final ELLIPSIS_TIME:Float = 0.5;

	static final STATE_NOT_STARTED:String = "NotStarted";
	static final STATE_DOWNLOADING_ASSETS:String = "DownloadingAssets";
	static final STATE_COMPLETE:String = "Complete";
	#if TOUCH_HERE_TO_PLAY
	static final STATE_TOUCH_HERE_TO_PLAY:String = "TouchHereToPlay";
	#end

	var ratio:Float = 0;

	var currentState:String = STATE_NOT_STARTED;

	private var downloadingAssetsPercent:Float = -1;
	private var downloadingAssetsComplete:Bool = false;

	private var completeTime:Float = -1;

	var logo:Bitmap;
	#if TOUCH_HERE_TO_PLAY
	var touchHereToPlay:Bitmap;
	var touchHereSprite:Sprite;
	#end
	var progressBarPieces:Array<Sprite>;
	var progressLeftText:TextField;
	var progressRightText:TextField;
	var dspText:TextField;
	var fnfText:TextField;
	var enhancedText:TextField;
	var stereoText:TextField;
	var vfdShader:VFDOverlay;
	var vfdBitmap:Bitmap;
	var box:Sprite;
	var progressLines:Sprite;

	public function new()
	{
		super(0.0);
		// trace('Initializing custom preloader...');
	}

	override function create():Void
	{
		super.create();

		setupStage();
		setupLogo();
		setupProgressBar();
		setupTextFields();
		setupBox();
		setupVFD();
		#if TOUCH_HERE_TO_PLAY
		setupTouchHereToPlay();
		#end
		updateLayout();

		Lib.current.stage.addEventListener(Event.RESIZE, onResize);
	}

	function onResize(e:Event):Void
	{
		this._width = Lib.current.stage.stageWidth;
		this._height = Lib.current.stage.stageHeight;
		ratio = this._width / BASE_WIDTH / 2.0;

		updateLayout();
	}

	function updateLayout():Void
	{
		if (logo != null)
		{
			logo.scaleX = logo.scaleY = ratio;
			logo.x = (this._width - logo.width) / 2;
			logo.y = (this._height - logo.height) / 2;
		}

		if (progressBarPieces != null)
		{
			var amountOfPieces:Int = 16;
			var maxBarWidth:Float = this._width - BAR_PADDING * 2;
			var pieceWidth:Float = maxBarWidth / amountOfPieces;
			var pieceGap:Int = 8;

			for (i in 0...progressBarPieces.length)
			{
				var piece = progressBarPieces[i];
				piece.graphics.clear();
				piece.graphics.beginFill(0xFFA4FF11);
				piece.graphics.drawRoundRect(0, 0, pieceWidth - pieceGap, BAR_HEIGHT, 4, 4);
				piece.graphics.endFill();
				piece.x = BAR_PADDING + i * pieceWidth;
				piece.y = this._height - BAR_PADDING - BAR_HEIGHT - 200;
			}
		}

		if (progressLines != null)
		{
			progressLines.graphics.clear();
			progressLines.graphics.lineStyle(2, 0xFFA4FF11);
			progressLines.graphics.drawRect(-2, this._height - BAR_PADDING - BAR_HEIGHT - 208, this._width + 4, 30);
		}

		if (progressLeftText != null)
		{
			progressLeftText.x = BAR_PADDING;
			progressLeftText.y = this._height - BAR_PADDING - BAR_HEIGHT - 290;
			progressLeftText.width = this._width - BAR_PADDING * 2;
		}
		if (progressRightText != null)
		{
			progressRightText.x = BAR_PADDING;
			progressRightText.y = this._height - BAR_PADDING - BAR_HEIGHT - 16 - 4;
			progressRightText.width = this._width - BAR_PADDING * 2;
		}

		if (box != null)
		{
			box.x = this._width - BAR_PADDING - BAR_HEIGHT - 432;
			box.y = this._height - BAR_PADDING - BAR_HEIGHT - 244;
		}

		if (vfdBitmap != null)
			vfdBitmap.bitmapData = new BitmapData(this._width, this._height, true, 0xFFFFFFFF);

		#if TOUCH_HERE_TO_PLAY
		if (touchHereToPlay != null)
		{
			touchHereToPlay.scaleX = touchHereToPlay.scaleY = ratio;
			touchHereToPlay.x = (this._width - touchHereToPlay.width) / 2;
			touchHereToPlay.y = (this._height - touchHereToPlay.height) / 2;
		}
		#end
	}

	function setupStage():Void
	{
		Lib.current.stage.color = 0xFF000000;
		Lib.current.stage.frameRate = 60;
		this._width = Lib.current.stage.stageWidth;
		this._height = Lib.current.stage.stageHeight;
		ratio = this._width / BASE_WIDTH / 2.0;
	}

	function setupLogo():Void
	{
		final logoPath:String = Paths.getPath('preloader/banner.png', IMAGE);
		final logoBitmapData:BitmapData = BitmapData.fromBytes(File.getBytes(logoPath));
		logo = new Bitmap(logoBitmapData);
		addChild(logo);
	}

	function setupProgressBar():Void
	{
		var amountOfPieces:Int = 16;
		progressBarPieces = [];

		progressLines = new Sprite();
		addChild(progressLines);
		
		for (i in 0...amountOfPieces)
		{
			var piece = new Sprite();
			addChild(piece);
			progressBarPieces.push(piece);
		}
	}

	function setupTextFields():Void
	{
		progressLeftText = new TextField();
		var progressLeftTextFormat = new TextFormat("DS-Digital", 32, 0xFFA4FF11, true);
		progressLeftTextFormat.align = TextFormatAlign.LEFT;
		progressLeftText.defaultTextFormat = progressLeftTextFormat;
		progressLeftText.selectable = false;
		progressLeftText.text = 'Downloading assets...';
		addChild(progressLeftText);

		progressRightText = new TextField();
		var progressRightTextFormat = new TextFormat("DS-Digital", 16, 0xFFA4FF11, true);
		progressRightTextFormat.align = TextFormatAlign.RIGHT;
		progressRightText.defaultTextFormat = progressRightTextFormat;
		progressRightText.selectable = false;
		progressRightText.text = '0%';
		addChild(progressRightText);
	}

	function setupBox():Void
	{
		box = new Sprite();
		box.graphics.beginFill(0xFFA4FF11, 1);
		box.graphics.drawRoundRect(0, 0, 64, 20, 5, 5);
		box.graphics.drawRoundRect(70, 0, 58, 20, 5, 5);
		box.graphics.endFill();
		box.graphics.beginFill(0xFFA4FF11, 0.1);
		box.graphics.drawRoundRect(0, 0, 128, 20, 5, 5);
		box.graphics.endFill();
		addChild(box);

		dspText = new TextField();
		dspText.selectable = false;
		dspText.textColor = 0x000000;
		dspText.width = this._width;
		dspText.height = 30;
		dspText.text = 'DSP';
		dspText.x = 10;
		dspText.y = -7;
		box.addChild(dspText);

		fnfText = new TextField();
		fnfText.selectable = false;
		fnfText.textColor = 0x000000;
		fnfText.width = this._width;
		fnfText.height = 30;
		fnfText.x = 78;
		fnfText.y = -7;
		fnfText.text = 'FNF';
		box.addChild(fnfText);

		enhancedText = new TextField();
		enhancedText.selectable = false;
		enhancedText.textColor = 0xFFA4FF11;
		enhancedText.width = this._width;
		enhancedText.height = 100;
		enhancedText.text = 'ENHANCED';
		enhancedText.x = -100;
		enhancedText.y = 0;
		box.addChild(enhancedText);

		stereoText = new TextField();
		stereoText.selectable = false;
		stereoText.textColor = 0xFFA4FF11;
		stereoText.width = this._width;
		stereoText.height = 100;
		stereoText.text = 'STEREO';
		stereoText.x = 0;
		stereoText.y = -40;
		box.addChild(stereoText);
	}

	function setupVFD():Void
	{
		vfdBitmap = new Bitmap();
		addChild(vfdBitmap);
		vfdShader = new VFDOverlay();
		vfdBitmap.shader = vfdShader;
	}

	#if TOUCH_HERE_TO_PLAY
	function setupTouchHereToPlay():Void
	{
		final touchPath:String = Paths.getPath('images/preloader/touchHereToPlay.png', IMAGE, null);
		final touchBitmapData:BitmapData = BitmapData.fromBytes(File.getBytes(touchPath));
		touchHereToPlay = new Bitmap(touchBitmapData);
		touchHereToPlay.alpha = 0.0;

		touchHereSprite = new Sprite();
		touchHereSprite.buttonMode = false;
		touchHereSprite.addChild(touchHereToPlay);
		addChild(touchHereSprite);
	}
	#end

	var lastElapsed:Float = 0.0;

	override function update(percent:Float):Void
	{
		var elapsed:Float = (Date.now().getTime() - this._startTime) / 1000.0;
		if (vfdShader != null)
			vfdShader.update(elapsed * 100);
		downloadingAssetsPercent = percent;
		var loadPercent:Float = updateState(percent, elapsed);
		updateGraphics(loadPercent, elapsed);
		lastElapsed = elapsed;
	}

	function updateState(percent:Float, elapsed:Float):Float
	{
		if (currentState == STATE_NOT_STARTED)
		{
			if (downloadingAssetsPercent > 0.0)
				currentState = STATE_DOWNLOADING_ASSETS;
			return percent;
		}

		if (currentState == STATE_DOWNLOADING_ASSETS)
		{
			if (downloadingAssetsPercent >= 1.0 || (elapsed > 0.0 && downloadingAssetsComplete))
				currentState = STATE_COMPLETE;
			return percent;
		}

		if (currentState == STATE_COMPLETE)
		{
			if (completeTime < 0)
				completeTime = elapsed;
			return 1.0;
		}

		#if TOUCH_HERE_TO_PLAY
		if (currentState == STATE_TOUCH_HERE_TO_PLAY)
		{
			if (completeTime < 0)
				completeTime = elapsed;
			if (touchHereToPlay.alpha < 1.0)
			{
				touchHereSprite.buttonMode = true;
				touchHereToPlay.alpha = 1.0;
				removeChild(vfdBitmap);
				addEventListener(MouseEvent.CLICK, onTouchHereToPlay);
				touchHereSprite.addEventListener(MouseEvent.MOUSE_OVER, overTouchHereToPlay);
				touchHereSprite.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownTouchHereToPlay);
				touchHereSprite.addEventListener(MouseEvent.MOUSE_OUT, outTouchHereToPlay);
			}
			return 1.0;
		}
		#end

		return 0.0;
	}

	#if TOUCH_HERE_TO_PLAY
	function overTouchHereToPlay(e:MouseEvent):Void
	{
		touchHereToPlay.scaleX = touchHereToPlay.scaleY = ratio * 1.1;
		touchHereToPlay.x = (this._width - touchHereToPlay.width) / 2;
		touchHereToPlay.y = (this._height - touchHereToPlay.height) / 2;
	}

	function outTouchHereToPlay(e:MouseEvent):Void
	{
		touchHereToPlay.scaleX = touchHereToPlay.scaleY = ratio;
		touchHereToPlay.x = (this._width - touchHereToPlay.width) / 2;
		touchHereToPlay.y = (this._height - touchHereToPlay.height) / 2;
	}

	function mouseDownTouchHereToPlay(e:MouseEvent):Void
	{
		touchHereToPlay.y += 10;
	}

	function onTouchHereToPlay(e:MouseEvent):Void
	{
		touchHereToPlay.x = (this._width - touchHereToPlay.width) / 2;
		touchHereToPlay.y = (this._height - touchHereToPlay.height) / 2;
		removeEventListener(MouseEvent.CLICK, onTouchHereToPlay);
		touchHereSprite.removeEventListener(MouseEvent.MOUSE_OVER, overTouchHereToPlay);
		touchHereSprite.removeEventListener(MouseEvent.MOUSE_OUT, outTouchHereToPlay);
		touchHereSprite.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownTouchHereToPlay);
		immediatelyStartGame();
	}
	#end

	function updateGraphics(percent:Float, elapsed:Float):Void
	{
		if (completeTime > 0.0)
		{
			var elapsedFinished:Float = renderLogoFadeOut(elapsed);
			if (elapsedFinished > LOGO_FADE_TIME)
			{
				#if TOUCH_HERE_TO_PLAY
				currentState = STATE_TOUCH_HERE_TO_PLAY;
				#else
				immediatelyStartGame();
				#end
			}
		}
		else
		{
			renderLogoFadeIn(elapsed);
			var piecesToRender:Int = Std.int(percent * progressBarPieces.length);
			for (i => piece in progressBarPieces)
			{
				piece.alpha = i <= piecesToRender ? 0.9 : 0.1;
			}
		}

		var ellipsisCount:Int = Std.int(elapsed / ELLIPSIS_TIME) % 3 + 1;
		var ellipsis:String = [for (i in 0...ellipsisCount) '.'].join('');
		var percentage:Int = Math.floor(percent * 100);

		var statusText:String;
		if (currentState == STATE_NOT_STARTED)
			statusText = 'Loading \n0/$TOTAL_STEPS ' + ellipsis;
		else if (currentState == STATE_DOWNLOADING_ASSETS)
			statusText = 'Downloading assets \n1/$TOTAL_STEPS ' + ellipsis;
		else if (currentState == STATE_COMPLETE)
			statusText = 'Finishing up \n$TOTAL_STEPS/$TOTAL_STEPS ' + ellipsis;
		#if TOUCH_HERE_TO_PLAY
		else if (currentState == STATE_TOUCH_HERE_TO_PLAY)
			statusText = null;
		#end
		else
			statusText = null;

		updateProgressLeftText(statusText);
		progressRightText.text = '$percentage%';
		super.update(percent);
	}

	function updateProgressLeftText(text:Null<String>):Void
	{
		if (progressLeftText != null)
		{
			if (text == null)
			{
				progressLeftText.alpha = 0.0;
			}
			else if (progressLeftText.text != text)
			{
				var progressLeftTextFormat = new TextFormat("DS-Digital", 32, 0xFFA4FF11, true);
				progressLeftTextFormat.align = TextFormatAlign.LEFT;
				progressLeftText.defaultTextFormat = progressLeftTextFormat;
				progressLeftText.text = text;

				dspText.defaultTextFormat = new TextFormat("Quantico", 20, 0x000000, false);
				dspText.text = 'DSP';
				dspText.textColor = 0x000000;

				fnfText.defaultTextFormat = new TextFormat("Quantico", 20, 0x000000, false);
				fnfText.text = 'FNF';
				fnfText.textColor = 0x000000;

				enhancedText.defaultTextFormat = new TextFormat("Inconsolata Black", 16, 0xFFA4FF11, false);
				enhancedText.text = 'ENHANCED';
				enhancedText.textColor = 0xFFA4FF11;

				stereoText.defaultTextFormat = new TextFormat("Inconsolata Bold", 36, 0xFFA4FF11, false);
				stereoText.text = 'NATURAL STEREO';
			}
		}
	}

	function immediatelyStartGame():Void
	{
		_loaded = true;
	}

	function renderLogoFadeOut(elapsed:Float):Float
	{
		var elapsedFinished = elapsed - completeTime;
		logo.alpha = 1.0 - CoolUtil.easeInOutCirc(elapsedFinished / LOGO_FADE_TIME);
		logo.scaleX = (1.0 - CoolUtil.easeInBack(elapsedFinished / LOGO_FADE_TIME)) * ratio;
		logo.scaleY = (1.0 - CoolUtil.easeInBack(elapsedFinished / LOGO_FADE_TIME)) * ratio;
		logo.x = (this._width - logo.width) / 2;
		logo.y = (this._height - logo.height) / 2;

		progressLeftText.alpha = logo.alpha;
		progressRightText.alpha = logo.alpha;
		box.alpha = logo.alpha;
		dspText.alpha = logo.alpha;
		fnfText.alpha = logo.alpha;
		enhancedText.alpha = logo.alpha;
		stereoText.alpha = logo.alpha;
		progressLines.alpha = logo.alpha;

		for (piece in progressBarPieces)
			piece.alpha = logo.alpha;

		return elapsedFinished;
	}

	function renderLogoFadeIn(elapsed:Float):Void
	{
		logo.alpha = CoolUtil.easeInOutCirc(elapsed / LOGO_FADE_TIME);
		logo.scaleX = CoolUtil.easeOutBack(elapsed / LOGO_FADE_TIME) * ratio;
		logo.scaleY = CoolUtil.easeOutBack(elapsed / LOGO_FADE_TIME) * ratio;
		logo.x = (this._width - logo.width) / 2;
		logo.y = (this._height - logo.height) / 2;
	}

	override function destroy():Void
	{
		if (logo != null)
		{
			removeChild(logo);
			logo = null;
		}
		super.destroy();
	}

	override function onLoaded():Void
	{
		super.onLoaded();
		_loaded = false;
		downloadingAssetsComplete = true;
	}
}
