package psychlua;

class ScoreFunctions
{
	// stupid bietch ass functions
	public static function implement(funk:FunkinLua)
	{
		var game:Dynamic = FunkinLua.getCurrentMusicState();

		funk.set("addScore", function(value:Int = 0)
		{
			cast(game, PlayState).songScore += value;
			cast(game, PlayState).recalculateRating();
		});
		funk.set("addMisses", function(value:Int = 0)
		{
			cast(game, PlayState).songMisses += value;
			cast(game, PlayState).recalculateRating();
		});
		funk.set("addHits", function(value:Int = 0)
		{
			cast(game, PlayState).songHits += value;
			cast(game, PlayState).recalculateRating();
		});
		funk.set("setScore", function(value:Int = 0)
		{
			cast(game, PlayState).songScore = value;
			cast(game, PlayState).recalculateRating();
		});
		funk.set("setMisses", function(value:Int = 0)
		{
			cast(game, PlayState).songMisses = value;
			cast(game, PlayState).recalculateRating();
		});
		funk.set("setHits", function(value:Int = 0)
		{
			cast(game, PlayState).songHits = value;
			cast(game, PlayState).recalculateRating();
		});
		funk.set("getScore", function()
		{
			return cast(game, PlayState).songScore;
		});
		funk.set("getMisses", function()
		{
			return cast(game, PlayState).songMisses;
		});
		funk.set("getHits", function()
		{
			return cast(game, PlayState).songHits;
		});
		funk.set("setHealth", function(value:Float = 0)
		{
			cast(game, PlayState).health = value;
		});
		funk.set("addHealth", function(value:Float = 0)
		{
			cast(game, PlayState).health += value;
		});
		funk.set("getHealth", function()
		{
			return cast(game, PlayState).health;
		});
	}
}
