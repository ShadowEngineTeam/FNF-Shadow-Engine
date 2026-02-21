package states.editors;

import backend.WeekData;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileFilter;
import lime.system.Clipboard;
import objects.HealthIcon;
import objects.MenuCharacter;
import objects.MenuItem;
import states.editors.MasterEditorMenu;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;

class WeekEditorState extends MusicBeatState
{
	var txtWeekTitle:FlxText;
	var bgSprite:FlxSprite;
	var lock:FlxSprite;
	var txtTracklist:FlxText;
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;
	var weekThing:MenuItem;
	var missingFileText:FlxText;

	var weekFile:WeekFile = null;

	public function new(weekFile:WeekFile = null)
	{
		super();
		this.weekFile = WeekData.createWeekFile();
		if (weekFile != null)
			this.weekFile = weekFile;
		else
			weekFileName = 'week1';
	}

	override function create()
	{
		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;

		var ui_tex:FlxAtlasFrames = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		var bgYellow:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51);
		bgSprite = new FlxSprite(0, 56);
		bgSprite.antialiasing = ClientPrefs.data.antialiasing;

		weekThing = new MenuItem(0, bgSprite.y + 396, weekFileName);
		weekThing.y += weekThing.height + 20;
		weekThing.antialiasing = ClientPrefs.data.antialiasing;
		add(weekThing);

		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();

		lock = new FlxSprite();
		lock.frames = ui_tex;
		lock.animation.addByPrefix('lock', 'lock');
		lock.animation.play('lock');
		lock.antialiasing = ClientPrefs.data.antialiasing;
		add(lock);

		missingFileText = new FlxText(0, 0, FlxG.width, "");
		missingFileText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingFileText.borderSize = 2;
		missingFileText.visible = false;
		add(missingFileText);

