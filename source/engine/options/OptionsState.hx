package options;

import states.MainMenuState;
import backend.StageData;
import flixel.addons.transition.FlxTransitionableState;
import mobile.substates.MobileControlSelectSubState;
import backend.ui.ShadowStyle;
#if (target.threaded)
import sys.thread.Thread;
import sys.thread.Mutex;
#end

class OptionsState extends MusicBeatState
{
	var options:Array<String> = [
		'Note Colors',
		'Controls',
		'Adjust Delay and Combo',
		'Graphics',
		'Visuals and UI',
		'Gameplay',
		'Mobile Options'
	];
	private var grpOptions:FlxTypedGroup<Alphabet>;

	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;

	var tipText:FlxText;
	#if (target.threaded) var mutex:Mutex = new Mutex(); #end

	function openSelectedSubstate(label:String)
	{
		persistentUpdate = false;
		if (label != "Adjust Delay and Combo")
			removeTouchPad();
		switch (label)
		{
			case 'Note Colors':
				openSubState(new options.NotesSubState());
			case 'Controls':
				openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals and UI':
				openSubState(new options.VisualsUISubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				MusicBeatState.switchState(new options.NoteOffsetState());
			case 'Mobile Options':
				openSubState(new mobile.options.MobileOptionsSubState());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = 0xFFea71fd;
		bg.updateHitbox();

		bg.screenCenter();
		add(bg);

		tipText = new FlxText(150, FlxG.height - #if android 40 #else 24 #end, 0, 'Press ${controls.mobileC ? #if android 'X' #else 'C' #end : 'CTRL'} to Go Mobile Controls Menu' #if android + '\nPress ${controls.mobileC ? 'Y' : 'SHIFT'} to Open DATA Folder' #end, 16);
		tipText.setFormat("VCR OSD Mono", 17, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tipText.borderSize = 1.25;
		tipText.scrollFactor.set();
		tipText.antialiasing = ClientPrefs.data.antialiasing;
		add(tipText);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true);
			optionText.screenCenter();
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		add(selectorRight);

		changeSelection();
		ClientPrefs.saveSettings();

		addTouchPad("UP_DOWN", #if android "A_B_X_Y" #else "A_B_C" #end);

		#if (target.threaded)
		Thread.create(() ->
		{
			mutex.acquire();

			for (i in VisualsUISubState.pauseMusics)
			{
				if (i.toLowerCase() != "none")
					Paths.music(Paths.formatToSongPath(i));
			}

			mutex.release();
		});
		#end

		super.create();
	}

	override function closeSubState()
	{
		super.closeSubState();
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
		ClientPrefs.saveSettings();
		ClientPrefs.loadPrefs();
		ShadowStyle.applySavedTheme();
		removeTouchPad();
		addTouchPad("UP_DOWN", #if android "A_B_X_Y" #else "A_B_C" #end);
		persistentUpdate = true;
	}

	var exiting:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!exiting)
		{
			if (controls.UI_UP_P)
			{
				changeSelection(-1);
			}
			if (controls.UI_DOWN_P)
			{
				changeSelection(1);
			}

			if ((#if android touchPad.buttonX.justPressed #else touchPad.buttonC.justPressed #end || FlxG.keys.justPressed.CONTROL))
			{
				persistentUpdate = false;
				openSubState(new MobileControlSelectSubState());
			}

			#if android
			if (touchPad.buttonY.justPressed || FlxG.keys.justPressed.SHIFT)
				android.Tools.openDataFolder();
			#end

			if (controls.BACK)
			{
				exiting = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				if (onPlayState)
				{
					StageData.loadDirectory(PlayState.SONG);
					LoadingState.loadAndSwitchState(new PlayState());
					FlxG.sound.music.volume = 0;
				}
				else
					MusicBeatState.switchState(new MainMenuState());
			}
			else if (controls.ACCEPT)
				openSelectedSubstate(options[curSelected]);
		}
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0)
			{
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		ShadowStyle.applySavedTheme();
		super.destroy();
	}
}
