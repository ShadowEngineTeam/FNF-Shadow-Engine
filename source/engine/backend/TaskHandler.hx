package backend;

import lime.app.Future;
import lime.app.Future.FutureWork;
import lime.system.ThreadPool;
#if (target.threaded)
import sys.thread.Deque;
#end

/**
 * Runs work on Lime's shared thread pool (the one behind threaded `Future`s), and hands results back to
 * the main thread. Work runs on the calling thread when `FEATURE_MULTITHREADING` is off.
 * Based on FunkinCrew/Funkin's `funkin.util.tasks.TaskHandler`.
 *
 * Work functions run alongside the game, so they must not touch display objects, the GPU, scripts or the
 * engine's caches (`Paths.currentTrackedAssets` and co.). Do that in the function passed to `toMainThread()`.
 */
@:access(lime.app.Future.FutureWork)
#if cpp
@:cppInclude('thread')
#end
class TaskHandler
{
	/**
	 * The most threads the pool runs at once.
	 */
	public static var maxThreads(default, null):Int = 1;

	#if (target.threaded)
	static final mainThreadQueue:Deque<Void->Void> = new Deque();
	#else
	static final mainThreadQueue:Array<Void->Void> = [];
	#end

	public static function initialize():Void
	{
		lime.app.Application.current.onUpdate.add(_ -> processMainThreadQueue());

		#if FEATURE_MULTITHREADING
		final cores:Int = untyped __cpp__('(int)std::thread::hardware_concurrency()');

		// Leave cores for the main thread, the audio thread and the GPU driver.
		#if mobile
		maxThreads = Std.int(Math.max(1, Math.ceil(cores / 4)));
		#else
		maxThreads = Std.int(Math.max(1, cores / 2));
		#end

		// Don't keep idle threads around.
		FutureWork.minThreads = 0;
		FutureWork.maxThreads = maxThreads;

		trace('Thread pool: up to $maxThreads threads ($cores cores)');
		#end
	}

	/**
	 * Queues `work` on the thread pool. Call it from the main thread.
	 */
	public static function run(work:Void->Void):Void
	{
		new Future<Bool>(() ->
		{
			work();
			return true;
		}, #if FEATURE_MULTITHREADING true #else false #end);
	}

	/**
	 * Queues `callback` to run on the main thread, on the next update or `processMainThreadQueue()`.
	 * Safe to call from any thread.
	 */
	public static function toMainThread(callback:Void->Void):Void
	{
		#if (target.threaded)
		mainThreadQueue.add(callback);
		#else
		mainThreadQueue.push(callback);
		#end
	}

	/**
	 * Runs the callbacks queued with `toMainThread()`. This happens every update; call it from the main
	 * thread to get results while blocking it.
	 * @return How many callbacks ran.
	 */
	public static function processMainThreadQueue():Int
	{
		var count:Int = 0;

		#if (target.threaded)
		var callback:Null<Void->Void> = mainThreadQueue.pop(false);
		while (callback != null)
		{
			callback();
			count++;
			callback = mainThreadQueue.pop(false);
		}
		#else
		while (mainThreadQueue.length > 0)
		{
			mainThreadQueue.shift()();
			count++;
		}
		#end

		return count;
	}

	/**
	 * @return Whether this is the main thread. Always true without `FEATURE_MULTITHREADING`.
	 */
	public static inline function isMainThread():Bool
		return ThreadPool.isMainThread();
}
