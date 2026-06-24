package animate;

import haxe.io.Bytes;
import openfl.display.BitmapData;

import backend.io.File;
import backend.io.FileSystem;

#if (flixel >= "5.9.0")
using StringTools;
#end

class FlxAnimateAssets
{
	public static dynamic function exists(path:String, type:AssetType):Bool
	{
		return FileSystem.exists(path);
	}

	public static dynamic function getText(path:String):String
	{
		if (FileSystem.exists(path))
			return File.getContent(path);

		return null;
	}

	public static dynamic function getBytes(path:String):Bytes
	{
		if (FileSystem.exists(path))
			return File.getBytes(path);

		return null;
	}

	public static dynamic function getBitmapData(path:String):BitmapData
	{
		if (FileSystem.exists(path))
			return BitmapData.fromBytes(File.getBytes(path));

		return null;
	}

	public static dynamic function list(path:String, ?type:AssetType, ?library:String, includeSubDirectories:Bool = false):Array<String>
	{
		var result:Array<String> = null;

		// Check openfl/flixel assets first
		result = #if (flixel >= "5.9.0") flixel.FlxG.assets.list(type); #else openfl.utils.Assets.list(type); #end

		if (result == null)
			result = [];

		// Fallback to filesystem for non-library assets
		#if sys
		if (library == null || library.length == 0)
		{
			if (sys.FileSystem.exists(path))
			{
				var files:Array<String> = sys.FileSystem.readDirectory(path);
				var result:Array<String> = [];
				var checkSubDirectory:String->Void = null;

				checkSubDirectory = (file) ->
				{
					if (sys.FileSystem.isDirectory('$path/$file') && includeSubDirectories)
					{
						var files = sys.FileSystem.readDirectory('$path/$file').map((subFile) -> '$file/$subFile');
						for (file in files)
							checkSubDirectory(file);
					}
					else
					{
						result.push(file);
					}
				};

				for (file in files)
					checkSubDirectory(file);

				return result;
			}
		}
		#end

		return result.filter((str) -> str.startsWith(path.substring(path.indexOf(':') + 1, path.length)))
			.map((str) -> str.split('${path.split(":").pop()}/').pop());
	}
}

typedef AssetType = #if (flixel >= "5.9.0") flixel.system.frontEnds.AssetFrontEnd.FlxAssetType #else openfl.utils.AssetType #end;