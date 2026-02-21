package options;

import lime.ui.WindowVSyncMode;
import objects.Note;
import objects.StrumNote;
import backend.ui.ShadowStyle;

class VisualsUISubState extends BaseOptionsMenu
{
	public static var pauseMusics:Array<String> = ['None', 'Breakfast', 'Tea Time'];

	var noteOptionID:Int = -1;
	var notes:FlxTypedGroup<StrumNote>;
	var notesTween:Array<FlxTween> = [];
	var noteY:Float = 90;

	public function new()
	{
		title = 'Visuals and UI';
		rpcTitle = 'Visuals & UI Settings Menu'; // for Discord Rich Presence

		// for note skins
		notes = new FlxTypedGroup<StrumNote>();
		for (i in 0...Note.colArray.length)
		{
			var note:StrumNote = new StrumNote(370 + (560 / Note.colArray.length) * i, -200, i, 0, null);
			note.centerOffsets();
			note.centerOrigin();
			note.playAnim('static');
			notes.add(note);
		}

		// options
		var noteSkins:Array<String> = Mods.mergeAllTextsNamed('images/noteSkins/list.txt');
		if (noteSkins.length > 0)
		{
			if (!noteSkins.contains(ClientPrefs.data.noteSkin))
				ClientPrefs.data.noteSkin = ClientPrefs.defaultData.noteSkin; // Reset to default if saved noteskin couldnt be found

			noteSkins.insert(0, ClientPrefs.defaultData.noteSkin); // Default skin always comes first
			var option:Option = new Option('Note Skins:', "Select your prefered Note skin.", 'noteSkin', 'string', noteSkins);
			addOption(option);
			option.onChange = onChangeNoteSkin;
			noteOptionID = optionsArray.length - 1;
		}

		var noteSplashes:Array<String> = Mods.mergeAllTextsNamed('images/noteSplashes/list.txt');
		if (noteSplashes.length > 0)
		{
			if (!noteSplashes.contains(ClientPrefs.data.splashSkin))
				ClientPrefs.data.splashSkin = ClientPrefs.defaultData.splashSkin; // Reset to default if saved splashskin couldnt be found

			noteSplashes.insert(0, ClientPrefs.defaultData.splashSkin); // Default skin always comes first
			var option:Option = new Option('Note Splashes:', "Select your prefered Note Splash variation or turn it off.", 'splashSkin', 'string',
				noteSplashes);
			addOption(option);
		}

		var option:Option = new Option('Note Splash Opacity', 'How much transparent should the Note Splashes be.', 'splashAlpha', 'percent');
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		var option:Option = new Option('Disable RGB Notes', "If checked, notes will use the HSV coloring method.", 'disableRGBNotes', 'bool');
		addOption(option);

		var option:Option = new Option('Hide HUD', 'If checked, hides most HUD elements.', 'hideHud', 'bool');
		addOption(option);

		var themeOptions:Array<String> = [ShadowStyle.ShadowTHEME_DARK, ShadowStyle.ShadowTHEME_LIGHT];
		var option:Option = new Option('UI Theme:', 'Choose between the light and dark Shadow UI themes.', 'uiTheme', 'string', themeOptions);
		addOption(option);
		option.onChange = onChangeUITheme;

		var option:Option = new Option('Time Bar:', "What should the Time Bar display?", 'timeBarType', 'string',
			['Time Left', 'Time Elapsed', 'Song Name', 'Disabled']);
		addOption(option);

		var option:Option = new Option('Flashing Lights', "Uncheck this if you're sensitive to flashing lights!", 'flashing', 'bool');
		addOption(option);

		var option:Option = new Option('Camera Zooms', "If unchecked, the camera won't zoom in on a beat hit.", 'camZooms', 'bool');
		addOption(option);

		var option:Option = new Option('Score Text Zoom on Hit', "If unchecked, disables the Score text zooming\neverytime you hit a note.", 'scoreZoom',
			'bool');
		addOption(option);

		var option:Option = new Option('Health Bar Opacity', 'How much transparent should the health bar and icons be.', 'healthBarAlpha', 'percent');
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		#if native
		var option:Option = new Option('VSync',
			'If checked, Enables VSync fixing any screen tearing at the cost of capping the FPS to screen refresh rate.',
			'vsync', 'bool');
		option.onChange = onChangeVSync;
		addOption(option);

		#if android
		var option:Option = new Option('Downscale Game',
			'If checked, Renders the game at a lower resolution (near 0.67x) for better performance.\n(Must restart the game to have an effect)',
			'downscaleGame', 'bool');
		option.onChange = onChangeScaleSize;
		addOption(option);
		#end
		#end

		var option:Option = new Option('Pause Screen Song:', "Which song do you prefer for the Pause Screen?", 'pauseMusic', 'string', pauseMusics);
		addOption(option);
		option.onChange = onChangePauseMusic;

		#if FEATURE_DISCORD_RPC
		var option:Option = new Option('Discord Rich Presence',
			"Uncheck this to prevent accidental leaks, it will hide the Application from your \"Playing\" box on Discord", 'discordRPC', 'bool');
		addOption(option);
		#end

		var option:Option = new Option('Show Note Timing', 'If checked, a timing of the hitted note will be shown on the screen (in miliseconds)',
			'showNoteTiming', 'bool');
		addOption(option);

		var option:Option = new Option('Combo Stacking', "If unchecked, Ratings and Combo won't stack, saving on System Memory and easier to read",
			'comboStacking', 'bool');
		addOption(option);

		super();
		add(notes);
	}

