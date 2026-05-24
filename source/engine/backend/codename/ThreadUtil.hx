package backend.codename;

import lime.utils.Log;
#if (target.threaded)
import sys.thread.Deque;
import sys.thread.Thread;
import sys.thread.Mutex;
#else
private typedef Thread = Dynamic;
#end
import Sys;

final class ThreadUtil
{
	inline static function error(text:String)
	{
		#if macro
		trace(text);
		#else
		FlxG.signals.preUpdate.addOnce(() -> Log.error(text));
		#end
	}

	/**
	 * Creates a new Thread with an error handler.
	 * @param func Function to execute
	 * @param autoRestart Whenever the thread should auto restart itself after crashing.
	 */
	public static function createSafe(func:Void->Void, autoRestart:Bool = false):Thread
	{
		#if (target.threaded)
		try
		{
			return if (autoRestart) Thread.create(() ->
			{
				var restart = true;
				while (restart)
					try
					{
						func();
						restart = false;
					}
					catch (e)
						error(e.details());
			}) else Thread.create(() ->
			{
				try
				{
					func();
				}
				catch (e)
					error(e.details());
			});
		}
		catch (e)
			error("Failed to safely create a thread: " + e.details());
		#end
		return null;
	}

	#if (target.threaded)
	public static var maxThreads:Int = 4;

	static var __threads:Array<Thread> = [];
	static var __pendingExecs:Deque<Void->Void> = new Deque();
	static var __threadMutex:Mutex = new Mutex();
	static var __threadUsed:Int = 0;

	static function __threadExecAsync()
	{
		var callback:Void->Void;
		while ((callback = __pendingExecs.pop(true)) != null)
		{
			__threadMutex.acquire();
			__threadUsed++;
			__threadMutex.release();

			callback();

			__threadMutex.acquire();
			__threadUsed--;
			__threadMutex.release();
		}
		__threadMutex.acquire();
		__threads.remove(Thread.current());
		__threadMutex.release();
	}
	#end

	/**
	 * Checks an array of path-returning functions in parallel and returns the first non-null result.
	 * On non-threaded targets, runs checks sequentially.
	 * Each function should return a path string if the file exists, or null if not.
	 */
	public static function firstExisting(checks:Array<Void->Null<String>>):Null<String>
	{
		if (checks == null || checks.length == 0)
			return null;
		if (checks.length == 1)
			return checks[0]();

		#if (target.threaded)
		var result:Null<String> = null;
		var mutex = new Mutex();
		var remaining = checks.length;

		for (check in checks)
		{
			var c = check;
			Thread.create(() ->
			{
				var r = c();
				if (r != null)
				{
					mutex.acquire();
					if (result == null)
						result = r;
					mutex.release();
				}
				mutex.acquire();
				remaining--;
				mutex.release();
			});
		}

		while (result == null && remaining > 0)
			Sys.sleep(0.001);

		return result;
		#else
		for (check in checks)
		{
			var r = check();
			if (r != null)
				return r;
		}
		return null;
		#end
	}

	public static function execAsync(func:Void->Void)
	{
		if (func == null)
			return;

		#if ((target.threaded) && !macro)
		__pendingExecs.add(func);
		if (__threadUsed >= __threads.length)
		{
			if (__threads.length == maxThreads)
				return;

			__threadMutex.acquire();
			try
			{
				var thread = Thread.create(__threadExecAsync);
				__threads.push(thread);
			}
			catch (e)
				Log.warn(e.details());
			__threadMutex.release();
		}
		#else
		func();
		#end
	}
}
