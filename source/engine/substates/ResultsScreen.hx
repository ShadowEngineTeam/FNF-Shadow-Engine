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
@:nullSafety
class ResultsScreen extends MusicBeatSubstate
{
	public var background:Null<FlxSprite>;
	public var text:Null<FlxText>;

	public var anotherBackground:Null<FlxSprite>;
	public var graph:Null<HitGraph>;
	public var graphSprite:Null<OpenFLSprite>;

	public var comboText:Null<FlxText>;
	public var contText:Null<FlxText>;
	public var settingsText:Null<FlxText>;

	public var music:Null<FlxSound>;

	public var graphData:Null<BitmapData>;

	public var ranking:Null<String>;
	public var accuracy:Null<String>;

	public var fuckingCamera:Null<ShadowCamera>;

	var instance:Null<PlayState>;

	override function create()
	{
		#if FEATURE_DISCORD_RPC
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Results", null);
		#end

		background = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		background.scrollFactor.set();
		add(background);

		instance = PlayState.instance;
		music = new FlxSound();
		var songName = PauseSubState.songName;
		var musicPath = songName != null && songName != 'None' ? Paths.music(songName) : null;
		if (musicPath == null)
		{
			var pauseMusic = Paths.formatToSongPath(ClientPrefs.data.pauseMusic ?? 'breakfast');
			musicPath = Paths.music(pauseMusic);
		}
		if (musicPath != null)
			music.loadEmbedded(musicPath, true, true);
		music.volume = 0;
		music.play(false, FlxG.random.int(0, Std.int(music.length / 2)));

		background.alpha = 0;

		text = new FlxText(20, -55, 0, "Song Cleared!");
		text.setFormat(Paths.font("Comfortaa-Bold.ttf"), 34, FlxColor.WHITE);
		text.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 4, 1);
		text.scrollFactor.set();
		add(text);

		instance = PlayState.instance;
		var score = instance?.songScore ?? 0;
		if (PlayState.isStoryMode)
		{
			score = PlayState.campaignScore;
			text.text = "Week Cleared!";
		}

		var sicks = instance?.totalSick ?? 0;
		var goods = instance?.totalGood ?? 0;
		var bads = instance?.totalBad ?? 0;
		var shits = instance?.totalShit ?? 0;
		var comboTxt:String = "";

		if (instance?.cpuControlled ?? false)
			comboTxt = 'Judgements:\nSicks - ${sicks}\nGoods - ${goods}\nBads - ${bads}\nShits - ${shits}\n\nHighest Combo: ${instance?.maxCombo ?? 0}\n\nPlayback Rate: ${instance?.playbackRate ?? 1.0}x';
		else
			comboTxt = 'Judgements:\nSicks - ${sicks}\nGoods - ${goods}\nBads - ${bads}\nShits - ${shits}\n\nMisses: ${(PlayState.isStoryMode ? PlayState.campaignMisses : instance?.songMisses ?? 0)}\nHighest Combo: ${instance?.maxCombo ?? 0}\nScore: ${FlxStringUtil.formatMoney(instance?.songScore ?? 0, false)}\nAccuracy: ${CoolUtil.floorDecimal((instance?.ratingPercent ?? 0) * 100, 2)}%\n\nPlayback Rate: ${instance?.playbackRate ?? 1.0}x';

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

		var totalGood = instance?.totalGood ?? 1;
		var totalBad = instance?.totalBad ?? 1;
		var sicks = truncateFloat((instance?.totalSick ?? 0) / totalGood, 1);
		var goods = truncateFloat(totalGood / totalBad, 1);

		if (sicks == Math.POSITIVE_INFINITY || Math.isNaN(sicks))
			sicks = 0;
		if (goods == Math.POSITIVE_INFINITY || Math.isNaN(goods))
			goods = 0;

		var mean:Float = 0;
		var playbackRate = instance?.playbackRate ?? 1.0;

		var songSaveNotes = instance?.songSaveNotes ?? [];
		var songJudges = instance?.songJudges ?? [];
		var safeFrames = ClientPrefs.data.safeFrames ?? 45;
		var diffThreshold = 166 * Math.floor((safeFrames / 60) * 1000) / 166;

