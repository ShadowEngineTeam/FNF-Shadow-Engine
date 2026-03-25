package backend;

@:nullSafety
class Highscore
{
	public static var weekScores:Map<String, Int> = new Map();
	public static var songScores:Map<String, Int> = new Map<String, Int>();
	public static var songRating:Map<String, Float> = new Map<String, Float>();

	public static function resetSong(song:String, diff:Int = 0):Void
	{
		var key:String = formatSong(song, diff);
		setScore(key, 0);
		setRating(key, 0);
	}

	public static function resetWeek(week:String, diff:Int = 0):Void
	{
		var key:String = formatSong(week, diff);
		setWeekScore(key, 0);
	}

	public static function saveScore(song:String, score:Int = 0, diff:Int = 0, rating:Float = -1):Void
	{
		if (song == null)
			return;
		var key:String = formatSong(song, diff);

		if (songScores.exists(key))
		{
			var existingScore = songScores.get(key);
			if (existingScore != null && existingScore < score)
			{
				setScore(key, score);
				if (rating >= 0)
					setRating(key, rating);
			}
		}
		else
		{
			setScore(key, score);
			if (rating >= 0)
				setRating(key, rating);
		}
	}

	public static function saveWeekScore(week:String, score:Int = 0, diff:Int = 0):Void
	{
		var key:String = formatSong(week, diff);

		if (weekScores.exists(key))
		{
			var existingScore = weekScores.get(key);
			if (existingScore != null && existingScore < score)
				setWeekScore(key, score);
		}
		else
			setWeekScore(key, score);
	}

	/**
	 * YOU SHOULD FORMAT SONG WITH formatSong() BEFORE TOSSING IN SONG VARIABLE
	 */
	static function setScore(song:String, score:Int):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songScores.set(song, score);
		FlxG.save.data.songScores = songScores;
		FlxG.save.flush();
	}

	static function setWeekScore(week:String, score:Int):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		weekScores.set(week, score);
		FlxG.save.data.weekScores = weekScores;
		FlxG.save.flush();
	}

	static function setRating(song:String, rating:Float):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songRating.set(song, rating);
		FlxG.save.data.songRating = songRating;
		FlxG.save.flush();
	}

	public static function formatSong(song:String, diff:Int):String
	{
		return Paths.formatToSongPath(song) + Difficulty.getFilePath(diff);
	}

	public static function getScore(song:String, diff:Int):Int
	{
		var key:String = formatSong(song, diff);
		if (!songScores.exists(key))
			setScore(key, 0);

		var result = songScores.get(key);
		return result != null ? result : 0;
	}

	public static function getRating(song:String, diff:Int):Float
	{
		var key:String = formatSong(song, diff);
		if (!songRating.exists(key))
			setRating(key, 0);

		var result = songRating.get(key);
		return result != null ? result : 0;
	}

	public static function getWeekScore(week:String, diff:Int):Int
	{
		var key:String = formatSong(week, diff);
		if (!weekScores.exists(key))
			setWeekScore(key, 0);

		var result = weekScores.get(key);
		return result != null ? result : 0;
	}

	public static function load():Void
	{
		if (FlxG.save.data.weekScores != null)
			weekScores = FlxG.save.data.weekScores;

		if (FlxG.save.data.songScores != null)
			songScores = FlxG.save.data.songScores;

		if (FlxG.save.data.songRating != null)
			songRating = FlxG.save.data.songRating;
	}
}
