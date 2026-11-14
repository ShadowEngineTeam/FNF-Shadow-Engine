package debug.codename;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

class FramerateCounter extends Sprite
{
	public var fpsNum:TextField;
	public var fpsLabel:TextField;
	public var lastFPS:Float = 0;

	private var frameCount:Int = 0;

	private var accumulatedTime:Float = openfl.Lib.getTimer();

	private final updateInterval:Float = 1 / 15;
	private var lastUpdateTime:Float = 0;

	public function new()
	{
		super();

		fpsNum = new TextField();
		fpsLabel = new TextField();

		for (label in [fpsNum, fpsLabel])
		{
			label.autoSize = LEFT;
			label.x = 0;
			label.y = 0;
			label.multiline = label.wordWrap = false;
			label.selectable = false;
			addChild(label);
		}

		fpsNum.text = "0";
		fpsNum.defaultTextFormat = new TextFormat(Framerate.fontName, 18, Framerate.COLOR_FG, true);
		fpsNum.setTextFormat(fpsNum.defaultTextFormat);

		fpsLabel.text = "FPS";
		var labelFmt = new TextFormat(Framerate.fontName, 11, Framerate.COLOR_DIM, false);
		labelFmt.letterSpacing = 1.5; // ~.14em at 11px
		fpsLabel.defaultTextFormat = labelFmt;
		fpsLabel.setTextFormat(labelFmt);
	}

	public function reload()
		lastUpdateTime = 0;

	public override function __enterFrame(t:Float)
	{
		if (alpha <= 0.05)
			return;

		super.__enterFrame(t);

		frameCount++;

		if ((lastUpdateTime += FlxG.rawElapsed) < updateInterval)
		{
			updateLabelPosition();
			return;
		}

		final timer = openfl.Lib.getTimer();

		final time = timer - accumulatedTime;

		accumulatedTime = timer;

		lastFPS = FlxMath.lerp(lastFPS, time <= 0 ? 0 : (1000 / time * frameCount), 1.0 - Math.pow(0.75, time * 0.06));

		fpsNum.text = Std.string(Math.round(lastFPS));
		lastUpdateTime = frameCount = 0;

		updateLabelPosition();
	}

	private inline function updateLabelPosition():Void
	{
		fpsLabel.x = fpsNum.x + fpsNum.width + 4;
		fpsLabel.y = (fpsNum.y + fpsNum.height) - fpsLabel.height - 2;
	}
}
