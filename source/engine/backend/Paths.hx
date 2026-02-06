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
	public static var IMAGE_EXT:String = "png";
	public static var GPU_IMAGE_EXT:String = #if ASTC "astc" #elseif S3TC "dds" #else IMAGE_EXT #end;
	#if FEATURE_VIDEOS
	public static var VIDEO_EXT = "mp4";
	#end
	public static var LOADOLD:Bool = false;

	public static function excludeAsset(key:String)
	{
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = [
		'assets/shared/images/touchpad/bg.$IMAGE_EXT',
		'assets/shared/images/touchpad/bg.$GPU_IMAGE_EXT',
		'assets/shared/music/freakyMenu.ogg'
	];

	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory()
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

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];

	public static function clearStoredMemory()
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
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
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

	static public function getLibraryPath(file:String, library = "shared")
	{
		return if (library == "shared") getSharedPath(file); else getLibraryPathForce(file, library);
	}

	static function getLibraryPathForce(file:String, library:String, ?level:String)
	{
		if (level == null)
			level = library;
		var returnPath = '$library:assets/$level/$file';
		return returnPath;
	}

	inline public static function getSharedPath(file:String = '')
	{
		return 'assets/shared/$file';
	}

	inline static public function getFolderPath(file:String, folder = "shared")
		return 'assets/$folder/$file';

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	inline static public function shaderFragment(key:String, ?library:String)
	{
		return getPath('shaders/$key.frag', TEXT, library);
	}

	inline static public function shaderVertex(key:String, ?library:String)
	{
		return getPath('shaders/$key.vert', TEXT, library);
	}

	inline static public function lua(key:String, ?library:String)
	{
		return getPath('$key.lua', TEXT, library);
	}

	#if FEATURE_VIDEOS
	static public function video(key:String)
	{
		#if FEATURE_MODS
		var file:String = modsVideo(key);
		if (FileSystem.exists(file))
		{
			return file;
		}
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}
	#end

	static public function sound(key:String, ?library:String):Sound
	{
		var sound:Sound = returnSound('sounds', key, library);
		return sound;
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String):Sound
	{
		var file:Sound = returnSound('music', key, library);
		return file;
	}

	inline static public function voices(song:String, postfix:String = null):Any
	{
		var songKey:String = 'songs/${formatToSongPath(song)}/Voices${postfix != null ? '-$postfix' : ''}${LOADOLD ? "-Old" : ""}';
		var voices = returnSound(null, songKey);
		return voices;
	}

	inline static public function inst(song:String, postfix:String = null):Sound
	{
		var songKey:String = 'songs/${formatToSongPath(song)}/Inst${postfix != null ? '-$postfix' : ''}${LOADOLD ? "-Old" : ""}';
		var inst = returnSound(null, songKey);
		return inst;
	}

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];

	static public function getImageAssetType(ext:String):AssetType
	{
		return switch (ext.toLowerCase())
		{
			case 'png', 'jpg', 'jpeg': AssetType.IMAGE;
			case _: AssetType.BINARY;
		}
	}

	static public function image(key:String, ?library:String = null):FlxGraphic
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
			bitmap = BitmapData.fromFile(file);
		else
		#end
		{
			file = getPath('images/$key.$GPU_IMAGE_EXT', getImageAssetType(GPU_IMAGE_EXT), library);
			if (currentTrackedAssets.exists(file))
			{
				localTrackedAssets.push(file);
				return currentTrackedAssets.get(file);
			}
			else if (Assets.exists(file, getImageAssetType(GPU_IMAGE_EXT)))
				bitmap = Assets.getBitmapData(file);

			if (Assets.exists(getPath('images/$key.$IMAGE_EXT', getImageAssetType(IMAGE_EXT), library), getImageAssetType(IMAGE_EXT)))
			{
				file = getPath('images/$key.$IMAGE_EXT', getImageAssetType(IMAGE_EXT), library);
				if (currentTrackedAssets.exists(file))
				{
					localTrackedAssets.push(file);
					return currentTrackedAssets.get(file);
				}
				bitmap = Assets.getBitmapData(file);
			}
		}

		if (bitmap != null)
		{
			var retVal = cacheBitmap(file, bitmap);
			if (retVal != null)
				return retVal;
		}

		trace('oh no its returning null NOOOO ($file)');
		return null;
	}

	static public function cacheBitmap(file:String, ?bitmap:BitmapData = null)
	{
		if (bitmap == null)
		{
			if (FileSystem.exists(file))
				bitmap = BitmapData.fromFile(file);
			else
			{
				if (Assets.exists(file, getImageAssetType(GPU_IMAGE_EXT)))
					bitmap = Assets.getBitmapData(file);

				if (Assets.exists(file, getImageAssetType(IMAGE_EXT)))
					bitmap = Assets.getBitmapData(file);
			}

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

	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		#if FEATURE_MODS
		if (!ignoreMods && FileSystem.exists(modFolders(key)))
			return File.getContent(modFolders(key));
		#end

		if (FileSystem.exists(getSharedPath(key)))
			return File.getContent(getSharedPath(key));

		var path:String = getPath(key, TEXT);
		if (Assets.exists(path, TEXT))
			return Assets.getText(path);
		return null;
	}

	inline static public function font(key:String)
	{
		#if FEATURE_MODS
		var file:String = modsFont(key);
		if (FileSystem.exists(file))
		{
			return file;
		}
		#end
		return 'assets/fonts/$key';
	}

	public static function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?library:String = null)
	{
		var path:String = getPath(key, type, library, false);

		#if FEATURE_MODS
		if (!ignoreMods)
		{
			var modKey:String = key;
			if (library == "songs")
				modKey = 'songs/$key';

			for (mod in Mods.getGlobalMods())
				if (FileSystem.exists(mods('$mod/$modKey')))
					return true;

			if (FileSystem.exists(mods(Mods.currentModDirectory + '/' + modKey)) || FileSystem.exists(mods(modKey)))
				return true;
		}
		#end

		return FileSystem.exists(path);
	}

	static public function getAtlas(key:String, ?library:String = null):FlxAtlasFrames
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

	static public function getSparrowAtlas(key:String, ?library:String = null):FlxAtlasFrames
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

	static public function getPackerAtlas(key:String, ?library:String = null):FlxAtlasFrames
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

	static public function getAsepriteAtlas(key:String, ?library:String = null):FlxAtlasFrames
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

	static public function formatToSongPath(path:String)
	{
		var invalidChars = ~/[~&\\;:<>#]/;
		var hideChars = ~/[.,'"%?!]/;

		var path = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(path).join("").toLowerCase();
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];

	public static function returnSound(path:Null<String>, key:String, ?library:String)
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
			{
				currentTrackedSounds.set(file, Sound.fromFile(file));
				// trace('precached mod sound: $file');
			}
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
			if (Assets.exists(retKey, SOUND))
				currentTrackedSounds.set(gottenPath, Assets.getSound(retKey));
		}
		localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}

	#if FEATURE_MODS
	inline static public function mods(key:String = '')
	{
		return #if mobile Sys.getCwd() + #end 'mods/' + key;
	}

	inline static public function modsFont(key:String)
	{
		return modFolders('fonts/' + key);
	}

	inline static public function modsJson(key:String)
	{
		return modFolders('data/' + key + '.json');
	}

	#if FEATURE_VIDEOS
	inline static public function modsVideo(key:String)
	{
		return modFolders('videos/' + key + '.' + VIDEO_EXT);
	}
	#end

	inline static public function modsSounds(path:String, key:String)
	{
		return modFolders(path + '/' + key + '.ogg');
	}

	inline static public function modsImages(key:String)
	{
		final gpuFile = modFolders('images/' + key + '.${Paths.GPU_IMAGE_EXT}');
		if (FileSystem.exists(gpuFile))
			return gpuFile;

		return modFolders('images/' + key + '.${Paths.IMAGE_EXT}');
	}

	inline static public function modsXml(key:String)
	{
		return modFolders('images/' + key + '.xml');
	}

	inline static public function modsTxt(key:String)
	{
		return modFolders('images/' + key + '.txt');
	}

	inline static public function modsImagesJson(key:String)
	{
		return modFolders('images/' + key + '.json');
	}

	static public function modFolders(key:String)
	{
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
		{
			var fileToCheck:String = mods(Mods.currentModDirectory + '/' + key);
			if (FileSystem.exists(fileToCheck))
			{
				return fileToCheck;
			}
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
