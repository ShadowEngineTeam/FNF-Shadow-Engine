package backend;

import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxRect;
import openfl.display.BitmapData;
import openfl.display3D.textures.RectangleTexture;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import openfl.system.System;
import openfl.geom.Rectangle;
import openfl.media.Sound;
import animate.FlxAnimateFrames;

class Paths
{
	public static final IMAGE_EXT:String = "png";
	public static final GPU_IMAGE_EXT:String = #if ASTC "astc" #elseif BPTC "dds" #else IMAGE_EXT #end;
	#if FEATURE_VIDEOS
	public static final VIDEO_EXT:String = "mp4";
	#end
	public static var LOADOLD:Bool = false;

	public static final dumpExclusions:Array<String> = [
		'assets/shared/images/touchpad/bg.$IMAGE_EXT',
		'assets/shared/images/touchpad/bg.$GPU_IMAGE_EXT',
		'assets/shared/music/freakyMenu.ogg'
	];

	// define the locally tracked assets
	public static final currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static final currentTrackedSounds:Map<String, Sound> = [];
	public static final localTrackedAssets:Array<String> = [];

	// haya I love you for the base cache dump I took to the max
	public static function excludeAsset(key:String):Void
	{
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static function clearUnusedMemory():Void
	{
		// clear non local assets in the tracked assets list
		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				var obj = currentTrackedAssets.get(key);
				@:privateAccess
				if (obj != null)
				{
					// remove the key from all cache maps
					FlxG.bitmap._cache.remove(key);
					openfl.Assets.cache.removeBitmapData(key);
					currentTrackedAssets.remove(key);

					// and get rid of the object
					obj.persist = false; // make sure the garbage collector actually clears it up
					obj.destroyOnNoUse = true;
					obj.destroy();
				}
			}
		}

