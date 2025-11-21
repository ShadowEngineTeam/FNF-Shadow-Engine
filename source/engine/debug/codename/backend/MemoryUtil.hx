package debug.codename.backend;

#if sys
import sys.io.Process;
#end
import openfl.system.System;

using StringTools;

/**
 * Tools that are related to memory.
 * Including garbage collection, and memory usage, and hardware info.
 *
 * DISCLAIMER: Hardware info is only available on Native platforms.
**/
#if cpp
@:cppFileCode('
#include <iostream>
#include <cstdio>
#if defined(_WIN32)
#include <windows.h>
#include <psapi.h>
#elif defined(__APPLE__) && defined(__MACH__)
#include <mach/mach.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#elif defined(__linux__) || defined(__gnu_linux__) || defined(__ANDROID__)
#include <sys/sysinfo.h>
#endif
')
#end
final class MemoryUtil
{
	/**
	 * Gets the total memory of the system.
	 * Output depends on the hardware.
	 */
	#if cpp
	#if (linux || android)
	@:functionCode('
		FILE *meminfo = fopen("/proc/meminfo", "r");

		if(meminfo == NULL)
			return -1;

		char line[256];
		while(fgets(line, sizeof(line), meminfo))
		{
			int ram;
			if(sscanf(line, "MemTotal: %d kB", &ram) == 1)
			{
				fclose(meminfo);
				return (ram / 1024);
			}
		}

		fclose(meminfo);
		return -1;
	')
	#elseif (mac || ios)
	@:functionCode('
		int mib [] = { CTL_HW, HW_MEMSIZE };
		int64_t value = 0;
		size_t length = sizeof(value);

		if(-1 == sysctl(mib, 2, &value, &length, NULL, 0))
			return -1;

		return value / 1024 / 1024;
	')
	#elseif windows
	@:functionCode("
		unsigned long long allocatedRAM = 0;
		GetPhysicallyInstalledSystemMemory(&allocatedRAM);
		return (allocatedRAM / 1024);
	")
	#end
	#end
	public static function getTotalMem():Float
	{
		return 0;
	}

	/**
	 * Gets the total swap/virtual memory of the system.
	 * Output depends on the hardware.
	**/
	#if cpp
	#if (linux || android)
	@:functionCode('
		FILE *meminfo = fopen("/proc/meminfo", "r");

		if(meminfo == NULL)
			return -1;

		char line[256];
		while(fgets(line, sizeof(line), meminfo))
		{
			int swap;
			if(sscanf(line, "SwapTotal: %d kB", &swap) == 1)
			{
				fclose(meminfo);
				return (swap / 1024);
			}
		}

		fclose(meminfo);
		return -1;
	')
	#elseif (mac || ios)
	@:functionCode('
		struct xsw_usage swapInfo;
		size_t size = sizeof(swapInfo);

		if (sysctlbyname("vm.swapusage", &swapInfo, &size, nullptr, 0) != 0) {
			perror("sysctlbyname");
			return 1;
		}

		return swapInfo.xsu_total / 1024 / 1024;
	')
	#elseif windows
	@:functionCode('
		PERFORMANCE_INFORMATION pi;
		pi.cb = sizeof(pi);
		if(GetPerformanceInfo(&pi, sizeof(pi)))
		{
			SIZE_T totalSwap = (pi.CommitLimit - pi.PhysicalTotal) * pi.PageSize;
			return (double)totalSwap / (1024.0 * 1024.0);
		}
		return 0;
	')
	#end
	#end
	public static function getTotalSwapMem():Float
	{
		return 0;
	}

	/**
	 * Gets the memory type of the system.
	 * Output depends on the platform, and hardware.
	 */
	public static function getMemType():String
	{
		#if windows
		var memoryMap:Map<Int, String> = [
			0 => null,
			1 => "Other",
			2 => "DRAM",
			3 => "Synchronous DRAM",
			4 => "Cache DRAM",
			5 => "EDO",
			6 => "EDRAM",
			7 => "VRAM",
			8 => "SRAM",
			9 => "RAM",
			10 => "ROM",
			11 => "Flash",
			12 => "EEPROM",
			13 => "FEPROM",
			14 => "EPROM",
			15 => "CDRAM",
			16 => "3DRAM",
			17 => "SDRAM",
			18 => "SGRAM",
			19 => "RDRAM",
			20 => "DDR",
			21 => "DDR2",
			22 => "DDR2 FB-DIMM",
			24 => "DDR3",
			25 => "FBD2",
			26 => "DDR4",
			27 => "LPDDR",
			28 => "LPDDR2",
			29 => "LPDDR3",
			30 => "LPDDR4",
			31 => "Logical Non-volatile device",
			32 => "HBM",
			33 => "HBM2",
			34 => "DDR5",
			35 => "LPDDR5",
			36 => "HBM3",
		];
		var memoryOutput:Int = -1;

		var process = new Process("powershell", [
			"-Command",
			"Get-CimInstance Win32_PhysicalMemory | Select-Object -ExpandProperty SMBIOSMemoryType"
		]);
		if (process.exitCode() == 0)
			memoryOutput = Std.int(Std.parseFloat(process.stdout.readAll().toString().trim().split("\n")[1]));
		if (memoryOutput != -1)
			return memoryMap[memoryOutput] == null ? 'Unknown ($memoryOutput)' : memoryMap[memoryOutput];
		#elseif (mac || ios)
		var process = new Process("system_profiler", ["SPMemoryDataType"]);
		var reg = ~/Type: (.+)/;
		reg.match(process.stdout.readAll().toString());
		if (process.exitCode() == 0)
			return reg.matched(1);
		#elseif android
		// MTODO: Do get mem type for android smh?
		#elseif linux
		/*var process = new Process("sudo", ["dmidecode", "--type", "17"]);
		if (process.exitCode() != 0) return "Unknown";
		var lines = process.stdout.readAll().toString().split("\n");
		for (line in lines) {
			if (line.startsWith("Type:")) {
				return line.substring("Type:".length).trim();
			}
		}*/
		// TODO: sort of unsafe? also requires users to use `sudo`
		// when launching the engine through the CLI, REIMPLEMENT LATER.
		#end
		return "Unknown";
	}
}
