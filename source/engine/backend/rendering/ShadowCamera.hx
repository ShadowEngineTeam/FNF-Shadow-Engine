package backend.rendering;

import flixel.FlxCamera;

/**
 * A `FlxCamera` that carries an identifier, used as the engine's camera type.
 */
class ShadowCamera extends FlxCamera
{
	/**
	 * The ID of this camera, used for debugging.
	 */
	public var id:String;

	public function new(id:String = 'unknown', x:Int = 0, y:Int = 0, width:Int = 0, height:Int = 0, zoom:Float = 0)
	{
		super(x, y, width, height, zoom);

		this.id = id;
	}
}
