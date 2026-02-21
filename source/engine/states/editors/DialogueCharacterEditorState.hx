package states.editors;

import lime.ui.FileDialog;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import lime.system.Clipboard;
import objects.TypedAlphabet;
import cutscenes.DialogueBoxPsych;
import cutscenes.DialogueCharacter;

class DialogueCharacterEditorState extends MusicBeatState
{
	var box:FlxSprite;
	var daText:TypedAlphabet = null;

	private static var TIP_TEXT_MAIN:String;
	private static var TIP_TEXT_OFFSET:String;

	var tipText:FlxText;
	var offsetLoopText:FlxText;
	var offsetIdleText:FlxText;
	var animText:FlxText;

	var camGame:FlxCamera;
	var camHUD:FlxCamera;

	var mainGroup:FlxSpriteGroup;
	var hudGroup:FlxSpriteGroup;

	var character:DialogueCharacter;
	var ghostLoop:DialogueCharacter;
	var ghostIdle:DialogueCharacter;

	var curAnim:Int = 0;

	inline static final TAB_ANIMATIONS:Int = 0;
	inline static final TAB_CHARACTER:Int = 1;

	override function create()
	{
		persistentUpdate = persistentDraw = true;
		camGame = initPsychCamera();
		camGame.bgColor = FlxColor.fromHSL(0, 0, 0.5);
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		mainGroup = new FlxSpriteGroup();
		mainGroup.cameras = [camGame];
		hudGroup = new FlxSpriteGroup();
		hudGroup.cameras = [camGame];
		add(mainGroup);
		add(hudGroup);

		character = new DialogueCharacter();
		character.scrollFactor.set();
		mainGroup.add(character);

		ghostLoop = new DialogueCharacter();
		ghostLoop.alpha = 0;
		ghostLoop.color = FlxColor.RED;
		ghostLoop.isGhost = true;
		ghostLoop.jsonFile = character.jsonFile;
		ghostLoop.cameras = [camGame];
		add(ghostLoop);

		ghostIdle = new DialogueCharacter();
		ghostIdle.alpha = 0;
		ghostIdle.color = FlxColor.BLUE;
		ghostIdle.isGhost = true;
		ghostIdle.jsonFile = character.jsonFile;
		ghostIdle.cameras = [camGame];
		add(ghostIdle);

		box = new FlxSprite(70, 370);
		box.antialiasing = ClientPrefs.data.antialiasing;
		box.frames = Paths.getSparrowAtlas('speech_bubble');
		box.scrollFactor.set();
		box.animation.addByPrefix('normal', 'speech bubble normal', 24);
		box.animation.addByPrefix('center', 'speech bubble middle', 24);
		box.animation.play('normal', true);
		box.setGraphicSize(Std.int(box.width * 0.9));
		box.updateHitbox();
		hudGroup.add(box);

		if (controls.mobileC)
		{
			TIP_TEXT_MAIN = '\nX - Reset Camera
				\nY - Toggle Speech Bubble
				\nA - Reset text';

			TIP_TEXT_OFFSET = '\nX - Reset Camera
				\nY - Toggle Ghosts
				\nTop Arrow Keys - Move Looping animation offset (Red)
				\nBottom Arrow Keys - Move Idle/Finished animation offset (Blue)
				\nHold Z to move offsets 10x faster';
		}
		else
		{
			TIP_TEXT_MAIN = 'JKLI - Move camera (Hold Shift to move 4x faster)
				\nQ/E - Zoom out/in
				\nR - Reset Camera
				\nH - Toggle Speech Bubble
				\nSpace - Reset text';

			TIP_TEXT_OFFSET = 'JKLI - Move camera (Hold Shift to move 4x faster)
				\nQ/E - Zoom out/in
				\nR - Reset Camera
				\nH - Toggle Ghosts
				\nWASD - Move Looping animation offset (Red)
				\nArrow Keys - Move Idle/Finished animation offset (Blue)
				\nHold Shift to move offsets 10x faster';
		}

		tipText = new FlxText(10, 10, FlxG.width - 20, TIP_TEXT_MAIN, 8);
		tipText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tipText.cameras = [camHUD];
		tipText.scrollFactor.set();
		add(tipText);

		offsetLoopText = new FlxText(10, 10, 0, '', 32);
		offsetLoopText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		offsetLoopText.cameras = [camHUD];
		offsetLoopText.scrollFactor.set();
		add(offsetLoopText);
		offsetLoopText.visible = false;

		offsetIdleText = new FlxText(10, 46, 0, '', 32);
		offsetIdleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		offsetIdleText.cameras = [camHUD];
		offsetIdleText.scrollFactor.set();
		add(offsetIdleText);
		offsetIdleText.visible = false;

		animText = new FlxText(10, 22, FlxG.width - 20, '', 8);
		animText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		animText.scrollFactor.set();
		animText.cameras = [camHUD];
		add(animText);

		reloadCharacter();
		updateTextBox();

		daText = new TypedAlphabet(DialogueBoxPsych.DEFAULT_TEXT_X, DialogueBoxPsych.DEFAULT_TEXT_Y, '', 0.05, false);
		daText.setScale(0.7);
		daText.text = DEFAULT_TEXT;
		hudGroup.add(daText);

		addEditorBox();
		FlxG.mouse.visible = true;
		updateCharTypeBox();

		#if FEATURE_MOBILE_CONTROLS
		addTouchPad("DIALOGUE_PORTRAIT", "DIALOGUE_PORTRAIT");
		addTouchPadCamera();
		#end

		super.create();
	}

