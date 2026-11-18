package mobile.backend;

#if mobile
/**
 * Applies the Downscale Game option.
 *
 * Android reads `scaleSize.txt` into `SDL_ANDROID_DRAW_SCALE` before the window is made
 * (templates/haxe/ApplicationMain.hx), so it takes effect after a restart.
 * iOS caps the pixel scale with `SDL_IOS_MAX_PIXEL_SCALE`, which SDL applies right away.
 */
class RenderScale
{
	public static final DOWNSCALE:Float = (720 / 1.5) / 720;

	#if ios
	static var nativeScale:Float = 0;
	#end

	public static function init():Void
	{
		#if ios
		apply();
		#end
	}

	public static function save():Void
	{
		#if android
		File.saveContent(lime.system.System.applicationStorageDirectory + 'scaleSize.txt', ClientPrefs.data.downscaleGame ? '$DOWNSCALE' : '1');
		#elseif ios
		apply();
		#end
	}

	#if ios
	static function apply():Void
	{
		// The window's pixel scale drops once the hint is set, so the screen's own scale is read first
		if (nativeScale <= 0)
			nativeScale = FlxG.stage.window.scale;

		final scale:Float = Math.max(1.0, nativeScale * DOWNSCALE);

		lime.system.System.setHint('IOS_MAX_PIXEL_SCALE', ClientPrefs.data.downscaleGame && scale < nativeScale ? '$scale' : '0');
	}
	#end
}
#end
