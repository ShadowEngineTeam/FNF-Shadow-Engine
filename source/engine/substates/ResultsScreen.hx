package substates;

import objects.OpenFLSprite;
import flixel.FlxBasic;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.display.Graphics;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.text.TextField;

/**
 * we're so Kade Engine
 */
class ResultsScreen extends MusicBeatSubstate
{
	public var background:FlxSprite;
	public var text:FlxText;

	public var anotherBackground:FlxSprite;
	public var graph:HitGraph;
	public var graphSprite:OpenFLSprite;

	public var comboText:FlxText;
	public var contText:FlxText;
	public var settingsText:FlxText;

	public var music:FlxSound;

	public var graphData:BitmapData;

	public var ranking:String;
	public var accuracy:String;

	public var fuckingCamera:FlxCamera;

	override function create()
	{
		#if FEATURE_DISCORD_RPC
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Results", null);
		#end

		background = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		background.scrollFactor.set();
		add(background);

		music = new FlxSound();
		if (PauseSubState.songName != null)
		{
			music.loadEmbedded(Paths.music(PauseSubState.songName), true, true);
		}
		else if (PauseSubState.songName != 'None')
		{
			music.loadEmbedded(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)), true, true);
		}
		music.volume = 0;
		music.play(false, FlxG.random.int(0, Std.int(music.length / 2)));

		background.alpha = 0;

		text = new FlxText(20, -55, 0, "Song Cleared!");
		text.setFormat(Paths.font("Comfortaa-Bold.ttf"), 34, FlxColor.WHITE);
		text.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 4, 1);
		text.scrollFactor.set();
		add(text);

		var score = PlayState.instance.songScore;
		if (PlayState.isStoryMode)
		{
			score = PlayState.campaignScore;
			text.text = "Week Cleared!";
		}

		var sicks = PlayState.instance.totalSick;
		var goods = PlayState.instance.totalGood;
		var bads = PlayState.instance.totalBad;
		var shits = PlayState.instance.totalShit;
		var comboTxt:String = "";

		if (PlayState.instance.cpuControlled)
			comboTxt = 'Judgements:\nSicks - ${sicks}\nGoods - ${goods}\nBads - ${bads}\nShits - ${shits}\n\nHighest Combo: ${PlayState.instance.maxCombo}\n\nPlayback Rate: ${PlayState.instance.playbackRate}x';
		else
			comboTxt = 'Judgements:\nSicks - ${sicks}\nGoods - ${goods}\nBads - ${bads}\nShits - ${shits}\n\nMisses: ${(PlayState.isStoryMode ? PlayState.campaignMisses : PlayState.instance.songMisses)}\nHighest Combo: ${PlayState.instance.maxCombo}\nScore: ${FlxStringUtil.formatMoney(PlayState.instance.songScore, false)}\nAccuracy: ${CoolUtil.floorDecimal(PlayState.instance.ratingPercent * 100, 2)}%\n\nPlayback Rate: ${PlayState.instance.playbackRate}x';

		comboText = new FlxText(20, -75, 0, comboTxt);
		comboText.setFormat(Paths.font("Comfortaa-Bold.ttf"), 28, FlxColor.WHITE);
		comboText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 4, 1);
		comboText.scrollFactor.set();
		add(comboText);

		contText = new FlxText(FlxG.width - 800, FlxG.height + 50, 0,
			'Press ${controls.mobileC ? 'A' : 'ENTER'} to continue or ${controls.mobileC ? 'B' : 'RESET'} to Restart Song.');
		contText.setFormat(Paths.font("Comfortaa-Bold.ttf"), 28, FlxColor.WHITE);
		contText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 4, 1);
		contText.scrollFactor.set();
		add(contText);

		anotherBackground = new FlxSprite(FlxG.width - 500, 45).makeGraphic(450, 240, FlxColor.BLACK);
		anotherBackground.scrollFactor.set();
		anotherBackground.alpha = 0;
		add(anotherBackground);

		graph = new HitGraph(FlxG.width - 500, 45, 495, 240);
		graph.alpha = 0;

		graphSprite = new OpenFLSprite(FlxG.width - 510, 45, 460, 240, graph);

		graphSprite.scrollFactor.set();
		graphSprite.alpha = 0;

		add(graphSprite);

		var sicks = truncateFloat(PlayState.instance.totalSick / PlayState.instance.totalGood, 1);
		var goods = truncateFloat(PlayState.instance.totalGood / PlayState.instance.totalBad, 1);

		if (sicks == Math.POSITIVE_INFINITY || sicks == Math.NaN)
			sicks = 0;
		if (goods == Math.POSITIVE_INFINITY || goods == Math.NaN)
			goods = 0;

		var mean:Float = 0;

		for (i in 0...PlayState.instance.songSaveNotes.length)
		{
			var obj = PlayState.instance.songSaveNotes[i];
			var obj2 = PlayState.instance.songJudges[i];
			var obj3 = obj[0];
			var diff = obj[3];
			var judge = obj2;
			if (diff != (166 * Math.floor((ClientPrefs.data.safeFrames / 60) * 1000) / 166))
				mean += diff;
			if (obj[1] != -1)
				graph.addToHistory(diff / PlayState.instance.playbackRate, judge, obj3 / PlayState.instance.playbackRate);
		}

		graph.update();

		mean = truncateFloat(mean / PlayState.instance.totalNotesHit, 2);

		settingsText = new FlxText(20, FlxG.height + 50, 0,
			'Mean: ${mean}ms (SICK:${ClientPrefs.data.sickWindow}ms,GOOD:${ClientPrefs.data.goodWindow}ms,BAD:${ClientPrefs.data.badWindow}ms)');
		settingsText.setFormat(Paths.font("Comfortaa-Bold.ttf"), 16, FlxColor.WHITE);
		settingsText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2, 1);
		settingsText.scrollFactor.set();
		add(settingsText);

		FlxTween.tween(background, {alpha: 0.5}, 0.5);
		FlxTween.tween(text, {y: 20}, 0.5, {ease: FlxEase.expoInOut});
		FlxTween.tween(comboText, {y: 145}, 0.5, {ease: FlxEase.expoInOut});
		FlxTween.tween(contText, {y: FlxG.height - 45}, 0.5, {ease: FlxEase.expoInOut});
		FlxTween.tween(settingsText, {y: FlxG.height - 35}, 0.5, {ease: FlxEase.expoInOut});
		FlxTween.tween(anotherBackground, {alpha: 0.6}, 0.5, {
			onUpdate: function(tween:FlxTween)
			{
				graph.alpha = FlxMath.lerp(0, 1, tween.percent);
				graphSprite.alpha = FlxMath.lerp(0, 1, tween.percent);
			}
		});
		fuckingCamera = new FlxCamera();
		fuckingCamera.bgColor.alpha = 0;
		FlxG.cameras.add(fuckingCamera, false);
		cameras = [fuckingCamera];
		forEachAlive(function(obj:FlxBasic)
		{
			obj.cameras = [fuckingCamera];
		});
		#if FEATURE_MOBILE_CONTROLS
		addTouchPad("NONE", "A_B");
		addTouchPadCamera(false);
		#end
		super.create();
	}

	var frames = 0;

	override function update(elapsed:Float)
	{
		if (music != null)
			if (music.volume < 0.5)
				music.volume += 0.01 * elapsed;

		if (controls.ACCEPT)
		{
			music.stop();
			PlayState.instance.endCallback();
		}

		if (#if FEATURE_MOBILE_CONTROLS touchPad.buttonB.justPressed || #end controls.RESET)
		{
			PlayState.instance.paused = true; // For lua
			FlxG.sound.music.volume = 0;
			PlayState.instance.vocals.volume = 0;

			MusicBeatState.resetState();
		}

		super.update(elapsed);
	}

	public static function truncateFloat(number:Float, precision:Int):Float
	{
		var num = number;
		num = num * Math.pow(10, precision);
		num = Math.round(num) / Math.pow(10, precision);
		return num;
	}
}

