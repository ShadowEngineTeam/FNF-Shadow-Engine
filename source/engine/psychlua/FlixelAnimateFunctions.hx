package psychlua;

class FlixelAnimateFunctions
{
	public static function implement(funk:FunkinLua)
	{
		funk.set("addAnimationBySymbol", function(obj:String, name:String, symbol:String, framerate:Int = 24, loop:Bool = true)
		{
			var animate:ModchartSprite = LuaUtils.getObjectDirectly(obj, false);
			if (animate != null)
			{
				animate.anim.addBySymbol(name, symbol, framerate, loop);
				if (animate.anim.curAnim == null)
				{
					animate.anim.play(name, true);
				}
				return true;
			}
			return false;
		});

		funk.set("addAnimationBySymbolIndices", function(obj:String, name:String, symbol:String, indices:String, framerate:Int = 24, loop:Bool = true)
		{
			var animate:ModchartSprite = LuaUtils.getObjectDirectly(obj, false);
			if (animate != null)
			{
				animate.anim.addBySymbolIndices(name, symbol, formatIndices(indices), framerate, loop);
				if (animate.anim.curAnim == null)
				{
					animate.anim.play(name, true);
				}
				return true;
			}
			return false;
		});

		funk.set("addAnimationByFrameLabel", function(obj:String, name:String, label:String, framerate:Int = 24, loop:Bool = true)
		{
			var animate:ModchartSprite = LuaUtils.getObjectDirectly(obj, false);
			if (obj != null)
			{
				animate.anim.addByFrameLabel(name, label, framerate, loop);
				if (animate.anim.curAnim == null)
				{
					animate.anim.play(name, true);
				}
				return true;
			}
			return false;
		});

		funk.set("addAnimationByFrameLabelIndices", function(obj:String, name:String, label:String, indices:String, framerate:Int = 24, loop:Bool = true)
		{
			var animate:ModchartSprite = LuaUtils.getObjectDirectly(obj, false);
			if (animate != null)
			{
				animate.anim.addByFrameLabelIndices(name, label, formatIndices(indices), framerate, loop);
				if (animate.anim.curAnim == null)
				{
					animate.anim.play(name, true);
				}
				return true;
			}
			return false;
		});
	}

	public static inline function formatIndices(indices:String):Array<Int>
		return [for (i in indices.trim().split(',')) Std.parseInt(i)];
}
