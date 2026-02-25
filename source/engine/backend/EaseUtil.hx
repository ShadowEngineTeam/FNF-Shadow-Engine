package backend;

class EaseUtil
{
	public static inline function stepped(steps:Int):Float->Float
	{
		return function(t:Float):Float
		{
			return Math.floor(t * steps) / steps;
		}
	}
}
