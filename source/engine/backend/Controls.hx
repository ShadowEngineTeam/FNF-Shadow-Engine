package backend;

import flixel.input.gamepad.FlxGamepadButton;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.mappings.FlxGamepadMapping;
import flixel.input.keyboard.FlxKey;

@:nullSafety
class Controls
{
	// Pressed buttons (directions)
	public var UI_UP_P(get, never):Bool;
	public var UI_DOWN_P(get, never):Bool;
	public var UI_LEFT_P(get, never):Bool;
	public var UI_RIGHT_P(get, never):Bool;
	public var NOTE_UP_P(get, never):Bool;
	public var NOTE_DOWN_P(get, never):Bool;
	public var NOTE_LEFT_P(get, never):Bool;
	public var NOTE_RIGHT_P(get, never):Bool;

	// Held buttons (directions)
	public var UI_UP(get, never):Bool;
	public var UI_DOWN(get, never):Bool;
	public var UI_LEFT(get, never):Bool;
	public var UI_RIGHT(get, never):Bool;
	public var NOTE_UP(get, never):Bool;
	public var NOTE_DOWN(get, never):Bool;
	public var NOTE_LEFT(get, never):Bool;
	public var NOTE_RIGHT(get, never):Bool;

	// Released buttons (directions)
	public var UI_UP_R(get, never):Bool;
	public var UI_DOWN_R(get, never):Bool;
	public var UI_LEFT_R(get, never):Bool;
	public var UI_RIGHT_R(get, never):Bool;
	public var NOTE_UP_R(get, never):Bool;
	public var NOTE_DOWN_R(get, never):Bool;
	public var NOTE_LEFT_R(get, never):Bool;
	public var NOTE_RIGHT_R(get, never):Bool;

	// Pressed buttons (others)
	public var ACCEPT(get, never):Bool;
	public var BACK(get, never):Bool;
	public var PAUSE(get, never):Bool;
	public var RESET(get, never):Bool;

	inline function get_UI_UP_P()
		return justPressed('ui_up');

	inline function get_UI_DOWN_P()
		return justPressed('ui_down');

	inline function get_UI_LEFT_P()
		return justPressed('ui_left');

	inline function get_UI_RIGHT_P()
		return justPressed('ui_right');

	inline function get_NOTE_UP_P()
		return justPressed('note_up');

	inline function get_NOTE_DOWN_P()
		return justPressed('note_down');

	inline function get_NOTE_LEFT_P()
		return justPressed('note_left');

	inline function get_NOTE_RIGHT_P()
		return justPressed('note_right');

	inline function get_UI_UP()
		return pressed('ui_up');

	inline function get_UI_DOWN()
		return pressed('ui_down');

	inline function get_UI_LEFT()
		return pressed('ui_left');

	inline function get_UI_RIGHT()
		return pressed('ui_right');

	inline function get_NOTE_UP()
		return pressed('note_up');

	inline function get_NOTE_DOWN()
		return pressed('note_down');

	inline function get_NOTE_LEFT()
		return pressed('note_left');

	inline function get_NOTE_RIGHT()
		return pressed('note_right');

	inline function get_UI_UP_R()
		return justReleased('ui_up');

	inline function get_UI_DOWN_R()
		return justReleased('ui_down');

	inline function get_UI_LEFT_R()
		return justReleased('ui_left');

	inline function get_UI_RIGHT_R()
		return justReleased('ui_right');

	inline function get_NOTE_UP_R()
		return justReleased('note_up');

	inline function get_NOTE_DOWN_R()
		return justReleased('note_down');

	inline function get_NOTE_LEFT_R()
		return justReleased('note_left');

	inline function get_NOTE_RIGHT_R()
		return justReleased('note_right');

	inline function get_ACCEPT()
		return justPressed('accept');

	inline function get_BACK()
		return justPressed('back');

	inline function get_PAUSE()
		return justPressed('pause');

	inline function get_RESET()
		return justPressed('reset');

	public var keyboardBinds:Map<String, Array<FlxKey>>;
	public var gamepadBinds:Map<String, Array<FlxGamepadInputID>>;
	#if FEATURE_MOBILE_CONTROLS
	public var mobileBinds:Map<String, Array<MobileInputID>>;
	#end

