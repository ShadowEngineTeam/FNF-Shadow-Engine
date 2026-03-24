package objects;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;

@:nullSafety
class BGSprite extends FlxSprite
{
	private var idleAnim:Null<String> = null;

	public function new(image:String, x:Float = 0, y:Float = 0, ?scrollX:Float = 1, ?scrollY:Float = 1, ?animArray:Array<String> = null, ?loop:Bool = false)
	{
		super(x, y);

		var sx:Float = scrollX != null ? scrollX : 1;
		var sy:Float = scrollY != null ? scrollY : 1;

		if (animArray != null && image != null)
		{
			var atlas:Null<FlxAtlasFrames> = Paths.getSparrowAtlas(image);
			if (atlas != null)
			{
				frames = atlas;
				for (i in 0...animArray.length)
				{
					var anim:String = animArray[i];
					animation.addByPrefix(anim, anim, 24, loop);
					if (idleAnim == null)
					{
						idleAnim = anim;
						animation.play(anim);
					}
				}
			}
		}
		else
		{
			if (image != null)
			{
				var img:Null<FlxGraphic> = Paths.image(image);
				if (img != null)
					loadGraphic(img);
			}
			active = false;
		}
		scrollFactor.set(sx, sy);
		antialiasing = ClientPrefs.data.antialiasing;
	}

	public function dance(?forceplay:Bool = false)
	{
		if (idleAnim != null)
		{
			var fp:Bool = forceplay != null ? forceplay : false;
			animation.play(idleAnim, fp);
		}
	}
}
