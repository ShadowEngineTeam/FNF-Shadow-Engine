package objects;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;

@:nullSafety
class AttachedSprite extends FlxSprite
{
	public var sprTracker:Null<FlxSprite> = null;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;
	public var angleAdd:Float = 0;
	public var alphaMult:Float = 1;

	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;
	public var copyVisible:Bool = false;

	public function new(?file:String = null, ?anim:String = null, ?library:String = null, ?loop:Bool = false)
	{
		super();
		if (anim != null && file != null)
		{
			var frames:Null<FlxAtlasFrames> = Paths.getSparrowAtlas(file, library);
			if (frames != null)
			{
				var animName:String = anim;
				this.frames = frames;
				animation.addByPrefix('idle', animName, 24, loop);
				animation.play('idle');
			}
		}
		else if (file != null)
		{
			var img:Null<FlxGraphic> = Paths.image(file);
			if (img != null)
				loadGraphic(img);
		}
		antialiasing = ClientPrefs.data.antialiasing;
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var tracker = sprTracker;
		if (tracker != null)
		{
			setPosition(tracker.x + xAdd, tracker.y + yAdd);
			scrollFactor.set(tracker.scrollFactor.x, tracker.scrollFactor.y);

			if (copyAngle)
				angle = tracker.angle + angleAdd;

			if (copyAlpha)
				alpha = tracker.alpha * alphaMult;

			if (copyVisible)
				visible = tracker.visible;
		}
	}

	override function destroy()
	{
		sprTracker = FlxDestroyUtil.destroy(sprTracker);
		super.destroy();
	}
}
