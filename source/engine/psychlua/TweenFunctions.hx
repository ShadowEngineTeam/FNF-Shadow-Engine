package psychlua;

import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import psychlua.LuaUtils.LuaTweenOptions;

class TweenFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var game:Dynamic = FunkinLua.getCurrentMusicState();

		// gay ass tweens
		funk.set("startTween", function(tag:String, vars:String, values:Any = null, duration:Float, options:Any = null)
		{
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if (penisExam != null)
			{
				if (values != null)
				{
					var myOptions:LuaTweenOptions = LuaUtils.getLuaTween(options);
					game.modchartTweens.set(tag, FlxTween.tween(penisExam, values, duration, {
						type: myOptions.type,
						ease: myOptions.ease,
						startDelay: myOptions.startDelay,
						loopDelay: myOptions.loopDelay,

						onUpdate: function(twn:FlxTween)
						{
							if (myOptions.onUpdate != null)
								game.callOnLuas(myOptions.onUpdate, [tag, vars]);
						},
						onStart: function(twn:FlxTween)
						{
							if (myOptions.onStart != null)
								game.callOnLuas(myOptions.onStart, [tag, vars]);
						},
						onComplete: function(twn:FlxTween)
						{
							if (myOptions.onComplete != null)
								game.callOnLuas(myOptions.onComplete, [tag, vars]);
							if (twn.type == FlxTweenType.ONESHOT || twn.type == FlxTweenType.BACKWARD)
								game.modchartTweens.remove(tag);
						}
					}));
				}
				else
				{
					FunkinLua.luaTrace('startTween: No values on 2nd argument!', false, false, FlxColor.RED);
				}
			}
			else
			{
				FunkinLua.luaTrace('startTween: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});

		funk.set("doTweenX", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			oldTweenFunction(tag, vars, {x: value}, duration, ease, 'doTweenX');
		});
		funk.set("doTweenY", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			oldTweenFunction(tag, vars, {y: value}, duration, ease, 'doTweenY');
		});
		funk.set("doTweenAngle", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			oldTweenFunction(tag, vars, {angle: value}, duration, ease, 'doTweenAngle');
		});
		funk.set("doTweenAlpha", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			oldTweenFunction(tag, vars, {alpha: value}, duration, ease, 'doTweenAlpha');
		});
		funk.set("doTweenZoom", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			oldTweenFunction(tag, vars, {zoom: value}, duration, ease, 'doTweenZoom');
		});
		funk.set("doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ease:String)
		{
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if (penisExam != null)
			{
				var curColor:FlxColor = penisExam.color;
				curColor.alphaFloat = penisExam.alpha;
				game.modchartTweens.set(tag, FlxTween.color(penisExam, duration, curColor, CoolUtil.colorFromString(targetColor), {
					ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						game.modchartTweens.remove(tag);
						game.callOnLuas('onTweenCompleted', [tag, vars]);
					}
				}));
			}
			else
			{
				FunkinLua.luaTrace('doTweenColor: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});

		funk.set("cancelTween", LuaUtils.cancelTween);
		funk.set("runTimer", function(tag:String, time:Float = 1, loops:Int = 1)
		{
			LuaUtils.cancelTimer(tag);
			game.modchartTimers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer)
			{
				if (tmr.finished)
				{
					game.modchartTimers.remove(tag);
				}
				final args:Array<Dynamic> = [tag, tmr.loops, tmr.loopsLeft];
				game.callOnLuas('onTimerCompleted', args);
				// trace('Timer Completed: ' + tag);
			}, loops));
		});
		funk.set("cancelTimer", LuaUtils.cancelTimer);
	}

	static function oldTweenFunction(tag:String, vars:String, tweenValue:Any, duration:Float, ease:String, funcName:String)
	{
		var target:Dynamic = LuaUtils.tweenPrepare(tag, vars);
		if (target != null)
		{
			FunkinLua.getCurrentMusicState().modchartTweens.set(tag, FlxTween.tween(target, tweenValue, duration, {
				ease: LuaUtils.getTweenEaseByString(ease),
				onComplete: function(twn:FlxTween)
				{
					FunkinLua.getCurrentMusicState().modchartTweens.remove(tag);
					FunkinLua.getCurrentMusicState().callOnLuas('onTweenCompleted', [tag, vars]);
				}
			}));
		}
		else
		{
			FunkinLua.luaTrace('$funcName: Couldnt find object: $vars', false, false, FlxColor.RED);
		}
	}
}
