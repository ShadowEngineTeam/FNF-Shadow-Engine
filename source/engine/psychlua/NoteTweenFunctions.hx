package psychlua;

import objects.StrumNote;
import flixel.tweens.FlxTween;

class NoteTweenFunctions
{
	// Tween shit, but for strums
	public static function implement(funk:FunkinLua)
	{
		var game:Dynamic = FunkinLua.getCurrentMusicState();

		funk.set("noteTweenX", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			LuaUtils.cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:StrumNote = cast(game, PlayState).strumLineNotes.members[note % cast(cast(game, PlayState).strumLineNotes.length, Int)];

			if (testicle != null)
			{
				game.modchartTweens.set(tag, FlxTween.tween(testicle, {x: value}, duration, {
					ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						game.callOnLuas('onTweenCompleted', [tag]);
						game.modchartTweens.remove(tag);
					}
				}));
			}
		});
		funk.set("noteTweenY", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			LuaUtils.cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:StrumNote = cast(game, PlayState).strumLineNotes.members[note % cast(cast(game, PlayState).strumLineNotes.length, Int)];

			if (testicle != null)
			{
				game.modchartTweens.set(tag, FlxTween.tween(testicle, {y: value}, duration, {
					ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						game.callOnLuas('onTweenCompleted', [tag]);
						game.modchartTweens.remove(tag);
					}
				}));
			}
		});
		funk.set("noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			LuaUtils.cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:StrumNote = cast(game, PlayState).strumLineNotes.members[note % cast(cast(game, PlayState).strumLineNotes.length, Int)];

			if (testicle != null)
			{
				game.modchartTweens.set(tag, FlxTween.tween(testicle, {angle: value}, duration, {
					ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						game.callOnLuas('onTweenCompleted', [tag]);
						game.modchartTweens.remove(tag);
					}
				}));
			}
		});
		funk.set("noteTweenDirection", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			LuaUtils.cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:StrumNote = cast(game, PlayState).strumLineNotes.members[note % cast(cast(game, PlayState).strumLineNotes.length, Int)];

			if (testicle != null)
			{
				game.modchartTweens.set(tag, FlxTween.tween(testicle, {direction: value}, duration, {
					ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						game.callOnLuas('onTweenCompleted', [tag]);
						game.modchartTweens.remove(tag);
					}
				}));
			}
		});
		funk.set("noteTweenAlpha", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			LuaUtils.cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:StrumNote = cast(game, PlayState).strumLineNotes.members[note % cast(cast(game, PlayState).strumLineNotes.length, Int)];

			if (testicle != null)
			{
				game.modchartTweens.set(tag, FlxTween.tween(testicle, {alpha: value}, duration, {
					ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						game.callOnLuas('onTweenCompleted', [tag]);
						game.modchartTweens.remove(tag);
					}
				}));
			}
		});
	}
}
