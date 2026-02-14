package backend;

class Rating
{
	public var name:String = '';
	public var image:String = '';
	public var hitWindow:Null<Int> = 0; // ms
	public var ratingMod:Float = 1;
	//public var score(get, set):Int;
	public var noteSplash:Bool = true;
	public var hits:Int = 0;

	public static var MAX_SCORE:Int = 500;
	public static var SCORING_OFFSET:Float = 54.99;
	public static var SCORING_SLOPE:Float = 0.080;
	public static var MIN_SCORE:Float = 9.0;
	public static var MISS_SCORE:Int = -100;
	public static var PERFECT_THRESHOLD:Float = 5.0; // 5ms
	public static var SICK_THRESHOLD:Float = 45.0;
	public static var GOOD_THRESHOLD:Float = 90.0;
	public static var BAD_THRESHOLD:Float = 135.0;
	public static var SHIT_THRESHOLD:Float = 160.0;

	public function new(name:String)
	{
		this.name = name;
		this.image = name;
		this.hitWindow = 0;

		var window:String = name + 'Window';
		try
		{
			this.hitWindow = Reflect.field(ClientPrefs.data, window);
		}
		catch (e)
			FlxG.log.error(e);
	}

	public static function loadDefault():Array<Rating>
	{
		var ratingsData:Array<Rating> = [new Rating('sick')]; // highest rating goes first

		var rating:Rating = new Rating('good');
		rating.ratingMod = 0.67;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('bad');
		rating.ratingMod = 0.34;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('shit');
		rating.ratingMod = 0;
		rating.noteSplash = false;
		ratingsData.push(rating);
		return ratingsData;
	}

	public static function scoreNote(msTiming:Float):Int
	{
		var absTiming:Float = Math.abs(msTiming);
		return switch (absTiming)
		{
			case(_ < PERFECT_THRESHOLD) => true:
				MAX_SCORE;
			default:
				var factor:Float = 1.0 - (1.0 / (1.0 + Math.exp(-SCORING_SLOPE * (absTiming - SCORING_OFFSET))));
				var score:Int = Std.int(MAX_SCORE * factor + MIN_SCORE);
				score;
		}
	}

	public static function judgeNote(msTiming:Float):String
	{
		var absTiming:Float = Math.abs(msTiming);
		return switch (absTiming)
		{
			case(_ < SICK_THRESHOLD) => true:
				'sick';
			case(_ < GOOD_THRESHOLD) => true:
				'good';
			case(_ < BAD_THRESHOLD) => true:
				'bad';
			case(_ < SHIT_THRESHOLD) => true:
				'shit';
			default:
				'miss';
		}
	}

	/*@:noCompletion
	private function get_score():Int
		return MAX_SCORE;

	@:noCompletion
	private function set_score(value:Int):Int
	{
		MAX_SCORE = value;
		return value;
	}*/
}
