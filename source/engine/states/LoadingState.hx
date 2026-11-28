package states;

import objects.Bar;
import lime.utils.Assets;
import openfl.display.BitmapData;
import openfl.media.Sound;
import backend.TaskHandler;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.FlxGraphic;
import backend.Song;
import backend.StageData;
#if ON_DEMAND_ASSETS
import backend.WebAssets;
#end
import objects.Character;

class LoadingState extends MusicBeatState
{
	public static var loaded:Int = 0;
	public static var loadMax:Int = 0;


	function new(target:Class<FlxState>, ?args:Array<Dynamic>, stopMusic:Bool)
	{
		this.target = target;
		this.args = args;
		this.stopMusic = stopMusic;
		#if ON_DEMAND_ASSETS
		startDownloads(startThreads);
		#else
		startThreads();
		#end

		super();
	}

	inline static public function loadAndSwitchState(target:Class<FlxState>, ?args:Array<Dynamic>, stopMusic = false, intrusive:Bool = true)
	{
		var loading = getNextState(target, args, stopMusic, intrusive);
		Funkin.switchState(loading.state, loading.args);
	}

	var target:Class<FlxState> = null;
	var args:Array<Dynamic> = null;
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

		bar = new Bar(0, 660, 'loadingBar', () -> progress());
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
			intendedPercent = progress();
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
		jsonsToPrepare = [];
		chartsToPrepare = [];

