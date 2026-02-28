package backend;

#if (cpp && windows)
@:buildXml('
<target id="haxe">
	<section if="mingw">
		<lib name="-ldwmapi" />
	</section>

	<section unless="mingw">
		<lib name="dwmapi.lib" />
	</section>
</target>
')
@:cppFileCode('
#include <windows.h>
#include <dwmapi.h>
')
#end
#if cpp
@:headerCode('#include <thread>')
#end
class Native
{
	public static function disableErrorReporting():Void
	{
		#if (cpp && windows)
		untyped __cpp__('SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX)');
		#end
	}

	public static function disableWindowsGhosting():Void
	{
		#if (cpp && windows)
		untyped __cpp__('DisableProcessWindowsGhosting()');
		#end
	}

	public static function setDarkMode(enable:Bool):Void
	{
		#if (cpp && windows)
		untyped __cpp__('
			HWND window = GetActiveWindow();
			int darkMode = {0} ? 1 : 0;
			if (DwmSetWindowAttribute(window, 20, &darkMode, sizeof(darkMode)) != S_OK)
				DwmSetWindowAttribute(window, 19, &darkMode, sizeof(darkMode));
			UpdateWindow(window);
		', enable);
		#end
	}

	public static function setConsoleOutputToUTF8():Void
	{
		#if (cpp && windows)
		untyped __cpp__('SetConsoleOutputCP(CP_UTF8);');
		#end
	}

	#if cpp
	@:functionCode('
        return std::thread::hardware_concurrency();
    ')
	#end
	public static function getCPUThreadsCount():Int
	{
		return 1;
	}
}
