// directly took from https://github.com/FunkinCrew/Funkin/blob/31dbd6819493fb8bae61d6e613c0dd69612f9cad/source/funkin/util/EaseUtil.hx

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