/**
 * stolen from https://github.com/HaxeFlixel/flixel/blob/master/flixel/system/debug/stats/StatsGraph.hx
 */
class HitGraph extends Sprite
{
	static inline var AXIS_COLOR:FlxColor = 0xffffff;
	static inline var AXIS_ALPHA:Float = 0.5;
	inline static var HISTORY_MAX:Int = 30;

	public var minLabel:TextField;
	public var curLabel:TextField;
	public var maxLabel:TextField;
	public var avgLabel:TextField;

	public var minValue:Float = -(Math.floor((ClientPrefs.data.safeFrames / 60) * 1000) + 95);
	public var maxValue:Float = Math.floor((ClientPrefs.data.safeFrames / 60) * 1000) + 95;

	public var showInput:Bool = FlxG.save.data.inputShow;

	public var graphColor:FlxColor;

	public var history:Array<Dynamic> = [];

	public var bitmap:Bitmap;

	public var ts:Float;

	var _axis:Shape;
	var _width:Int;
	var _height:Int;
	var _unit:String;
	var _labelWidth:Int;
	var _label:String;

	public function new(X:Int, Y:Int, Width:Int, Height:Int)
	{
		super();
		x = X;
		y = Y;
		_width = Width;
		_height = Height;

		var bm = new BitmapData(Width, Height);
		bm.draw(this);
		bitmap = new Bitmap(bm);

		_axis = new Shape();
		_axis.x = _labelWidth + 10;

		ts = Math.floor((ClientPrefs.data.safeFrames / 60) * 1000) / 166;

		var early = createTextField(10, 10, FlxColor.WHITE, 12);
		var late = createTextField(10, _height - 20, FlxColor.WHITE, 12);

		early.text = "Early (" + -166 * ts + "ms)";
		late.text = "Late (" + 166 * ts + "ms)";

		addChild(early);
		addChild(late);

		addChild(_axis);

		drawAxes();
	}

