package backend;

import openfl.utils.Assets;
import backend.Section;

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

	@:optional var disableNoteRGB:Bool;

	@:optional var gameOverChar:String;
	@:optional var gameOverSound:String;
	@:optional var gameOverLoop:String;
	@:optional var gameOverEnd:String;

	@:optional var arrowSkin:String;
	@:optional var playerArrowSkin:String;
	@:optional var opponentArrowSkin:String;
	@:optional var splashSkin:String;

	@:optional var format:String;
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
	public var disableNoteRGB:Bool = false;
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

		// backwards compability
		if (songJson.arrowSkin != null && (songJson.playerArrowSkin == null || songJson.opponentArrowSkin == null))
		{
			songJson.playerArrowSkin = songJson.opponentArrowSkin = songJson.arrowSkin;
			songJson.arrowSkin == null;
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

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var formattedFolder:String  = Paths.formatToSongPath(folder);
		var formattedSong:String  = Paths.formatToSongPath(jsonInput);
		var path:String  = "";
		var rawJson:String = null;
		#if MODS_ALLOWED
		var modPath:String  = Paths.modsJson(formattedFolder + '/' + formattedSong);
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
}