	var UI_typebox:ShadowTabMenu;
	var UI_mainbox:ShadowTabMenu;
	var editorTypeWidth:Int = 160;
	var editorTypeHeight:Int = 180;
	var editorMainWidth:Int = 270;
	var editorMainHeight:Int = 305;

	function addEditorBox()
	{
		var mainTabs:Array<TabDef> = [
			{name: 'Animations', label: 'Animations'},
			{name: 'Character', label: 'Character'},
		];
		UI_mainbox = new ShadowTabMenu(13, 55, mainTabs, editorMainWidth,
			editorMainHeight);
		UI_mainbox.scrollFactor.set();
		UI_mainbox.cameras = [camHUD];
		addAnimationsUI();
		addCharacterUI();
		add(UI_mainbox);
		add(UI_typebox);
		UI_mainbox.selectedTab = TAB_CHARACTER;
		lastTab = TAB_CHARACTER;

		var typeTabs:Array<TabDef> = [{name: 'Character Type', label: 'Character Type'}];
		UI_typebox = new ShadowTabMenu(290, 55, typeTabs, editorTypeWidth,
			editorTypeHeight);
		UI_typebox.scrollFactor.set();
		UI_typebox.cameras = [camHUD];
		addTypeUI();
		add(UI_typebox);
	}

	var leftCheckbox:ShadowCheckbox;
	var centerCheckbox:ShadowCheckbox;
	var rightCheckbox:ShadowCheckbox;

	function addTypeUI()
	{
		var tab:FlxSpriteGroup = UI_typebox.getTabGroup("Character Type");
		if (tab == null)
			return;

		var pad:Int = ShadowStyle.SPACING_MD;
		var rowDelta:Int = ShadowStyle.HEIGHT_CHECKBOX + ShadowStyle.SPACING_SM;

		leftCheckbox = new ShadowCheckbox(pad, pad, "Left", false, function(checked:Bool)
		{
			character.jsonFile.dialogue_pos = 'left';
			updateCharTypeBox();
		});
		tab.add(leftCheckbox);

		centerCheckbox = new ShadowCheckbox(pad, pad + rowDelta, "Center", false, function(checked:Bool)
		{
			character.jsonFile.dialogue_pos = 'center';
			updateCharTypeBox();
		});
		tab.add(centerCheckbox);

		rightCheckbox = new ShadowCheckbox(pad, pad + rowDelta * 2, "Right", false, function(checked:Bool)
		{
			character.jsonFile.dialogue_pos = 'right';
			updateCharTypeBox();
		});
		tab.add(rightCheckbox);
	}

