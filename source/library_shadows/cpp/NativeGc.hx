// https://github.com/NovaFlare-Engine-Concentration/FNF-NovaFlare-Engine/blob/3319e87bd57ca8f0cf90bae8583dc42239811fca/source/backend/gc/GCManager.hx
package cpp;

extern class NativeGc
{
	/**
		Get GC memory information.
		@param inWhatInfo Information category identifier (defined by hxcpp)
		@return Returns the corresponding numerical information (such as bytes, ratio, etc.)
	 */
	@:native("__hxcpp_gc_mem_info")
	static function memInfo(inWhatInfo:Int):Float;

	/**
		Allocate an object for the specified class on the GC heap (extended allocation).
		@param cls Target class
		@param size Additional allocated byte size
		@return Newly created object instance
	 */
	@:native("_hx_allocate_extended")
	@:templatedCall
	static function allocateExtended<T>(cls:Class<T>, size:Int):T;

	/**
		Register a finalizer for the object.
		@param instance Object that provides the finalize() method
		@param inPin Whether to pin the object to avoid movement (affects collection timing)
	 */
	@:native("_hx_add_finalizable")
	static function addFinalizable(instance:{function finalize():Void;}, inPin:Bool):Void;

	/**
		Directly allocate a raw byte block on the GC heap.
		@param inBytes Number of bytes to allocate
		@param isContainer Whether as a container (containing pointers)
		@return Raw pointer (RawPointer)
	 */
	@:native("::hx::InternalNew")
	static function allocGcBytesRaw(inBytes:Int, isContainer:Bool):RawPointer<cpp.Void>;

	/**
		Allocate bytes on the GC heap and return a safe pointer.
		@param inBytes Number of bytes to allocate
		@return Pointer to the allocated memory
	 */
	inline static function allocGcBytes(inBytes:Int):Pointer<cpp.Void>
		return Pointer.fromRaw(allocGcBytesRaw(inBytes, false));

	/**
		Enable/disable GC.
		@param inEnable true to enable, false to disable
	 */
	@:native("__hxcpp_enable")
	extern static function enable(inEnable:Bool):Void;

	/**
		Trigger a garbage collection.
		@param major Whether to perform a major collection
	 */
	@:native("__hxcpp_collect")
	extern static function run(major:Bool):Void;

	/**
		Compact the heap to reduce fragmentation.
	 */
	@:native("__hxcpp_gc_compact")
	extern static function compact():Void;

	/**
		Trace and optionally print GC object information for the specified type.
		@param sought Target type
		@param printInstances Whether to print instance information
		@return Number of matching objects
	 */
	@:native("__hxcpp_gc_trace")
	extern static function nativeTrace(sought:Class<Dynamic>, printInstances:Bool):Int;

	/**
		Mark the object as not recyclable (temporary keep-alive).
		@param inObject Object to keep alive
	 */
	@:native("__hxcpp_gc_do_not_kill")
	extern static function doNotKill(inObject:Dynamic):Void;

	/**
		Get the next "zombie" object that has been marked for collection.
		@return Zombie object (may be null)
	 */
	@:native("__hxcpp_get_next_zombie")
	extern static function getNextZombie():Dynamic;

	/**
		Insert a GC safe point for thread-coordinated collection.
	 */
	@:native("__hxcpp_gc_safe_point")
	extern static function safePoint():Void;

	/**
		Enter the GC free zone (disables certain checks, use with caution).
	 */
	@:native("__hxcpp_enter_gc_free_zone")
	extern static function enterGCFreeZone():Void;

	/**
		Exit the GC free zone, restoring normal checks.
	 */
	@:native("__hxcpp_exit_gc_free_zone")
	extern static function exitGCFreeZone():Void;

	/**
		Set the minimum free space threshold.
		@param inBytes Number of bytes
	 */
	@:native("__hxcpp_set_minimum_free_space")
	extern static function setMinimumFreeSpace(inBytes:Int):Void;

	/**
		Set the target free space percentage.
		@param inPercentage Percentage (0-100)
	 */
	@:native("__hxcpp_set_target_free_space_percentage")
	extern static function setTargetFreeSpacePercentage(inPercentage:Int):Void;

	/**
		Set the minimum working memory size.
		@param inBytes Number of bytes
	 */
	@:native("__hxcpp_set_minimum_working_memory")
	extern static function setMinimumWorkingMemory(inBytes:Int):Void;

	/**
		Trigger a Minor GC (incremental collection).
	 */
	@:native("__hxcpp_gc_minor")
	extern public static function gc_minor():Void;

	/**
		Update GC state/parameters (for internal synchronization).
	 */
	@:native("__hxcpp_gc_update")
	extern public static function gc_update():Void;

	/**
		Get the Minor base delta bytes.
		@return Number of bytes
	 */
	@:native("__hxcpp_get_minor_base_delta_bytes")
	extern static function getMinorBaseDeltaBytes():Int;

	/**
		Set the Minor base delta bytes.
		@param inBytes Number of bytes
	 */
	@:native("__hxcpp_set_minor_base_delta_bytes")
	extern static function setMinorBaseDeltaBytes(inBytes:Int):Void;

	/**
		Set the minimum frequent trigger time for Minor (milliseconds).
		@param inMs Number of milliseconds
	 */
	@:native("__hxcpp_set_minor_gate_ms")
	extern static function setMinorGateMs(inMs:Int):Void;

	/**
		Set the starting trigger bytes for Minor.
		@param inBytes Number of bytes
	 */
	@:native("__hxcpp_set_minor_start_bytes")
	extern static function setMinorStartBytes(inBytes:Int):Void;

	/**
		Enable/disable large object handling mechanism.
		@param inEnable 0 to disable, 1 to enable
	 */
	@:native("__hxcpp_gc_large_refresh_enable")
	extern static function gcLargeRefreshEnable(inEnable:Int):Void;

	/**
		Get the minimum frequent trigger time for Minor (milliseconds).
		@return Number of milliseconds
	 */
	@:native("__hxcpp_get_minor_gate_ms")
	extern static function getMinorGateMs():Int;

	/**
		Get the starting trigger bytes for Minor.
		@return Number of bytes
	 */
	@:native("__hxcpp_get_minor_start_bytes")
	extern static function getMinorStartBytes():Int;

	/**
		Query whether the large object handling mechanism is enabled.
		@return 0 not enabled, 1 enabled
	 */
	@:native("__hxcpp_gc_get_large_refresh_enabled")
	extern static function gcGetLargeRefreshEnabled():Int;

	/**
		Configure GC parallel and refinement thread counts.
		@param parallelThreads Number of parallel marking/processing threads
		@param refineThreads Number of refinement processing threads
	 */
	@:native("__hxcpp_gc_set_threads")
	extern static function gcSetThreads(parallelThreads:Int, refineThreads:Int):Void;

	/**
		Set the theoretical maximum pause time for GC (milliseconds).
		@param inMs Number of milliseconds
	 */
	@:native("__hxcpp_gc_set_max_pause_ms")
	extern static function gcSetMaxPauseMs(inMs:Int):Void;

	/**
		Enable/disable aggressive safepoint strategy.
		@param inEnable 0 to disable, 1 to enable
	 */
	@:native("__hxcpp_gc_aggressive_safepoint")
	extern static function gcAggressiveSafepoint(inEnable:Int):Void;

	/**
		Enable/disable parallel reference processing.
		@param inEnable 0 to disable, 1 to enable
	 */
	@:native("__hxcpp_gc_enable_parallel_ref_proc")
	extern static function gcEnableParallelRefProc(inEnable:Int):Void;

	/**
		Get the number of parallel GC threads.
		@return Number of threads
	 */
	@:native("__hxcpp_gc_get_parallel_threads")
	extern static function gcGetParallelThreads():Int;

	/**
		Get the number of refinement processing threads.
		@return Number of threads
	 */
	@:native("__hxcpp_gc_get_refine_threads")
	extern static function gcGetRefineThreads():Int;

	/**
		Get the maximum pause time for GC (milliseconds).
		@return Number of milliseconds
	 */
	@:native("__hxcpp_gc_get_max_pause_ms")
	extern static function gcGetMaxPauseMs():Int;

	/**
		Query whether aggressive safepoint is enabled.
		@return 0 not enabled, 1 enabled
	 */
	@:native("__hxcpp_gc_get_aggressive_safepoint")
	extern static function gcGetAggressiveSafepoint():Int;

	/**
		Query whether parallel reference processing is enabled.
		@return 0 not enabled, 1 enabled
	 */
	@:native("__hxcpp_gc_get_parallel_ref_proc_enabled")
	extern static function gcGetParallelRefProcEnabled():Int;

	/**
		Get the current estimated garbage bytes.
		@return Number of bytes
	 */
	@:native("__hxcpp_gc_garbage_estimate")
	extern static function gcGarbageEstimate():Int;
}
