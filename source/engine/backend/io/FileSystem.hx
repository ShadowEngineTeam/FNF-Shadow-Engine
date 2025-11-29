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
		if (SysFileSystem.exists(cwd(path)))
			return true;
		#end
		if (Assets.exists(openflcwd(path)))
			return true;

		return Assets.list().filter(asset -> asset.startsWith(path) && asset != path).length > 0;
	}

	public static function rename(path:String, newPath:String):Void
	{
		#if MODS_ALLOWED
		if (SysFileSystem.exists(cwd(path)))
			SysFileSystem.rename(cwd(path), cwd(newPath));
		#end
	}

	public static function stat(path:String):Null<FileStat>
	{
		#if MODS_ALLOWED
		return SysFileSystem.stat(cwd(path));
		#else
		return null;
		#end
	}

	public static function fullPath(path:String):String
	{
		#if MODS_ALLOWED
		return SysFileSystem.fullPath(path);
		#else
		return path;
		#end
	}

	public static function absolutePath(path:String):String
	{
		#if MODS_ALLOWED
		return SysFileSystem.absolutePath(path);
		#else
		return path;
		#end
	}

	public static function isDirectory(path:String):Bool
	{
		#if MODS_ALLOWED
		if (SysFileSystem.exists(cwd(path)) && SysFileSystem.isDirectory(cwd(path)))
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
		if (SysFileSystem.exists(cwd(path)) && !SysFileSystem.isDirectory(cwd(path)))
			SysFileSystem.deleteFile(cwd(path));
		#end
	}

	public static function deleteDirectory(path:String):Void
	{
		#if MODS_ALLOWED
		if (SysFileSystem.exists(cwd(path)) && SysFileSystem.isDirectory(cwd(path)))
			SysFileSystem.deleteDirectory(cwd(path));
		#end
	}

	public static function readDirectory(path:String):Array<String>
	{
		#if MODS_ALLOWED
		if (SysFileSystem.exists(path) && SysFileSystem.isDirectory(path))
			return SysFileSystem.readDirectory(path);
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
}
