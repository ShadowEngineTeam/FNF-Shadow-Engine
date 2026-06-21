package backend;

class Difficulty
{
	public static var defaultList(default, never):Array<Diff> = [EASY, NORMAL, HARD];
	public static var list:Array<Diff> = [];

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

		final fileSuffix:String = diff != NORMAL ? '-$diff' : '';
		return Paths.formatToSongPath(fileSuffix);
	}

	inline public static function loadFromWeek(?week:WeekData):Void
	{
		week ??= WeekData.getCurrentWeek();

		final diffStr:Array<Diff> = week.difficulties;
		diffStr?.length > 0 ? list = diffStr : resetList();
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
}

enum abstract Diff(String) from String to String
{
	final EASY:Diff = "easy";
	final NORMAL:Diff = "normal";
	final HARD:Diff = "hard";
	final ERECT:Diff = "erect";
	final NIGHTMARE:Diff = "nightmare";
}
