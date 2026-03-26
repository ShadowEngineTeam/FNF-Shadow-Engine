package objects;

import flixel.math.FlxRect;
import flixel.graphics.FlxGraphic;

@:nullSafety
class Bar extends FlxSpriteGroup
{
	public var leftBar:Null<FlxSprite> = null;
	public var rightBar:Null<FlxSprite> = null;
	public var bg:Null<FlxSprite> = null;
	public var valueFunction:Null<Void->Float> = null;
	public var percent(default, set):Float = 0;
	public var bounds:Dynamic = {min: 0, max: 1};
	public var leftToRight(default, set):Bool = true;
	public var barCenter(default, null):Float = 0;

	// you might need to change this if you want to use a custom bar
	public var barWidth(default, set):Int = 1;
	public var barHeight(default, set):Int = 1;
	public var barOffset:FlxPoint = FlxPoint.get(3, 3);

	private var percentTween:Null<FlxTween> = null;

	public function new(x:Float, y:Float, image:String = 'healthBar', ?valueFunction:Void->Float, boundX:Float = 0, boundY:Float = 1)
	{
		super(x, y);

		this.valueFunction = valueFunction;
		bounds.min = boundX;
		bounds.max = boundY;

		var img:Null<FlxGraphic> = Paths.image(image);
		if (img != null)
		{
			bg = new FlxSprite();
			bg.loadGraphic(img);
			bg.antialiasing = ClientPrefs.data.antialiasing;
			barWidth = Std.int(bg.width - 6);
			barHeight = Std.int(bg.height - 6);

			leftBar = new FlxSprite();
			leftBar.makeGraphic(Std.int(bg.width), Std.int(bg.height), FlxColor.WHITE);
			leftBar.antialiasing = ClientPrefs.data.antialiasing;

			rightBar = new FlxSprite();
			rightBar.makeGraphic(Std.int(bg.width), Std.int(bg.height), FlxColor.WHITE);
			rightBar.color = FlxColor.BLACK;
			rightBar.antialiasing = ClientPrefs.data.antialiasing;

			if (leftBar != null)
				add(leftBar);
			if (rightBar != null)
				add(rightBar);
			if (bg != null)
				add(bg);
			regenerateClips();
		}

		moves = false;
		immovable = true;
	}

	public var enabled:Bool = true;

	override function update(elapsed:Float)
	{
		if (!enabled)
		{
			super.update(elapsed);
			return;
		}

		var vf = valueFunction;
		if (vf != null)
		{
			var rawValue:Float = vf();
			var value:Float = FlxMath.remapToRange(FlxMath.bound(rawValue, bounds.min, bounds.max), bounds.min, bounds.max, 0, 100);
			percent = set_percent(value);
		}
		else
			percent = 0;
		super.update(elapsed);
	}

	public function setBounds(min:Float, max:Float)
	{
		bounds.min = min;
		bounds.max = max;
	}

	public function setColors(?left:FlxColor, ?right:FlxColor)
	{
		var lb = leftBar;
		var rb = rightBar;
		if (left != null && lb != null)
			lb.color = left;
		if (right != null && rb != null)
			rb.color = right;
	}

	public function updateBar()
	{
		var lb = leftBar;
		var rb = rightBar;
		var bgSprite = bg;
		if (lb == null || rb == null || bgSprite == null)
			return;

		lb.setPosition(bgSprite.x, bgSprite.y);
		rb.setPosition(bgSprite.x, bgSprite.y);

		var leftSize:Float = 0;
		if (leftToRight)
			leftSize = FlxMath.lerp(0, barWidth, percent / 100);
		else
			leftSize = FlxMath.lerp(0, barWidth, 1 - percent / 100);

		lb.clipRect.width = leftSize;
		lb.clipRect.height = barHeight;
		lb.clipRect.x = barOffset.x;
		lb.clipRect.y = barOffset.y;

		rb.clipRect.width = barWidth - leftSize;
		rb.clipRect.height = barHeight;
		rb.clipRect.x = barOffset.x + leftSize;
		rb.clipRect.y = barOffset.y;

		barCenter = lb.x + leftSize + barOffset.x;

		lb.clipRect = lb.clipRect;
		rb.clipRect = rb.clipRect;
	}

	public function regenerateClips()
	{
		var lb = leftBar;
		var rb = rightBar;
		var bgSprite = bg;
		if (lb != null && bgSprite != null)
		{
			lb.setGraphicSize(Std.int(bgSprite.width), Std.int(bgSprite.height));
			lb.updateHitbox();
			lb.clipRect = new FlxRect(0, 0, Std.int(bgSprite.width), Std.int(bgSprite.height));
		}
		if (rb != null && bgSprite != null)
		{
			rb.setGraphicSize(Std.int(bgSprite.width), Std.int(bgSprite.height));
			rb.updateHitbox();
			rb.clipRect = new FlxRect(0, 0, Std.int(bgSprite.width), Std.int(bgSprite.height));
		}
		updateBar();
	}

	private function set_percent(value:Float)
	{
		if (value != percent)
		{
			if (percentTween != null)
				percentTween.cancel();

			var duration:Float = 0.15;
			percentTween = FlxTween.num(percent, value, duration, {ease: FlxEase.quadOut}, (v) ->
			{
				percent = v;
				updateBar();
			});
		}
		return value;
	}

	private function set_leftToRight(value:Bool)
	{
		leftToRight = value;
		updateBar();
		return value;
	}

	private function set_barWidth(value:Int)
	{
		barWidth = value;
		regenerateClips();
		return value;
	}

	private function set_barHeight(value:Int)
	{
		barHeight = value;
		regenerateClips();
		return value;
	}

	override function destroy()
	{
		active = false;
		barOffset.put();
		bg = FlxDestroyUtil.destroy(bg);
		leftBar = FlxDestroyUtil.destroy(leftBar);
		rightBar = FlxDestroyUtil.destroy(rightBar);
		super.destroy();
	}
}
