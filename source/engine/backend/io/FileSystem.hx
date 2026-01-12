package backend.io;

import openfl.Assets;
#if sys
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
		if (path.startsWith(Sys.getCwd()) || path.startsWith(lime.system.System.applicationStorageDirectory) /*|| path.startsWith(Paths.mods())*/)
			return path;
		else
			return Sys.getCwd() + path;
	}

	static function openflcwd(path:String):String
	{
		@:privateAccess
		for (library in lime.utils.Assets.libraries.keys())
			if (Assets.exists('$library:$path') && !path.startsWith('$library:'))
				return '$library:$path';

		return path;
	}

	public static function exists(path:String):Bool
	{
		#if MODS_ALLOWED
		var actualPath:String = path;
		#if linux
		actualPath = getCaseInsensitivePath(cwd(path));
		if (actualPath == null)
			actualPath = cwd(path);
		#end
		if (SysFileSystem.exists(actualPath))
			return true;
		#end
		if (Assets.exists(openflcwd(path)))
			return true;

		return Assets.list().filter(asset -> asset.startsWith(path) && asset != path).length > 0;
	}

	public static function rename(path:String, newPath:String):Void
	{
		#if MODS_ALLOWED
		var actualPath:String = path;
		#if linux
		actualPath = getCaseInsensitivePath(cwd(path));
		if (actualPath == null)
			actualPath = cwd(path);
		#end
		if (SysFileSystem.exists(actualPath))
			SysFileSystem.rename(actualPath, newPath);
		#end
	}

	public static function stat(path:String):Null<FileStat>
	{
		#if MODS_ALLOWED
		var actualPath = path;
		#if linux
		actualPath = getCaseInsensitivePath(cwd(path));
		if (actualPath == null)
			actualPath = cwd(path);
		#end
		return SysFileSystem.stat(actualPath);
		#else
		return null;
		#end
	}

	public static function fullPath(path:String):String
	{
		#if MODS_ALLOWED
		var actualPath = path;
		#if linux
		actualPath = getCaseInsensitivePath(path);
		if (actualPath == null)
			actualPath = path;
		#end
		return SysFileSystem.fullPath(actualPath);
		#else
		return path;
		#end
	}

	public static function absolutePath(path:String):String
	{
		#if MODS_ALLOWED
		var actualPath = path;
		#if linux
		actualPath = getCaseInsensitivePath(path);
		if (actualPath == null)
			actualPath = path;
		#end
		return SysFileSystem.absolutePath(actualPath);
		#else
		return path;
		#end
	}

	public static function isDirectory(path:String):Bool
	{
		#if MODS_ALLOWED
		var actualPath = path;
		#if linux
		actualPath = getCaseInsensitivePath(cwd(path));
		if (actualPath == null)
			actualPath = cwd(path);
		#end
		if (SysFileSystem.exists(actualPath) && SysFileSystem.isDirectory(actualPath))
			return true;
		#end

		return Assets.list().filter(asset -> asset.startsWith(path) && asset != path).length > 0;
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
		var actualPath = path;
		#if linux
		actualPath = getCaseInsensitivePath(cwd(path));
		if (actualPath == null)
			actualPath = cwd(path);
		#end
		if (SysFileSystem.exists(actualPath) && !SysFileSystem.isDirectory(actualPath))
			SysFileSystem.deleteFile(actualPath);
		#end
	}

	public static function deleteDirectory(path:String):Void
	{
		#if MODS_ALLOWED
		var actualPath = path;
		#if linux
		actualPath = getCaseInsensitivePath(cwd(path));
		if (actualPath == null)
			actualPath = cwd(path);
		#end
		if (SysFileSystem.exists(actualPath) && SysFileSystem.isDirectory(actualPath))
			SysFileSystem.deleteDirectory(actualPath);
		#end
	}

	public static function readDirectory(path:String):Array<String>
	{
		#if MODS_ALLOWED
		var actualPath = path;
		#if linux
		actualPath = getCaseInsensitivePath(path);
		if (actualPath == null)
			actualPath = path;
		#end
		if (SysFileSystem.exists(actualPath) && SysFileSystem.isDirectory(actualPath))
			return SysFileSystem.readDirectory(actualPath);
		#end

		var filteredList:Array<String> = Assets.list().filter(f -> f.startsWith(path));
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
			for (library in lime.utils.Assets.libraries.keys())
			{
				var libPath:String = '$library:$item';
				if (library != 'default' && Assets.exists(libPath) && !results.contains(libPath))
					results.push(libPath);
				else if (Assets.exists(item) && !results.contains(item))
					results.push(item);
			}
		}
		return results.map(f -> f.substr(f.lastIndexOf("/") + 1));
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
