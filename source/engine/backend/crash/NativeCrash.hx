package backend.crash;

#if FEATURE_NATIVE_CRASH_HANDLER
/**
 * Reports native crashes (segfaults, aborts, stack overflows) that the Haxe crash handler cannot catch.
 * From FunkinCrew/Funkin's `funkin.external.crash.NativeCrash`.
 */
@:build(macros.LinkerMacro.xml('project/Build.xml'))
@:include('nativecrash.hpp')
extern class NativeCrash
{
	/**
	 * Installs the handler.
	 * @param logDir Directory the report is written to, relative to the working directory at the time of the crash.
	 * @param appName Name shown in the dialog title and at the top of the report.
	 */
	@:native('NATIVECRASH_Install')
	static function install(logDir:cpp.ConstCharStar, appName:cpp.ConstCharStar):Void;

	/**
	 * Writes through a null pointer to trigger a real segfault, for testing the handler.
	 */
	@:native('NATIVECRASH_ForceCrash')
	static function forceCrash():Void;
}
#end
