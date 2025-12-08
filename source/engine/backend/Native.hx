package backend;

import lime.app.Application;
import lime.system.Display;
import lime.system.System;
import flixel.util.FlxColor;

#if (cpp && windows)
@:buildXml('
<target id="haxe">
	<section if="mingw">
		<lib name="-luser32" />
		<lib name="-lkernel32" />
		<lib name="-ldwmapi" />
		<lib name="-ladvapi32" />
		<lib name="-lgdi32" />
	</section>

	<section unless="mingw">
		<lib name="user32.lib" />
		<lib name="kernel32.lib" />
		<lib name="dwmapi.lib" />
		<lib name="advapi32.lib" />
		<lib name="gdi32.lib" />
	</section>
</target>
')
@:cppFileCode('
#include <windows.h>
#include <psapi.h>
#include <dwmapi.h>
#include <stdint.h>
#include <stdio.h>
#include <winuser.h>
#include <wingdi.h>

struct HandleData {
	DWORD pid = 0;
	HWND handle = 0;
};

BOOL CALLBACK findByPID(HWND handle, LPARAM lParam) {
	DWORD targetPID = ((HandleData*)lParam)->pid;
	DWORD curPID = 0;

	GetWindowThreadProcessId(handle, &curPID);
	if (targetPID != curPID || GetWindow(handle, GW_OWNER) != (HWND)0 || !IsWindowVisible(handle)) {
		return TRUE;
	}

	((HandleData*)lParam)->handle = handle;
	return FALSE;
}

HWND curHandle = 0;
void getHandle() {
	if (curHandle == (HWND)0) {
		HandleData data;
		data.pid = GetCurrentProcessId();
		EnumWindows(findByPID, (LPARAM)&data);
		curHandle = data.handle;
	}
}
')
#end
#if cpp
@:headerCode('#include <thread>')
#end
class Native
{
	public static function __init__():Void
	{
		registerDPIAware();
	}

	public static function registerDPIAware():Void
	{
		#if (cpp && windows)
		untyped __cpp__('
			SetProcessDPIAware();	
			#ifdef DPI_AWARENESS_CONTEXT
			SetProcessDpiAwarenessContext(
				#ifdef DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2
				DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2
				#else
				DPI_AWARENESS_CONTEXT_SYSTEM_AWARE
				#endif
			);
			#endif
		');
		#end
	}

	private static var fixedScaling:Bool = false;

	public static function fixScaling():Void
	{
		if (fixedScaling)
			return;
		fixedScaling = true;

		#if (cpp && windows)
		final display:Null<Display> = System.getDisplay(0);
		if (display != null)
		{
			final dpiScale:Float = display.dpi / 96;
			@:privateAccess Application.current.window.width = Std.int(Main.game.width * dpiScale);
			@:privateAccess Application.current.window.height = Std.int(Main.game.height * dpiScale);

			Application.current.window.x = Std.int((Application.current.window.display.bounds.width - Application.current.window.width) / 2);
			Application.current.window.y = Std.int((Application.current.window.display.bounds.height - Application.current.window.height) / 2);
		}

		untyped __cpp__('
			getHandle();
			if (curHandle != (HWND)0) {
				HDC curHDC = GetDC(curHandle);
				RECT curRect;
				GetClientRect(curHandle, &curRect);
				FillRect(curHDC, &curRect, (HBRUSH)GetStockObject(BLACK_BRUSH));
				ReleaseDC(curHandle, curHDC);
			}
		');
		#end
	}

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
