package debug.codename;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

#if cpp
@:cppFileCode('
#if defined(_WIN32)
  #include <windows.h>
  #include <psapi.h>
  #include <winternl.h>
  #pragma comment(lib, "ntdll.lib")
#elif defined(__APPLE__) && defined(__MACH__)
  #include <mach/mach.h>
#elif defined(__linux__) || defined(__gnu_linux__) || defined(__ANDROID__)
  #include <stdio.h>
#endif
')
@:cppNamespaceCode('
// https://github.com/winsiderss/systeminformer/blob/v3.2.25011.2103/SystemInformer/procprv.c
#if defined(_WIN32)
typedef struct _VM_COUNTERS_EX {
    SIZE_T PeakVirtualSize;
    SIZE_T VirtualSize;
    ULONG  PageFaultCount;
    SIZE_T PeakWorkingSetSize;
    SIZE_T WorkingSetSize;
    SIZE_T QuotaPeakPagedPoolUsage;
    SIZE_T QuotaPagedPoolUsage;
    SIZE_T QuotaPeakNonPagedPoolUsage;
    SIZE_T QuotaNonPagedPoolUsage;
    SIZE_T PagefileUsage;
    SIZE_T PeakPagefileUsage;
    SIZE_T PrivateUsage;
} VM_COUNTERS_EX_LOCAL;
static bool isRunningUnderWine()
{
    HMODULE ntdll = GetModuleHandleA("ntdll.dll");
    if (!ntdll) return false;
    return GetProcAddress(ntdll, "wine_get_version") != nullptr;
}
#endif
double MemoryCounter_obj::native_getMemory()
{
#if defined(_WIN32)
	// https://github.com/winsiderss/systeminformer/blob/v3.2.25011.2103/SystemInformer/procprv.c
    VM_COUNTERS_EX_LOCAL counters = {0};
    NTSTATUS status = NtQueryInformationProcess(
        GetCurrentProcess(),
        (PROCESSINFOCLASS)3, // ProcessVmCounters
        &counters,
        sizeof(counters),
        NULL
    );
    if (NT_SUCCESS(status))
        return isRunningUnderWine() ? (double)counters.PagefileUsage : (double)counters.PrivateUsage;
    return 0.0;
#elif defined(__APPLE__) && defined(__MACH__)
    struct task_vm_info vmInfo = {0};
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t kr = task_info(mach_task_self(), TASK_VM_INFO,
                                 (task_info_t)&vmInfo, &count);
    if (kr != KERN_SUCCESS)
        return 0.0;
    const mach_msg_type_number_t kMinCount =
        (mach_msg_type_number_t)(
            (offsetof(task_vm_info_data_t, compressed) + sizeof(vmInfo.compressed))
            / sizeof(natural_t));
    if (count >= kMinCount)
        return (double)(vmInfo.resident_size + vmInfo.compressed);
    return (double)vmInfo.resident_size;
#elif defined(__linux__) || defined(__gnu_linux__) || defined(__ANDROID__)
    FILE *fp = fopen("/proc/self/status", "r");
    if (!fp)
		return 0.0;
    char line[256];
    unsigned long vmpriv = 0, vmrss = 0, vmswap = 0;
    while (fgets(line, sizeof(line), fp)) {
        sscanf(line, "VmPrivate: %lu kB", &vmpriv);
        sscanf(line, "VmRSS: %lu kB",     &vmrss);
        sscanf(line, "VmSwap: %lu kB",    &vmswap);
    }
    fclose(fp);
    if (vmpriv > 0)
        return (double)vmpriv * 1024.0;
    return (double)(vmrss + vmswap) * 1024.0;
#else
    return 0.0;
#endif
}
')
@:headerClassCode('
    static double native_getMemory();
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
	private static function __getMemory():Float
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
