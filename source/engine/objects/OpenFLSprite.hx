package objects;

import openfl.display.Sprite;

/**
 * Designed to draw a OpenFL Sprite as a FlxSprite (To allow layering and auto sizing for haxe flixel cameras)
 */
class OpenFLSprite extends FlxSprite
{
	public var flSprite:Sprite;

	public function new(x, y, width, height, Sprite:Sprite)
	{
		super(x, y);

		makeGraphic(width, height, FlxColor.TRANSPARENT);

		flSprite = Sprite;

		pixels.draw(flSprite);
	}

	private var _frameCount:Int = 0;

	override function update(elapsed:Float)
	{
		if (_frameCount != 2)
		{
			pixels.draw(flSprite);
			_frameCount++;
		}
	}

	public function updateDisplay()
	{
		if (flSprite != null && pixels != null)
		{
			try
			{
				pixels.draw(flSprite);
			}
			catch (e:Dynamic)
			{
				trace('Error drawing OpenFL Sprite: $e');
				// Optionally, set a fallback graphic or skip
			}
		}
	}
}
