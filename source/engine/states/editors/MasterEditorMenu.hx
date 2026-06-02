package states.editors;

import backend.WeekData;
import objects.Character;
import states.MainMenuState;
import states.FreeplayState;

@:nullSafety
class MasterEditorMenu extends MusicBeatState
{
	var options:Array<String> = [
		'Chart Editor',
		'Character Editor',
		'Week Editor',
		'Menu Character Editor',
		'Dialogue Editor',
		'Dialogue Portrait Editor',
		'Note Splash Debug'
	];
	@:nullSafety(Off) private var grpTexts:FlxTypedGroup<Alphabet>;
	@:nullSafety(Off) private var directories:Array<String> = [null];

	private var curSelected = 0;
	private var curDirectory = 0;
	@:nullSafety(Off) private var directoryTxt:FlxText;

	override function create()
	{
		FlxG.camera.bgColor = FlxColor.BLACK;
		#if FEATURE_DISCORD_RPC
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Editors Main Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF353535;
		add(bg);

		grpTexts = new FlxTypedGroup<Alphabet>();
		add(grpTexts);

		for (i in 0...options.length)
		{
			var leText:Alphabet = new Alphabet(90, 320, options[i], true);
			leText.isMenuItem = true;
			leText.targetY = i;
			grpTexts.add(leText);
			leText.snapToPosition();
		}

		#if FEATURE_MODS
		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 42).makeGraphic(FlxG.width, 42, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		directoryTxt = new FlxText(textBG.x, textBG.y + 4, FlxG.width, '', 32);
		directoryTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		directoryTxt.scrollFactor.set();
		add(directoryTxt);

		for (folder in Mods.getModDirectories())
		{
			directories.push(folder);
		}

		var found:Int = directories.indexOf(Mods.currentModDirectory);
		if (found > -1)
			curDirectory = found;
		changeDirectory();
		#end
		changeSelection();

		FlxG.mouse.visible = false;

		#if FEATURE_MOBILE_CONTROLS
		addTouchPad(#if FEATURE_MODS "LEFT_FULL" #else "UP_DOWN" #end, "A_B");
		#end

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (Funkin.controls.UI_UP_P)
		{
			changeSelection(-1);
		}
		if (Funkin.controls.UI_DOWN_P)
		{
			changeSelection(1);
		}
		#if FEATURE_MODS
		if (Funkin.controls.UI_LEFT_P)
		{
			changeDirectory(-1);
		}
		if (Funkin.controls.UI_RIGHT_P)
		{
			changeDirectory(1);
		}
		#end

		if (Funkin.controls.BACK)
		{
			Funkin.switchState(MainMenuState);
		}

		if (Funkin.controls.ACCEPT)
		{
			switch (options[curSelected])
			{
				case 'Chart Editor': // felt it would be cool maybe
					LoadingState.loadAndSwitchState(ChartingState, false);
				case 'Character Editor':
					LoadingState.loadAndSwitchState(CharacterEditorState, [Character.DEFAULT_CHARACTER, false]);
				case 'Week Editor':
					Funkin.switchState(WeekEditorState);
				case 'Menu Character Editor':
					Funkin.switchState(MenuCharacterEditorState);
				case 'Dialogue Editor':
					LoadingState.loadAndSwitchState(DialogueEditorState, false);
				case 'Dialogue Portrait Editor':
					LoadingState.loadAndSwitchState(DialogueCharacterEditorState, false);
				case 'Note Splash Debug':
					Funkin.switchState(NoteSplashDebugState);
			}
			FlxG.sound.music.volume = 0;
			FreeplayState.destroyFreeplayVocals();
		}

		var bullShit:Int = 0;
		for (item in grpTexts.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
		super.update(elapsed);
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;
	}

	#if FEATURE_MODS
	function changeDirectory(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curDirectory += change;

		if (curDirectory < 0)
			curDirectory = directories.length - 1;
		if (curDirectory >= directories.length)
			curDirectory = 0;

		WeekData.setDirectoryFromWeek();
		if (directories[curDirectory] == null || directories[curDirectory].length < 1)
			directoryTxt.text = '< No Mod Directory Loaded >';
		else
		{
			Mods.currentModDirectory = directories[curDirectory];
			directoryTxt.text = '< Loaded Mod Directory: ' + Mods.currentModDirectory + ' >';
		}
		directoryTxt.text = directoryTxt.text.toUpperCase();
	}
	#end
}
