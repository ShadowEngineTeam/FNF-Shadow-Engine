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
	public static function getCurrentUsage():cpp.SizeT;
	#else
	public static inline function getCurrentUsage():Float
	{
		#if html5
		return openfl.system.System.totalMemory;
		#else
		return 0.0;
		#end
	}
	#end
}
