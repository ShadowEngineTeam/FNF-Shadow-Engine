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
		if ((library == null || library.length == 0) && FileSystem.isDirectory(path))
		{
			var result:Array<String> = [];
			var checkSubDirectory:String->Void = null;

			checkSubDirectory = (file) ->
			{
				if (includeSubDirectories && FileSystem.isDirectory('$path/$file'))
				{
					for (subFile in FileSystem.readDirectory('$path/$file'))
						checkSubDirectory('$file/$subFile');
				}
				else
				{
					result.push(file);
				}
			};

			for (file in FileSystem.readDirectory(path))
				checkSubDirectory(file);

			return result;
		}

		var result:Array<String> = #if (flixel >= "5.9.0") flixel.FlxG.assets.list(type); #else openfl.utils.Assets.list(type); #end

		if (result == null)
			return [];

		return result.filter((str) -> str.startsWith(path.substring(path.indexOf(':') + 1, path.length)))
			.map((str) -> str.split('${path.split(":").pop()}/').pop());
	}
}

typedef AssetType = #if (flixel >= "5.9.0") flixel.system.frontEnds.AssetFrontEnd.FlxAssetType #else openfl.utils.AssetType #end;