	public function justPressed(key:String):Bool
	{
		var kbBind = keyboardBinds[key];
		if (kbBind != null && FlxG.keys.anyJustPressed(kbBind))
		{
			controllerMode = false;
			return true;
		}

		var gpBind = gamepadBinds[key];
		if (gpBind != null && _checkGamepad(gpBind, FlxG.gamepads.anyJustPressed))
			return true;

		#if FEATURE_MOBILE_CONTROLS
		var mbBind = mobileBinds[key];
		if (mbBind != null && (mobileCJustPressed(mbBind) || touchPadJustPressed(mbBind)))
			return true;
		#end
		return false;
	}

	public function pressed(key:String):Bool
	{
		var kbBind = keyboardBinds[key];
		if (kbBind != null && FlxG.keys.anyPressed(kbBind))
		{
			controllerMode = false;
			return true;
		}

		var gpBind = gamepadBinds[key];
		if (gpBind != null && _checkGamepad(gpBind, FlxG.gamepads.anyPressed))
			return true;

		#if FEATURE_MOBILE_CONTROLS
		var mbBind = mobileBinds[key];
		if (mbBind != null && (mobileCPressed(mbBind) || touchPadPressed(mbBind)))
			return true;
		#end
		return false;
	}

	public function justReleased(key:String):Bool
	{
		var kbBind = keyboardBinds[key];
		if (kbBind != null && FlxG.keys.anyJustReleased(kbBind))
		{
			controllerMode = false;
			return true;
		}

		var gpBind = gamepadBinds[key];
		if (gpBind != null && _checkGamepad(gpBind, FlxG.gamepads.anyJustReleased))
			return true;

		#if FEATURE_MOBILE_CONTROLS
		var mbBind = mobileBinds[key];
		if (mbBind != null && (mobileCJustReleased(mbBind) || touchPadJustReleased(mbBind)))
			return true;
		#end
		return false;
	}

	public var controllerMode:Bool = false;

	function _checkGamepad(keys:Array<FlxGamepadInputID>, checkFn:FlxGamepadInputID->Bool):Bool
	{
		for (key in keys)
			if (checkFn(key) == true)
			{
				controllerMode = true;
				return true;
			}
		return false;
	}

	#if FEATURE_MOBILE_CONTROLS
	public var isInSubstate:Bool = false; // don't worry about this it becomes true and false on it's own in MusicBeatSubstate
	public var requestedInstance(get, default):Null<Dynamic> = null; // is set to MusicBeatState or MusicBeatSubstate when the constructor is called
	public var requestedMobileC(get, default):Null<IMobileControls> = null; // for PlayState and EditorPlayState (hitbox and touchPad)
	public var mobileC(get, never):Bool;

	private function touchPadPressed(keys:Array<MobileInputID>):Bool
	{
		var tp = requestedInstance?.touchPad;
		return keys != null && tp != null && tp.anyPressed(keys);
	}

	private function touchPadJustPressed(keys:Array<MobileInputID>):Bool
	{
		var tp = requestedInstance?.touchPad;
		return keys != null && tp != null && tp.anyJustPressed(keys);
	}

	private function touchPadJustReleased(keys:Array<MobileInputID>):Bool
	{
		var tp = requestedInstance?.touchPad;
		return keys != null && tp != null && tp.anyJustReleased(keys);
	}

	private function mobileCPressed(keys:Array<MobileInputID>):Bool
	{
		var mc = requestedMobileC;
		return keys != null && mc != null && mc.instance.anyPressed(keys);
	}

	private function mobileCJustPressed(keys:Array<MobileInputID>):Bool
	{
		var mc = requestedMobileC;
		return keys != null && mc != null && mc.instance.anyJustPressed(keys);
	}

	private function mobileCJustReleased(keys:Array<MobileInputID>):Bool
	{
		var mc = requestedMobileC;
		return keys != null && mc != null && mc.instance.anyJustReleased(keys);
	}

	@:noCompletion
	private function get_requestedInstance():Dynamic
		return isInSubstate ? MusicBeatSubstate.instance : MusicBeatState.getState();

	@:noCompletion
	private function get_requestedMobileC():IMobileControls
		return requestedInstance.mobileControls;

	@:noCompletion
	private function get_mobileC():Bool
		return ClientPrefs.data.controlsAlpha >= 0.1;
	#else
	public var isInSubstate:Bool = false;
	public var mobileC:Bool = false;
	#end

	public static var instance:Null<Controls> = null;

	public function new()
	{
		gamepadBinds = ClientPrefs.gamepadBinds;
		keyboardBinds = ClientPrefs.keyBinds;
		#if FEATURE_MOBILE_CONTROLS
		mobileBinds = ClientPrefs.mobileBinds;
		#end
	}
}
