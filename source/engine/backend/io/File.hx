package backend.io;

import openfl.Assets;
#if sys
import sys.FileSystem as SysFileSystem;
import sys.FileStat;
import sys.io.File as SysFile;
import sys.io.FileInput;
import sys.io.FileOutput;
#end

/**
 * Unified file class that works with both native file access and OpenFL assets.
 * @see https://github.com/Psych-Slice/P-Slice/blob/master/source/mikolka/funkin/custom/NativeFileSystem.hx
 */
class File
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

	public static function getContent(path:String):String
	{
		#if MODS_ALLOWED
		if (SysFileSystem.exists(cwd(path)))
			return SysFile.getContent(cwd(path));
		#end

		return Assets.getText(openflcwd(path));
	}

	public static function getBytes(path:String):haxe.io.Bytes
	{
		#if MODS_ALLOWED
		if (SysFileSystem.exists(cwd(path)))
			return SysFile.getBytes(cwd(path));
		#end

		switch (haxe.io.Path.extension(path).toLowerCase())
		{
			case 'otf' | 'ttf':
				return openfl.utils.ByteArray.fromFile(openflcwd(path));
			default:
				return Assets.getBytes(openflcwd(path));
		}
	}

	public static function saveContent(path:String, content:String):Void
	{
		#if MODS_ALLOWED
		SysFile.saveContent(cwd(path), content);
		#end
	}

	public static function saveBytes(path:String, bytes:haxe.io.Bytes):Void
	{
		#if MODS_ALLOWED
		SysFile.saveBytes(cwd(path), bytes);
		#end
	}

	public static function read(path:String, binary:Bool = true):Null<FileInput>
	{
		#if MODS_ALLOWED
		return SysFile.read(cwd(path), binary);
		#else
		return null;
		#end
	}

	public static function write(path:String, binary:Bool = true):Null<FileOutput>
	{
		#if MODS_ALLOWED
		return SysFile.write(cwd(path), binary);
		#else
		return null;
		#end
	}

	public static function append(path:String, binary:Bool = true):Null<FileOutput>
	{
		#if MODS_ALLOWED
		return SysFile.append(cwd(path), binary);
		#else
		return null;
		#end
	}

	public static function update(path:String, binary:Bool = true):Null<FileOutput>
	{
		#if MODS_ALLOWED
		return SysFile.update(cwd(path), binary);
		#else
		return null;
		#end
	}

	public static function copy(srcPath:String, dstPath:String):Void
	{
		#if MODS_ALLOWED
		SysFile.copy(cwd(srcPath), cwd(dstPath));
		#end
	}
}
