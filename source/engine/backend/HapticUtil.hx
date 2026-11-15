package backend;

#if FEATURE_HAPTICS
import extension.haptics.Haptic;
#end

/**
 * Utility class for extra vibration functions.
 */
class HapticUtil
{
	public static inline final DEFAULT_VIBRATION_PERIOD:Float = 0.1;
	public static inline final DEFAULT_VIBRATION_DURATION:Float = 0.1;
	public static inline final DEFAULT_VIBRATION_AMPLITUDE:Float = 0.5;
	public static inline final MAX_VIBRATION_AMPLITUDE:Float = 1;
	public static inline final DEFAULT_VIBRATION_SHARPNESS:Float = 1;

	/**
	 * Indicates if haptics are available.
	 */
	public static var hapticsAvailable(get, never):Bool;

	/**
	 * Triggers vibration.
	 *
	 * @param period The time for one complete vibration in seconds.
	 * @param duration The time taken for a complete cycle in seconds.
	 * @param amplitude The intensity of the vibration (0.0 to 1.0).
	 * @param sharpness Controls the feel of vibration.
	 */
	public static function vibrate(period:Float = DEFAULT_VIBRATION_PERIOD, duration:Float = DEFAULT_VIBRATION_DURATION,
			amplitude:Float = DEFAULT_VIBRATION_AMPLITUDE, sharpness:Float = DEFAULT_VIBRATION_SHARPNESS):Void
	{
		#if FEATURE_HAPTICS
		if (!hapticsAvailable)
			return;

		final amplitudeValue:Float = Math.max(0, Math.min(MAX_VIBRATION_AMPLITUDE, amplitude));

		if (period > 0)
		{
			final durations:Array<Float> = [];
			final amplitudes:Array<Float> = [];
			final sharpnesses:Array<Float> = [];

			final durationPeriod:Float = period / 2;
			for (i in 0...Math.ceil(duration / durationPeriod))
			{
				durations[i] = durationPeriod;
				amplitudes[i] = amplitudeValue;
				sharpnesses[i] = sharpness;
			}

			Haptic.vibratePattern(durations, amplitudes, sharpnesses);
		}
		else
		{
			Haptic.vibrateOneShot(duration, amplitudeValue, sharpness);
		}
		#end
	}

	/**
	 * Triggers vibration using a preset.
	 *
	 * @param vibrationPreset Vibration's data.
	 */
	public static function vibrateByPreset(?vibrationPreset:VibrationPreset):Void
	{
		if (!hapticsAvailable)
			return;

		if (vibrationPreset == null)
			vibrate();
		else
			vibrate(vibrationPreset.period, vibrationPreset.duration, vibrationPreset.amplitude, vibrationPreset.sharpness);
	}

	static function get_hapticsAvailable():Bool
	{
		#if FEATURE_HAPTICS
		return ClientPrefs.data.haptics;
		#else
		return false;
		#end
	}
}

/**
 * A typedef containing data needed for vibrate function call.
 */
typedef VibrationPreset =
{
	var period:Float;
	var duration:Float;
	var amplitude:Float;
	var sharpness:Float;
}
