package backend;

import openfl.utils.Assets;
import backend.Section;
import haxe.DynamicAccess;
import openfl.media.Sound;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;

	@:optional var disableNoteCustomColor:Bool;

	@:optional var songName:String; // the name to show, like Funkin's metadata
	@:optional var artist:String;
	@:optional var charter:String;
	@:optional var variant:String;

	@:optional var gameOverChar:String;
	@:optional var gameOverSound:String;
	@:optional var gameOverLoop:String;
	@:optional var gameOverEnd:String;

	@:optional var arrowSkin:String;
	@:optional var playerArrowSkin:String;
	@:optional var opponentArrowSkin:String;
	@:optional var splashSkin:String;

	@:optional var format:String;

	@:optional var offsets:SongOffsets;
}

/**
 * Audio offsets in milliseconds, as in Funkin's song metadata.
 * A negative instrumental offset starts the instrumental before the chart.
 */
typedef SongOffsets =
{
	@:optional var instrumental:Float;
	@:optional var altInstrumentals:DynamicAccess<Float>;
	@:optional var vocals:DynamicAccess<Float>;
	@:optional var altVocals:DynamicAccess<DynamicAccess<Float>>;
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var events:Array<Dynamic>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var playerArrowSkin:String;
	public var opponentArrowSkin:String;
	public var splashSkin:String;
	public var gameOverChar:String;
	public var gameOverSound:String;
	public var gameOverLoop:String;
	public var gameOverEnd:String;
	public var disableNoteRGB(get, set):Bool;
	public var disableNoteCustomColor:Bool = false;
	public var speed:Float = 1;
	public var stage:String;
	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';

	private static function onLoadJson(songJson:Dynamic) // Convert old charts to newest format, or convert new format to old format?
	{
		if (songJson.format == null)
			songJson.format = 'psych_legacy';

		if (songJson.gfVersion == null && songJson.player3 != null)
		{
			songJson.gfVersion = songJson.player3;
			songJson.player3 = null;
		}

		// backwards compatibility
		if (songJson.arrowSkin != null && (songJson.playerArrowSkin == null || songJson.opponentArrowSkin == null))
		{
			songJson.playerArrowSkin = songJson.opponentArrowSkin = songJson.arrowSkin;
			songJson.arrowSkin == null;
		}

		if (songJson.disableNoteRGB != null)
		{
			songJson.disableNoteCustomColor = songJson.disableNoteRGB;
			songJson.disableNoteRGB = null;
		}

		if (StringTools.startsWith(songJson.format, 'psych_v1'))
			songJson.format = 'psych_v1';

		if (songJson.events == null && songJson.format == 'psych_legacy')
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while (i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if (note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
						continue;
					}
					i++;
				}
			}
		}
	}

	public static function getInstrumentalOffset(song:SwagSong, ?instrumental:String):Float
	{
		final offsets:Null<SongOffsets> = song.offsets;
		if (offsets == null)
			return 0;

		if (instrumental != null && offsets.altInstrumentals != null && offsets.altInstrumentals.exists(instrumental))
			return offsets.altInstrumentals.get(instrumental);

		return offsets.instrumental ?? 0;
	}

	public static function getVocalOffset(song:SwagSong, charId:String, ?instrumental:String):Float
	{
		final offsets:Null<SongOffsets> = song.offsets;
		if (offsets == null)
			return 0;

		final vocals:Null<DynamicAccess<Float>> = instrumental == null ? offsets.vocals : (offsets.altVocals != null ? offsets.altVocals.get(instrumental) : null);
		if (vocals == null || !vocals.exists(charId))
			return 0;

		return vocals.get(charId);
	}

	/**
	 * The audio suffixes to try for a song, most specific first: its mix, then Erect, then none.
	 */
	public static function audioSuffixes(?variant:String):Array<Null<String>>
	{
		if (variant != null && variant.length == 0)
			variant = null;
		final erect:Null<String> = Difficulty.getSongPrefix(null, false);
		final list:Array<Null<String>> = [];

		if (variant != null && erect != null)
			list.push('$variant-$erect');
		if (variant != null)
			list.push(variant);
		if (erect != null)
			list.push(erect);
		list.push(null);

		return list;
	}

	public static function findInst(song:String, ?variant:String, ?altInstrumental:String):Null<Sound>
	{
		if (altInstrumental != null)
		{
			final snd:Null<Sound> = Paths.inst(song, altInstrumental);
			if (snd != null)
				return snd;
		}

		for (suffix in audioSuffixes(variant))
		{
			final snd:Null<Sound> = Paths.inst(song, suffix);
			if (snd != null)
				return snd;
		}
		return null;
	}

	public static function findVocals(song:String, ?variant:String, ?name:String):Null<Sound>
	{
		if (name != null && name.length == 0)
			return null;

		for (suffix in audioSuffixes(variant))
		{
			final postfix:Null<String> = (name != null && suffix != null) ? '$name-$suffix' : (name ?? suffix);
			final snd:Null<Sound> = Paths.voices(song, postfix);
			if (snd != null)
				return snd;
		}
		return null;
	}

	/**
	 * The mixes of a song with a chart for a difficulty, from its `data/song/mix/` folders.
	 * The default mix comes first.
	 */
	public static function listMixes(songPath:String, difficulty:Int):Array<String>
	{
		final chart:String = Highscore.formatSong(songPath, difficulty) + '.json';
		final mixes:Array<String> = [substates.FreeplayOptionsSubState.DEFAULT_MIX];
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'data/$songPath/'))
		{
			for (file in FileSystem.readDirectory(folder))
			{
				if (!mixes.contains(file) && FileSystem.isDirectory(folder + file) && FileSystem.exists('$folder$file/$chart'))
					mixes.push(file);
			}
		}
		return mixes;
	}

	/**
	 * The `data/` folder of a song's chart, with its mix folder if it has one.
	 */
	public static function chartFolder(song:SwagSong):String
	{
		final folder:String = Paths.formatToSongPath(song.song);
		return (song.variant?.length > 0) ? '$folder/${song.variant}' : folder;
	}

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		var path:String = "";
		var rawJson:String = null;
		#if FEATURE_MODS
		var modPath:String = Paths.modsJson(formattedFolder + '/' + formattedSong);
		if (FileSystem.exists(modPath))
		{
			path = modPath;
			rawJson = File.getContent(modPath).trim();
		}
		#end

		if (rawJson == null)
		{
			path = Paths.json(formattedFolder + '/' + formattedSong);
			rawJson = File.getContent(path).trim();
		}

		// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		if (rawJson != null)
			while (!rawJson.endsWith("}"))
				rawJson = rawJson.substr(0, rawJson.length - 1);

		var songJson:Dynamic = parseJSONshit(rawJson, path);

		if (!jsonInput.startsWith("events"))
			StageData.loadDirectory(songJson);

		onLoadJson(songJson);
		return songJson;
	}

	public static function parseJSONshit(rawJson:String, ?file:String):SwagSong
	{
		final parsed:Dynamic = Json.parse(rawJson, file);

		if (parsed.song != null)
		{
			if (Std.isOfType(parsed.song, String))
			{
				parsed.format ??= 'psych_v1';
				return parsed;
			}

			parsed.song.format = 'psych_legacy';
			return parsed.song;
		}

		if (parsed.events != null)
		{
			return {
				events: cast parsed.events,
				song: "",
				notes: [],
				bpm: 0,
				needsVoices: true,
				speed: 1,
				player1: "",
				player2: "",
				gfVersion: "",
				stage: "",
				format: 'psych_v1'
			};
		}

		throw new haxe.Exception("No song data found, or is invalid.");
	}

	function get_disableNoteRGB():Bool
		return disableNoteCustomColor;

	function set_disableNoteRGB(value:Bool):Bool
	{
		disableNoteCustomColor = value;
		return value;
	}
}