		// run the garbage collector for good measure lmfao
		System.gc();
		#if cpp
		cpp.NativeGc.run(true);
		#end
	}

	public static function clearStoredMemory():Void
	{
		// clear anything not in the tracked assets list
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null && !currentTrackedAssets.exists(key))
			{
				openfl.Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}

		// clear all sounds that are cached
		for (key => asset in currentTrackedSounds)
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && asset != null)
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}

		localTrackedAssets.resize(0);
		openfl.Assets.cache.clear("songs");
	}

	public static function getPath(file:String, ?type:AssetType = TEXT, ?library:Null<String> = null, ?modsAllowed:Bool = false):String
	{
		#if FEATURE_MODS
		if (modsAllowed)
		{
			var customFile:String = file;
			if (library != null)
				customFile = '$library/$file';

			var modded:String = modFolders(customFile);
			if (FileSystem.exists(modded))
				return modded;
		}
		#end

		if (library == "mobile")
			return getSharedPath('mobile/$file');

		if (library != null)
			return getLibraryPath(file, library);

		return getSharedPath(file);
	}

	public static function getLibraryPath(file:String, library:String = "shared"):String
	{
		return (library == "shared") ? getSharedPath(file) : getLibraryPathForce(file, library);
	}

	static function getLibraryPathForce(file:String, library:String, ?level:String):String
	{
		if (level == null)
			level = library;
		return '$library:assets/$level/$file';
	}

	inline public static function getSharedPath(file:String = ''):String
	{
		return 'assets/shared/$file';
	}

	inline public static function getFolderPath(file:String, folder:String = "shared"):String
	{
		return 'assets/$folder/$file';
	}

	inline public static function txt(key:String, ?library:String):String
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	inline public static function xml(key:String, ?library:String):String
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline public static function json(key:String, ?library:String):String
	{
		return getPath('data/$key.json', TEXT, library);
	}

	inline public static function shaderFragment(key:String, ?library:String):String
	{
		return getPath('shaders/$key.frag', TEXT, library);
	}

	inline public static function shaderVertex(key:String, ?library:String):String
	{
		return getPath('shaders/$key.vert', TEXT, library);
	}

	inline public static function lua(key:String, ?library:String):String
	{
		return getPath('$key.lua', TEXT, library);
	}

	#if FEATURE_VIDEOS
	public static function video(key:String):String
	{
		#if FEATURE_MODS
		var file:String = modsVideo(key);
		if (FileSystem.exists(file))
			return file;
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}
	#end

	inline public static function font(key:String):String
	{
		#if FEATURE_MODS
		var file:String = modsFont(key);
		if (FileSystem.exists(file))
			return file;
		#end
		return 'assets/fonts/$key';
	}

	public static function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?library:String = null):Bool
	{
		var path:String = getPath(key, type, library, false);

		#if FEATURE_MODS
		if (!ignoreMods)
		{
			var modKey:String = key;
			for (mod in Mods.getGlobalMods())
				if (FileSystem.exists(mods('$mod/$modKey')))
					return true;

			if (FileSystem.exists(mods(Mods.currentModDirectory + '/' + modKey)) || FileSystem.exists(mods(modKey)))
				return true;
		}
		#end

		return FileSystem.exists(path);
	}

	public static function getImageAssetType(ext:String):AssetType
	{
		return switch (ext.toLowerCase())
		{
			case 'png' | 'jpg' | 'jpeg': IMAGE;
			default: BINARY;
		}
	}

	public static function image(key:String, ?library:String = null):FlxGraphic
	{
		var bitmap:BitmapData = null;
		var file:String = null;

		#if FEATURE_MODS
		file = modsImages(key);
		if (currentTrackedAssets.exists(file))
		{
			localTrackedAssets.push(file);
			return currentTrackedAssets.get(file);
		}
		else if (FileSystem.exists(file))
		{
			bitmap = getBitmapDataFromFile(file);
		}
		else
		#end
		{
			file = getPath('images/$key.$GPU_IMAGE_EXT', getImageAssetType(GPU_IMAGE_EXT), library);
			if (currentTrackedAssets.exists(file))
			{
				localTrackedAssets.push(file);
				return currentTrackedAssets.get(file);
			}
			else if (FileSystem.exists(file))
				bitmap = getBitmapDataFromFile(file);

			if (bitmap == null)
			{
				file = getPath('images/$key.$IMAGE_EXT', getImageAssetType(IMAGE_EXT), library);
				if (currentTrackedAssets.exists(file))
				{
					localTrackedAssets.push(file);
					return currentTrackedAssets.get(file);
				}
				else if (FileSystem.exists(file))
				{
					bitmap = getBitmapDataFromFile(file);
				}
			}
		}

		if (bitmap != null)
		{
			var retVal = cacheBitmap(file, bitmap);
			if (retVal != null)
				return retVal;
		}

		trace('Failed to load image: $file');
		return null;
	}

	public static function cacheBitmap(file:String, ?bitmap:BitmapData = null):FlxGraphic
	{
		if (bitmap == null)
		{
			if (FileSystem.exists(file))
				bitmap = getBitmapDataFromFile(file);

			if (bitmap == null)
				return null;
		}

		localTrackedAssets.push(file);
		/*if (bitmap.readable)
		{
			var texture:RectangleTexture = FlxG.stage.context3D.createRectangleTexture(bitmap.width, bitmap.height, BGRA, true);
			texture.uploadFromBitmapData(bitmap);
			bitmap.image.data = null;
			bitmap.dispose();
			bitmap.disposeImage();
			bitmap = BitmapData.fromTexture(texture);
		}*/
		var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, file);
		newGraphic.persist = true;
		newGraphic.destroyOnNoUse = false;
		currentTrackedAssets.set(file, newGraphic);
		return newGraphic;
	}

	public static function getBitmapDataFromFile(file:String, useCache:Bool = true):BitmapData
	{
		if (useCache && currentTrackedAssets.exists(file))
		{
			var graphic = currentTrackedAssets.get(file);
			if (graphic != null && graphic.bitmap != null)
				return graphic.bitmap;
		}

		var ext:String = haxe.io.Path.extension(file).toLowerCase();
		if (ext == 'astc' || ext == 'dds')
		{
			try
			{
				var bytes = File.getBytes(file);
				if (bytes != null)
				{
					var texture = switch (ext)
					{
						case 'astc': openfl.Lib.current.stage.context3D.createASTCTexture(bytes);
						case 'dds': openfl.Lib.current.stage.context3D.createBPTCTexture(bytes);
						default: null;
					};

					if (texture != null)
						return BitmapData.fromTexture(texture);
				}
			}
			catch (e:Dynamic)
			{
				trace('Failed to load compressed texture from $file: $e');
				return null;
			}
		}

		return BitmapData.fromFile(file);
	}

	public static function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		#if FEATURE_MODS
		if (!ignoreMods)
		{
			var modPath:String = modFolders(key);
			if (FileSystem.exists(modPath))
				return File.getContent(modPath);
		}
		#end

		var sharedPath:String = getSharedPath(key);
		if (FileSystem.exists(sharedPath))
			return File.getContent(sharedPath);

		return null;
	}

	public static function sound(key:String, ?library:String):Sound
	{
		return returnSound('sounds', key, library);
	}

	inline public static function soundRandom(key:String, min:Int, max:Int, ?library:String):Sound
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline public static function music(key:String, ?library:String):Sound
	{
		return returnSound('music', key, library);
	}

	inline public static function voices(song:String, postfix:String = null):Any
	{
		var songKey:String = 'songs/${formatToSongPath(song)}/Voices${postfix != null ? '-$postfix' : ''}${LOADOLD ? "-Old" : ""}';
		return returnSound(null, songKey);
	}

	inline public static function inst(song:String, postfix:String = null):Sound
	{
		var songKey:String = 'songs/${formatToSongPath(song)}/Inst${postfix != null ? '-$postfix' : ''}${LOADOLD ? "-Old" : ""}';
		return returnSound(null, songKey);
	}

	public static function returnSound(path:Null<String>, key:String, ?library:String):Sound
	{
		#if FEATURE_MODS
		var modLibPath:String = '';
		if (library != null)
			modLibPath = '$library/';
		if (path != null)
			modLibPath += '$path';

		var file:String = modsSounds(modLibPath, key);
		if (FileSystem.exists(file))
		{
			if (!currentTrackedSounds.exists(file))
				currentTrackedSounds.set(file, Sound.fromFile(file));
			localTrackedAssets.push(file);
			return currentTrackedSounds.get(file);
		}
		#end

		// I hate this so god damn much
		var gottenPath:String = '$key.ogg';
		if (path != null)
			gottenPath = '$path/$gottenPath';
		gottenPath = getPath(gottenPath, SOUND, library);
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);

		if (!currentTrackedSounds.exists(gottenPath))
		{
			var retKey:String = (path != null) ? '$path/$key' : key;
			retKey = getPath('$retKey.ogg', SOUND, library);
			if (FileSystem.exists(retKey))
				currentTrackedSounds.set(gottenPath, Sound.fromBytes(File.getBytes(retKey)));
		}

		localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}

	public static function getAtlas(key:String, ?library:String = null):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, library);

		var xmlPath:String = getPath('images/$key.xml', TEXT, library, true);
		#if FEATURE_MODS
		var modXml:String = modsXml(key);
		if (FileSystem.exists(modXml))
			return FlxAtlasFrames.fromSparrow(imageLoaded, File.getContent(modXml));
		#end

		if (FileSystem.exists(xmlPath))
			return FlxAtlasFrames.fromSparrow(imageLoaded, File.getContent(xmlPath));

		var jsonPath:String = getPath('images/$key.json', TEXT, library, true);
		#if FEATURE_MODS
		var modJson:String = modsImagesJson(key);
		if (FileSystem.exists(modJson))
			return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, File.getContent(modJson));
		#end

		if (FileSystem.exists(jsonPath))
			return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, File.getContent(jsonPath));

		return getPackerAtlas(key, library);
	}

	public static function getSparrowAtlas(key:String, ?library:String = null):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, library);

		#if FEATURE_MODS
		var modXml:String = modsXml(key);
		if (FileSystem.exists(modXml))
			return FlxAtlasFrames.fromSparrow(imageLoaded, File.getContent(modXml));
		#end

		var xmlPath:String = getPath('images/$key.xml', library);
		return FlxAtlasFrames.fromSparrow(imageLoaded, File.getContent(xmlPath));
	}

	public static function getPackerAtlas(key:String, ?library:String = null):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, library);

		#if FEATURE_MODS
		var modTxt:String = modsTxt(key);
		if (FileSystem.exists(modTxt))
			return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, File.getContent(modTxt));
		#end

		var txtPath:String = getPath('images/$key.txt', library);
		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, File.getContent(txtPath));
	}

	public static function getAsepriteAtlas(key:String, ?library:String = null):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, library);

		#if FEATURE_MODS
		var modJson:String = modsImagesJson(key);
		if (FileSystem.exists(modJson))
			return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, File.getContent(modJson));
		#end

		var jsonPath:String = getPath('images/$key.json', library);
		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, File.getContent(jsonPath));
	}

	public static function getTextureAtlas(key:String, ?library:String = null, ?settings:FlxAnimateSettings):FlxAnimateFrames
	{
		if (settings == null)
			settings = {};

		if (settings.filterQuality == null && ClientPrefs.data.lowQuality)
			settings.filterQuality = FilterQuality.LOW;

		var animateFolder:String = getPath('images/$key', library);

		#if FEATURE_MODS
		var modFolder:String = modsImages(key);
		if (FileSystem.exists(modFolder))
			return FlxAnimateFrames.fromAnimate(modFolder, settings);
		#end

		return FlxAnimateFrames.fromAnimate(animateFolder, settings);
	}

	public static function formatToSongPath(path:String):String
	{
		var invalidChars = ~/[~&\\;:<>#]/;
		var hideChars = ~/[.,'"%?!]/;

		var formattedPath = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(formattedPath).join("").toLowerCase();
	}

	#if FEATURE_MODS
	inline public static function mods(key:String = ''):String
	{
		return #if mobile Sys.getCwd() + #end 'mods/' + key;
	}

	inline public static function modsFont(key:String):String
	{
		return modFolders('fonts/' + key);
	}

	inline public static function modsJson(key:String):String
	{
		return modFolders('data/' + key + '.json');
	}

	#if FEATURE_VIDEOS
	inline public static function modsVideo(key:String):String
	{
		return modFolders('videos/' + key + '.' + VIDEO_EXT);
	}
	#end

	inline public static function modsSounds(path:String, key:String):String
	{
		return modFolders(path + '/' + key + '.ogg');
	}

	inline public static function modsImages(key:String):String
	{
		var gpuFile:String = modFolders('images/' + key + '.${GPU_IMAGE_EXT}');
		if (FileSystem.exists(gpuFile))
			return gpuFile;

		return modFolders('images/' + key + '.${IMAGE_EXT}');
	}

	inline public static function modsXml(key:String):String
	{
		return modFolders('images/' + key + '.xml');
	}

	inline public static function modsTxt(key:String):String
	{
		return modFolders('images/' + key + '.txt');
	}

	inline public static function modsImagesJson(key:String):String
	{
		return modFolders('images/' + key + '.json');
	}

	public static function modFolders(key:String):String
	{
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
		{
			var fileToCheck:String = mods(Mods.currentModDirectory + '/' + key);
			if (FileSystem.exists(fileToCheck))
				return fileToCheck;
		}

		for (mod in Mods.getGlobalMods())
		{
			var fileToCheck:String = mods(mod + '/' + key);
			if (FileSystem.exists(fileToCheck))
				return fileToCheck;
		}

		return #if mobile Sys.getCwd() + #end 'mods/' + key;
	}
	#end
}
