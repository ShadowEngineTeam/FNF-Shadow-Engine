package mobile.psychlua;

import psychlua.CustomSubstate;
#if FEATURE_LUA
import lime.ui.Haptic;
import psychlua.FunkinLua;
import psychlua.LuaUtils;
import mobile.backend.TouchUtil;

/**
 * ...
 * @author: Karim Akra and Homura Akemi (HomuHomu833)
 */
@:nullSafety
class MobileFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var controls = Controls.instance;
		if (controls != null)
			funk.set('mobileC', controls.mobileC);

		funk.set('mobileControlsMode', getMobileControlsAsString());

		funk.set("extraButtonPressed", (button:String) ->
		{
			#if FEATURE_MOBILE_CONTROLS
			button = button.toLowerCase();
			var mobileControlsLocal = MusicBeatState.getState()?.mobileControls;
			if (mobileControls != null)
			{
				switch (button)
				{
					case 'second':
						return mobileControlsLocal.buttonExtra2.pressed;
					default:
						return mobileControlsLocal.buttonExtra.pressed;
				}
			}
			#end
			return false;
		});

		funk.set("extraButtonJustPressed", (button:String) ->
		{
			#if FEATURE_MOBILE_CONTROLS
			button = button.toLowerCase();
			var mobileControlsLocal = MusicBeatState.getState()?.mobileControls;
			if (mobileControlsLocal != null)
			{
				switch (button)
				{
					case 'second':
						return mobileControlsLocal.buttonExtra2.justPressed;
					default:
						return mobileControlsLocal.buttonExtra.justPressed;
				}
			}
			#end
			return false;
		});

		funk.set("extraButtonJustReleased", (button:String) ->
		{
			#if FEATURE_MOBILE_CONTROLS
			button = button.toLowerCase();
			var mobileControlsLocal = MusicBeatState.getState()?.mobileControls;
			if (mobileControlsLocal != null)
			{
				switch (button)
				{
					case 'second':
						return mobileControlsLocal.buttonExtra2.justReleased;
					default:
						return mobileControlsLocal.buttonExtra.justReleased;
				}
			}
			#end
			return false;
		});

		funk.set("extraButtonReleased", (button:String) ->
		{
			#if FEATURE_MOBILE_CONTROLS
			button = button.toLowerCase();
			var mobileControlsLocal = MusicBeatState.getState()?.mobileControls;
			if (mobileControlsLocal != null)
			{
				switch (button)
				{
					case 'second':
						return mobileControlsLocal.buttonExtra2.released;
					default:
						return mobileControlsLocal.buttonExtra.released;
				}
			}
			#end
			return false;
		});

		funk.set("vibrate", (?duration:Int, ?period:Int) ->
		{
			if (duration == null)
				return FunkinLua.luaTrace('vibrate: No duration specified.');
			var p:Int = (period != null) ? period : 0;
			var d:Int = duration;
			return Haptic.vibrate(p, d);
		});

		funk.set("addTouchPad", (DPadMode:String, ActionMode:String, ?addToCustomSubstate:Bool = false, ?posAtCustomSubstate:Int = -1) ->
		{
			#if FEATURE_MOBILE_CONTROLS
			var state = FunkinLua.getCurrentMusicState();
			if (state != null)
				state.makeLuaTouchPad(DPadMode, ActionMode);
			if (addToCustomSubstate == true)
			{
				var ltp = state?.luaTouchPad;
				if (ltp != null && state != null && !state.members.contains(ltp))
					CustomSubstate.insertLuaTpad(posAtCustomSubstate);
			}
			else if (state != null)
				state.addLuaTouchPad();
			#end
		});

		funk.set("removeTouchPad", () ->
		{
			#if FEATURE_MOBILE_CONTROLS
			FunkinLua.getCurrentMusicState().removeLuaTouchPad();
			#end
		});

		funk.set("addTouchPadCamera", (?defaultDrawTarget:Bool) ->
		{
			#if FEATURE_MOBILE_CONTROLS
			if (defaultDrawTarget == null)
				defaultDrawTarget = false;
			if (FunkinLua.getCurrentMusicState().luaTouchPad == null)
			{
				FunkinLua.luaTrace('addTouchPadCamera: Touch Pad does not exist.');
				return;
			}
			FunkinLua.getCurrentMusicState().addLuaTouchPadCamera(defaultDrawTarget);
			#end
		});

		funk.set("touchPadJustPressed", function(button:Dynamic):Bool
		{
			#if FEATURE_MOBILE_CONTROLS
			if (FunkinLua.getCurrentMusicState().luaTouchPad == null)
			{
				return false;
			}
			return FunkinLua.getCurrentMusicState().luaTouchPadJustPressed(button);
			#else
			return false;
			#end
		});

		funk.set("touchPadPressed", function(button:Dynamic):Bool
		{
			#if FEATURE_MOBILE_CONTROLS
			if (FunkinLua.getCurrentMusicState().luaTouchPad == null)
			{
				return false;
			}
			return FunkinLua.getCurrentMusicState().luaTouchPadPressed(button);
			#else
			return false;
			#end
		});

		funk.set("touchPadJustReleased", function(button:Dynamic):Bool
		{
			#if FEATURE_MOBILE_CONTROLS
			if (FunkinLua.getCurrentMusicState().luaTouchPad == null)
			{
				return false;
			}
			return FunkinLua.getCurrentMusicState().luaTouchPadJustReleased(button);
			#else
			return false;
			#end
		});

		funk.set("touchPadReleased", function(button:Dynamic):Bool
		{
			#if FEATURE_MOBILE_CONTROLS
			if (FunkinLua.getCurrentMusicState().luaTouchPad == null)
			{
				return false;
			}
			return FunkinLua.getCurrentMusicState().luaTouchPadReleased(button);
			#else
			return false;
			#end
		});

		funk.set("touchJustPressed", TouchUtil.justPressed);
		funk.set("touchPressed", TouchUtil.pressed);
		funk.set("touchJustReleased", TouchUtil.justReleased);
		funk.set("touchReleased", TouchUtil.released);
		funk.set("touchPressedObject", function(object:String, ?camera:String):Bool
		{
			var state = FunkinLua.getCurrentMusicState();
			var luaObj = state?.getLuaObject(object);
			var obj:Null<FlxSprite> = luaObj != null ? cast(luaObj, FlxSprite) : null;
			var cam:Null<FlxCamera> = camera != null ? LuaUtils.cameraFromString(camera) : null;
			if (obj == null)
			{
				FunkinLua.luaTrace('touchPressedObject: $object does not exist.');
				return false;
			}
			return TouchUtil.overlaps(obj, cam) && TouchUtil.pressed;
		});

		funk.set("touchJustPressedObject", function(object:String, ?camera:String):Bool
		{
			var state = FunkinLua.getCurrentMusicState();
			var luaObj = state?.getLuaObject(object);
			var obj:Null<FlxSprite> = luaObj != null ? cast(luaObj, FlxSprite) : null;
			var cam:Null<FlxCamera> = camera != null ? LuaUtils.cameraFromString(camera) : null;
			if (obj == null)
			{
				FunkinLua.luaTrace('touchJustPressedObject: $object does not exist.');
				return false;
			}
			return TouchUtil.overlaps(obj, cam) && TouchUtil.justPressed;
		});

		funk.set("touchJustReleasedObject", function(object:String, ?camera:String):Bool
		{
			var state = FunkinLua.getCurrentMusicState();
			var luaObj = state?.getLuaObject(object);
			var obj:Null<FlxSprite> = luaObj != null ? cast(luaObj, FlxSprite) : null;
			var cam:Null<FlxCamera> = camera != null ? LuaUtils.cameraFromString(camera) : null;
			if (obj == null)
			{
				FunkinLua.luaTrace('touchJustReleasedObject: $object does not exist.');
				return false;
			}
			return TouchUtil.overlaps(obj, cam) && TouchUtil.justReleased;
		});

		funk.set("touchReleasedObject", function(object:String, ?camera:String):Bool
		{
			var state = FunkinLua.getCurrentMusicState();
			var luaObj = state?.getLuaObject(object);
			var obj:Null<FlxSprite> = luaObj != null ? cast(luaObj, FlxSprite) : null;
			var cam:Null<FlxCamera> = camera != null ? LuaUtils.cameraFromString(camera) : null;
			if (obj == null)
			{
				FunkinLua.luaTrace('touchReleasedObject: $object does not exist.');
				return false;
			}
			return TouchUtil.overlaps(obj, cam) && TouchUtil.released;
		});

		funk.set("touchPressedObjectComplex", function(object:String, ?camera:String):Bool
		{
			var state = FunkinLua.getCurrentMusicState();
			var luaObj = state?.getLuaObject(object);
			var obj:Null<FlxSprite> = luaObj != null ? cast(luaObj, FlxSprite) : null;
			var cam:Null<FlxCamera> = camera != null ? LuaUtils.cameraFromString(camera) : null;
			if (obj == null)
			{
				FunkinLua.luaTrace('touchPressedObjectComplex: $object does not exist.');
				return false;
			}
			return TouchUtil.overlapsComplex(obj, cam) && TouchUtil.pressed;
		});

		funk.set("touchJustPressedObjectComplex", function(object:String, ?camera:String):Bool
		{
			var state = FunkinLua.getCurrentMusicState();
			var luaObj = state?.getLuaObject(object);
			var obj:Null<FlxSprite> = luaObj != null ? cast(luaObj, FlxSprite) : null;
			var cam:Null<FlxCamera> = camera != null ? LuaUtils.cameraFromString(camera) : null;
			if (obj == null)
			{
				FunkinLua.luaTrace('touchJustPressedObjectComplex: $object does not exist.');
				return false;
			}
			return TouchUtil.overlapsComplex(obj, cam) && TouchUtil.justPressed;
		});

		funk.set("touchJustReleasedObjectComplex", function(object:String, ?camera:String):Bool
		{
			var state = FunkinLua.getCurrentMusicState();
			var luaObj = state?.getLuaObject(object);
			var obj:Null<FlxSprite> = luaObj != null ? cast(luaObj, FlxSprite) : null;
			var cam:Null<FlxCamera> = camera != null ? LuaUtils.cameraFromString(camera) : null;
			if (obj == null)
			{
				FunkinLua.luaTrace('touchJustReleasedObjectComplex: $object does not exist.');
				return false;
			}
			return TouchUtil.overlapsComplex(obj, cam) && TouchUtil.justReleased;
		});

		funk.set("touchReleasedObjectComplex", function(object:String, ?camera:String):Bool
		{
			var state = FunkinLua.getCurrentMusicState();
			var luaObj = state?.getLuaObject(object);
			var obj:Null<FlxSprite> = luaObj != null ? cast(luaObj, FlxSprite) : null;
			var cam:Null<FlxCamera> = camera != null ? LuaUtils.cameraFromString(camera) : null;
			if (obj == null)
			{
				FunkinLua.luaTrace('touchReleasedObjectComplex: $object does not exist.');
				return false;
			}
			return TouchUtil.overlapsComplex(obj, cam) && TouchUtil.released;
		});

		funk.set("touchOverlapsObject", function(object:String, ?camera:String):Bool
		{
			var state = FunkinLua.getCurrentMusicState();
			var luaObj = state?.getLuaObject(object);
			var obj:Null<FlxSprite> = luaObj != null ? cast(luaObj, FlxSprite) : null;
			var cam:Null<FlxCamera> = camera != null ? LuaUtils.cameraFromString(camera) : null;
			if (obj == null)
			{
				FunkinLua.luaTrace('touchOverlapsObject: $object does not exist.');
				return false;
			}
			return TouchUtil.overlaps(obj, cam);
		});

		funk.set("touchOverlapsObjectComplex", function(object:String, ?camera:String):Bool
		{
			var state = FunkinLua.getCurrentMusicState();
			var luaObj = state?.getLuaObject(object);
			var obj:Null<FlxSprite> = luaObj != null ? cast(luaObj, FlxSprite) : null;
			var cam:Null<FlxCamera> = camera != null ? LuaUtils.cameraFromString(camera) : null;
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
		#if FEATURE_MOBILE_CONTROLS
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
		#else
		return 'none';
		#end
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
	}
}
#end
#end