	var curSelectedAnim:String;
	var animationArray:Array<String> = [];
	var animationDropDown:ShadowDropdown;
	var animationInputText:ShadowTextInput;
	var loopInputText:ShadowTextInput;
	var idleInputText:ShadowTextInput;

	function addAnimationsUI()
	{
		var tab:FlxSpriteGroup = UI_mainbox.getTabGroup("Animations");
		if (tab == null)
			return;

		var pad:Int = ShadowStyle.SPACING_MD;
		var labelHeight:Int = ShadowStyle.FONT_SIZE_SM + 4;
		var dropdownWidth:Int = editorMainWidth - pad * 2;

		var y:Int = pad;
		tab.add(new ShadowLabel(pad, y, "Animations:", ShadowStyle.FONT_SIZE_SM));
		y += labelHeight;

		animationDropDown = new ShadowDropdown(pad, y, animationArray.length > 0 ? animationArray : [''], function(index:Int)
		{
			if (index < 0 || index >= animationArray.length)
				return;
			var anim:String = animationArray[index];
			if (character.dialogueAnimations.exists(anim))
			{
				ghostLoop.playAnim(anim);
				ghostIdle.playAnim(anim, true);

				curSelectedAnim = anim;
				var animData:DialogueAnimArray = character.dialogueAnimations.get(curSelectedAnim);
				if (animData != null)
				{
					offsetLoopText.text = 'Loop: ' + animData.loop_offsets;
					offsetIdleText.text = 'Idle: ' + animData.idle_offsets;

					animationInputText.text = animData.anim;
					loopInputText.text = animData.loop_name;
					idleInputText.text = animData.idle_name;
				}
			}
		}, dropdownWidth, 8);
		tab.add(animationDropDown);
		y += ShadowStyle.HEIGHT_INPUT + ShadowStyle.SPACING_MD;

		tab.add(new ShadowLabel(pad, y, "Animation name:", ShadowStyle.FONT_SIZE_SM));
		y += labelHeight;
		animationInputText = new ShadowTextInput(pad, y, dropdownWidth, '');
		tab.add(animationInputText);
		blockPressWhileTypingOn.push(animationInputText);
		y += ShadowStyle.HEIGHT_INPUT + ShadowStyle.SPACING_MD;

		tab.add(new ShadowLabel(pad, y, "Loop name on .XML file:", ShadowStyle.FONT_SIZE_SM));
		y += labelHeight;
		loopInputText = new ShadowTextInput(pad, y, dropdownWidth, '');
		tab.add(loopInputText);
		blockPressWhileTypingOn.push(loopInputText);
		y += ShadowStyle.HEIGHT_INPUT + ShadowStyle.SPACING_MD;

		tab.add(new ShadowLabel(pad, y, "Idle/Finished name on .XML file:", ShadowStyle.FONT_SIZE_SM));
		y += labelHeight;
		idleInputText = new ShadowTextInput(pad, y, dropdownWidth, '');
		tab.add(idleInputText);
		blockPressWhileTypingOn.push(idleInputText);
		y += ShadowStyle.HEIGHT_INPUT + ShadowStyle.SPACING_MD;

		var buttonY:Int = y;
		var addUpdateButton:ShadowButton = new ShadowButton(pad, buttonY, "Add/Update", function()
		{
			var theAnim:String = animationInputText.text.trim();
			if (theAnim.length == 0)
				return;

			if (character.dialogueAnimations.exists(theAnim))
			{
				for (i in 0...character.jsonFile.animations.length)
				{
					var animArray:DialogueAnimArray = character.jsonFile.animations[i];
					if (animArray.anim.trim() == theAnim)
					{
						animArray.loop_name = loopInputText.text;
						animArray.idle_name = idleInputText.text;
						break;
					}
				}

				character.reloadAnimations();
				ghostLoop.reloadAnimations();
				ghostIdle.reloadAnimations();
				if (curSelectedAnim == theAnim)
				{
					ghostLoop.playAnim(theAnim);
					ghostIdle.playAnim(theAnim, true);
				}
			}
			else
			{
				var newAnim:DialogueAnimArray = {
					anim: theAnim,
					loop_name: loopInputText.text,
					loop_offsets: [0, 0],
					idle_name: idleInputText.text,
					idle_offsets: [0, 0]
				};
				character.jsonFile.animations.push(newAnim);

				character.reloadAnimations();
				ghostLoop.reloadAnimations();
				ghostIdle.reloadAnimations();
			}

			var lastIndex:Int = animationDropDown.selectedIndex;
			reloadAnimationsDropDown();
			if (animationArray.length > 0)
				animationDropDown.selectedIndex = Std.int(Math.min(lastIndex, animationArray.length - 1));
		}, 110);
		var removeUpdateButton:ShadowButton = new ShadowButton(pad + addUpdateButton.width + ShadowStyle.SPACING_MD, buttonY, "Remove", function()
		{
			var targetAnim:String = animationInputText.text.trim();
			for (i in 0...character.jsonFile.animations.length)
			{
				var animArray:DialogueAnimArray = character.jsonFile.animations[i];
				if (animArray != null && animArray.anim.trim() == targetAnim)
				{
					var lastIndex = animationDropDown.selectedIndex;
					character.jsonFile.animations.remove(animArray);
					character.reloadAnimations();
					ghostLoop.reloadAnimations();
					ghostIdle.reloadAnimations();
					reloadAnimationsDropDown();
					if (animationArray.length > 0)
					{
						animationDropDown.selectedIndex = Std.int(Math.max(0, Math.min(lastIndex, animationArray.length - 1)));
						var nextAnim:String = animationArray[animationDropDown.selectedIndex];
						if (character.dialogueAnimations.exists(nextAnim))
						{
							ghostLoop.playAnim(nextAnim);
							ghostIdle.playAnim(nextAnim, true);
						}
					}
					animationInputText.text = '';
					loopInputText.text = '';
					idleInputText.text = '';
					break;
				}
			}
		}, 90);

		tab.add(addUpdateButton);
		tab.add(removeUpdateButton);
		reloadAnimationsDropDown();
	}

