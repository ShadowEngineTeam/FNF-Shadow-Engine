package backend;

import backend.scripting.*;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxSave;
import backend.rendering.PsychCamera;
import haxe.io.Path;

/**
 * A static engine functions and global objects instances holder.
 */
class Funkin
{
	public static var controls(get, never):Controls;

    public static function switchState(nextState:Class<FlxState>, ?arguments:Array<Dynamic>):Void
	{
		if (nextState == null)
		{
			Funkin.resetState();
			return;
		}

		var nextStateInstance:FlxState = backend.scripting.ModsStateRedirect.redirect(nextState, arguments ?? []);

		if (nextStateInstance == FlxG.state)
		{
			resetState();
			return;
		}

		if (FlxTransitionableState.skipNextTransIn)
			FlxG.switchState(nextStateInstance);
		else
			startTransition(nextStateInstance);
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function resetState()
	{
		if (FlxTransitionableState.skipNextTransIn)
			FlxG.resetState();
		else
			startTransition();
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function startTransition(nextState:FlxState = null)
	{
		if (nextState == null)
		{
			Funkin.resetState();
			return;
		}

		FlxG.state.openSubState(new CustomFadeTransition(0.6, false));
		if (nextState == FlxG.state)
			CustomFadeTransition.finishCallback = function() FlxG.resetState();
		else
			CustomFadeTransition.finishCallback = function() FlxG.switchState(nextState);
	}

	private static function get_controls()
	{
		return Controls.instance;
	}
}