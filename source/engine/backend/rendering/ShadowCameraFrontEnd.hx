package backend.rendering;

import flixel.FlxCamera;
import flixel.system.frontEnds.CameraFrontEnd;

/**
 * A `CameraFrontEnd` override that uses `ShadowCamera`!
 */
@:nullSafety
class ShadowCameraFrontEnd extends CameraFrontEnd
{
	public override function reset(?newCamera:FlxCamera):Void
	{
		super.reset(newCamera ?? new ShadowCamera());
	}
}