	function reloadAnimationsDropDown()
	{
		animationArray = [];
		for (anim in character.jsonFile.animations)
		{
			animationArray.push(anim.anim);
		}

		if (animationArray.length < 1)
			animationArray = [''];

		if (animationDropDown != null)
		{
			animationDropDown.setOptions(animationArray);
			if (animationArray.length > 0)
				animationDropDown.selectedIndex = Std.int(Math.min(animationDropDown.selectedIndex, animationArray.length - 1));
			else
				animationDropDown.selectedIndex = 0;
			if (animationArray.length > 0 && animationDropDown.callback != null)
				animationDropDown.callback(animationDropDown.selectedIndex);
		}
	}

	var imageInputText:ShadowTextInput;
	var scaleStepper:ShadowStepper;
	var xStepper:ShadowStepper;
	var yStepper:ShadowStepper;
	var blockPressWhileTypingOn:Array<ShadowTextInput> = [];

	function addCharacterUI()
	{
		var tab:FlxSpriteGroup = UI_mainbox.getTabGroup("Character");
		if (tab == null)
			return;

		var pad:Int = ShadowStyle.SPACING_MD;
		var fieldWidth:Int = editorMainWidth - pad * 2;
		var labelHeight:Int = ShadowStyle.FONT_SIZE_SM + 4;

		var y:Int = pad;
		tab.add(new ShadowLabel(pad, y, "Image file name:", ShadowStyle.FONT_SIZE_SM));
		y += labelHeight;
		imageInputText = new ShadowTextInput(pad, y, fieldWidth, character.jsonFile.image);
		imageInputText.callback = function(text:String)
		{
			character.jsonFile.image = text;
			reloadCharacter();
		};
		tab.add(imageInputText);
		blockPressWhileTypingOn.push(imageInputText);
		y += ShadowStyle.HEIGHT_INPUT + ShadowStyle.SPACING_MD;

		tab.add(new ShadowLabel(pad, y, "Position Offset:", ShadowStyle.FONT_SIZE_SM));
		y += labelHeight;

		// Fit 2 steppers exactly inside the field width
		var stepperSpacing:Int = ShadowStyle.SPACING_MD;
		var stepperWidth:Int = Std.int((fieldWidth - stepperSpacing) / 2);

		xStepper = new ShadowStepper(pad, y, 10, character.jsonFile.position[0], -2000, 2000, 0, function(value:Float)
		{
			character.jsonFile.position[0] = value;
			reloadCharacter();
		}, stepperWidth);

		yStepper = new ShadowStepper(pad + stepperWidth + stepperSpacing, y, 10, character.jsonFile.position[1], -2000, 2000, 0, function(value:Float)
		{
			character.jsonFile.position[1] = value;
			reloadCharacter();
		}, stepperWidth);

		tab.add(xStepper);
		tab.add(yStepper);
		y += ShadowStyle.HEIGHT_INPUT + ShadowStyle.SPACING_MD;

		var buttonY:Int = y + ShadowStyle.SPACING_MD;
		var buttonWidth:Int = 110;
		var buttonSpacing:Int = ShadowStyle.SPACING_MD;

		var reloadImageButton:ShadowButton = new ShadowButton(pad, buttonY, "Reload Image", function()
		{
			reloadCharacter();
		}, buttonWidth);

		var loadButton:ShadowButton = new ShadowButton(pad + buttonWidth + buttonSpacing, buttonY, "Load Character", function()
		{
			loadCharacter();
		}, buttonWidth);

		// Move Save Character under Reload Image
		var saveButton:ShadowButton = new ShadowButton(pad, buttonY + ShadowStyle.HEIGHT_BUTTON + buttonSpacing, "Save Character", function()
		{
			saveCharacter();
		}, buttonWidth);

		tab.add(reloadImageButton);
		tab.add(loadButton);
		tab.add(saveButton);
	}

