package states;

import backend.Highscore;
import backend.ui.ShadowStyle;
import flixel.addons.transition.FlxTransitionableState;

class InitState extends MusicBeatState
{
	override public function create():Void
	{
		Paths.clearStoredMemory();

		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;

		#if FEATURE_LUA
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];

		super.create();

		FlxG.save.bind('funkin', CoolUtil.getSavePath());

		ClientPrefs.loadPrefs();
		ShadowStyle.applySavedTheme();

		Highscore.load();

		if (FlxG.save.data != null && FlxG.save.data.fullscreen)
			FlxG.fullscreen = FlxG.save.data.fullscreen;

		persistentUpdate = true;
		persistentDraw = true;

		#if FEATURE_MOBILE_CONTROLS
		MobileData.init();
		#end

		if (FlxG.save.data.weekCompleted != null)
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;

		FlxG.mouse.visible = false;

		TitleState.showIntro = true;

		FlxTransitionableState.skipNextTransIn = true;
		if (FlxG.save.data.flashing == null && !FlashingState.leftState)
		{
			Funkin.controls.isInSubstate = false; // idfk what's wrong
			FlxTransitionableState.skipNextTransOut = true;
			Funkin.switchState(FlashingState);
		}
		else
		{
			Funkin.switchState(TitleState);
		}
	}
}
