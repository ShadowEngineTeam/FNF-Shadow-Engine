package states;

import objects.Bar;
#if (target.threaded)
import sys.thread.Thread;
import sys.thread.Mutex;
#end
import lime.utils.Assets;
import openfl.display.BitmapData;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.FlxGraphic;
import backend.Song;
import backend.StageData;
import objects.Character;

class LoadingState extends MusicBeatState
{
	public static var loaded:Int = 0;
	public static var loadMax:Int = 0;

	static var requestedBitmaps:Map<String, BitmapData> = [];
	#if (target.threaded)
	static var mutex:Mutex = new Mutex();
	static var loadedMutex:Mutex = new Mutex();
	#end

	function new(target:FlxState, stopMusic:Bool)
	{
		this.target = target;
		this.stopMusic = stopMusic;
		startThreads();

		super();
	}

	inline static public function loadAndSwitchState(target:FlxState, stopMusic = false, intrusive:Bool = true)
		MusicBeatState.switchState(getNextState(target, stopMusic, intrusive));

	var target:FlxState = null;
	var stopMusic:Bool = false;
	var dontUpdate:Bool = false;

	var bar:Bar;
	var barWidth:Int = 0;
	var intendedPercent:Float = 0;
	var canChangeState:Bool = true;

	var loadingText:FlxText;
	var timePassed:Float;

	override function create()
	{
		if (checkLoaded())
		{
			dontUpdate = true;
			super.create();
			onLoad();
			return;
		}

		add(new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xffafff34));

		var bg = new FlxSprite(0, 0, Paths.image('funkay'));
		bg.setGraphicSize(0, FlxG.height);
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		loadingText = new FlxText(520, 600, 400, 'Now Loading...', 32);
		loadingText.setFormat(Paths.font("Comfortaa-Bold.ttf"), 32, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
		loadingText.borderSize = 2;
		add(loadingText);

		bar = new Bar(0, 660, 'loadingBar', () -> (loaded / loadMax));
		bar.screenCenter(X);
		bar.barOffset.set(3, 3);
		bar.setColors(FlxColor.WHITE, FlxColor.BLACK); // example colors
		add(bar);

		persistentUpdate = true;
		super.create();
	}

	var transitioning:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (dontUpdate)
			return;

		if (!transitioning)
		{
			if (bar.percent >= 99.99999 && canChangeState && !finishedLoading && checkLoaded())
			{
				transitioning = true;
				onLoad();
				return;
			}
			intendedPercent = loaded / loadMax;
		}

