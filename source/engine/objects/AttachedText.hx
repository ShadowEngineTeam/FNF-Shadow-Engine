package objects;

@:nullSafety(Strict)
class AttachedText extends Alphabet
{
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var sprTracker:Null<FlxSprite> = null;
	public var copyVisible:Bool = true;
	public var copyAlpha:Bool = false;

	public function new(text:String = "", ?offsetX:Float = 0, ?offsetY:Float = 0, ?bold = false, ?scale:Float = 1)
	{
		var ox:Float = offsetX != null ? offsetX : 0;
		var oy:Float = offsetY != null ? offsetY : 0;
		var s:Float = scale != null ? scale : 1;

		super(0, 0, text, bold);

		this.setScale(s);
		this.isMenuItem = false;
		this.offsetX = ox;
		this.offsetY = oy;
	}

	override function update(elapsed:Float)
	{
		var tracker = sprTracker;
		if (tracker != null)
		{
			setPosition(tracker.x + offsetX, tracker.y + offsetY);
			if (copyVisible)
				visible = tracker.visible;

			if (copyAlpha)
				alpha = tracker.alpha;
		}

		super.update(elapsed);
	}

	override function destroy()
	{
		sprTracker = FlxDestroyUtil.destroy(sprTracker);
		super.destroy();
	}
}