		var charArray:Array<String> = weekFile.weekCharacters;
		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, charArray[char]);
			weekCharacterThing.y += 70;
			grpWeekCharacters.add(weekCharacterThing);
		}

		add(bgYellow);
		add(bgSprite);
		add(grpWeekCharacters);

		var tracksSprite:FlxSprite = new FlxSprite(FlxG.width * 0.07, bgSprite.y + 435).loadGraphic(Paths.image('Menu_Tracks'));
		tracksSprite.antialiasing = ClientPrefs.data.antialiasing;
		add(tracksSprite);

		txtTracklist = new FlxText(FlxG.width * 0.05, tracksSprite.y + 60, 0, "", 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = Paths.font("vcr.ttf");
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);
		add(txtWeekTitle);

		addEditorBox();
		reloadAllShit();

		FlxG.mouse.visible = true;
		#if FEATURE_MOBILE_CONTROLS
		addTouchPad("UP_DOWN", "B");
		#end

		super.create();
	}

	var UI_box:ShadowTabMenu;
	var blockPressWhileTypingOn:Array<ShadowTextInput> = [];

	function addEditorBox()
	{
		var tabs:Array<TabDef> = [{name: 'Week', label: 'Week'}, {name: 'Other', label: 'Other'}];
		UI_box = new ShadowTabMenu(FlxG.width - 260, FlxG.height - 395, tabs, 250, 385);
		UI_box.scrollFactor.set();

		addWeekUI();
		addOtherUI();

		var loadWeekButton:ShadowButton = new ShadowButton(0, 650, "Load Week", function()
		{
			loadWeek();
		}, 90);
		loadWeekButton.screenCenter(X);
		loadWeekButton.x -= 120;
		add(loadWeekButton);

		var freeplayButton:ShadowButton = new ShadowButton(0, 650, "Freeplay", function()
		{
			MusicBeatState.switchState(new WeekEditorFreeplayState(weekFile));
		}, 90);
		freeplayButton.screenCenter(X);
		add(freeplayButton);

		var saveWeekButton:ShadowButton = new ShadowButton(0, 650, "Save Week", function()
		{
			saveWeek(weekFile);
		}, 90);
		saveWeekButton.screenCenter(X);
		saveWeekButton.x += 120;
		add(saveWeekButton);

		add(UI_box);
	}

	var songsInputText:ShadowTextInput;
	var backgroundInputText:ShadowTextInput;
	var displayNameInputText:ShadowTextInput;
	var weekNameInputText:ShadowTextInput;
	var weekFileInputText:ShadowTextInput;
	var opponentInputText:ShadowTextInput;
	var boyfriendInputText:ShadowTextInput;
	var girlfriendInputText:ShadowTextInput;
	var hideCheckbox:ShadowCheckbox;

	public static var weekFileName:String = 'week1';

	function addWeekUI()
	{
		var tab:FlxSpriteGroup = UI_box.getTabGroup("Week");
		if (tab == null)
			return;

		tab.add(new ShadowLabel(10, 12, "Songs:"));
		songsInputText = new ShadowTextInput(10, 30, 220, '');
		songsInputText.callback = function(text)
		{
			var splittedText:Array<String> = text.trim().split(',');
			for (i in 0...splittedText.length)
				splittedText[i] = splittedText[i].trim();

			while (splittedText.length < weekFile.songs.length)
				weekFile.songs.pop();

			for (i in 0...splittedText.length)
			{
				if (i >= weekFile.songs.length)
					weekFile.songs.push([splittedText[i], 'dad', [146, 113, 253]]);
				else
				{
					weekFile.songs[i][0] = splittedText[i];
					if (weekFile.songs[i][1] == null || weekFile.songs[i][1])
					{
						weekFile.songs[i][1] = 'dad';
						weekFile.songs[i][2] = [146, 113, 253];
					}
				}
			}
			updateText();
		};
		blockPressWhileTypingOn.push(songsInputText);
		tab.add(songsInputText);

		tab.add(new ShadowLabel(10, 62, "Characters:"));
		opponentInputText = new ShadowTextInput(10, 80, 70, '');
		opponentInputText.callback = function(text)
		{
			weekFile.weekCharacters[0] = text.trim();
			updateText();
		};
		blockPressWhileTypingOn.push(opponentInputText);
		tab.add(opponentInputText);

		boyfriendInputText = new ShadowTextInput(85, 80, 70, '');
		boyfriendInputText.callback = function(text)
		{
			weekFile.weekCharacters[1] = text.trim();
			updateText();
		};
		blockPressWhileTypingOn.push(boyfriendInputText);
		tab.add(boyfriendInputText);

		girlfriendInputText = new ShadowTextInput(160, 80, 70, '');
		girlfriendInputText.callback = function(text)
		{
			weekFile.weekCharacters[2] = text.trim();
			updateText();
		};
		blockPressWhileTypingOn.push(girlfriendInputText);
		tab.add(girlfriendInputText);

		tab.add(new ShadowLabel(10, 112, "Background Asset:"));
		backgroundInputText = new ShadowTextInput(10, 130, 120, '');
		backgroundInputText.callback = function(text)
		{
			weekFile.weekBackground = text.trim();
			reloadBG();
		};
		blockPressWhileTypingOn.push(backgroundInputText);
		tab.add(backgroundInputText);

		tab.add(new ShadowLabel(10, 172, "Display Name:"));
		displayNameInputText = new ShadowTextInput(10, 190, 220, '');
		displayNameInputText.callback = function(text)
		{
			weekFile.storyName = text.trim();
			updateText();
		};
		blockPressWhileTypingOn.push(displayNameInputText);
		tab.add(displayNameInputText);

		tab.add(new ShadowLabel(10, 222, "Week Name (Reset Score Menu):"));
		weekNameInputText = new ShadowTextInput(10, 240, 150, '');
		weekNameInputText.callback = function(text)
		{
			weekFile.weekName = text.trim();
		};
		blockPressWhileTypingOn.push(weekNameInputText);
		tab.add(weekNameInputText);

		tab.add(new ShadowLabel(10, 272, "Week File:"));
		weekFileInputText = new ShadowTextInput(10, 290, 100, '');
		weekFileInputText.callback = function(text)
		{
			weekFileName = text.trim();
			reloadWeekThing();
		};
		blockPressWhileTypingOn.push(weekFileInputText);
		tab.add(weekFileInputText);

		hideCheckbox = new ShadowCheckbox(10, 325, "Hide from Story Mode?", false, function(checked)
		{
			weekFile.hideStoryMode = checked;
		});
		tab.add(hideCheckbox);

		reloadWeekThing();
	}

	var weekBeforeInputText:ShadowTextInput;
	var difficultiesInputText:ShadowTextInput;
	var lockedCheckbox:ShadowCheckbox;
	var hiddenUntilUnlockCheckbox:ShadowCheckbox;

	function addOtherUI()
	{
		var tab:FlxSpriteGroup = UI_box.getTabGroup("Other");
		if (tab == null)
			return;

		lockedCheckbox = new ShadowCheckbox(10, 15, "Week starts Locked", false, function(checked)
		{
			weekFile.startUnlocked = !checked;
			lock.visible = checked;
			hiddenUntilUnlockCheckbox.alpha = 0.4 + 0.6 * (checked ? 1 : 0);
		});
		tab.add(lockedCheckbox);

		hiddenUntilUnlockCheckbox = new ShadowCheckbox(10, 40, "Hidden until Unlocked", false, function(checked)
		{
			weekFile.hiddenUntilUnlocked = checked;
		});
		hiddenUntilUnlockCheckbox.alpha = 0.4;
		tab.add(hiddenUntilUnlockCheckbox);

		tab.add(new ShadowLabel(10, 75, "Week to finish for Unlock:"));
		weekBeforeInputText = new ShadowTextInput(10, 95, 100, '');
		weekBeforeInputText.callback = function(text)
		{
			weekFile.weekBefore = text.trim();
		};
		blockPressWhileTypingOn.push(weekBeforeInputText);
		tab.add(weekBeforeInputText);

		tab.add(new ShadowLabel(10, 135, "Difficulties:"));
		difficultiesInputText = new ShadowTextInput(10, 155, 200, '');
		difficultiesInputText.callback = function(text)
		{
			weekFile.difficulties = text.trim();
		};
		blockPressWhileTypingOn.push(difficultiesInputText);
		tab.add(difficultiesInputText);

		tab.add(new ShadowLabel(10, 190, "Default: Easy, Normal, Hard", ShadowStyle.FONT_SIZE_SM, ShadowStyle.TEXT_SECONDARY));
	}

	function reloadAllShit()
	{
		var weekString:String = weekFile.songs[0][0];
		for (i in 1...weekFile.songs.length)
			weekString += ', ' + weekFile.songs[i][0];

		songsInputText.text = weekString;
		backgroundInputText.text = weekFile.weekBackground;
		displayNameInputText.text = weekFile.storyName;
		weekNameInputText.text = weekFile.weekName;
		weekFileInputText.text = weekFileName;

		opponentInputText.text = weekFile.weekCharacters[0];
		boyfriendInputText.text = weekFile.weekCharacters[1];
		girlfriendInputText.text = weekFile.weekCharacters[2];

		hideCheckbox.checked = weekFile.hideStoryMode;
		weekBeforeInputText.text = weekFile.weekBefore;

		difficultiesInputText.text = '';
		if (weekFile.difficulties != null)
			difficultiesInputText.text = weekFile.difficulties;

		lockedCheckbox.checked = !weekFile.startUnlocked;
		lock.visible = lockedCheckbox.checked;

		hiddenUntilUnlockCheckbox.checked = weekFile.hiddenUntilUnlocked;
		hiddenUntilUnlockCheckbox.alpha = 0.4 + 0.6 * (lockedCheckbox.checked ? 1 : 0);

		reloadBG();
		reloadWeekThing();
		updateText();
	}

	function updateText()
	{
		for (i in 0...grpWeekCharacters.length)
			grpWeekCharacters.members[i].changeCharacter(weekFile.weekCharacters[i]);

		var stringThing:Array<String> = [];
		for (i in 0...weekFile.songs.length)
			stringThing.push(weekFile.songs[i][0]);

		txtTracklist.text = '';
		for (i in 0...stringThing.length)
			txtTracklist.text += stringThing[i] + '\n';

		txtTracklist.text = txtTracklist.text.toUpperCase();
		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;

		txtWeekTitle.text = weekFile.storyName.toUpperCase();
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);
	}

	function reloadBG()
	{
		bgSprite.visible = true;
		var assetName:String = weekFile.weekBackground;
		var isMissing:Bool = true;

		if (assetName != null && assetName.length > 0)
		{
			#if FEATURE_MODS
			var modPath = Paths.modsImages('menubackgrounds/menu_' + assetName);
			if (FileSystem.exists(modPath))
			{
				bgSprite.loadGraphic(modPath);
				isMissing = false;
			}
			else
			#end
			{
				var basePath = Paths.getPath('images/menubackgrounds/menu_' + assetName + '.png', IMAGE);
				if (FileSystem.exists(basePath))
				{
					bgSprite.loadGraphic(basePath);
					isMissing = false;
				}
			}
		}

		if (isMissing)
			bgSprite.visible = false;
	}

	function reloadWeekThing()
	{
		weekThing.visible = true;
		missingFileText.visible = false;

		var assetName:String = weekFileInputText.text.trim();
		var isMissing:Bool = true;

		if (assetName != null && assetName.length > 0)
		{
			#if FEATURE_MODS
			var modPath:String = Paths.modsImages('storymenu/' + assetName);
			if (FileSystem.exists(modPath))
			{
				weekThing.loadGraphic(modPath);
				isMissing = false;
			}
			else
			#end
			{
				var basePath:String = Paths.getPath('images/storymenu/' + assetName + '.png', IMAGE);
				if (FileSystem.exists(basePath))
				{
					weekThing.loadGraphic(basePath);
					isMissing = false;
				}
				else
				{
					#if HAS_GPU_TEXTURES
					var baseGpuPath:String = Paths.getPath('images/storymenu/' + assetName + Paths.GPU_IMAGE_EXT, Paths.getImageAssetType(Paths.GPU_IMAGE_EXT));
					if (FileSystem.exists(baseGpuPath))
					{
						weekThing.loadGraphic(baseGpuPath);
						isMissing = false;
					}
					#end
				}
			}
		}

		if (isMissing)
		{
			weekThing.visible = false;
			missingFileText.visible = true;
			missingFileText.text = 'MISSING FILE: images/storymenu/' + assetName + '.png';
		}

		recalculateStuffPosition();

		#if FEATURE_DISCORD_RPC
		DiscordClient.changePresence("Week Editor", "Editing: " + weekFileName);
		#end
	}

	override function update(elapsed:Float)
	{
		if (loadedWeek != null)
		{
			weekFile = loadedWeek;
			loadedWeek = null;
			reloadAllShit();
		}

		var blockInput:Bool = false;
		for (inputText in blockPressWhileTypingOn)
		{
			if (inputText.hasFocus())
			{
				ClientPrefs.toggleVolumeKeys(false);
				blockInput = true;

				if (FlxG.keys.justPressed.ENTER)
					inputText.input.hasFocus = false;
				break;
			}
		}

		if (!blockInput)
		{
			ClientPrefs.toggleVolumeKeys(true);
			if (FlxG.keys.justPressed.ESCAPE #if FEATURE_MOBILE_CONTROLS || touchPad.buttonB.justPressed #end)
			{
				MusicBeatState.switchState(new MasterEditorMenu());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
		}

		super.update(elapsed);

		lock.y = weekThing.y;
		missingFileText.y = weekThing.y + 36;
	}

	function recalculateStuffPosition()
	{
		weekThing.screenCenter(X);
		lock.x = weekThing.width + 10 + weekThing.x;
	}

	private static var _file:FileReference;

	public static function loadWeek()
	{
		#if mobile
		var fileDialog:lime.ui.FileDialog = new lime.ui.FileDialog();
		fileDialog.onOpen.add((file) -> onLoadComplete(file));
		fileDialog.onCancel.add(() -> onLoadCancel(true));
		fileDialog.open('json');
		#else
		var jsonFilter:FileFilter = new FileFilter('JSON', 'json');
		_file = new FileReference();
		_file.addEventListener(Event.COMPLETE, onLoadComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse([jsonFilter]);
		#end
	}

	public static var loadedWeek:WeekFile = null;
	public static var loadError:Bool = false;

	private static function onLoadComplete(#if mobile file:haxe.io.Bytes #else _ #end):Void
	{
		#if mobile
		if (file != null && file.length > 0)
		{
			var jsonStr:String = file.getString(0, file.length);
			loadedWeek = cast Json.parse(jsonStr);
			if (loadedWeek.weekCharacters != null && loadedWeek.weekName != null)
			{
				trace("Successfully loaded file.");
				loadError = false;
				weekFileName = '';
				return;
			}
		}
		#elseif sys
		_file.removeEventListener(Event.COMPLETE, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		var fullPath:String = null;
		@:privateAccess
		if (_file.__path != null)
			fullPath = _file.__path;

		if (fullPath != null)
		{
			var rawJson:String = File.getContent(fullPath);
			if (rawJson != null)
			{
				loadedWeek = cast Json.parse(rawJson, fullPath);
				if (loadedWeek.weekCharacters != null && loadedWeek.weekName != null)
				{
					var cutName:String = _file.name.substr(0, _file.name.length - 5);
					trace("Successfully loaded file: " + cutName);
					loadError = false;
					weekFileName = cutName;
					_file = null;
					return;
				}
			}
		}
		loadError = true;
		loadedWeek = null;
		_file = null;
		#else
		trace("File couldn't be loaded! You aren't on Desktop, are you?");
		#end
	}

	private static function onLoadCancel(_):Void
	{
		#if !mobile
		_file.removeEventListener(Event.COMPLETE, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		#end
		trace("Cancelled file loading.");
	}

	private static function onLoadError(_):Void
	{
		#if !mobile
		_file.removeEventListener(Event.COMPLETE, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		#end
		trace("Problem loading file");
	}

	public static function saveWeek(weekFile:WeekFile)
	{
		var data:String = Json.stringify(weekFile, "\t");
		if (data.length > 0)
		{
			#if mobile
			var fileDialog:lime.ui.FileDialog = new lime.ui.FileDialog();
			fileDialog.onCancel.add(() -> onSaveCancel(null));
			fileDialog.onSave.add((path) -> onSaveComplete(null));
			fileDialog.save(data, null, weekFileName + ".json", null, "*/*");
			#else
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, weekFileName + ".json");
			#end
		}
	}

	private static function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	private static function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	private static function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}
}

class WeekEditorFreeplayState extends MusicBeatState
{
	var weekFile:WeekFile = null;

	public function new(weekFile:WeekFile = null)
	{
		super();
		this.weekFile = WeekData.createWeekFile();
		if (weekFile != null)
			this.weekFile = weekFile;
	}

	var bg:FlxSprite;
	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<HealthIcon> = [];

	var curSelected:Int = 0;

	override function create()
	{
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = FlxColor.WHITE;
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...weekFile.songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, weekFile.songs[i][0], true);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);
			songText.scaleX = Math.min(1, 980 / songText.width);
			songText.snapToPosition();

			var icon:HealthIcon = new HealthIcon(weekFile.songs[i][1]);
			icon.sprTracker = songText;
			iconArray.push(icon);
			add(icon);
		}

		addEditorBox();
		changeSelection();
		#if FEATURE_MOBILE_CONTROLS 
		addTouchPad("UP_DOWN", "B");
		#end
		super.create();
	}

	var UI_box:ShadowTabMenu;
	var blockPressWhileTypingOn:Array<ShadowTextInput> = [];

	function addEditorBox()
	{
		var tabs:Array<TabDef> = [{name: 'Freeplay', label: 'Freeplay'}];
		UI_box = new ShadowTabMenu(FlxG.width - 360, FlxG.height - 270, tabs, 250, 200);
		UI_box.scrollFactor.set();

		addFreeplayUI();

		var blackBlack:FlxSprite = new FlxSprite(0, 670).makeGraphic(FlxG.width, 50, FlxColor.BLACK);
		blackBlack.alpha = 0.6;
		add(blackBlack);

		var loadWeekButton:ShadowButton = new ShadowButton(0, 685, "Load Week", function()
		{
			WeekEditorState.loadWeek();
		}, 90);
		loadWeekButton.screenCenter(X);
		loadWeekButton.x -= 120;
		add(loadWeekButton);

		var storyModeButton:ShadowButton = new ShadowButton(0, 685, "Story Mode", function()
		{
			MusicBeatState.switchState(new WeekEditorState(weekFile));
		}, 90);
		storyModeButton.screenCenter(X);
		add(storyModeButton);

		var saveWeekButton:ShadowButton = new ShadowButton(0, 685, "Save Week", function()
		{
			WeekEditorState.saveWeek(weekFile);
		}, 90);
		saveWeekButton.screenCenter(X);
		saveWeekButton.x += 120;
		add(saveWeekButton);

		add(UI_box);
	}

	var bgColorStepperR:ShadowStepper;
	var bgColorStepperG:ShadowStepper;
	var bgColorStepperB:ShadowStepper;
	var iconInputText:ShadowTextInput;

	function addFreeplayUI()
	{
		var tab:FlxSpriteGroup = UI_box.getTabGroup("Freeplay");
		if (tab == null)
			return;

		tab.add(new ShadowLabel(10, 12, "Background Color R/G/B:"));

		bgColorStepperR = new ShadowStepper(10, 32, 20, 255, 0, 255, 0, function(v)
		{
			updateBG();
		}, 55);
		tab.add(bgColorStepperR);

		bgColorStepperG = new ShadowStepper(70, 32, 20, 255, 0, 255, 0, function(v)
		{
			updateBG();
		}, 55);
		tab.add(bgColorStepperG);

		bgColorStepperB = new ShadowStepper(130, 32, 20, 255, 0, 255, 0, function(v)
		{
			updateBG();
		}, 55);
		tab.add(bgColorStepperB);

		var copyColor:ShadowButton = new ShadowButton(10, 65, "Copy", function()
		{
			Clipboard.text = bg.color.red + ',' + bg.color.green + ',' + bg.color.blue;
		}, 60);
		tab.add(copyColor);

		var pasteColor:ShadowButton = new ShadowButton(75, 65, "Paste", function()
		{
			if (Clipboard.text != null)
			{
				var leColor:Array<Int> = [];
				var splitted:Array<String> = Clipboard.text.trim().split(',');
				for (i in 0...splitted.length)
				{
					var toPush:Int = Std.parseInt(splitted[i]);
					if (!Math.isNaN(toPush))
					{
						if (toPush > 255)
							toPush = 255;
						else if (toPush < 0)
							toPush *= -1;
						leColor.push(toPush);
					}
				}
				if (leColor.length > 2)
				{
					bgColorStepperR.value = leColor[0];
					bgColorStepperG.value = leColor[1];
					bgColorStepperB.value = leColor[2];
					updateBG();
				}
			}
		}, 60);
		tab.add(pasteColor);

		tab.add(new ShadowLabel(10, 100, "Selected icon:"));
		iconInputText = new ShadowTextInput(10, 118, 100, '');
		iconInputText.callback = function(text)
		{
			weekFile.songs[curSelected][1] = text;
			iconArray[curSelected].changeIcon(text);
		};
		blockPressWhileTypingOn.push(iconInputText);
		tab.add(iconInputText);

		var hideFreeplayCheckbox:ShadowCheckbox = new ShadowCheckbox(10, 152, "Hide from Freeplay?", weekFile.hideFreeplay, function(checked)
		{
			weekFile.hideFreeplay = checked;
		});
		tab.add(hideFreeplayCheckbox);
	}

	function updateBG()
	{
		weekFile.songs[curSelected][2][0] = Math.round(bgColorStepperR.value);
		weekFile.songs[curSelected][2][1] = Math.round(bgColorStepperG.value);
		weekFile.songs[curSelected][2][2] = Math.round(bgColorStepperB.value);
		bg.color = FlxColor.fromRGB(weekFile.songs[curSelected][2][0], weekFile.songs[curSelected][2][1], weekFile.songs[curSelected][2][2]);
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = weekFile.songs.length - 1;
		if (curSelected >= weekFile.songs.length)
			curSelected = 0;

		var bullShit:Int = 0;
		for (i in 0...iconArray.length)
			iconArray[i].alpha = 0.6;

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;
			item.alpha = 0.6;
			if (item.targetY == 0)
				item.alpha = 1;
		}

		iconInputText.text = weekFile.songs[curSelected][1];
		bgColorStepperR.value = Math.round(weekFile.songs[curSelected][2][0]);
		bgColorStepperG.value = Math.round(weekFile.songs[curSelected][2][1]);
		bgColorStepperB.value = Math.round(weekFile.songs[curSelected][2][2]);
		updateBG();
	}

	override function update(elapsed:Float)
	{
		if (WeekEditorState.loadedWeek != null)
		{
			super.update(elapsed);
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new WeekEditorFreeplayState(WeekEditorState.loadedWeek));
			WeekEditorState.loadedWeek = null;
			return;
		}

		var blockInput:Bool = false;
		for (inputText in blockPressWhileTypingOn)
		{
			if (inputText.hasFocus())
			{
				ClientPrefs.toggleVolumeKeys(false);
				blockInput = true;
				if (FlxG.keys.justPressed.ENTER)
					inputText.input.hasFocus = false;
				break;
			}
		}

		if (!blockInput)
		{
			ClientPrefs.toggleVolumeKeys(true);
			if (FlxG.keys.justPressed.ESCAPE #if FEATURE_MOBILE_CONTROLS || touchPad.buttonB.justPressed #end)
			{
				MusicBeatState.switchState(new MasterEditorMenu());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}

			if (controls.UI_UP_P)
				changeSelection(-1);
			if (controls.UI_DOWN_P)
				changeSelection(1);
		}
		super.update(elapsed);
	}
}