		timePassed += elapsed;
		var txt:String = 'Now Loading.';
		switch (Math.floor(timePassed % 1 * 3))
		{
			case 1:
				txt += '.';
			case 2:
				txt += '..';
		}
		loadingText.text = txt;
	}

	var finishedLoading:Bool = false;

	function onLoad()
	{
		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		imagesToPrepare = [];
		soundsToPrepare = [];
		musicToPrepare = [];
		songsToPrepare = [];

		FlxG.camera.visible = false;
		// FlxTransitionableState.skipNextTransIn = true;
		MusicBeatState.switchState(target);
		transitioning = true;
		finishedLoading = true;
	}

	static function checkLoaded():Bool
	{
		for (key => bitmap in requestedBitmaps)
		{
			if (bitmap != null && Paths.cacheBitmap(key, bitmap) != null)
				trace('finished preloading image $key');
			else
				trace('failed to cache image $key');
		}
		requestedBitmaps.clear();
		return (loaded == loadMax);
	}

	static function getNextState(target:FlxState, stopMusic = false, intrusive:Bool = true):FlxState
	{
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;

		if (weekDir != null && weekDir.length > 0 && weekDir != '')
			directory = weekDir;

		var doPrecache:Bool = false;
		if (ClientPrefs.data.loadingScreen)
		{
			clearInvalids();
			if (intrusive)
			{
				if (imagesToPrepare.length > 0 || soundsToPrepare.length > 0 || musicToPrepare.length > 0 || songsToPrepare.length > 0)
					return new LoadingState(target, stopMusic);
			}
			else
				doPrecache = true;
		}

		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		if (doPrecache)
		{
			startThreads();
			while (true)
			{
				if (checkLoaded())
				{
					imagesToPrepare = [];
					soundsToPrepare = [];
					musicToPrepare = [];
					songsToPrepare = [];
					break;
				}
				else
					#if sys Sys.sleep(0.01); #else haxe.Timer.delay(() -> {}, 10); #end
			}
		}
		return target;
	}

	static var imagesToPrepare:Array<String> = [];
	static var soundsToPrepare:Array<String> = [];
	static var musicToPrepare:Array<String> = [];
	static var songsToPrepare:Array<String> = [];

	public static function prepare(images:Array<String> = null, sounds:Array<String> = null, music:Array<String> = null)
	{
		if (images != null)
			imagesToPrepare = imagesToPrepare.concat(images);
		if (sounds != null)
			soundsToPrepare = soundsToPrepare.concat(sounds);
		if (music != null)
			musicToPrepare = musicToPrepare.concat(music);
	}

	static var dontPreloadDefaultVoices:Bool = false;

	public static function prepareToSong()
	{
		if (!ClientPrefs.data.loadingScreen)
			return;

		var song:SwagSong = PlayState.SONG;
		var folder:String = Paths.formatToSongPath(song.song);
		try
		{
			var path:String = Paths.json('$folder/preload');
			var json:Dynamic = null;

			#if FEATURE_MODS
			var modPath:String = Paths.modsJson('$folder/preload');
			if (FileSystem.exists(modPath))
				json = Json.parse(File.getContent(modPath), modPath);
			else if (FileSystem.exists(path))
				json = Json.parse(File.getContent(path), path);
			#else
			if (FileSystem.exists(path))
				json = Json.parse(File.getContent(path), path);
			#end

			if (json != null)
				prepare((!ClientPrefs.data.lowQuality || json.images_low) ? json.images : json.images_low, json.sounds, json.music);
		}
		catch (e:Dynamic) {}

		if (song.stage == null || song.stage.length < 1)
			song.stage = StageData.vanillaSongStage(folder);

		var stageData:StageFile = StageData.getStageFile(song.stage);
		if (stageData != null && stageData.preload != null)
			prepare((!ClientPrefs.data.lowQuality || stageData.preload.images_low) ? stageData.preload.images : stageData.preload.images_low,
				stageData.preload.sounds, stageData.preload.music);

		songsToPrepare.push('$folder/Inst' + Difficulty.getSongPrefix());

		var player1:String = song.player1;
		var player2:String = song.player2;
		var gfVersion:String = song.gfVersion;
		var needsVoices:Bool = song.needsVoices;
		var prefixVocals:String = needsVoices ? '$folder/Voices' + Difficulty.getSongPrefix() : null;
		if (gfVersion == null)
			gfVersion = 'gf';

		dontPreloadDefaultVoices = false;
		preloadCharacter(player1, prefixVocals);
		if (player2 != player1)
			preloadCharacter(player2, prefixVocals);
		if (!stageData?.hide_girlfriend && gfVersion != player2 && gfVersion != player1)
			preloadCharacter(gfVersion);

		if (!dontPreloadDefaultVoices && needsVoices)
			songsToPrepare.push(prefixVocals);
	}

	public static function clearInvalids()
	{
		clearInvalidFrom(imagesToPrepare, 'images', '.png', IMAGE); // leaving this as is
		// clearInvalidFrom(imagesToPrepare, 'images', '.${Paths.IMAGE_EXT}', Paths.IMAGE_ASSETTYPE);
		clearInvalidFrom(soundsToPrepare, 'sounds', '.ogg', SOUND);
		clearInvalidFrom(musicToPrepare, 'music', ' .ogg', SOUND);
		clearInvalidFrom(songsToPrepare, 'songs', '.ogg', SOUND);

		for (arr in [imagesToPrepare, soundsToPrepare, musicToPrepare, songsToPrepare])
			while (arr.contains(null))
				arr.remove(null);
	}

	static function clearInvalidFrom(arr:Array<String>, prefix:String, ext:String, type:AssetType, ?library:String = null)
	{
		for (i in 0...arr.length)
		{
			var folder:String = arr[i];
			if (folder.trim().endsWith('/'))
			{
				for (subfolder in Mods.directoriesWithFile(Paths.getSharedPath(), '$prefix/$folder'))
					for (file in FileSystem.readDirectory(subfolder))
						if (file.endsWith(ext))
							arr.push(folder + file.substr(0, file.length - ext.length));

				// trace('Folder detected! ' + folder);
			}
		}

		var i:Int = 0;
		while (i < arr.length)
		{
			var member:String = arr[i];
			var myKey = '$prefix/$member$ext';

			// trace('attempting on $prefix: $myKey');
			var doTrace:Bool = false;
			if (member.endsWith('/') || (!Paths.fileExists(myKey, type, false, library) && (doTrace = true)))
			{
				arr.remove(member);
				if (doTrace)
					trace('Removed invalid $prefix: $member');
			}
			else
				i++;
		}
	}

	public static function startThreads()
	{
		loadMax = imagesToPrepare.length + soundsToPrepare.length + musicToPrepare.length + songsToPrepare.length;
		loaded = 0;

		#if (!target.threaded)
		for (sound in soundsToPrepare)
		{
			try
			{
				var ret:Dynamic = Paths.sound(sound);
				if (ret != null)
					trace('finished preloading sound $sound');
				else
					trace('ERROR! fail on preloading sound $sound');
			}
			catch (e:Dynamic)
			{
				trace('ERROR! fail on preloading sound $sound');
			}
			loaded++;
		}

		for (music in musicToPrepare)
		{
			try
			{
				var ret:Dynamic = Paths.music(music);
				if (ret != null)
					trace('finished preloading music $music');
				else
					trace('ERROR! fail on preloading music $music');
			}
			catch (e:Dynamic)
			{
				trace('ERROR! fail on preloading music $music');
			}
			loaded++;
		}

		for (song in songsToPrepare)
		{
			try
			{
				var ret:Dynamic = Paths.returnSound(null, 'songs/$song');
				if (ret != null)
					trace('finished preloading song $song');
				else
					trace('ERROR! fail on preloading song $song');
			}
			catch (e:Dynamic)
			{
				trace('ERROR! fail on preloading song $song');
			}
			loaded++;
		}

		for (image in imagesToPrepare)
		{
			try
			{
				var bitmap:BitmapData = null;
				var file:String = null;

				#if FEATURE_MODS
				file = Paths.modsImages(image);
				if (Paths.currentTrackedAssets.exists(file))
				{
					loaded++;
					continue;
				}
				else if (FileSystem.exists(file))
					bitmap = Paths.getBitmapDataFromFile(file);
				else
				#end
				{
					#if USING_GPU_TEXTURES
					file = Paths.getPath('images/$image.${Paths.GPU_IMAGE_EXT}', Paths.getImageAssetType(Paths.GPU_IMAGE_EXT));
					if (Paths.currentTrackedAssets.exists(file))
					{
						loaded++;
						continue;
					}
					else if (FileSystem.exists(file))
						bitmap = Paths.getBitmapDataFromFile(file);
					else
					#end
					{
						file = Paths.getPath('images/$image.${Paths.IMAGE_EXT}', Paths.getImageAssetType(Paths.IMAGE_EXT));
						if (Paths.currentTrackedAssets.exists(file))
						{
							loaded++;
							continue;
						}
						else if (FileSystem.exists(file))
							bitmap = Paths.getBitmapDataFromFile(file);
						else
						{
							trace('no such image $image exists');
							loaded++;
							continue;
						}
					}
				}

				if (bitmap != null)
					requestedBitmaps.set(file, bitmap);
				else
					trace('oh no the image is null NOOOO ($image)');
			}
			catch (e:Dynamic)
			{
				trace('ERROR! fail on preloading image $image');
			}
			loaded++;
		}
		#else
		for (sound in soundsToPrepare)
			initThread(() -> Paths.sound(sound), 'sound $sound');
		for (music in musicToPrepare)
			initThread(() -> Paths.music(music), 'music $music');
		for (song in songsToPrepare)
			initThread(() -> Paths.returnSound(null, 'songs/$song'), 'song $song');

		for (image in imagesToPrepare)
		{
			#if (target.threaded)
			Thread.create(() -> {
			#end
				#if (target.threaded)
				mutex.acquire();
				#end
				try
				{
					var bitmap:BitmapData = null;
					var file:String = null;

					#if FEATURE_MODS
					file = Paths.modsImages(image);
					if (Paths.currentTrackedAssets.exists(file))
					{
						#if (target.threaded)
						mutex.release();
						loadedMutex.acquire();
						#end
						loaded++;
						#if (target.threaded)
						loadedMutex.release();
						#end
						return;
					}
					else if (FileSystem.exists(file))
						bitmap = Paths.image(file).bitmap;
					else
					#end
					{
						#if USING_GPU_TEXTURES
						file = Paths.getPath('images/$image.${Paths.GPU_IMAGE_EXT}', Paths.getImageAssetType(Paths.GPU_IMAGE_EXT));
						if (Paths.currentTrackedAssets.exists(file))
						{
							#if (target.threaded)
							mutex.release();
							loadedMutex.acquire();
							#end
							loaded++;
							#if (target.threaded)
							loadedMutex.release();
							#end
							return;
						}
						else if (FileSystem.exists(file))
							bitmap = Paths.image(file).bitmap;
						else
						#end
						{
							file = Paths.getPath('images/$image.${Paths.IMAGE_EXT}', Paths.getImageAssetType(Paths.IMAGE_EXT));
							if (Paths.currentTrackedAssets.exists(file))
							{
								#if (target.threaded)
								mutex.release();
								loadedMutex.acquire();
								#end
								loaded++;
								#if (target.threaded)
								loadedMutex.release();
								#end
								return;
							}
							else if (FileSystem.exists(file))
								bitmap = Paths.image(file).bitmap;
							else
							{
								trace('no such image $image exists');
								#if (target.threaded)
								mutex.release();
								loadedMutex.acquire();
								#end
								loaded++;
								#if (target.threaded)
								loadedMutex.release();
								#end
								return;
							}
						}
					}
					#if (target.threaded)
					mutex.release();
					#end

					if (bitmap != null)
						requestedBitmaps.set(file, bitmap);
					else
						trace('oh no the image is null NOOOO ($image)');
				}
				catch (e:Dynamic)
				{
					#if (target.threaded)
					mutex.release();
					#end
					trace('ERROR! fail on preloading image $image');
				}
				#if (target.threaded)
				loadedMutex.acquire();
				#end
				loaded++;
				#if (target.threaded)
				loadedMutex.release();
				#end
			#if (target.threaded)
			});
			#end
		}
		#end
	}

	static function initThread(func:Void->Dynamic, traceData:String)
	{
		#if (target.threaded)
		Thread.create(() -> {
		#end
			#if (target.threaded)
			mutex.acquire();
			#end
			try
			{
				var ret:Dynamic = func();
				if (ret != null)
					trace('finished preloading $traceData');
				else
					trace('ERROR! fail on preloading $traceData');
			}
			catch (e:Dynamic)
			{
				trace('ERROR! fail on preloading $traceData');
			}
			#if (target.threaded)
			mutex.release();
			#end

			#if (target.threaded)
			loadedMutex.acquire();
			#end
			loaded++;
			#if (target.threaded)
			loadedMutex.release();
			#end
		#if (target.threaded)
		});
		#end
	}

	inline private static function preloadCharacter(char:String, ?prefixVocals:String)
	{
		try
		{
			var path:String = Paths.getPath('characters/$char.json', TEXT, null, true);
			var character:Dynamic = Json.parse(File.getContent(path), path);

			imagesToPrepare.push(character.image);
			if (prefixVocals != null && character.vocals_file != null)
			{
				songsToPrepare.push(prefixVocals + "-" + character.vocals_file + Difficulty.getSongPrefix());
				if (char == PlayState.SONG.player1)
					dontPreloadDefaultVoices = true;
			}
		}
		catch (e:Dynamic)
		{
		}
	}
}
