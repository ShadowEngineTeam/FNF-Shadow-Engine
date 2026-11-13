package debug.codename;

import backend.codename.MemoryUtil;
import backend.codename.RegisteryUtil;
import lime.utils.Log;
#if android
import android.os.Build;
import android.os.Build.VERSION;
#end
#if sys
import sys.io.Process;
#end
#if cpp
import cpp.Float64;
import cpp.UInt64;
#end

using StringTools;

#if cpp
#if windows
@:buildXml('
<target id="haxe">
	<lib name="dxgi.lib" unless="mingw" />
	<lib name="-ldxgi" if="mingw" />
</target>
')
@:cppFileCode('
#include <windows.h>
#include <dxgi.h>
')
#elseif (mac || ios)
#if mac
@:buildXml('
<target id="haxe">
	<vflag name="-framework" value="Metal" />
</target>
')
#end
@:cppFileCode('
#include <mach-o/arch.h>
#include <objc/runtime.h>
#include <objc/message.h>

extern "C" id MTLCreateSystemDefaultDevice(void);
')
#else
@:buildXml('
<files id="haxe">
	<compilerflag value="-I${haxelib:lime}/project/lib/bgfx/3rdparty/khronos" />
</files>
')
@:cppFileCode('
#include <dlfcn.h>
#include <vector>
#define VK_NO_PROTOTYPES
#include <vulkan-local/vulkan_core.h>
')
@:headerInclude('sys/utsname.h')
#end
#end
class SystemInfo extends FramerateCategory
{
	public static var osInfo:String = "Unknown";
	public static var gpuName:String = "Unknown";
	public static var cpuName:String = "Unknown";
	public static var totalMem:String = "Unknown";
	public static var totalSwapMem:String = "Unknown";
	public static var memType:String = "Unknown";

	static var __formattedSysText:String = "";

	public static function init()
	{
		Log.throwErrors = false;

		#if linux
		var process = new Process("cat", ["/etc/os-release"]);
		if (process.exitCode() != 0)
			Log.error('Unable to grab OS Label');
		else
		{
			var osName = "";
			var osVersion = "";
			for (line in process.stdout.readAll().toString().split("\n"))
			{
				if (line.startsWith("NAME="))
				{
					var index = line.indexOf('"');
					if (index != -1)
						osName = line.substring(index + 1, line.lastIndexOf('"'));
					else
					{
						var arr = line.split("=");
						arr.shift();
						osName = arr.join("=");
					}
				}
				if (line.startsWith("VERSION="))
				{
					var index = line.indexOf('"');
					if (index != -1)
						osVersion = line.substring(index + 1, line.lastIndexOf('"'));
					else
					{
						var arr = line.split("=");
						arr.shift();
						osVersion = arr.join("=");
					}
				}
			}
			if (osName != "")
				osInfo = '${osName} ${osVersion}'.trim();
		}
		#elseif windows
		var windowsCurrentVersionPath = "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion";
		var buildNumber = Std.parseInt(RegistryUtil.get(HKEY_LOCAL_MACHINE, windowsCurrentVersionPath, "CurrentBuildNumber"));
		var edition = RegistryUtil.get(HKEY_LOCAL_MACHINE, windowsCurrentVersionPath, "ProductName");

		var lcuKey = "WinREVersion"; // Last Cumulative Update Key On Older Windows Versions
		if (buildNumber >= 22000) // Windows 11 Initial Release Build Number
		{
			edition = edition.replace("Windows 10", "Windows 11");
			lcuKey = "LCUVer"; // Last Cumulative Update Key On Windows 11
		}

		var lcuVersion = RegistryUtil.get(HKEY_LOCAL_MACHINE, windowsCurrentVersionPath, lcuKey);

		osInfo = edition;

		if (lcuVersion != null && lcuVersion != "")
			osInfo += ' ${lcuVersion}';
		else if (lime.system.System.platformVersion != null && lime.system.System.platformVersion != "")
			osInfo += ' ${lime.system.System.platformVersion}';
		#elseif web
			osInfo = '${lime.system.System.platformLabel}';
		#else
		if (lime.system.System.platformLabel != null
			&& lime.system.System.platformLabel != ""
			&& lime.system.System.platformVersion != null
			&& lime.system.System.platformVersion != "")
			osInfo = '${lime.system.System.platformLabel.replace(lime.system.System.platformVersion, "").trim()} ${lime.system.System.platformVersion}';
		else
			Log.error('Unable to grab OS Label');
		#end

		try
		{
			#if windows
			cpuName = RegistryUtil.get(HKEY_LOCAL_MACHINE, "HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0", "ProcessorNameString");
			#elseif mac
			var process = new Process("sysctl -a | grep brand_string"); // Somehow this isn't able to use the args but it still works
			if (process.exitCode() != 0)
				throw 'Could not fetch CPU information';

			cpuName = process.stdout.readAll().toString().trim().split(":")[1].trim();
			#elseif linux
			var process = new Process("lscpu", []);
			if (process.exitCode() != 0)
				throw 'Could not fetch CPU information';

			for (line in process.stdout.readAll().toString().split("\n"))
			{
				var trimmedLine = line.trim();
				if (trimmedLine.startsWith("Model name:"))
				{
					cpuName = trimmedLine.substr(trimmedLine.indexOf(":") + 1).trim();
					break;
				}
			}
			#elseif android
			cpuName = (VERSION.SDK_INT >= VERSION_CODES.S) ? Build.SOC_MODEL : Build.HARDWARE;
			#elseif ios
			cpuName = "Apple SoC";
			#end
		}
		catch (e)
		{
			Log.error('Unable to grab CPU Name: $e');
		}
		@:privateAccess
		if (FlxG.renderTile) // Blit doesn't enable the gpu. Idk if we should fix this
		{
			var context3D:Null<openfl.display3D.Context3D> = flixel.FlxG.stage.context3D;

			if (context3D != null && context3D.isBGFX)
			{
				var caps:lime.graphics.bgfx.BGFXCaps = context3D.bgfx.getCaps();
				gpuName = '${getDeviceName(caps.vendorId, caps.deviceId)} (${context3D.bgfx.getRendererName(caps.rendererType)})';
			}
			else if (context3D != null && context3D.gl != null)
			{
				gpuName = Std.string(context3D.gl.getParameter(context3D.gl.RENDERER)).split("/")[0].trim();
			}
			else
				Log.error('Unable to grab GPU Info');
		}

		#if cpp
		totalMem = getSizeString(MemoryUtil.getTotalMem());
		#end

		try
		{
			memType = MemoryUtil.getMemType();
		}
		catch (e)
		{
			Log.error('Unable to grab RAM Type: $e');
		}

		Log.throwErrors = true;

		totalSwapMem = getSizeString(MemoryUtil.getTotalSwapMem());
		formatSysInfo();
	}

	// bgfx only reports the PCI ids of the device it runs on, not its name.
	static function getDeviceName(vendorId:Int, deviceId:Int):String
	{
		final vendorName:String = switch (vendorId)
		{
			case 0x1002: "AMD";
			case 0x106b: "Apple";
			case 0x8086: "Intel";
			case 0x10de: "NVIDIA";
			case 0x1414: "Microsoft";
			case 0x13b5: "ARM";
			case 0x5143: "Qualcomm";
			case 0x1010: "Imagination Technologies";
			case 0x14e4: "Broadcom";
			default: "Unknown";
		}

		final name:Null<String> = getNativeDeviceName(vendorId, deviceId);
		if (name != null && name != "")
			return name;

		return '$vendorName GPU';
	}

	// A device id of 0 means bgfx only knows the vendor.
	#if windows
	@:functionCode('
		IDXGIFactory1* factory = NULL;
		if (FAILED(CreateDXGIFactory1(__uuidof(IDXGIFactory1), (void**)&factory)))
			return null();

		::String name = null();
		IDXGIAdapter1* adapter = NULL;
		for (UINT i = 0; factory->EnumAdapters1(i, &adapter) != DXGI_ERROR_NOT_FOUND; i++)
		{
			DXGI_ADAPTER_DESC1 desc;
			bool matches = SUCCEEDED(adapter->GetDesc1(&desc)) && desc.VendorId == (UINT)vendorId && (deviceId == 0 || desc.DeviceId == (UINT)deviceId);
			adapter->Release();

			if (matches)
			{
				name = ::String::create(desc.Description);
				break;
			}
		}

		factory->Release();
		return name;
	')
	#elseif (mac || ios)
	@:functionCode('
		id device = MTLCreateSystemDefaultDevice();
		if (device == NULL)
			return null();

		::String name = null();
		id deviceName = ((id (*)(id, SEL))objc_msgSend)(device, sel_registerName("name"));
		if (deviceName != NULL)
		{
			const char* utf8 = ((const char* (*)(id, SEL))objc_msgSend)(deviceName, sel_registerName("UTF8String"));
			if (utf8 != NULL)
				name = ::String::create(utf8);
		}

		((void (*)(id, SEL))objc_msgSend)(device, sel_registerName("release"));
		return name;
	')
	#elseif cpp
	@:functionCode('
		#ifdef __ANDROID__
		void* vulkan = dlopen("libvulkan.so", RTLD_NOW | RTLD_LOCAL);
		#else
		void* vulkan = dlopen("libvulkan.so.1", RTLD_NOW | RTLD_LOCAL);
		#endif
		if (vulkan == NULL)
			return null();

		PFN_vkCreateInstance createInstance = (PFN_vkCreateInstance)dlsym(vulkan, "vkCreateInstance");
		PFN_vkDestroyInstance destroyInstance = (PFN_vkDestroyInstance)dlsym(vulkan, "vkDestroyInstance");
		PFN_vkEnumeratePhysicalDevices enumeratePhysicalDevices = (PFN_vkEnumeratePhysicalDevices)dlsym(vulkan, "vkEnumeratePhysicalDevices");
		PFN_vkGetPhysicalDeviceProperties getPhysicalDeviceProperties = (PFN_vkGetPhysicalDeviceProperties)dlsym(vulkan, "vkGetPhysicalDeviceProperties");

		::String name = null();
		VkInstanceCreateInfo createInfo = {};
		createInfo.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
		VkInstance instance = VK_NULL_HANDLE;

		if (createInstance != NULL && destroyInstance != NULL && enumeratePhysicalDevices != NULL && getPhysicalDeviceProperties != NULL
			&& createInstance(&createInfo, NULL, &instance) == VK_SUCCESS)
		{
			uint32_t count = 0;
			enumeratePhysicalDevices(instance, &count, NULL);
			std::vector<VkPhysicalDevice> devices(count);
			if (count > 0)
				enumeratePhysicalDevices(instance, &count, devices.data());

			for (uint32_t i = 0; i < count; i++)
			{
				VkPhysicalDeviceProperties properties;
				getPhysicalDeviceProperties(devices[i], &properties);

				// bgfx keeps the low 16 bits of both ids.
				if ((uint16_t)properties.vendorID == (uint16_t)vendorId && (deviceId == 0 || (uint16_t)properties.deviceID == (uint16_t)deviceId))
				{
					name = ::String::create(properties.deviceName);
					break;
				}
			}

			destroyInstance(instance, NULL);
		}

		dlclose(vulkan);
		return name;
	')
	#end
	@:noCompletion
	private static function getNativeDeviceName(vendorId:Int, deviceId:Int):Null<String>
	{
		return null;
	}

	static inline function row(key:String, value:String):String
		return '<font color="#8A7E72">$key </font><font color="#E8E2D6">$value</font>';

	static function formatSysInfo()
	{
		var lines:Array<String> = [];

		#if android
		lines.push(row("Device:", '${Build.BRAND.charAt(0).toUpperCase() + Build.BRAND.substring(1)} ${Build.MODEL} (${Build.BOARD})'));
		#end
		if (osInfo != "Unknown")
			lines.push(row("System:", osInfo));
		if (cpuName != "Unknown")
			lines.push(row("CPU:", '$cpuName ${getCPUArch()}'));

		if (gpuName != "Unknown" && gpuName != cpuName)
			lines.push(row("GPU:", gpuName));
		if (totalMem != "Unknown" && memType != "Unknown")
			lines.push(row("Total MEM:", '$totalMem $memType ${totalSwapMem != "Unknown" ? '+ $totalSwapMem SWAP' : ""}'));

		__formattedSysText = lines.join("\n");
	}

	static function getSizeString(size:Float):String
	{
		if (size < 1024)
			return Std.int(size) + " MB";
		else if (size < 1024 * 1024)
			return Std.int(size / 1024) + " GB";
		else
		{
			var tb = size / (1024 * 1024);
			return Std.int(tb) + "." + CoolUtil.addZeros(Std.string(Std.int((tb % 1) * 100)), 2) + " TB";
		}
	}

	public function new()
	{
		super("System Info");
	}

	public override function __enterFrame(t:Float)
	{
		if (alpha <= 0.05)
			return;

		_text = __formattedSysText;
		#if (cpp || hl)
		//_text += '${__formattedSysText == "" ? "" : "\n"}Garbage Collector: ${MemoryUtil.disableCount ? "OFF" : "ON"} (${MemoryUtil.disableCount})';
		#end

		this.text.htmlText = _text;
		super.__enterFrame(t);
	}

	#if windows
	@:functionCode('
		SYSTEM_INFO osInfo;

		GetSystemInfo(&osInfo);

		switch(osInfo.wProcessorArchitecture)
		{
			case 9:
				return ::String("x86_64");
			case 5:
				return ::String("ARM");
			case 12:
				return ::String("ARM64");
			case 6:
				return ::String("IA-64");
			case 0:
				return ::String("x86");
			default:
				return ::String("Unknown");
		}
	')
	#elseif (mac || ios)
	@:functionCode('
		const NXArchInfo *archInfo = NXGetLocalArchInfo();
    	return ::String(archInfo == NULL ? "Unknown" : archInfo->name);
	')
	#elseif cpp
	@:functionCode('
		struct utsname osInfo{};
		uname(&osInfo);
		return ::String(osInfo.machine);
	')
	#end
	@:noCompletion
	private static function getCPUArch():String
	{
		return "Unknown";
	}
}
