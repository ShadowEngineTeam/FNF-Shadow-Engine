package mobile.psychlua;

import psychlua.CustomSubstate;
#if LUA_ALLOWED
import lime.ui.Haptic;
import psychlua.FunkinLua;
import psychlua.LuaUtils;
import mobile.backend.TouchUtil;
#if android import mobile.backend.PsychJNI; #end

/**
 * ...
 * @author: Karim Akra and Homura Akemi (HomuHomu833)
 */
class MobileFunctions
{
	public static function implement(funk:FunkinLua)
	{
		funk.set('mobileC', Controls.instance.mobileC);

		funk.set('mobileControlsMode', getMobileControlsAsString());

		funk.set("extraButtonPressed", (button:String) ->
		{
			button = button.toLowerCase();
			if (MusicBeatState.getState().mobileControls != null)
			{
				switch (button)
				{
					case 'second':
						return MusicBeatState.getState().mobileControls.buttonExtra2.pressed;
					default:
						return MusicBeatState.getState().mobileControls.buttonExtra.pressed;
				}
			}
			return false;
		});

		funk.set("extraButtonJustPressed", (button:String) ->
		{
			button = button.toLowerCase();
			if (MusicBeatState.getState().mobileControls != null)
			{
				switch (button)
				{
					case 'second':
						return MusicBeatState.getState().mobileControls.buttonExtra2.justPressed;
					default:
						return MusicBeatState.getState().mobileControls.buttonExtra.justPressed;
				}
			}
			return false;
		});

		funk.set("extraButtonJustReleased", (button:String) ->
		{
			button = button.toLowerCase();
			if (MusicBeatState.getState().mobileControls != null)
			{
				switch (button)
				{
					case 'second':
						return MusicBeatState.getState().mobileControls.buttonExtra2.justReleased;
					default:
						return MusicBeatState.getState().mobileControls.buttonExtra.justReleased;
				}
			}
			return false;
		});

		funk.set("extraButtonReleased", (button:String) ->
		{
			button = button.toLowerCase();
			if (MusicBeatState.getState().mobileControls != null)
			{
				switch (button)
				{
					case 'second':
						return MusicBeatState.getState().mobileControls.buttonExtra2.released;
					default:
						return MusicBeatState.getState().mobileControls.buttonExtra.released;
				}
			}
			return false;
		});

		funk.set("vibrate", (?duration:Int, ?period:Int) ->
		{
			if (duration == null)
				return FunkinLua.luaTrace('vibrate: No duration specified.');
			else if (period == null)
				period = 0;
			return Haptic.vibrate(period, duration);
		});

		funk.set("addTouchPad", (DPadMode:String, ActionMode:String, ?addToCustomSubstate:Bool = false, ?posAtCustomSubstate:Int = -1) ->
		{
			FunkinLua.getCurrentMusicState().makeLuaTouchPad(DPadMode, ActionMode);
			if (addToCustomSubstate)
			{
				if (FunkinLua.getCurrentMusicState().luaTouchPad != null || !FunkinLua.getCurrentMusicState().members.contains(FunkinLua.getCurrentMusicState().luaTouchPad))
					CustomSubstate.insertLuaTpad(posAtCustomSubstate);
			}
			else
				FunkinLua.getCurrentMusicState().addLuaTouchPad();
		});

		funk.set("removeTouchPad", () ->
		{
			FunkinLua.getCurrentMusicState().removeLuaTouchPad();
		});

		funk.set("addTouchPadCamera", (?defaultDrawTarget:Bool) ->
		{
			if (defaultDrawTarget == null)
				defaultDrawTarget = false;
			if (FunkinLua.getCurrentMusicState().luaTouchPad == null)
			{
				FunkinLua.luaTrace('addTouchPadCamera: Touch Pad does not exist.');
				return;
			}
			FunkinLua.getCurrentMusicState().addLuaTouchPadCamera(defaultDrawTarget);
		});

		funk.set("touchPadJustPressed", function(button:Dynamic):Bool
		{
			if (FunkinLua.getCurrentMusicState().luaTouchPad == null)
			{
				return false;
			}
			return FunkinLua.getCurrentMusicState().luaTouchPadJustPressed(button);
		});

		funk.set("touchPadPressed", function(button:Dynamic):Bool
		{
			if (FunkinLua.getCurrentMusicState().luaTouchPad == null)
			{
				return false;
			}
			return FunkinLua.getCurrentMusicState().luaTouchPadPressed(button);
		});

		funk.set("touchPadJustReleased", function(button:Dynamic):Bool
		{
			if (FunkinLua.getCurrentMusicState().luaTouchPad == null)
			{
				return false;
			}
			return FunkinLua.getCurrentMusicState().luaTouchPadJustReleased(button);
		});

		funk.set("touchPadReleased", function(button:Dynamic):Bool
		{
			if (FunkinLua.getCurrentMusicState().luaTouchPad == null)
			{
				return false;
			}
			return FunkinLua.getCurrentMusicState().luaTouchPadReleased(button);
		});

		funk.set("touchJustPressed", TouchUtil.justPressed);
		funk.set("touchPressed", TouchUtil.pressed);
		funk.set("touchJustReleased", TouchUtil.justReleased);
		funk.set("touchReleased", TouchUtil.released);
		funk.set("touchPressedObject", function(object:String, ?camera:String):Bool
		{
			var obj = FunkinLua.getCurrentMusicState().getLuaObject(object);
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			if (obj == null)
			{
				FunkinLua.luaTrace('touchPressedObject: $object does not exist.');
				return false;
			}
			return TouchUtil.overlaps(obj, cam) && TouchUtil.pressed;
		});

		funk.set("touchJustPressedObject", function(object:String, ?camera:String):Bool
		{
			var obj = FunkinLua.getCurrentMusicState().getLuaObject(object);
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			if (obj == null)
			{
				FunkinLua.luaTrace('touchJustPressedObject: $object does not exist.');
				return false;
			}
			return TouchUtil.overlaps(obj, cam) && TouchUtil.justPressed;
		});

		funk.set("touchJustReleasedObject", function(object:String, ?camera:String):Bool
		{
			var obj = FunkinLua.getCurrentMusicState().getLuaObject(object);
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			if (obj == null)
			{
				FunkinLua.luaTrace('touchJustReleasedObject: $object does not exist.');
				return false;
			}
			return TouchUtil.overlaps(obj, cam) && TouchUtil.justReleased;
		});

		funk.set("touchReleasedObject", function(object:String, ?camera:String):Bool
		{
			var obj = FunkinLua.getCurrentMusicState().getLuaObject(object);
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			if (obj == null)
			{
				FunkinLua.luaTrace('touchReleasedObject: $object does not exist.');
				return false;
			}
			return TouchUtil.overlaps(obj, cam) && TouchUtil.released;
		});

		funk.set("touchPressedObjectComplex", function(object:String, ?camera:String):Bool
		{
			var obj = FunkinLua.getCurrentMusicState().getLuaObject(object);
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			if (obj == null)
			{
				FunkinLua.luaTrace('touchPressedObjectComplex: $object does not exist.');
				return false;
			}
			return TouchUtil.overlapsComplex(obj, cam) && TouchUtil.pressed;
		});

		funk.set("touchJustPressedObjectComplex", function(object:String, ?camera:String):Bool
		{
			var obj = FunkinLua.getCurrentMusicState().getLuaObject(object);
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			if (obj == null)
			{
				FunkinLua.luaTrace('touchJustPressedObjectComplex: $object does not exist.');
				return false;
			}
			return TouchUtil.overlapsComplex(obj, cam) && TouchUtil.justPressed;
		});

		funk.set("touchJustReleasedObjectComplex", function(object:String, ?camera:String):Bool
		{
			var obj = FunkinLua.getCurrentMusicState().getLuaObject(object);
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			if (obj == null)
			{
				FunkinLua.luaTrace('touchJustReleasedObjectComplex: $object does not exist.');
				return false;
			}
			return TouchUtil.overlapsComplex(obj, cam) && TouchUtil.justReleased;
		});

		funk.set("touchReleasedObjectComplex", function(object:String, ?camera:String):Bool
		{
			var obj = FunkinLua.getCurrentMusicState().getLuaObject(object);
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			if (obj == null)
			{
				FunkinLua.luaTrace('touchReleasedObjectComplex: $object does not exist.');
				return false;
			}
			return TouchUtil.overlapsComplex(obj, cam) && TouchUtil.released;
		});

		funk.set("touchOverlapsObject", function(object:String, ?camera:String):Bool
		{
			var obj = FunkinLua.getCurrentMusicState().getLuaObject(object);
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			if (obj == null)
			{
				FunkinLua.luaTrace('touchOverlapsObject: $object does not exist.');
				return false;
			}
			return TouchUtil.overlaps(obj, cam);
		});

		funk.set("touchOverlapsObjectComplex", function(object:String, ?camera:String):Bool
		{
			var obj = FunkinLua.getCurrentMusicState().getLuaObject(object);
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			if (obj == null)
			{
				FunkinLua.luaTrace('touchOverlapsObjectComplex: $object does not exist.');
				return false;
			}
			return TouchUtil.overlapsComplex(obj, cam);
		});
	}