		FlxG.camera.visible = false;
		// FlxTransitionableState.skipNextTransIn = true;
		Funkin.switchState(target, args);
		transitioning = true;
		finishedLoading = true;
	}

	static function checkLoaded():Bool
	{
		TaskHandler.processMainThreadQueue();
		#if ON_DEMAND_ASSETS
		if (downloaded < downloadMax)
			return false;
		#end
		return (loaded == loadMax);
	}

	// The web can only wait for its downloads on the loading screen
	static var usesLoadingScreen(get, never):Bool;

	inline static function get_usesLoadingScreen():Bool
		return #if ON_DEMAND_ASSETS true #else ClientPrefs.data.loadingScreen #end;

	static function progress():Float
	{
		#if ON_DEMAND_ASSETS
		final total:Int = downloadMax + loadMax;
		return total > 0 ? (downloaded + loaded) / total : 1;
		#else
		return loaded / loadMax;
		#end
	}

	static function getNextState(target:Class<FlxState>, ?args:Array<Dynamic>, stopMusic = false, intrusive:Bool = true):{state:Class<FlxState>, args:Array<Dynamic>}
	{
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;

		if (weekDir != null && weekDir.length > 0 && weekDir != '')
			directory = weekDir;

		Paths.setCurrentLevel(directory);

		#if ON_DEMAND_ASSETS
		librariesToLoad = directory == 'shared' ? ['shared'] : ['shared', directory];
		WebAssets.unloadLibrariesExcept(librariesToLoad);

		clearInvalids();
		if (hasDownloads())
			return {state: LoadingState, args: [target, args, stopMusic]};
		#end

		var doPrecache:Bool = false;
		if (usesLoadingScreen)
		{
			clearInvalids();
			if (intrusive)
			{
				if (imagesToPrepare.length > 0 || soundsToPrepare.length > 0 || musicToPrepare.length > 0 || songsToPrepare.length > 0)
					return {state: LoadingState, args: [target, args, stopMusic]};
			}
			else
				doPrecache = true;
		}

		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		if (doPrecache)
		{
			// The main thread only waits here, so give the pool its core.
			TaskHandler.setBlocking(true);
			startThreads();
			while (true)
			{
				if (checkLoaded())
				{
					imagesToPrepare = [];
					soundsToPrepare = [];
					musicToPrepare = [];
					songsToPrepare = [];
					jsonsToPrepare = [];
					chartsToPrepare = [];
					TaskHandler.setBlocking(false);
					break;
				}
				else
					#if sys Sys.sleep(0.001); #else haxe.Timer.delay(() -> {}, 1); #end
			}
		}
		return {state: target, args: args};
	}

	static var imagesToPrepare:Array<String> = [];
	static var soundsToPrepare:Array<String> = [];
	static var musicToPrepare:Array<String> = [];
	static var songsToPrepare:Array<String> = [];
	// Parsed on the pool and handed to Paths.takeParsed(): texture atlas jsons, and song jsons (events).
	static var jsonsToPrepare:Array<String> = [];
	static var chartsToPrepare:Array<String> = [];

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
		if (!usesLoadingScreen)
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
		// PlayState reads it again, so give it this one.
		Paths.storeParsed(StageData.getStagePath(song.stage), stageData);
		if (stageData != null && stageData.preload != null)
			prepare((!ClientPrefs.data.lowQuality || stageData.preload.images_low) ? stageData.preload.images : stageData.preload.images_low,
				stageData.preload.sounds, stageData.preload.music);

		songsToPrepare.push('$folder/Inst' + Difficulty.getSongPrefix());

		var player1:String = song.player1;
		var player2:String = song.player2;
		var gfVersion:String = song.gfVersion;
		var needsVoices:Bool = song.needsVoices;
		var prefixVocals:String = needsVoices ? '$folder/Voices' : null;
		if (gfVersion == null)
			gfVersion = 'gf';

		dontPreloadDefaultVoices = false;
		preloadCharacter(player1, prefixVocals);
		if (player2 != player1)
			preloadCharacter(player2, prefixVocals);
		if (!stageData?.hide_girlfriend && gfVersion != player2 && gfVersion != player1)
			preloadCharacter(gfVersion);

		#if ON_DEMAND_ASSETS
		if (song.gameOverChar != null && song.gameOverChar.length > 0 && song.gameOverChar != player1)
			preloadCharacter(song.gameOverChar);
		#end

		if (!dontPreloadDefaultVoices && needsVoices)
			songsToPrepare.push(prefixVocals);

		final erect:Bool = Difficulty.list[PlayState.storyDifficulty] == ERECT || Difficulty.list[PlayState.storyDifficulty] == NIGHTMARE;
		final events:Null<{file:String, folder:String}> = Song.findEvents(song, erect);
		if (events != null)
			chartsToPrepare.push(Song.jsonPath(events.file, events.folder));
	}

	public static function clearInvalids()
	{
		clearInvalidFrom(imagesToPrepare, 'images', ['png'], IMAGE); // leaving this as is
		// clearInvalidFrom(imagesToPrepare, 'images', ['.${Paths.IMAGE_EXT}'], Paths.IMAGE_ASSETTYPE);
		clearInvalidFrom(soundsToPrepare, 'sounds', Paths.SOUND_EXTS, SOUND);
		clearInvalidFrom(musicToPrepare, 'music', Paths.SOUND_EXTS, SOUND);
		clearInvalidFrom(songsToPrepare, 'songs', Paths.SOUND_EXTS, SOUND);

		for (arr in [imagesToPrepare, soundsToPrepare, musicToPrepare, songsToPrepare])
			while (arr.contains(null))
				arr.remove(null);
	}

	static function clearInvalidFrom(arr:Array<String>, prefix:String, exts:Array<String>, type:AssetType, ?library:String = null)
	{
		for (i in 0...arr.length)
		{
			var folder:String = arr[i];
			if (folder.trim().endsWith('/'))
			{
				final roots:Array<String> = Paths.getBaseFolders();
				for (r in 0...roots.length)
					for (subfolder in Mods.directoriesWithFile(roots[r], '$prefix/$folder', r == roots.length - 1))
						for (file in FileSystem.readDirectory(subfolder))
							for (ext in exts)
								if (file.endsWith(ext))
								{
									arr.push(folder + file.substr(0, file.length - ext.length));
									break;
								}

				// trace('Folder detected! ' + folder);
			}
		}

		var i:Int = 0;
		while (i < arr.length)
		{
			var member:String = arr[i];
			var valid:Bool = false;
			for (ext in exts)
			{
				var myKey = '$prefix/$member.$ext';
				if (Paths.fileExists(myKey, type, false, library))
				{
					valid = true;
					break;
				}
			}

			if (member.endsWith('/') || !valid)
			{
				arr.remove(member);
				if (!member.endsWith('/'))
					trace('Removed invalid $prefix: $member');
			}
			else
				i++;
		}
	}

	public static function startThreads()
	{
		final images:Array<String> = unique(imagesToPrepare);
		final sounds:Array<{path:Null<String>, key:String}> = [];
		for (sound in unique(soundsToPrepare))
			sounds.push({path: 'sounds', key: sound});
		for (music in unique(musicToPrepare))
			sounds.push({path: 'music', key: music});
		for (song in unique(songsToPrepare))
			sounds.push({path: null, key: 'songs/$song'});

		final jsons:Array<String> = unique(jsonsToPrepare);
		final charts:Array<String> = unique(chartsToPrepare);

		loadMax = images.length + sounds.length + jsons.length + charts.length;
		loaded = 0;

		for (sound in sounds)
			preloadSound(sound.path, sound.key);
		for (image in images)
			preloadImage(image, jsons);
		for (json in jsons)
			preloadJson(json, false);
		for (chart in charts)
			preloadJson(chart, true);
	}

	#if ON_DEMAND_ASSETS
	static var librariesToLoad:Array<String> = [];
	static var downloaded:Int = 0;
	static var downloadMax:Int = 0;

	static function filesToDownload():Array<String>
	{
		final files:Array<String> = [];
		function add(file:Null<String>):Void
		{
			if (file != null && !files.contains(file) && WebAssets.needsDownload(file))
				files.push(file);
		}

		// Images come with their atlas files, and texture atlases are folders
		for (image in unique(imagesToPrepare))
			for (folder in Paths.getBaseFolders())
				for (file in WebAssets.filesToDownload(folder + 'images/' + image))
					add(file);
		for (json in unique(jsonsToPrepare))
			add(json);
		for (sound in unique(soundsToPrepare))
			add(Paths.findSoundFile('sounds', sound)?.file);
		for (music in unique(musicToPrepare))
			add(Paths.findSoundFile('music', music)?.file);
		for (song in unique(songsToPrepare))
			add(Paths.findSoundFile(null, 'songs/$song')?.file);
		return files;
	}

	static function hasDownloads():Bool
	{
		for (library in librariesToLoad)
			if (!WebAssets.isLibraryLoaded(library))
				return true;
		return filesToDownload().length > 0;
	}

	// Downloads the libraries and files the state needs, then calls `callback` to decode them.
	static function startDownloads(callback:Void->Void):Void
	{
		final files:Array<String> = filesToDownload();
		final libraries:Array<String> = librariesToLoad.filter(library -> !WebAssets.isLibraryLoaded(library));

		downloaded = 0;
		downloadMax = libraries.length + files.length;
		loaded = 0;
		loadMax = unique(imagesToPrepare).length + unique(soundsToPrepare).length + unique(musicToPrepare).length + unique(songsToPrepare).length
			+ unique(jsonsToPrepare).length + unique(chartsToPrepare).length;

		if (downloadMax == 0)
		{
			callback();
			return;
		}

		function done():Void
		{
			downloaded++;
			if (downloaded == downloadMax)
				callback();
		}

		for (library in libraries)
			WebAssets.loadLibrary(library, done);
		for (file in files)
			WebAssets.download(file, done);
	}
	#end

	static function unique(list:Array<String>):Array<String>
	{
		final result:Array<String> = [];
		for (item in list)
			if (!result.contains(item))
				result.push(item);
		return result;
	}

	// The pool only finds and decodes files; the caches are filled on the main thread.
	static function preloadSound(path:Null<String>, key:String):Void
	{
		TaskHandler.run(() ->
		{
			var found:Null<{key:String, file:String, mod:Bool}> = null;
			var sound:Null<Sound> = null;
			var error:Null<Dynamic> = null;

			try
			{
				found = Paths.findSoundFile(path, key);
				if (found != null)
					sound = found.mod ? Sound.fromFile(found.file) : Sound.fromBytes(File.getBytes(found.file));
			}
			catch (e:Dynamic)
				error = e;

			TaskHandler.toMainThread(() ->
			{
				if (sound != null)
				{
					Paths.cacheSound(found.key, sound);
					trace('finished preloading ${path ?? 'song'} $key');
				}
				else
					trace('ERROR! fail on preloading ${path ?? 'song'} $key${error != null ? ': $error' : ''}');

				#if ON_DEMAND_ASSETS
				if (found != null && !found.mod)
					WebAssets.release(found.file);
				#end

				loaded++;
			});
		});
	}

	// `jsons` is only read here; spritemap jsons are parsed there instead of as sprite sheets.
	static function preloadImage(image:String, jsons:Array<String>):Void
	{
		TaskHandler.run(() ->
		{
			var file:Null<String> = null;
			var bitmap:Null<BitmapData> = null;
			var bytes:Null<haxe.io.Bytes> = null;
			var atlasFile:Null<String> = null;
			var atlas:Null<Dynamic> = null;
			var error:Null<Dynamic> = null;

			try
			{
				file = Paths.findImageFile(image);
				if (file != null)
				{
					bytes = File.getBytes(file);
					// Compressed GPU textures are uploaded when they are created, which has to happen on the main thread.
					if (bytes != null #if USING_GPU_TEXTURES && !Paths.isGpuImageExt(file) #end)
					{
						bitmap = BitmapData.fromBytes(bytes);
						bytes = null;
					}
				}

				atlasFile = Paths.findAtlasFile(image);
				if (atlasFile != null && !jsons.contains(atlasFile))
					atlas = Paths.parseAtlasFile(atlasFile);
			}
			catch (e:Dynamic)
				error = e;

			TaskHandler.toMainThread(() ->
			{
				if (atlas != null)
					Paths.storeParsed(atlasFile, atlas);

				try
				{
					if (file == null)
						trace(error != null ? 'ERROR! fail on preloading image $image: $error' : 'no such image $image exists');
					else if (Paths.currentTrackedAssets.exists(file))
						bitmap?.dispose();
					else
					{
						if (bitmap == null && bytes != null)
							bitmap = BitmapData.fromBytes(bytes);

						if (bitmap != null && Paths.cacheBitmap(file, bitmap) != null)
							trace('finished preloading image $file');
						else
							trace('failed to cache image $file');
					}
				}
				catch (e:Dynamic)
					trace('ERROR! fail on preloading image $image: $e');

				#if (ON_DEMAND_ASSETS && !USING_GPU_TEXTURES)
				if (file != null)
					WebAssets.release(file);
				#end

				loaded++;
			});
		});
	}

	static function preloadJson(file:String, chart:Bool):Void
	{
		TaskHandler.run(() ->
		{
			var data:Null<Dynamic> = null;
			var error:Null<Dynamic> = null;

			try
			{
				data = chart ? Song.parseJsonFile(file) : Json.parse(File.getContent(file).replace(String.fromCharCode(0xFEFF), ''), file);
			}
			catch (e:Dynamic)
				error = e;

			TaskHandler.toMainThread(() ->
			{
				if (data != null)
				{
					Paths.storeParsed(file, data);
					trace('finished preloading $file');
				}
				else
					trace('ERROR! fail on preloading $file${error != null ? ': $error' : ''}');

				loaded++;
			});
		});
	}

	// Texture atlases are folders, so preload their spritemaps and jsons.
	static function prepareCharacterImage(image:String):Void
	{
		if (!Paths.isTextureAtlas(image))
		{
			imagesToPrepare.push(image);
			return;
		}

		var folder:String = Paths.getPath('images/$image');
		#if FEATURE_MODS
		final modFolder:String = Paths.modFolders('images/$image');
		if (FileSystem.exists(modFolder) && FileSystem.isDirectory(modFolder))
			folder = modFolder;
		#end

		if (!FileSystem.isDirectory(folder))
			return;

		// The same paths FlxAnimateFrames reads.
		for (file in ['Animation.json', 'metadata.json'])
			if (FileSystem.exists('$folder/$file'))
				jsonsToPrepare.push('$folder/$file');

		for (file in FileSystem.readDirectory(folder))
			if (file.startsWith('spritemap') && file.endsWith('.json'))
			{
				imagesToPrepare.push('$image/${file.substr(0, file.length - '.json'.length)}');
				jsonsToPrepare.push('$folder/$file');
			}
	}

	inline private static function preloadCharacter(char:String, ?prefixVocals:String)
	{
		try
		{
			var path:String = Paths.getPath('characters/$char.json', TEXT, null, true);
			var character:Dynamic = Json.parse(File.getContent(path), path);
			// Character reads it again, so give it this one.
			Paths.storeParsed(path, character);

			var images:Array<String> = [];
			if (character.image is String)
				images.push(character.image);
			else if (character.image != null)
				images = character.image;
			else if (character.assetPath is String) // V-Slice
				images.push((character.assetPath : String).replace('shared:', ''));

			for (image in images)
				prepareCharacterImage(image);
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
