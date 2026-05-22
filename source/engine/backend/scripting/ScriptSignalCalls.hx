package backend.scripting;

import backend.IMusicState;
import flixel.FlxG;

class ScriptSignalCalls
{
	public static var initialized:Bool = false;

	public static function init()
	{
		if (initialized)
			return;
		initialized = true;

		FlxG.signals.focusGained.add(function()
		{
			callOnState("onFocusGained");
		});
		FlxG.signals.focusLost.add(function()
		{
			callOnState("onFocusLost");
		});
		FlxG.signals.gameResized.add(function(w:Int, h:Int)
		{
			callOnState("onGameResized", [w, h]);
		});
		FlxG.signals.postDraw.add(function()
		{
			callOnState("onDrawPost");
		});
		FlxG.signals.postStateSwitch.add(function()
		{
			callOnState("onStateSwitchPost");
		});
		FlxG.signals.preDraw.add(function()
		{
			callOnState("onDrawPre");
		});
		FlxG.signals.preStateCreate.add(function(state:flixel.FlxState)
		{
			var musicState:IMusicState = cast(state, IMusicState);
			if (musicState != null)
				musicState.callOnScripts("onStateCreatePre", [state]);
		});
		FlxG.signals.preStateSwitch.add(function()
		{
			callOnState("onStateSwitchPre");
		});
	}

	static function callOnState(funcToCall:String, args:Array<Dynamic> = null)
	{
		if (args == null)
			args = [];

		var curState = FlxG.state;
		if (curState != null)
		{
			var musicState:IMusicState = cast(curState, IMusicState);
			if (musicState != null)
				musicState.callOnScripts(funcToCall, args);

			var subState = curState.subState;
			if (subState != null)
			{
				var musicSubState:IMusicState = cast(subState, IMusicState);
				if (musicSubState != null)
					musicSubState.callOnScripts(funcToCall, args);
			}
		}
	}
}
