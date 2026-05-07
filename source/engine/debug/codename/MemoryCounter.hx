package debug.codename;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

#if cpp
@:cppFileCode('
#if defined(_WIN32)
  #include <windows.h>
  #include <psapi.h>
#elif defined(__APPLE__) && defined(__MACH__)
  #include <mach/mach.h>
#elif defined(__linux__) || defined(__gnu_linux__) || defined(__ANDROID__)
  #include <stdio.h>
#endif
')
@:cppNamespaceCode('
size_t MemoryCounter_obj::native_getMemory()
{
#if defined(_WIN32)
    PROCESS_MEMORY_COUNTERS_EX info;
    if (GetProcessMemoryInfo(GetCurrentProcess(),
                             (PROCESS_MEMORY_COUNTERS*)&info,
                             sizeof(info))) {
        return (size_t)info.PrivateUsage;
    }
    return (size_t)0;
#elif defined(__APPLE__) && defined(__MACH__)
    struct task_vm_info vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    if (task_info(mach_task_self(), TASK_VM_INFO,
                  (task_info_t)&vmInfo, &count) == KERN_SUCCESS) {
        return (size_t)vmInfo.internal + (size_t)vmInfo.compressed;
    }
    return (size_t)0;
#elif defined(__linux__) || defined(__gnu_linux__) || defined(__ANDROID__)
    size_t vmrss = 0, vmswap = 0;
    FILE *fp = fopen("/proc/self/status", "r");
    if (fp) {
        char line[256];
        while (fgets(line, sizeof(line), fp)) {
            if (sscanf(line, "VmRSS: %zu kB", &vmrss) == 1) continue;
            if (sscanf(line, "VmSwap: %zu kB", &vmswap) == 1) continue;
        }
        fclose(fp);
        return (vmrss + vmswap) * 1024;
    }
    return (size_t)0;
#else
    return (size_t)0;
#endif
}
')
@:headerClassCode('
    static size_t native_getMemory();
')
#end
class MemoryCounter extends Sprite
{
	public var memoryText:TextField;
	public var memoryPeakText:TextField;

	public var memory:Float = 0;
	public var memoryPeak:Float = 0;

	public function new()
	{
		super();

		memoryText = new TextField();
		memoryPeakText = new TextField();

		for (label in [memoryText, memoryPeakText])
		{
			label.autoSize = LEFT;
			label.x = 0;
			label.y = 0;
			label.text = "MEM";
			label.multiline = label.wordWrap = false;
			label.defaultTextFormat = new TextFormat(Framerate.fontName, 12, -1);
			label.selectable = false;
			addChild(label);
		}
		memoryPeakText.alpha = 0.5;
	}

	public function reload() {}

	public override function __enterFrame(t:Float)
	{
		if (alpha <= 0.05)
			return;
		super.__enterFrame(t);

		final mem:Float = getCurrentMemory();

		if (mem == memory)
		{
			updateLabelPosition();
			return;
		}

		memory = mem;
		if (memoryPeak < memory)
			memoryPeak = memory;

		refreshText(memory, memoryPeak);

		updateLabelPosition();
	}

	private inline function getCurrentMemory():Float
	{
		#if cpp
		return cast __getMemory();
		#elseif html5
		return openfl.system.System.totalMemory;
		#else
		return 0.0;
		#end
	}

	#if cpp
	@:noCompletion
	@:native('debug::codename::MemoryCounter_obj::native_getMemory')
	private static function __getMemory():cpp.SizeT
		return 0;
	#end

	private inline function updateLabelPosition():Void
		memoryPeakText.x = memoryText.x + memoryText.width;

	private inline function refreshText(mem:Float, peak:Float):Void
	{
		memoryText.text = (Framerate.debugMode == 2 ? "MEM: " : "") + CoolUtil.getSizeString(mem);
		memoryPeakText.text = ' / ${CoolUtil.getSizeString(peak)}';
	}
}
