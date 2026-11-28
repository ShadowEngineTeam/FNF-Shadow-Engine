package backend.io;

#if USE_OPENFL_FILESYSTEM
import lime.utils.Assets as LimeAssets;
import openfl.Assets as OpenFLAssets;
#end
#if mobile
import mobile.backend.io.Assets as MobileAssets;
#end
#if (sys && FEATURE_MODS)
import sys.FileSystem as SysFileSystem;
import sys.FileStat;
#end
#if (linux && FEATURE_MODS)
import sys.thread.Mutex;
#end

using StringTools;

/**
 * Unified file system class that works with both native file access and OpenFL assets.
 * @see https://github.com/Psych-Slice/P-Slice/blob/master/source/mikolka/funkin/custom/NativeFileSystem.hx
 */
class FileSystem
{
	inline static function cwd(path:String):String
	{
		/*if (path.startsWith(Sys.getCwd()) || path.startsWith(lime.system.System.applicationStorageDirectory))
			return path;
		else
			return Sys.getCwd() + path;*/
		return path;
	}

	#if USE_OPENFL_FILESYSTEM
	static function openflcwd(path:String):String
	{
		@:privateAccess
		for (library in LimeAssets.libraries.keys())
			if (OpenFLAssets.exists('$library:$path') && !path.startsWith('$library:'))
				return '$library:$path';

		return path;
	}
	#end

	public static function exists(path:String):Bool
	{
		#if FEATURE_MODS
		#if linux
		if (getCaseInsensitivePath(cwd(path)) != null)
			return true;
		#else
		if (SysFileSystem.exists(cwd(path)))
			return true;
		#end
		#end

		#if USE_OPENFL_FILESYSTEM
		if (OpenFLAssets.exists(openflcwd(path)) || OpenFLAssets.list().filter(asset -> asset.startsWith(path + "/") && asset != path).length > 0)
			return true;
		#end

		#if mobile
		if (MobileAssets.exists(path))
			return true;
		#end

		return false;
	}

	public static function rename(path:String, newPath:String):Void
	{
		#if FEATURE_MODS
		#if linux
		var actualPath:String = cwd(path);
		actualPath = getCaseInsensitivePath(path);
		if (actualPath == null)
			actualPath = path;
		if (SysFileSystem.exists(actualPath))
			SysFileSystem.rename(actualPath, cwd(newPath));
		#else
		if (SysFileSystem.exists(cwd(path)))
			SysFileSystem.rename(cwd(path), cwd(newPath));
		#end
		#end

		clearCache();
	}

	public static function stat(path:String):Null<#if sys FileStat #else Dynamic #end>
	{
		#if FEATURE_MODS
		#if linux
		var actualPath:String = cwd(path);
		actualPath = getCaseInsensitivePath(path);
		if (actualPath == null)
			actualPath = path;
		if (SysFileSystem.exists(actualPath))
			return SysFileSystem.stat(actualPath);
		#else
		if (SysFileSystem.exists(cwd(path)))
			return SysFileSystem.stat(cwd(path));
		#end
		return null;
		#else
		#if mobile
		if (MobileAssets.exists(path))
			return MobileAssets.stat(path);
		#end
		return null;
		#end
	}

	public static function fullPath(path:String):String
	{
		#if FEATURE_MODS
		#if linux
		var actualPath:String = cwd(path);
		actualPath = getCaseInsensitivePath(path);
		if (actualPath == null)
			actualPath = path;
		return SysFileSystem.fullPath(actualPath);
		#else
		return SysFileSystem.fullPath(cwd(path));
		#end
		#else
		return path;
		#end
	}

	public static function absolutePath(path:String):String
	{
		#if FEATURE_MODS
		#if linux
		var actualPath:String = cwd(path);
		actualPath = getCaseInsensitivePath(path);
		if (actualPath == null)
			actualPath = path;
		return SysFileSystem.absolutePath(actualPath);
		#else
		return SysFileSystem.absolutePath(cwd(path));
		#end
		#else
		return path;
		#end
	}

	public static function isDirectory(path:String):Bool
	{
		#if FEATURE_MODS
		#if linux
		var actualPath:String = cwd(path);
		actualPath = getCaseInsensitivePath(path);
		if (actualPath == null)
			actualPath = path;
		if (SysFileSystem.isDirectory(actualPath))
			return true;
		#else
		if (SysFileSystem.isDirectory(cwd(path)))
			return true;
		#end
		#end

		#if USE_OPENFL_FILESYSTEM
		if (OpenFLAssets.list().filter(asset -> asset.startsWith(path) && asset != path).length > 0)
			return true;
		#end

		#if mobile
		if (MobileAssets.isDirectory(path))
			return true;
		#end

		return false;
	}

	public static function createDirectory(path:String):Void
	{
		#if FEATURE_MODS
		if (!SysFileSystem.exists(cwd(path)))
			SysFileSystem.createDirectory(cwd(path));
		#end

		clearCache();
	}

	public static function deleteFile(path:String):Void
	{
		#if FEATURE_MODS
		#if linux
		var actualPath:String = cwd(path);
		actualPath = getCaseInsensitivePath(path);
		if (actualPath == null)
			actualPath = path;
		if (SysFileSystem.exists(actualPath))
			SysFileSystem.deleteFile(actualPath);
		#else
		if (SysFileSystem.exists(cwd(path)))
			SysFileSystem.deleteFile(cwd(path));
		#end
		#end

		clearCache();
	}