	function updateCharTypeBox()
	{
		leftCheckbox.checked = false;
		centerCheckbox.checked = false;
		rightCheckbox.checked = false;

		switch (character.jsonFile.dialogue_pos)
		{
			case 'left':
				leftCheckbox.checked = true;
			case 'center':
				centerCheckbox.checked = true;
			case 'right':
				rightCheckbox.checked = true;
		}
		reloadCharacter();
		updateTextBox();
	}

	private static var DEFAULT_TEXT:String = 'Lorem ipsum dolor sit amet';

	function reloadCharacter()
	{
		var charsArray:Array<DialogueCharacter> = [character, ghostLoop, ghostIdle];
		for (char in charsArray)
		{
			char.frames = Paths.getSparrowAtlas('dialogue/' + character.jsonFile.image);
			char.jsonFile = character.jsonFile;
			char.reloadAnimations();
			char.setGraphicSize(Std.int(char.width * DialogueCharacter.DEFAULT_SCALE * character.jsonFile.scale));
			char.updateHitbox();
		}
		character.x = DialogueBoxPsych.LEFT_CHAR_X;
		character.y = DialogueBoxPsych.DEFAULT_CHAR_Y;

		switch (character.jsonFile.dialogue_pos)
		{
			case 'right':
				character.x = FlxG.width - character.width + DialogueBoxPsych.RIGHT_CHAR_X;

			case 'center':
				character.x = FlxG.width / 2;
				character.x -= character.width / 2;
		}
		character.x += character.jsonFile.position[0] + mainGroup.x;
		character.y += character.jsonFile.position[1] + mainGroup.y;
		character.playAnim(character.jsonFile.animations[0].anim);
		if (character.jsonFile.animations.length > 0)
		{
			curSelectedAnim = character.jsonFile.animations[0].anim;
			var animShit:DialogueAnimArray = character.dialogueAnimations.get(curSelectedAnim);
			ghostLoop.playAnim(animShit.anim);
			ghostIdle.playAnim(animShit.anim, true);
			offsetLoopText.text = 'Loop: ' + animShit.loop_offsets;
			offsetIdleText.text = 'Idle: ' + animShit.idle_offsets;
		}

		curAnim = 0;
		animText.text = 'Animation: '
			+ character.jsonFile.animations[curAnim].anim
				+ ' ('
				+ (curAnim + 1)
				+ ' / '
				+ character.jsonFile.animations.length
				+ ') - Press W or S to scroll';

		#if FEATURE_DISCORD_RPC
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Dialogue Character Editor", "Editting: " + character.jsonFile.image);
		#end
	}