	public static function getMobileControlsAsString():String
	{
		try 
		{
			switch (MobileData.mode)
			{
				case 0:
					return 'left';
				case 1:
					return 'right';
				case 2:
					return 'custom';
				case 3:
					return 'hitbox';
				default:
					return 'none';
			}
		}
		catch (e:Dynamic)
		{
			return 'unknown';
		}
	}
}

#if android
class AndroidFunctions
{
	// static var spicyPillow:AndroidBatteryManager = new AndroidBatteryManager();
	public static function implement(funk:FunkinLua)
	{
		var lua:State = funk.lua;
		// funk.set("isRooted", AndroidTools.isRooted());
		funk.set("isDolbyAtmos", AndroidTools.isDolbyAtmos());
		funk.set("isAndroidTV", AndroidTools.isAndroidTV());
		funk.set("isTablet", AndroidTools.isTablet());
		funk.set("isChromebook", AndroidTools.isChromebook());
		funk.set("isDeXMode", AndroidTools.isDeXMode());
		// funk.set("isCharging", spicyPillow.isCharging());

		funk.set("backJustPressed", FlxG.android.justPressed.BACK);
		funk.set("backPressed", FlxG.android.pressed.BACK);
		funk.set("backJustReleased", FlxG.android.justReleased.BACK);

		funk.set("menuJustPressed", FlxG.android.justPressed.MENU);
		funk.set("menuPressed", FlxG.android.pressed.MENU);
		funk.set("menuJustReleased", FlxG.android.justReleased.MENU);

		funk.set("getCurrentOrientation", () -> PsychJNI.getCurrentOrientationAsString());
		funk.set("setOrientation", function(?hint:String):Void
		{
			switch (hint.toLowerCase())
			{
				case 'portrait':
					hint = 'Portrait';
				case 'portraitupsidedown' | 'upsidedownportrait' | 'upsidedown':
					hint = 'PortraitUpsideDown';
				case 'landscapeleft' | 'leftlandscape':
					hint = 'LandscapeLeft';
				case 'landscaperight' | 'rightlandscape' | 'landscape':
					hint = 'LandscapeRight';
				default:
					hint = null;
			}
			if (hint == null)
				return FunkinLua.luaTrace('setOrientation: No orientation specified.');
			PsychJNI.setOrientation(FlxG.stage.stageWidth, FlxG.stage.stageHeight, false, hint);
		});

		funk.set("minimizeWindow", () -> AndroidTools.minimizeWindow());

		funk.set("showToast", function(text:String, ?duration:Int, ?xOffset:Int, ?yOffset:Int) /* , ?gravity:Int*/
		{
			if (text == null)
				return FunkinLua.luaTrace('showToast: No text specified.');
			else if (duration == null)
				return FunkinLua.luaTrace('showToast: No duration specified.');

			if (xOffset == null)
				xOffset = 0;
			if (yOffset == null)
				yOffset = 0;

			AndroidToast.makeText(text, duration, -1, xOffset, yOffset);
		});

		funk.set("isScreenKeyboardShown", () -> PsychJNI.isScreenKeyboardShown());

		funk.set("clipboardHasText", () -> PsychJNI.clipboardHasText());
		funk.set("clipboardGetText", () -> PsychJNI.clipboardGetText());
		funk.set("clipboardSetText", function(?text:String):Void
		{
			if (text != null)
				return FunkinLua.luaTrace('clipboardSetText: No text specified.');
			PsychJNI.clipboardSetText(text);
		});

		funk.set("manualBackButton", () -> PsychJNI.manualBackButton());

		funk.set("setActivityTitle", function(text:String):Void
		{
			if (text != null)
				return FunkinLua.luaTrace('setActivityTitle: No text specified.');
			PsychJNI.setActivityTitle(text);
		});
	}
}
#end
#end
