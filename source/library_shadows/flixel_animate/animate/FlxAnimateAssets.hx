package animate;

import haxe.io.Bytes;
import openfl.display.BitmapData;

import backend.io.File;
import backend.io.FileSystem;

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
		// SHADOW TODO: implement includeSubDirectories?
		return FileSystem.readDirectory(path);
	}
}

typedef AssetType = #if (flixel >= "5.9.0") flixel.system.frontEnds.AssetFrontEnd.FlxAssetType #else openfl.utils.AssetType #end;