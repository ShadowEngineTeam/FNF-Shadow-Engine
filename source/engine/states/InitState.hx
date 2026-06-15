package states;

import backend.Highscore;
import backend.ui.ShadowStyle;
import flixel.addons.transition.FlxTransitionableState;
import lime.system.System as LimeSystem;

#if native
import lime.ui.WindowVSyncMode;
#end

@:nullSafety
class InitState extends FlxState
{
	override public function create():Void
	{
		super.create();
		
		FlxG.mouse.visible = false;
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;

		Paths.clearStoredMemory();

		#if FEATURE_TRACY
		cpp.vm.tracy.TracyProfiler.setThreadName("main");
		#end

		#if FEATURE_VIDEOS
		hxvlc.util.Handle.init();
		#end

		#if FEATURE_MODS
		Mods.pushGlobalMods();
		#end

		Mods.loadTopMod();

		#if FEATURE_HSCRIPT
		backend.scripting.ScriptSignalCalls.init();
		#end

		#if FEATURE_DISCORD_RPC
		DiscordClient.prepare();
		#end

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];
		FlxG.save.bind('funkin', CoolUtil.getSavePath());

		if (FlxG.save.data?.fullscreen == true)
			FlxG.fullscreen = FlxG.save.data.fullscreen;

		if (FlxG.save.data?.weekCompleted != null)
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;

		Controls.instance = new Controls();
		ClientPrefs.loadPrefs();
		ClientPrefs.loadDefaultKeys();
		Highscore.load();
		ShadowStyle.applySavedTheme();

		#if FEATURE_MOBILE_CONTROLS
		MobileData.init();
		#end

		#if mobile
		LimeSystem.allowScreenTimeout = ClientPrefs.data.screensaver;
		#end

		FlxSprite.defaultAntialiasing = ClientPrefs.data.antialiasing;
		FlxG.game.soundTray.active = true;
		FlxG.inputs.resetOnStateSwitch = false;

		#if android
		FlxG.android.preventDefaultKeys = [flixel.input.android.FlxAndroidKey.BACK];
		#end

		#if native
		FlxG.stage.application.window.setVSyncMode(ClientPrefs.data.vsync ? WindowVSyncMode.ON : WindowVSyncMode.OFF);
		#end


		TitleState.showIntro = true;
		var nextState:Class<FlxState> = FlxG.save.data.flashing == null && !FlashingState.leftState ? FlashingState : TitleState;
		Funkin.controls.isInSubstate = false;
		Funkin.switchState(nextState);
	}
}