	/**
	 * Redraws the axes of the graph.
	 */
	function drawAxes():Void
	{
		var gfx = _axis.graphics;
		gfx.clear();
		gfx.lineStyle(1, AXIS_COLOR, AXIS_ALPHA);

		// y-Axis
		gfx.moveTo(0, 0);
		gfx.lineTo(0, _height);

		// x-Axis
		gfx.moveTo(0, _height);
		gfx.lineTo(_width, _height);

		gfx.moveTo(0, _height / 2);
		gfx.lineTo(_width, _height / 2);
	}

	public static function createTextField(X:Float = 0, Y:Float = 0, Color:FlxColor = FlxColor.WHITE, Size:Int = 12):TextField
	{
		return initTextField(new TextField(), X, Y, Color, Size);
	}

	public static function initTextField<T:TextField>(tf:T, X:Float = 0, Y:Float = 0, Color:FlxColor = FlxColor.WHITE, Size:Int = 12):T
	{
		tf.x = X;
		tf.y = Y;
		tf.multiline = false;
		tf.wordWrap = false;
		tf.embedFonts = true;
		tf.selectable = false;
		tf.defaultTextFormat = new TextFormat("assets/fonts/vcr.ttf", Size, Color.to24Bit());
		tf.alpha = Color.alphaFloat;
		tf.autoSize = TextFieldAutoSize.LEFT;
		return tf;
	}

	function drawJudgementLine(ms:Float):Void
	{
		var gfx:Graphics = graphics;

		gfx.lineStyle(1, graphColor, 0.3);

		var ts = Math.floor((ClientPrefs.data.safeFrames / 60) * 1000) / 166;
		var range:Float = Math.max(maxValue - minValue, maxValue * 0.1);

		var value = ((ms * ts) - minValue) / range;

		var pointY = _axis.y + ((-value * _height - 1) + _height);

		var graphX = _axis.x + 1;

		if (ms == 45)
			gfx.moveTo(graphX, _axis.y + pointY);

		var graphX = _axis.x + 1;

		gfx.drawRect(graphX, pointY, _width, 1);

		gfx.lineStyle(1, graphColor, 1);
	}

