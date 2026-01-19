package states.editors;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileFilter;
import objects.MenuCharacter;

class MenuCharacterEditorState extends MusicBeatState
{
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;
	var characterFile:MenuCharacterFile = null;
	var defaultCharacters:Array<String> = ['dad', 'bf', 'gf'];

	var camEditor:FlxCamera;
	var camHUD:FlxCamera;
	var camOther:FlxCamera;

	var UI_offsetPanel:ShadowPanel;
	var UI_offsetLabel:ShadowLabel;
	
	var UI_helpOverlay:FlxSprite;
	var UI_help:ShadowPanel;
	var showHelp:Bool = false;

	override function create()
	{
		characterFile = {
			image: 'Menu_Dad',
			scale: 1,
			position: [0, 0],
			idle_anim: 'M Dad Idle',
			confirm_anim: 'M Dad Idle',
			flipX: false
		};

		camEditor = initPsychCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;

		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Menu Character Editor", "Editting: " + characterFile.image);
		#end

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();
		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, defaultCharacters[char]);
			weekCharacterThing.y += 70;
			weekCharacterThing.alpha = 0.2;
			grpWeekCharacters.add(weekCharacterThing);
		}

		add(new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51));
		add(grpWeekCharacters);

		makeOffsetUI();
		addEditorBox();
		makeHelpUI();

		FlxG.mouse.visible = true;
		updateCharTypeBox();

		addTouchPad("MENU_CHARACTER", "MENU_CHARACTER");

		super.create();
	}

	var UI_typebox:ShadowTabMenu;
	var UI_mainbox:ShadowTabMenu;
	var blockPressWhileTypingOn:Array<ShadowTextInput> = [];

	function makeOffsetUI()
	{
		var panelWidth = 160;
		var panelHeight = 80;
		var panelX = (FlxG.width - panelWidth) / 2;
		var panelY = FlxG.height - 180;

		UI_offsetPanel = new ShadowPanel(panelX, panelY, panelWidth, panelHeight, "Position Offset");
		UI_offsetPanel.cameras = [camHUD];
		UI_offsetPanel.showCloseButton = false;
		UI_offsetPanel.showMinimizeButton = false;

		UI_offsetLabel = new ShadowLabel(10, ShadowStyle.HEIGHT_HEADER + 10, "[0, 0]", ShadowStyle.FONT_SIZE_LG);
		UI_offsetPanel.add(UI_offsetLabel);

		add(UI_offsetPanel);
	}

	function makeHelpUI()
	{
		var panelWidth = 500;
		var panelHeight = 280;
		var panelX = (FlxG.width - panelWidth) / 2;
		var panelY = (FlxG.height - panelHeight) / 2;

		UI_helpOverlay = new FlxSprite();
		UI_helpOverlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		UI_helpOverlay.alpha = 0.3;
		UI_helpOverlay.cameras = [camOther];
		UI_helpOverlay.visible = false;
		add(UI_helpOverlay);

		UI_help = new ShadowPanel(panelX, panelY, panelWidth, panelHeight, "Menu Character Editor Help");
		UI_help.cameras = [camOther];
		UI_help.visible = false;
		UI_help.showCloseButton = false;
		UI_help.showMinimizeButton = false;

		var helpText = "Arrow Keys - Change Offset (Hold Shift for 10x speed)\n\n" +
			"Space - Play 'Start Press' animation (Boyfriend only)\n\n" +
			"F1 - Toggle this help menu\n\n" +
			"ESC - Exit to Editor Menu\n\n\n" +
			"Press F1 or ESC to close";

		var helpContent = new ShadowLabel(20, ShadowStyle.HEIGHT_HEADER + 15, helpText, ShadowStyle.FONT_SIZE_MD);
		UI_help.add(helpContent);

		add(UI_help);
	}

	function addEditorBox()
	{
		// Character Type panel - bottom left
		var typeWidth = 150;
		var typeHeight = 180;
		var tabs = [{name: 'Character Type', label: 'Character Type'}];
		UI_typebox = new ShadowTabMenu(130, FlxG.height - typeHeight - 80, tabs, typeWidth, typeHeight);
		UI_typebox.cameras = [camHUD];
		UI_typebox.showCloseButton = false;
		UI_typebox.showMinimizeButton = false;
		addTypeUI();
		add(UI_typebox);

		// Character panel - bottom right
		var charWidth = 260;
		var charHeight = 220;
		var tabs = [{name: 'Character', label: 'Character'}];
		UI_mainbox = new ShadowTabMenu(FlxG.width - charWidth - 130, FlxG.height - charHeight - 80, tabs, charWidth, charHeight);
		UI_mainbox.cameras = [camHUD];
		UI_mainbox.showCloseButton = false;
		UI_mainbox.showMinimizeButton = false;
		addCharacterUI();
		add(UI_mainbox);

		// Load/Save buttons - centered at bottom
		var buttonWidth = 140;
		var buttonSpacing = 12;
		var totalWidth = buttonWidth * 2 + buttonSpacing;
		var baseX = (FlxG.width - totalWidth) / 2;
		var buttonY = FlxG.height - 75;

		var loadButton = new ShadowButton(baseX, buttonY, "Load Character", function()
		{
			loadCharacter();
		}, buttonWidth, ShadowStyle.HEIGHT_BUTTON);
		loadButton.cameras = [camHUD];
		add(loadButton);

		var saveButton = new ShadowButton(baseX + buttonWidth + buttonSpacing, buttonY, "Save Character", function()
		{
			saveCharacter();
		}, buttonWidth, ShadowStyle.HEIGHT_BUTTON);
		saveButton.cameras = [camHUD];
		add(saveButton);

		// Help tip - top right
		var tipText = new FlxText(FlxG.width - 100, 15, 80, "F1 - Help", ShadowStyle.FONT_SIZE_SM);
		tipText.setFormat(null, ShadowStyle.FONT_SIZE_SM, FlxColor.WHITE, RIGHT);
		tipText.scrollFactor.set();
		tipText.cameras = [camHUD];
		add(tipText);
	}

	var opponentCheckbox:ShadowCheckbox;
	var boyfriendCheckbox:ShadowCheckbox;
	var girlfriendCheckbox:ShadowCheckbox;
	var curTypeSelected:Int = 0; // 0 = Dad, 1 = BF, 2 = GF

	function addTypeUI()
	{
		var tab_group = UI_typebox.getTabGroup("Character Type");

		opponentCheckbox = new ShadowCheckbox(10, 20, "Opponent", false, function(_)
		{
			selectCharacterType(0);
		});

		boyfriendCheckbox = new ShadowCheckbox(opponentCheckbox.x, opponentCheckbox.y + 40, "Boyfriend", false, function(_)
		{
			selectCharacterType(1);
		});

		girlfriendCheckbox = new ShadowCheckbox(boyfriendCheckbox.x, boyfriendCheckbox.y + 40, "Girlfriend", false, function(_)
		{
			selectCharacterType(2);
		});

		tab_group.add(opponentCheckbox);
		tab_group.add(boyfriendCheckbox);
		tab_group.add(girlfriendCheckbox);
	}

	var imageInputText:ShadowTextInput;
	var idleInputText:ShadowTextInput;
	var confirmInputText:ShadowTextInput;
	var scaleStepper:ShadowStepper;
	var flipXCheckbox:ShadowCheckbox;

	function addCharacterUI()
	{
		var tab_group = UI_mainbox.getTabGroup("Character");
		var pad = 10;
		var inputWidth = 160;
		var rowHeight = 45;

		// Row 1: Image file name + Scale
		var row1Y = 20;
		tab_group.add(new ShadowLabel(pad, row1Y, 'Image file name:', ShadowStyle.FONT_SIZE_SM));
		imageInputText = new ShadowTextInput(pad, row1Y + 18, inputWidth, characterFile.image, function(text)
		{
			characterFile.image = text;
		});
		blockPressWhileTypingOn.push(imageInputText);

		tab_group.add(new ShadowLabel(pad + inputWidth + 15, row1Y, 'Scale:', ShadowStyle.FONT_SIZE_SM));
		scaleStepper = new ShadowStepper(pad + inputWidth + 15, row1Y + 18, 0.05, characterFile.scale, 0.1, 30, 2, function(value)
		{
			characterFile.scale = value;
			reloadSelectedCharacter();
		}, 80);

		// Row 2: Idle animation
		var row2Y = row1Y + rowHeight;
		tab_group.add(new ShadowLabel(pad, row2Y, 'Idle animation (.XML):', ShadowStyle.FONT_SIZE_SM));
		idleInputText = new ShadowTextInput(pad, row2Y + 18, inputWidth, characterFile.idle_anim, function(text)
		{
			characterFile.idle_anim = text;
		});
		blockPressWhileTypingOn.push(idleInputText);

		// Row 3: Confirm animation
		var row3Y = row2Y + rowHeight;
		tab_group.add(new ShadowLabel(pad, row3Y, 'Start Press animation (.XML):', ShadowStyle.FONT_SIZE_SM));
		confirmInputText = new ShadowTextInput(pad, row3Y + 18, inputWidth, characterFile.confirm_anim, function(text)
		{
			characterFile.confirm_anim = text;
		});
		blockPressWhileTypingOn.push(confirmInputText);

		// Row 4: Flip X checkbox + Reload button
		var row4Y = row3Y + rowHeight;
		flipXCheckbox = new ShadowCheckbox(pad, row4Y + 5, "Flip X", characterFile.flipX, function(value)
		{
			grpWeekCharacters.members[curTypeSelected].flipX = value;
			characterFile.flipX = value;
		});

		var reloadImageButton = new ShadowButton(pad + inputWidth + 15, row4Y, "Reload Char", function()
		{
			reloadSelectedCharacter();
		}, 90, ShadowStyle.HEIGHT_BUTTON);

		tab_group.add(imageInputText);
		tab_group.add(scaleStepper);
		tab_group.add(idleInputText);
		tab_group.add(confirmInputText);
		tab_group.add(flipXCheckbox);
		tab_group.add(reloadImageButton);
	}

	function updateCharTypeBox()
	{
		opponentCheckbox.setChecked(false);
		boyfriendCheckbox.setChecked(false);
		girlfriendCheckbox.setChecked(false);

		switch (curTypeSelected)
		{
			case 0:
				opponentCheckbox.setChecked(true);
			case 1:
				boyfriendCheckbox.setChecked(true);
			case 2:
				girlfriendCheckbox.setChecked(true);
		}

		updateCharacters();
	}

	function selectCharacterType(index:Int)
	{
		curTypeSelected = index;
		updateCharTypeBox();
	}

	function updateCharacters()
	{
		for (i in 0...3)
		{
			var char:MenuCharacter = grpWeekCharacters.members[i];
			char.alpha = 0.2;
			char.character = '';
			char.changeCharacter(defaultCharacters[i]);
		}
		reloadSelectedCharacter();
	}

	function reloadSelectedCharacter()
	{
		var char:MenuCharacter = grpWeekCharacters.members[curTypeSelected];

		char.alpha = 1;
		char.frames = Paths.getSparrowAtlas('menucharacters/' + characterFile.image);
		char.animation.addByPrefix('idle', characterFile.idle_anim, 24);
		if (curTypeSelected == 1)
			char.animation.addByPrefix('confirm', characterFile.confirm_anim, 24, false);
		char.flipX = (characterFile.flipX == true);

		char.scale.set(characterFile.scale, characterFile.scale);
		char.updateHitbox();
		char.animation.play('idle');
		updateOffset();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Menu Character Editor", "Editting: " + characterFile.image);
		#end
	}

	override function update(elapsed:Float)
	{
		// Handle help UI toggle
		if (FlxG.keys.justPressed.F1)
		{
			showHelp = !showHelp;
			UI_help.visible = showHelp;
			UI_helpOverlay.visible = showHelp;
			FlxG.mouse.enabled = !showHelp;
		}

		// If help is open, only allow closing it
		if (showHelp)
		{
			if (FlxG.keys.justPressed.ESCAPE #if android || FlxG.android.justPressed.BACK #end)
			{
				showHelp = false;
				UI_help.visible = false;
				UI_helpOverlay.visible = false;
				FlxG.mouse.enabled = true;
			}
			super.update(elapsed);
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
					inputText.setFocus(false);
				break;
			}
		}

		if (!blockInput)
		{
			ClientPrefs.toggleVolumeKeys(true);
			if (FlxG.keys.justPressed.ESCAPE #if android || FlxG.android.justPressed.BACK #end || touchPad.buttonB.justPressed)
			{
				MusicBeatState.switchState(new states.editors.MasterEditorMenu());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}

			var shiftMult:Int = 1;
			if (FlxG.keys.pressed.SHIFT || touchPad.buttonA.pressed)
				shiftMult = 10;

			if (FlxG.keys.justPressed.LEFT || touchPad.buttonLeft.justPressed)
			{
				characterFile.position[0] += shiftMult;
				updateOffset();
			}
			if (FlxG.keys.justPressed.RIGHT || touchPad.buttonRight.justPressed)
			{
				characterFile.position[0] -= shiftMult;
				updateOffset();
			}
			if (FlxG.keys.justPressed.UP || touchPad.buttonUp.justPressed)
			{
				characterFile.position[1] += shiftMult;
				updateOffset();
			}
			if (FlxG.keys.justPressed.DOWN || touchPad.buttonDown.justPressed)
			{
				characterFile.position[1] -= shiftMult;
				updateOffset();
			}

			if (FlxG.keys.justPressed.SPACE || touchPad.buttonC.justPressed && curTypeSelected == 1)
			{
				grpWeekCharacters.members[curTypeSelected].animation.play('confirm', true);
			}
		}

		var char:MenuCharacter = grpWeekCharacters.members[1];
		if (char.animation.curAnim != null && char.animation.curAnim.name == 'confirm' && char.animation.curAnim.finished)
		{
			char.animation.play('idle', true);
		}

		super.update(elapsed);
	}

	function updateOffset()
	{
		var char:MenuCharacter = grpWeekCharacters.members[curTypeSelected];
		char.offset.set(characterFile.position[0], characterFile.position[1]);
		if (UI_offsetLabel != null)
			UI_offsetLabel.text = '[' + characterFile.position[0] + ', ' + characterFile.position[1] + ']';
	}

	var _file:FileReference = null;

	function loadCharacter()
	{
		#if mobile
		var fileDialog = new lime.ui.FileDialog();
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

	function onLoadComplete(#if mobile file:haxe.io.Bytes #else _ #end):Void
	{
		#if mobile
		if (file != null && file.length > 0)
		{
			var jsonStr:String = file.getString(0, file.length);
			var loadedChar:MenuCharacterFile = cast Json.parse(jsonStr);
			if (loadedChar.idle_anim != null && loadedChar.confirm_anim != null) // Make sure it's really a character
			{
				trace("Successfully loaded file.");
				characterFile = loadedChar;
				reloadSelectedCharacter();
				imageInputText.text = characterFile.image;
				idleInputText.text = characterFile.idle_anim;
				confirmInputText.text = characterFile.confirm_anim;
				scaleStepper.value = characterFile.scale;
				updateOffset();
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
				var loadedChar:MenuCharacterFile = cast Json.parse(rawJson, fullPath);
				if (loadedChar.idle_anim != null && loadedChar.confirm_anim != null) // Make sure it's really a character
				{
					var cutName:String = _file.name.substr(0, _file.name.length - 5);
					trace("Successfully loaded file: " + cutName);
					characterFile = loadedChar;
					reloadSelectedCharacter();
					imageInputText.text = characterFile.image;
					idleInputText.text = characterFile.idle_anim;
					confirmInputText.text = characterFile.confirm_anim;
					scaleStepper.value = characterFile.scale;
					updateOffset();
					_file = null;
					return;
				}
			}
		}
		_file = null;
		#else
		trace("File couldn't be loaded! You aren't on Desktop, are you?");
		#end
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onLoadCancel(_):Void
	{
		#if !mobile
		_file.removeEventListener(Event.COMPLETE, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		#end
		trace("Cancelled file loading.");
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onLoadError(_):Void
	{
		#if !mobile
		_file.removeEventListener(Event.COMPLETE, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		#end
		trace("Problem loading file");
	}

	function saveCharacter()
	{
		var data:String = Json.stringify(characterFile, "\t");
		if (data.length > 0)
		{
			var splittedImage:Array<String> = imageInputText.text.trim().split('_');
			var characterName:String = splittedImage[splittedImage.length - 1].toLowerCase().replace(' ', '');

			#if mobile
			var fileDialog = new lime.ui.FileDialog();
			fileDialog.onCancel.add(() -> onSaveCancel(null));
			fileDialog.onSave.add((path) -> onSaveComplete(null));
			fileDialog.save(data, null, characterName + ".json", null, "*/*");
			#else
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, characterName + ".json");
			#end
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}
}
