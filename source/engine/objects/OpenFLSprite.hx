package objects;

import openfl.display.Sprite;

/**
 * Designed to draw a OpenFL Sprite as a FlxSprite (To allow layering and auto sizing for haxe flixel cameras)
 */
@:nullSafety
class OpenFLSprite extends FlxSprite
{
	public var flSprite:Null<Sprite> = null;

	public function new(x:Float, y:Float, width:Int, height:Int, sprite:Sprite)
	{
		super(x, y);

		makeGraphic(width, height, FlxColor.TRANSPARENT);

		flSprite = sprite;

		pixels.draw(flSprite);
	}

	private var _frameCount:Int = 0;

	override function update(elapsed:Float)
	{
		if (_frameCount != 2)
		{
			var s = flSprite;
			if (s != null)
				pixels.draw(s);
			_frameCount++;
		}
	}

	public function updateDisplay()
	{
		var s = flSprite;
		if (s != null && pixels != null)
		{
			try
			{
				pixels.draw(s);
			}
			catch (e:Dynamic)
			{
				trace('Error drawing OpenFL Sprite: $e');
			}
		}
	}
}
