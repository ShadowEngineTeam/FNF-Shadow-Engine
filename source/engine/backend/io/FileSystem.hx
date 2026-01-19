package backend.io;

#if USE_OPENFL_FILESYSTEM
import lime.utils.Assets as LimeAssets;
import openfl.Assets as OpenFLAssets;
#end
#if mobile
import mobile.backend.io.Assets as MobileAssets;
#end
#if (sys && MODS_ALLOWED)
import sys.FileSystem as SysFileSystem;
import sys.FileStat;
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
		#if MODS_ALLOWED
		#if linux
		var actualPath:String = cwd(path);
		actualPath = getCaseInsensitivePath(path);
		if (actualPath == null)
			actualPath = path;
		if (SysFileSystem.exists(actualPath))
			return true;
		#else
		if (SysFileSystem.exists(cwd(path)))
			return true;
		#end
		#end

		#if USE_OPENFL_FILESYSTEM
		if (OpenFLAssets.exists(openflcwd(path)) || OpenFLAssets.list().filter(asset -> asset.startsWith(path) && asset != path).length > 0)
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
		#if MODS_ALLOWED
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
	}

	public static function stat(path:String):Null<FileStat>
	{
		#if MODS_ALLOWED
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
		#end
		#if mobile
		if (MobileAssets.exists(path))
			return MobileAssets.stat(path);
		#end
		return null;
	}

	public static function fullPath(path:String):String
	{
		#if MODS_ALLOWED
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
		#if MODS_ALLOWED
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
		#if MODS_ALLOWED
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
		#if MODS_ALLOWED
		if (!SysFileSystem.exists(cwd(path)))
			SysFileSystem.createDirectory(cwd(path));
		#end
	}

	public static function deleteFile(path:String):Void
	{
		#if MODS_ALLOWED
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
	}

	public static function deleteDirectory(path:String):Void
	{
		#if MODS_ALLOWED
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
	}

	public static function readDirectory(path:String):Array<String>
	{
		var result:Array<String> = null;

		#if MODS_ALLOWED
		#if linux
		var actualPath:String = cwd(path);
		actualPath = getCaseInsensitivePath(path) ?? path;
		if (SysFileSystem.exists(actualPath) && SysFileSystem.isDirectory(actualPath))
			result = SysFileSystem.readDirectory(actualPath);
		#else
		if (SysFileSystem.exists(cwd(path)) && SysFileSystem.isDirectory(cwd(path)))
			result = SysFileSystem.readDirectory(cwd(path));
		#end
		#end

		#if USE_OPENFL_FILESYSTEM
		if (result == null)
		{
			var filteredList:Array<String> = OpenFLAssets.list().filter(f -> f.startsWith(path));
			var results:Array<String> = [];

			for (i in filteredList.copy())
			{
				var slashsCount = path.split('/').length;
				if (path.endsWith('/'))
					slashsCount--;

				if (i.split('/').length - 1 != slashsCount)
					filteredList.remove(i);
			}

			for (item in filteredList)
			{
				@:privateAccess
				for (library in LimeAssets.libraries.keys())
				{
					var libPath = '$library:$item';
					if (library != 'default' && OpenFLAssets.exists(libPath) && !results.contains(libPath))
						results.push(libPath);
					else if (OpenFLAssets.exists(item) && !results.contains(item))
						results.push(item);
				}
			}

			result = results.map(f -> f.substr(f.lastIndexOf("/") + 1));
		}
		#end

		#if mobile
		if (MobileAssets.exists(path) && MobileAssets.isDirectory(path))
			result = MobileAssets.readDirectory(path);
		#end

		return result ?? [];
	}

	#if (linux && MODS_ALLOWED)
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

			if (!SysFileSystem.exists(current) || !SysFileSystem.isDirectory(current))
				return null;

			var files:Array<String> = SysFileSystem.readDirectory(current);

			var found:Bool = false;
			for (f in files)
			{
				if (f.toLowerCase() == part.toLowerCase())
				{
					if (current == "/")
						current += f;
					else
						current += "/" + f;
					found = true;
					break;
				}
			}

			if (!found)
				return null;
		}

		return current;
	}
	#end
}
