package external.memory;

#if cpp
#if ios
@:buildXml('<include name="../../../../../../../source/engine/external/memory/build.xml" />')
#else
@:buildXml('<include name="../../../../source/engine/external/memory/build.xml" />')
#end
@:include("memory.h")
extern #end class Memory
{
	#if cpp
	@:native("getMemoryUsage")
	#end
	public static function getCurrentUsage():#if cpp cpp.SizeT #else Float #end
	{
		#if html5
		return openfl.system.System.totalMemory / 1024 / 1024;
		#elseif !cpp
		return 0.0;
		#end
	}
}