		for (i in 0...songSaveNotes.length)
		{
			var obj:Array<Dynamic> = songSaveNotes[i];
			var obj2 = songJudges[i];
			if (obj == null)
				continue;
			var obj3 = obj[0] ?? 0;
			var diff:Float = obj[3] ?? 0;
			var judge = obj2 ?? '';
			if (diff != diffThreshold)
				mean += diff;
			if ((obj[1] ?? -1) != -1)
				graph.addToHistory(diff / playbackRate, judge, obj3 / playbackRate);
		}

		graph.update();

		mean = truncateFloat(mean / (instance?.totalNotesHit ?? 1), 2);

		settingsText = new FlxText(20, FlxG.height + 50, 0,
			'Mean: ${mean}ms (SICK:${ClientPrefs.data.sickWindow ?? 50}ms,GOOD:${ClientPrefs.data.goodWindow ?? 100}ms,BAD:${ClientPrefs.data.badWindow ?? 150}ms)');
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
				if (graph != null)
					graph.alpha = FlxMath.lerp(0, 1, tween.percent);
				if (graphSprite != null)
					graphSprite.alpha = FlxMath.lerp(0, 1, tween.percent);
			}
		});
		fuckingCamera = new ShadowCamera();
		fuckingCamera.bgColor.alpha = 0;
		FlxG.cameras.add(fuckingCamera, false);
		if (fuckingCamera != null)
			cameras = [fuckingCamera];
		forEachAlive(function(obj:FlxBasic)
		{
			if (fuckingCamera != null)
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
			instance?.endCallback();
		}

		if (#if FEATURE_MOBILE_CONTROLS touchPad?.buttonB?.justPressed || #end controls.RESET)
		{
			if (instance != null)
				instance.paused = true;
			FlxG.sound.music.volume = 0;
			if (instance != null && instance.vocals != null)
				instance.vocals.volume = 0;

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

	public var minValue:Float = -(Math.floor(((ClientPrefs.data.safeFrames ?? 45) / 60) * 1000) + 95);
	public var maxValue:Float = Math.floor(((ClientPrefs.data.safeFrames ?? 45) / 60) * 1000) + 95;

	public var showInput:Bool = FlxG.save.data?.inputShow ?? false;

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

		ts = Math.floor(((ClientPrefs.data.safeFrames ?? 45) / 60) * 1000) / 166;

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
		tf.defaultTextFormat = new TextFormat("assets/fonts/vcr.ttf", Size, Color.rgb);
		tf.alpha = Color.alphaFloat;
		tf.autoSize = TextFieldAutoSize.LEFT;
		return tf;
	}

	function drawJudgementLine(ms:Float):Void
	{
		var gfx:Graphics = graphics;

		gfx.lineStyle(1, graphColor, 0.3);

		var ts = Math.floor(((ClientPrefs.data.safeFrames ?? 45) / 60) * 1000) / 166;
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
			var anaArray = PlayState.instance?.anaArray ?? [];
			for (i in 0...anaArray.length)
			{
				var ana = anaArray[i];
				if (ana == null)
					continue;

				var value = ((ana.key ?? 0) * 25 - minValue) / range;

				if (ana.hit)
					gfx.beginFill(0xFFFF00);
				else
					gfx.beginFill(0xC2B280);

				var hitTime:Float = ana.hitTime ?? -1;
				if (hitTime < 0)
					continue;

				var pointY = (-value * _height - 1) + _height;
				gfx.drawRect(graphX + fitX(hitTime), pointY, 2, 2);
				gfx.endFill();
			}
		}

		for (i in 0...history.length)
		{
			var entry:Array<Dynamic> = history[i];
			if (entry == null)
				continue;

			var value = ((entry[0] ?? 0) - minValue) / range;
			var judge = entry[1] ?? '';

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

			gfx.drawRect(fitX(entry[2] ?? 0), pointY, 4, 4);

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
		if (musicLength <= 0)
			musicLength = 1.0;
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