	function updateTextBox()
	{
		box.flipX = false;
		var anim:String = 'normal';
		switch (character.jsonFile.dialogue_pos)
		{
			case 'left':
				box.flipX = true;
			case 'center':
				anim = 'center';
		}
		box.animation.play(anim, true);
		DialogueBoxPsych.updateBoxOffsets(box);
	}

	var currentGhosts:Int = 0;
	var lastTab:Int = TAB_CHARACTER;
	var transitioning:Bool = false;

	override function update(elapsed:Float)
	{
		if (transitioning)
		{
			super.update(elapsed);
			return;
		}

		if (character.animation.curAnim != null)
		{
			if (daText.finishedText)
			{
				if (character.animationIsLoop())
				{
					character.playAnim(character.animation.curAnim.name, true);
				}
			}
			else if (character.animation.curAnim.finished)
			{
				character.animation.curAnim.restart();
			}
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

		if (!blockInput && !ShadowDropdown.isAnyOpen())
		{
			ClientPrefs.toggleVolumeKeys(true);
			if (FlxG.keys.justPressed.SPACE #if FEATURE_MOBILE_CONTROLS || (touchPad.buttonA.justPressed && UI_mainbox.selectedTab == TAB_CHARACTER) #end)
			{
				character.playAnim(character.jsonFile.animations[curAnim].anim);
				daText.resetDialogue();
				updateTextBox();
			}

			// lots of Ifs lol get trolled
			var offsetAdd:Int = 1;
			var speed:Float = 300;
			if (FlxG.keys.pressed.SHIFT #if FEATURE_MOBILE_CONTROLS || touchPad.buttonZ.pressed #end)
			{
				speed = 1200;
				offsetAdd = 10;
			}

			var negaMult:Array<Int> = [1, 1, -1, -1];
			var controlArray:Array<Bool> = [
				FlxG.keys.pressed.J,
				FlxG.keys.pressed.I,
				FlxG.keys.pressed.L,
				FlxG.keys.pressed.K
			];
			for (i in 0...controlArray.length)
			{
				if (controlArray[i])
				{
					if (i % 2 == 1)
					{
						mainGroup.y += speed * elapsed * negaMult[i];
					}
					else
					{
						mainGroup.x += speed * elapsed * negaMult[i];
					}
				}
			}

			if (UI_mainbox.selectedTab == TAB_ANIMATIONS
				&& curSelectedAnim != null
				&& character.dialogueAnimations.exists(curSelectedAnim))
			{
				var moved:Bool = false;
				var animShit:DialogueAnimArray = character.dialogueAnimations.get(curSelectedAnim);
				var controlArrayLoop:Array<Bool> = [
					FlxG.keys.justPressed.A
					#if FEATURE_MOBILE_CONTROLS || touchPad.buttonLeft2.justPressed #end,
					FlxG.keys.justPressed.W
					#if FEATURE_MOBILE_CONTROLS || touchPad.buttonUp2.justPressed #end,
					FlxG.keys.justPressed.D
					#if FEATURE_MOBILE_CONTROLS || touchPad.buttonRight2.justPressed #end,
					FlxG.keys.justPressed.S
					#if FEATURE_MOBILE_CONTROLS || touchPad.buttonDown2.justPressed #end];
				var controlArrayIdle:Array<Bool> = [
					FlxG.keys.justPressed.LEFT
					#if FEATURE_MOBILE_CONTROLS || touchPad.buttonLeft.justPressed #end,
					FlxG.keys.justPressed.UP
					#if FEATURE_MOBILE_CONTROLS || touchPad.buttonUp.justPressed #end,
					FlxG.keys.justPressed.RIGHT
					#if FEATURE_MOBILE_CONTROLS || touchPad.buttonRight.justPressed #end,
					FlxG.keys.justPressed.DOWN
					#if FEATURE_MOBILE_CONTROLS || touchPad.buttonDown.justPressed #end];
				for (i in 0...controlArrayLoop.length)
				{
					if (controlArrayLoop[i])
					{
						if (i % 2 == 1)
						{
							animShit.loop_offsets[1] += offsetAdd * negaMult[i];
						}
						else
						{
							animShit.loop_offsets[0] += offsetAdd * negaMult[i];
						}
						moved = true;
					}
				}
				for (i in 0...controlArrayIdle.length)
				{
					if (controlArrayIdle[i])
					{
						if (i % 2 == 1)
						{
							animShit.idle_offsets[1] += offsetAdd * negaMult[i];
						}
						else
						{
							animShit.idle_offsets[0] += offsetAdd * negaMult[i];
						}
						moved = true;
					}
				}

				if (moved)
				{
					offsetLoopText.text = 'Loop: ' + animShit.loop_offsets;
					offsetIdleText.text = 'Idle: ' + animShit.idle_offsets;
					ghostLoop.offset.set(animShit.loop_offsets[0], animShit.loop_offsets[1]);
					ghostIdle.offset.set(animShit.idle_offsets[0], animShit.idle_offsets[1]);
				}
			}

			if (FlxG.keys.pressed.Q && camGame.zoom > 0.1)
			{
				camGame.zoom -= elapsed * camGame.zoom;
				if (camGame.zoom < 0.1)
					camGame.zoom = 0.1;
			}
			if (FlxG.keys.pressed.E && camGame.zoom < 1)
			{
				camGame.zoom += elapsed * camGame.zoom;
				if (camGame.zoom > 1)
					camGame.zoom = 1;
			}
			if (FlxG.keys.justPressed.H #if FEATURE_MOBILE_CONTROLS || touchPad.buttonY.justPressed #end)
			{
				if (UI_mainbox.selectedTab == TAB_ANIMATIONS)
				{
					currentGhosts++;
					if (currentGhosts > 2)
						currentGhosts = 0;

					ghostLoop.visible = (currentGhosts != 1);
					ghostIdle.visible = (currentGhosts != 2);
					ghostLoop.alpha = (currentGhosts == 2 ? 1 : 0.6);
					ghostIdle.alpha = (currentGhosts == 1 ? 1 : 0.6);
				}
				else
				{
					hudGroup.visible = !hudGroup.visible;
				}
			}
			if (FlxG.keys.justPressed.R #if FEATURE_MOBILE_CONTROLS || touchPad.buttonX.justPressed #end)
			{
				camGame.zoom = 1;
				mainGroup.setPosition(0, 0);
				hudGroup.visible = true;
			}

			if (UI_mainbox.selectedTab != lastTab)
			{
				if (UI_mainbox.selectedTab == TAB_ANIMATIONS)
				{
					hudGroup.alpha = 0;
					mainGroup.alpha = 0;
					ghostLoop.alpha = 0.6;
					ghostIdle.alpha = 0.6;
					tipText.text = TIP_TEXT_OFFSET;
					offsetLoopText.visible = true;
					offsetIdleText.visible = true;
					animText.visible = false;
					currentGhosts = 0;
				}
				else
				{
					hudGroup.alpha = 1;
					mainGroup.alpha = 1;
					ghostLoop.alpha = 0;
					ghostIdle.alpha = 0;
					tipText.text = TIP_TEXT_MAIN;
					offsetLoopText.visible = false;
					offsetIdleText.visible = false;
					animText.visible = true;
					updateTextBox();
					daText.resetDialogue();

					if (curAnim < 0)
						curAnim = character.jsonFile.animations.length - 1;
					else if (curAnim >= character.jsonFile.animations.length)
						curAnim = 0;

					character.playAnim(character.jsonFile.animations[curAnim].anim);
					animText.text = 'Animation: '
						+ character.jsonFile.animations[curAnim].anim
							+ ' ('
							+ (curAnim + 1)
							+ ' / '
							+ character.jsonFile.animations.length
							+ ') - Press W or S to scroll';
				}
				lastTab = UI_mainbox.selectedTab;
				currentGhosts = 0;
			}

			if (UI_mainbox.selectedTab == TAB_CHARACTER)
			{
				var negaMult:Array<Int> = [1, -1];
				var controlAnim:Array<Bool> = [FlxG.keys.justPressed.W, FlxG.keys.justPressed.S];

				if (controlAnim.contains(true))
				{
					for (i in 0...controlAnim.length)
					{
						if (controlAnim[i] && character.jsonFile.animations.length > 0)
						{
							curAnim -= negaMult[i];
							if (curAnim < 0)
								curAnim = character.jsonFile.animations.length - 1;
							else if (curAnim >= character.jsonFile.animations.length)
								curAnim = 0;

							var animToPlay:String = character.jsonFile.animations[curAnim].anim;
							if (character.dialogueAnimations.exists(animToPlay))
							{
								character.playAnim(animToPlay, daText.finishedText);
							}
						}
					}
					animText.text = 'Animation: '
						+ character.jsonFile.animations[curAnim].anim
							+ ' ('
							+ (curAnim + 1)
							+ ' / '
							+ character.jsonFile.animations.length
							+ ') - Press W or S to scroll';
				}
			}

			if (FlxG.keys.justPressed.ESCAPE #if android || FlxG.android.justPressed.BACK #end #if FEATURE_MOBILE_CONTROLS || touchPad.buttonB.justPressed #end)
			{
				MusicBeatState.switchState(new states.editors.MasterEditorMenu());
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 1);
				transitioning = true;
			}

			ghostLoop.setPosition(character.x, character.y);
			ghostIdle.setPosition(character.x, character.y);
			hudGroup.x = mainGroup.x;
			hudGroup.y = mainGroup.y;
		}
		super.update(elapsed);
	}

	function loadCharacter()
	{
		var fileDialog:lime.ui.FileDialog = new lime.ui.FileDialog();
		fileDialog.onOpen.add((file) -> onLoadComplete(file));
		fileDialog.open('json');
	}

	function onLoadComplete(file:haxe.io.Bytes):Void
	{
		#if sys
		if (file != null && file.length > 0)
		{
			var jsonStr:String = file.getString(0, file.length);
			var loadedChar:DialogueCharacterFile = cast Json.parse(jsonStr);
			if (loadedChar.dialogue_pos != null) // Make sure it's really a dialogue character
			{
				trace("Successfully loaded file.");
				character.jsonFile = loadedChar;
				reloadCharacter();
				reloadAnimationsDropDown();
				updateCharTypeBox();
				updateTextBox();
				daText.resetDialogue();
				imageInputText.text = character.jsonFile.image;
				scaleStepper.value = character.jsonFile.scale;
				xStepper.value = character.jsonFile.position[0];
				yStepper.value = character.jsonFile.position[1];
				return;
			}
		}
		#else
		trace("File couldn't be loaded! You aren't on Native, are you?");
		#end
	}

	function saveCharacter()
	{
		var data:String = Json.stringify(character.jsonFile, "\t");
		if (data.length > 0)
		{
			var splittedImage:Array<String> = imageInputText.text.trim().split('_');
			var characterName:String = splittedImage[0].toLowerCase().replace(' ', '');
			var fileDialog:lime.ui.FileDialog = new lime.ui.FileDialog();
			fileDialog.save(data, null, characterName + ".json", null, "application/json");
		}
	}

	function clipboardAdd(prefix:String = ''):String
	{
		if (prefix.toLowerCase().endsWith('v')) // probably copy paste attempt
		{
			prefix = prefix.substring(0, prefix.length - 1);
		}

		var text:String = prefix + Clipboard.text.replace('\n', '');
		return text;
	}
}
