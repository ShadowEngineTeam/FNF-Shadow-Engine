package states.editors;

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
	var txtOffsets:FlxText;
	var defaultCharacters:Array<String> = ['dad', 'bf', 'gf'];

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
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
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

		txtOffsets = new FlxText(20, 10, 0, "[0, 0]", 32);
		txtOffsets.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		txtOffsets.alpha = 0.7;
		add(txtOffsets);

		var tipText:FlxText = new FlxText(0, 540, FlxG.width, "Arrow Keys - Change Offset (Hold shift for 10x speed)
			\nSpace - Play \"Start Press\" animation (Boyfriend Character Type)", 16);
		tipText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		tipText.scrollFactor.set();
		add(tipText);

		addEditorBox();
		FlxG.mouse.visible = true;
		updateCharTypeBox();

		addTouchPad("MENU_CHARACTER", "MENU_CHARACTER");

		super.create();
	}

	var UI_typebox:ShadowTabMenu;
	var UI_mainbox:ShadowTabMenu;
	var blockPressWhileTypingOn:Array<ShadowTextInput> = [];

	function addEditorBox()
	{
		var tabs = [{name: 'Character Type', label: 'Character Type'}];
		UI_typebox = new ShadowTabMenu(100, FlxG.height - 180 - 50, tabs, 120, 180);
		UI_typebox.scrollFactor.set();
		addTypeUI();
		add(UI_typebox);

		var tabs = [{name: 'Character', label: 'Character'}];
		UI_mainbox = new ShadowTabMenu(FlxG.width - 240 - 100, FlxG.height - 180 - 50, tabs, 240, 180);
		UI_mainbox.scrollFactor.set();
		addCharacterUI();
		add(UI_mainbox);

		var buttonWidth = 140;
		var buttonSpacing = 12;
		var totalWidth = buttonWidth * 2 + buttonSpacing;
		var baseX = (FlxG.width - totalWidth) / 2;

		var loadButton = new ShadowButton(baseX, 480, "Load Character", function()
		{
			loadCharacter();
		}, buttonWidth, ShadowStyle.HEIGHT_BUTTON);
		add(loadButton);

		var saveButton = new ShadowButton(baseX + buttonWidth + buttonSpacing, 480, "Save Character", function()
		{
			saveCharacter();
		}, buttonWidth, ShadowStyle.HEIGHT_BUTTON);
		add(saveButton);
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

		imageInputText = new ShadowTextInput(10, 20, 140, characterFile.image, function(text)
		{
			characterFile.image = text;
		});
		blockPressWhileTypingOn.push(imageInputText);
		idleInputText = new ShadowTextInput(10, imageInputText.y + 35, 140, characterFile.idle_anim, function(text)
		{
			characterFile.idle_anim = text;
		});
		blockPressWhileTypingOn.push(idleInputText);
		confirmInputText = new ShadowTextInput(10, idleInputText.y + 35, 140, characterFile.confirm_anim, function(text)
		{
			characterFile.confirm_anim = text;
		});
		blockPressWhileTypingOn.push(confirmInputText);

		flipXCheckbox = new ShadowCheckbox(10, confirmInputText.y + 30, "Flip X", characterFile.flipX, function(value)
		{
			grpWeekCharacters.members[curTypeSelected].flipX = value;
			characterFile.flipX = value;
		});

		var reloadImageButton = new ShadowButton(140, confirmInputText.y + 30, "Reload Char", function()
		{
			reloadSelectedCharacter();
		}, 90, ShadowStyle.HEIGHT_BUTTON);

		scaleStepper = new ShadowStepper(140, imageInputText.y, 0.05, characterFile.scale, 0.1, 30, 2, function(value)
		{
			characterFile.scale = value;
			reloadSelectedCharacter();
		}, 80);

		var confirmDescText = new ShadowLabel(10, confirmInputText.y - 18, 'Start Press animation on the .XML:', ShadowStyle.FONT_SIZE_SM);
		tab_group.add(new ShadowLabel(10, imageInputText.y - 18, 'Image file name:', ShadowStyle.FONT_SIZE_SM));
		tab_group.add(new ShadowLabel(10, idleInputText.y - 18, 'Idle animation on the .XML:', ShadowStyle.FONT_SIZE_SM));
		tab_group.add(new ShadowLabel(scaleStepper.x, scaleStepper.y - 18, 'Scale:', ShadowStyle.FONT_SIZE_SM));
		tab_group.add(flipXCheckbox);
		tab_group.add(reloadImageButton);
		tab_group.add(confirmDescText);
		tab_group.add(imageInputText);
		tab_group.add(idleInputText);
		tab_group.add(confirmInputText);
		tab_group.add(scaleStepper);
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
		txtOffsets.text = '' + characterFile.position;
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
				idleInputText.text = characterFile.image;
				confirmInputText.text = characterFile.image;
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
					idleInputText.text = characterFile.image;
					confirmInputText.text = characterFile.image;
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
