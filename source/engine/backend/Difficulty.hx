package backend;

class Difficulty
{
	public static var defaultList(default, never):Array<Diff> = [EASY, NORMAL, HARD];
	public static var list:Array<Diff> = [];

	inline public static function getString(?index:Int):String
		return Std.string(getByIndex(index));

	inline public static function getByIndex(?index:Int):Diff
	{
		index ??= PlayState.storyDifficulty;

		if (index < 0 || index >= list.length)
			return NORMAL;

		return list[index];
	}

	inline public static function getFilePath(?index:Int):String
	{
		index ??= PlayState.storyDifficulty;

		final diff:Diff = getByIndex(index);

		final fileSuffix:String = diff != NORMAL ? '-${diffToString(diff)}' : '';
		return Paths.formatToSongPath(fileSuffix);
	}

	inline public static function loadFromWeek(?week:WeekData):Void
	{
		week ??= WeekData.getCurrentWeek();

		final diffStr:Array<String> = week.difficulties;
		if (diffStr != null && diffStr.length > 0)
		{
			list = [];
			for (diff in diffStr)
				list.push(stringToDiff(diff));
		}
		else
			resetList();
	}

	inline public static function resetList():Void
		list = defaultList.copy();

	inline public static function copyFrom(diffs:Array<Diff>):Void
		list = diffs.copy();

	inline public static function getSongPrefix(?index:Int, ?includeDash:Bool = true):Null<String>
	{
		index ??= PlayState.storyDifficulty;

		final diff:Diff = getByIndex(index);

		if (diff == ERECT || diff == NIGHTMARE)
			return includeDash ? '-Erect' : 'Erect';

		return includeDash ? '' : null;
	}

	inline public static function diffToString(diff:Diff):String
	{
		switch (diff)
		{
			case EASY: return "easy";
			case NORMAL: return "normal";
			case HARD: return "hard";
			case ERECT: return "erect";
			case NIGHTMARE: return "nightmare";
			case CUSTOM(name): return name;
		}
	}

	inline public static function stringToDiff(str:String):Diff
	{
		switch (str.toLowerCase())
		{
			case "easy": return EASY;
			case "normal": return NORMAL;
			case "hard": return HARD;
			case "erect": return ERECT;
			case "nightmare": return NIGHTMARE;
			default: return CUSTOM(str);
		}
	}
}

enum Diff
{
	EASY;
	NORMAL;
	HARD;
	ERECT;
	NIGHTMARE;
	CUSTOM(name:String);
}