	public static function deleteDirectory(path:String):Void
	{
		#if FEATURE_MODS
		#if linux
		var actualPath:String = cwd(path);
		actualPath = getCaseInsensitivePath(path);
		if (actualPath == null)
			actualPath = path;
		if (SysFileSystem.exists(actualPath))
			SysFileSystem.deleteDirectory(actualPath);
		#else
		if (SysFileSystem.exists(cwd(path)))
			SysFileSystem.deleteDirectory(cwd(path));
		#end
		#end

		clearCache();
	}

	public static function readDirectory(path:String):Array<String>
	{
		#if FEATURE_MODS
		#if linux
		var actualPath:String = cwd(path);
		actualPath = getCaseInsensitivePath(path);
		if (actualPath == null)
			actualPath = path;
		if (SysFileSystem.exists(actualPath) && SysFileSystem.isDirectory(actualPath))
			return SysFileSystem.readDirectory(actualPath);
		#else
		if (SysFileSystem.exists(cwd(path)) && SysFileSystem.isDirectory(cwd(path)))
			return SysFileSystem.readDirectory(cwd(path));
		#end
		#end

		#if USE_OPENFL_FILESYSTEM
		if (OpenFLAssets.list().filter(asset -> asset.startsWith(path + "/") && asset != path).length > 0)
			return openflReadDirectory(path);
		#end

		#if mobile
		if (MobileAssets.exists(path) && MobileAssets.isDirectory(path))
			return MobileAssets.readDirectory(path);
		#end

		return null;
	}

	#if USE_OPENFL_FILESYSTEM
	static function openflReadDirectory(path:String):Array<String>
	{
		var filteredList:Array<String> = OpenFLAssets.list().filter(f -> f.startsWith(path + "/"));
		var results:Array<String> = [];
		for (i in filteredList.copy())
		{
			var slashsCount:Int = path.split('/').length;
			if (path.endsWith('/'))
				slashsCount -= 1;

			if (i.split('/').length - 1 != slashsCount)
				filteredList.remove(i);
		}
		for (item in filteredList)
		{
			@:privateAccess
			for (library in LimeAssets.libraries.keys())
			{
				var libPath:String = '$library:$item';
				if (library != 'default' && OpenFLAssets.exists(libPath) && !results.contains(libPath))
					results.push(libPath);
				else if (OpenFLAssets.exists(item) && !results.contains(item))
					results.push(item);
			}
		}
		return results.map(f -> f.substr(f.lastIndexOf("/") + 1));
	}
	#end

	#if (linux && FEATURE_MODS)
	// Directory listings for getCaseInsensitivePath(): directory -> (lowercase name -> real name), or
	// null for a path that is not a readable directory. The walk below only runs once the exact path
	// failed a stat, i.e. for wrongly-cased paths and for files that do not exist - and Paths probes
	// many of those (every mod folder and GPU format before the fallback). Re-reading each parent
	// directory for every one of them made plain lookups cost several opendir/getdents/close rounds.
	// Cleared on any write through backend.io and on Paths.clearStoredMemory().
	static final dirEntries:Map<String, Null<Map<String, String>>> = [];
	static final dirEntriesMutex:Mutex = new Mutex();

	static function getDirEntries(dir:String):Null<Map<String, String>>
	{
		dirEntriesMutex.acquire();
		var entries:Null<Map<String, String>> = dirEntries.get(dir);
		if (entries == null && !dirEntries.exists(dir))
		{
			var names:Null<Array<String>> = null;
			try
			{
				if (SysFileSystem.exists(dir) && SysFileSystem.isDirectory(dir))
					names = SysFileSystem.readDirectory(dir);
			}
			catch (e:Dynamic)
			{
			}

			if (names != null)
			{
				entries = [];
				for (name in names)
				{
					final lower:String = name.toLowerCase();
					// First match wins, like the linear scan this replaces.
					if (!entries.exists(lower))
						entries.set(lower, name);
				}
			}
			dirEntries.set(dir, entries);
		}
		dirEntriesMutex.release();
		return entries;
	}
	#end

	/**
	 * Drops the cached directory listings used to resolve wrongly-cased paths on Linux.
	 */
	public static function clearCache():Void
	{
		#if (linux && FEATURE_MODS)
		dirEntriesMutex.acquire();
		dirEntries.clear();
		dirEntriesMutex.release();
		#end
	}

	#if (linux && FEATURE_MODS)
	/**
	 * Returns `path` with each component matched case-insensitively against what is on disk, or
	 * null when no such file or directory exists. A non-null result has been checked to exist.
	 */
	@:allow(backend.io.File)
	static function getCaseInsensitivePath(path:String):String
	{
		if (SysFileSystem.exists(path))
			return path;

		var parts:Array<String> = path.split("/");
		var current:String = Sys.getCwd();

		if (path.charAt(0) == "/")
			current = "/";

		for (part in parts)
		{
			if (part == "")
				continue;

			final entries:Null<Map<String, String>> = getDirEntries(current);
			if (entries == null)
				return null;

			final found:Null<String> = entries.get(part.toLowerCase());
			if (found == null)
				return null;

			if (current == "/")
				current += found;
			else
				current += "/" + found;
		}

		// The listings may predate a change made outside backend.io.
		if (!SysFileSystem.exists(current))
		{
			clearCache();
			return null;
		}

		return current;
	}
	#end
}
