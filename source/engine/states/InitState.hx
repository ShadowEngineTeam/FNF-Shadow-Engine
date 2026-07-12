package states;

import backend.Highscore;
import backend.ui.ShadowStyle;
#if DIRECT_NULL
import backend.WeekData;
import backend.Song;
#end
import flixel.addons.transition.FlxTransitionableState;
import lime.system.System as LimeSystem;

#if native
import lime.ui.WindowVSyncMode;
#end

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
		backend.scripting.GlobalScript.init();
		#end

		#if FEATURE_DISCORD_RPC
		DiscordClient.prepare();
		#end

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];
		FlxG.save.bind('funkin', CoolUtil.getSavePath());

		if (FlxG.save.data?.fullscreen)
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


		#if DIRECT_NULL
		// TEMP: boot straight into the null-and-void mod song for bgfx render
		// debugging, skipping the whole menu flow. Build with -D DIRECT_NULL.
		{
			// force shaders on: the menu (where it's toggled) is skipped here
			ClientPrefs.data.shaders = true;

			Mods.currentModDirectory = "null-and-void";
			WeekData.reloadWeekFiles(false);
			var week = WeekData.weeksLoaded.get("null-and-void");
			WeekData.setDirectoryFromWeek(week);
			Difficulty.loadFromWeek(week);

			var diff:Int = Difficulty.list.indexOf(Difficulty.stringToDiff("hard"));
			if (diff < 0) diff = 0;

			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = diff;

			var songPath:String = Paths.formatToSongPath("Null-and-Void");
			var json:String = Highscore.formatSong(songPath, diff);
			PlayState.SONG = Song.loadFromJson(json, songPath);

			// normal flow always has (persistent) menu music playing when
			// PlayState starts; the skipped menus leave FlxG.sound.music null and
			// the Lua setup reads FlxG.sound.music.length. Play the base menu
			// track silently so a real, transition-surviving music exists, just
			// like coming from a menu (PlayState stops+replaces it afterward).
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0, false);

			LoadingState.prepareToSong();
			LoadingState.loadAndSwitchState(PlayState);
			return;
		}
		#end

		TitleState.showIntro = true;
		var nextState:Class<FlxState> = FlxG.save.data.flashing == null && !FlashingState.leftState ? FlashingState : TitleState;
		Funkin.controls.isInSubstate = false;
		Funkin.switchState(nextState);
	}
}