	/**
	 * Redraws the graph based on the values stored in the history.
	 */
	function drawGraph():Void
	{
		var gfx:Graphics = graphics;
		gfx.clear();
		gfx.lineStyle(1, graphColor, 1);

		gfx.beginFill(0x00FF00);
		drawJudgementLine(45);
		gfx.endFill();

		gfx.beginFill(0xFF0000);
		drawJudgementLine(90);
		gfx.endFill();

		gfx.beginFill(0x8b0000);
		drawJudgementLine(135);
		gfx.endFill();

		gfx.beginFill(0x580000);
		drawJudgementLine(166);
		gfx.endFill();

		gfx.beginFill(0x00FF00);
		drawJudgementLine(-45);
		gfx.endFill();

		gfx.beginFill(0xFF0000);
		drawJudgementLine(-90);
		gfx.endFill();

		gfx.beginFill(0x8b0000);
		drawJudgementLine(-135);
		gfx.endFill();

		gfx.beginFill(0x580000);
		drawJudgementLine(-166);
		gfx.endFill();

		var range:Float = Math.max(maxValue - minValue, maxValue * 0.1);
		var graphX = _axis.x + 1;

		if (showInput)
		{
			for (i in 0...PlayState.instance.anaArray.length)
			{
				var ana = PlayState.instance.anaArray[i];

				var value = (ana.key * 25 - minValue) / range;

				if (ana.hit)
					gfx.beginFill(0xFFFF00);
				else
					gfx.beginFill(0xC2B280);

				if (ana.hitTime < 0)
					continue;

				var pointY = (-value * _height - 1) + _height;
				gfx.drawRect(graphX + fitX(ana.hitTime), pointY, 2, 2);
				gfx.endFill();
			}
		}

		for (i in 0...history.length)
		{
			var value = (history[i][0] - minValue) / range;
			var judge = history[i][1];

			switch (judge)
			{
				case "sick":
					gfx.beginFill(0x00FFFF);
				case "good":
					gfx.beginFill(0x00FF00);
				case "bad":
					gfx.beginFill(0xFF0000);
				case "shit":
					gfx.beginFill(0x8b0000);
				case "miss":
					gfx.beginFill(0x580000);
				default:
					gfx.beginFill(0xFFFFFF);
			}
			var pointY = ((-value * _height - 1) + _height);

			/*if (i == 0)
				gfx.moveTo(graphX, _axis.y + pointY); */
			gfx.drawRect(fitX(history[i][2]), pointY, 4, 4);

			gfx.endFill();
		}

		if (bitmap != null)
            bitmap.bitmapData.dispose();

		var bm = new BitmapData(_width, _height, true, 0x00000000);
		try
        {
            bm.draw(this);
            bitmap = new Bitmap(bm);
        }
        catch (e:Dynamic)
        {
            trace('Error drawing HitGraph: $e');
            bm.dispose();
        }
	}

	public function fitX(x:Float)
	{
		var musicLength = FlxG.sound.music?.length ?? 1.0;
        if (musicLength <= 0) musicLength = 1.0;
        return (x / musicLength) * _width;
	}

	public function addToHistory(diff:Float, judge:String, time:Float)
	{
		history.push([diff, judge, time]);
	}

	public function update():Void
	{
		if (_width <= 0 || _height <= 0)
        {
            trace('Invalid graph dimensions: $_width x $_height');
            return;
        }

		drawGraph();
	}

	public function average():Float
	{
		var sum:Float = 0;
		for (value in history)
			sum += value;
		return sum / history.length;
	}

	public function destroy():Void
	{
		_axis = FlxDestroyUtil.removeChild(this, _axis);
		history = null;
	}
}