	override function changeSelection(change:Int = 0)
	{
		super.changeSelection(change);

		if (noteOptionID < 0)
			return;

		for (i in 0...Note.colArray.length)
		{
			var note:StrumNote = notes.members[i];
			if (notesTween[i] != null)
				notesTween[i].cancel();
			if (curSelected == noteOptionID)
				notesTween[i] = FlxTween.tween(note, {y: noteY}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
			else
				notesTween[i] = FlxTween.tween(note, {y: -200}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
		}
	}

	var changedMusic:Bool = false;

	function onChangePauseMusic()
	{
		if (ClientPrefs.data.pauseMusic == 'None')
			FlxG.sound.music.volume = 0;
		else
			FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)));

		changedMusic = true;
	}

	function onChangeNoteSkin()
	{
		notes.forEachAlive(function(note:StrumNote)
		{
			changeNoteSkin(note);
			note.centerOffsets();
			note.centerOrigin();
		});
	}

	function onChangeUITheme()
	{
		ShadowStyle.applySavedTheme();
	}

	function changeNoteSkin(note:StrumNote)
	{
		var skin:String = Note.defaultNoteSkin;
		var customSkin:String = skin + Note.getNoteSkinPostfix();
		if (#if HAS_GPU_TEXTURES Paths.fileExists('images/$customSkin.${Paths.GPU_IMAGE_EXT}', Paths.getImageAssetType(Paths.GPU_IMAGE_EXT)) || #end Paths.fileExists('images/$customSkin.${Paths.IMAGE_EXT}', Paths.getImageAssetType(Paths.IMAGE_EXT)))
			skin = customSkin;

		note.texture = skin; // Load texture and anims
		note.reloadNote();
		note.playAnim('static');
	}

	override function destroy()
	{
		if (changedMusic && !OptionsState.onPlayState)
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 1, true);
		super.destroy();
	}

	#if native
	function onChangeVSync()
		FlxG.stage.application.window.setVSyncMode(ClientPrefs.data.vsync ? WindowVSyncMode.ON : WindowVSyncMode.OFF);

	#if android
	function onChangeScaleSize()
		File.saveContent(lime.system.System.applicationStorageDirectory + 'scaleSize.txt', (ClientPrefs.data.downscaleGame ? '${(720 / 1.5) / 720}' : '1'));
	#end
	#end
}
