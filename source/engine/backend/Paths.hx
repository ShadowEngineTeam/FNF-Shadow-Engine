package backend;

import flixel.system.FlxAssets;
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

@:nullSafety
class Paths
{
	public static final IMAGE_EXT:String = "png";
	#if USING_GPU_TEXTURES
	public static final GPU_IMAGE_EXT:String = #if ASTC "astc" #elseif BC "dds" #else IMAGE_EXT #end;
	#end
	#if FEATURE_VIDEOS
	public static final VIDEO_EXT:String = "mp4";
	#end
	public static var LOADOLD:Bool = false;

	public static final dumpExclusions:Array<String> = [
		'assets/shared/images/touchpad/bg.$IMAGE_EXT',
		#if USING_GPU_TEXTURES
		'assets/shared/images/touchpad/bg.$GPU_IMAGE_EXT',
		#end
		'assets/shared/images/ui/cursor.png',
		'assets/shared/images/ui/cursorCross.png',
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

	public static function getPath(file:String, ?type:AssetType = TEXT, ?library:Null<String> = null, modsAllowed:Bool = false):String
	{
		#if USING_GPU_TEXTURES
		if (file.endsWith(IMAGE_EXT) && FileSystem.exists(haxe.io.Path.withoutExtension(file) + '.$GPU_IMAGE_EXT'))
			file = haxe.io.Path.withoutExtension(file) + '.$GPU_IMAGE_EXT';
		#end

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

	public static function fileExists(key:String, type:AssetType, ignoreMods:Bool = false, ?library:String = null):Bool
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
			
			#if USING_GPU_TEXTURES
			if (modKey.endsWith(IMAGE_EXT))
			{
				modKey = haxe.io.Path.withoutExtension(modKey) + '.$GPU_IMAGE_EXT';

				for (mod in Mods.getGlobalMods())
					if (FileSystem.exists(mods('$mod/$modKey')))
						return true;

				if (FileSystem.exists(mods(Mods.currentModDirectory + '/' + modKey)) || FileSystem.exists(mods(modKey)))
					return true;
			}
			#end
		}
		#end

		#if USING_GPU_TEXTURES
		if (path.endsWith(IMAGE_EXT) && FileSystem.exists(haxe.io.Path.withoutExtension(path) + '.$GPU_IMAGE_EXT'))
			return true;
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

	public static function image(key:String, ?library:String = null):Null<FlxGraphic>
	{
		var bitmap:Null<BitmapData> = null;
		var file:String = '';

		#if FEATURE_MODS
		file = modsImages(key);
		if (currentTrackedAssets.exists(file))
		{
			localTrackedAssets.push(file);
			var asset = currentTrackedAssets.get(file);
			if (asset != null) return asset;
		}
		else if (FileSystem.exists(file))
		{
			var bytes = File.getBytes(file);
			if (bytes != null)
				bitmap = BitmapData.fromBytes(bytes);
		}
		else
		#end
		{
			for (ext in [#if USING_GPU_TEXTURES GPU_IMAGE_EXT, #end IMAGE_EXT])
			{
				file = getPath('images/$key.$ext', getImageAssetType(ext), library);
				if (currentTrackedAssets.exists(file))
				{
					localTrackedAssets.push(file);
					var asset = currentTrackedAssets.get(file);
					if (asset != null) return asset;
				}
				else if (FileSystem.exists(file))
				{
					var bytes = File.getBytes(file);
					if (bytes != null)
						bitmap = BitmapData.fromBytes(bytes);
				}

				if (bitmap != null) break;
			}
		}

		if (bitmap != null)
		{
			var retVal = cacheBitmap(file, bitmap);
			if (retVal != null)
				return retVal;
		}

		trace('Failed to load image: $file');
		
		if (currentTrackedAssets.exists('__flixel_logo'))
		{
			localTrackedAssets.push('__flixel_logo');
			var logo = currentTrackedAssets.get('__flixel_logo');
			if (logo != null) return logo;
		}

		var fallback = cacheBitmap('__flixel_logo', FlxAssets.getBitmapFromClass(GraphicLogo));
		if (fallback != null) return fallback;
		
		trace("Failed to load fallback image");
		return null;
	}

	public static function cacheBitmap(file:String, ?bitmap:Null<BitmapData> = null):Null<FlxGraphic>
	{
		if (bitmap == null)
		{
			if (FileSystem.exists(file))
			{
				var bytes = File.getBytes(file);
				if (bytes != null)
					bitmap = BitmapData.fromBytes(bytes);
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

	public static function getTextFromFile(key:String, ignoreMods:Bool = false):Null<String>
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

	public static function sound(key:String, ?library:String):Null<Sound>
	{
		return returnSound('sounds', key, library);
	}

	inline public static function soundRandom(key:String, min:Int, max:Int, ?library:String):Null<Sound>
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline public static function music(key:String, ?library:String):Null<Sound>
	{
		return returnSound('music', key, library);
	}

	inline public static function voices(song:String, postfix:String = null):Null<Any>
	{
		var songKey:String = 'songs/${formatToSongPath(song)}/Voices${postfix != null ? '-$postfix' : ''}${LOADOLD ? "-Old" : ""}';
		return returnSound(null, songKey);
	}

	inline public static function inst(song:String, postfix:String = null):Null<Sound>
	{
		var songKey:String = 'songs/${formatToSongPath(song)}/Inst${postfix != null ? '-$postfix' : ''}${LOADOLD ? "-Old" : ""}';
		return returnSound(null, songKey);
	}

	public static function returnSound(path:Null<String>, key:String, ?library:String):Null<Sound>
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
			var snd = currentTrackedSounds.get(file);
			if (snd != null) return snd;
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
			{
				var bytes = File.getBytes(retKey);
				if (bytes != null)
					currentTrackedSounds.set(gottenPath, Sound.fromBytes(bytes));
			}
		}

		localTrackedAssets.push(gottenPath);
		var result = currentTrackedSounds.get(gottenPath);
		if (result != null) return result;
		trace("Failed to load sound: " + gottenPath);
		return null;
	}

	public static function getAtlas(key:String, ?library:String = null):Null<FlxAtlasFrames>
	{
		var imageLoaded = image(key, library);
		if (imageLoaded == null)
		{
			trace("Failed to load image for atlas: " + key);
			return null;
		}

		var xmlPath:String = getPath('images/$key.xml', TEXT, library, true);
		#if FEATURE_MODS
		var modXml:String = modsXml(key);
		if (FileSystem.exists(modXml))
		{
			var content = File.getContent(modXml);
			if (content != null) return FlxAtlasFrames.fromSparrow(imageLoaded, content);
		}
		#end

		if (FileSystem.exists(xmlPath))
		{
			var content = File.getContent(xmlPath);
			if (content != null) return FlxAtlasFrames.fromSparrow(imageLoaded, content);
		}

		var jsonPath:String = getPath('images/$key.json', TEXT, library, true);
		#if FEATURE_MODS
		var modJson:String = modsImagesJson(key);
		if (FileSystem.exists(modJson))
		{
			var content = File.getContent(modJson);
			if (content != null) return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, content);
		}
		#end

		if (FileSystem.exists(jsonPath))
		{
			var content = File.getContent(jsonPath);
			if (content != null) return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, content);
		}

		return getPackerAtlas(key, library);
	}

	public static function getSparrowAtlas(key:String, ?library:String = null):Null<FlxAtlasFrames>
	{
		var imageLoaded = image(key, library);
		if (imageLoaded == null)
		{
			trace("Failed to load image for sparrow atlas: " + key);
			return null;
		}

		#if FEATURE_MODS
		var modXml:String = modsXml(key);
		if (FileSystem.exists(modXml))
		{
			var content = File.getContent(modXml);
			if (content != null) return FlxAtlasFrames.fromSparrow(imageLoaded, content);
		}
		#end

		var xmlPath:String = getPath('images/$key.xml', library);
		var content = File.getContent(xmlPath);
		if (content != null) return FlxAtlasFrames.fromSparrow(imageLoaded, content);
		trace("Failed to load sparrow atlas: " + key);
		return null;
	}

	public static function getPackerAtlas(key:String, ?library:String = null):Null<FlxAtlasFrames>
	{
		var imageLoaded = image(key, library);
		if (imageLoaded == null)
		{
			trace("Failed to load image for packer atlas: " + key);
			return null;
		}

		#if FEATURE_MODS
		var modTxt:String = modsTxt(key);
		if (FileSystem.exists(modTxt))
		{
			var content = File.getContent(modTxt);
			if (content != null) return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, content);
		}
		#end

		var txtPath:String = getPath('images/$key.txt', library);
		var content = File.getContent(txtPath);
		if (content != null) return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, content);
		trace("Failed to load packer atlas: " + key);
		return null;
	}

	public static function getAsepriteAtlas(key:String, ?library:String = null):Null<FlxAtlasFrames>
	{
		var imageLoaded = image(key, library);
		if (imageLoaded == null)
		{
			trace("Failed to load image for aseprite atlas: " + key);
			return null;
		}

		#if FEATURE_MODS
		var modJson:String = modsImagesJson(key);
		if (FileSystem.exists(modJson))
		{
			var content = File.getContent(modJson);
			if (content != null) return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, content);
		}
		#end

		var jsonPath:String = getPath('images/$key.json', library);
		var content = File.getContent(jsonPath);
		if (content != null) return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, content);
		trace("Failed to load aseprite atlas: " + key);
		return null;
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
		#if USING_GPU_TEXTURES
		var gpuFile:String = modFolders('images/' + key + '.${GPU_IMAGE_EXT}');
		if (FileSystem.exists(gpuFile))
			return gpuFile;
		#end

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
