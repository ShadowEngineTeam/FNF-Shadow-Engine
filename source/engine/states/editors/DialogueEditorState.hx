package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import haxe.Json;
import lime.ui.FileDialog;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileFilter;
import objects.TypedAlphabet;
import cutscenes.DialogueBoxPsych;
import cutscenes.DialogueCharacter;

class DialogueEditorState extends MusicBeatState
{
	var character:DialogueCharacter;
	var box:FlxSprite;
	var daText:TypedAlphabet;

	var selectedText:FlxText;
	var animText:FlxText;

	var defaultLine:DialogueLine;
	var dialogueFile:DialogueFile = null;

	override function create()
	{
		persistentUpdate = persistentDraw = true;
		FlxG.camera.bgColor = FlxColor.fromHSL(0, 0, 0.5);

		defaultLine = {
			portrait: DialogueCharacter.DEFAULT_CHARACTER,
			expression: 'talk',
			text: DEFAULT_TEXT,
			boxState: DEFAULT_BUBBLETYPE,
			speed: 0.05,
			sound: ''
		};

		dialogueFile = {
			dialogue: [copyDefaultLine()]
		};

		character = new DialogueCharacter();
		character.scrollFactor.set();
		add(character);

		box = new FlxSprite(70, 370);
		box.antialiasing = ClientPrefs.data.antialiasing;
		box.frames = Paths.getSparrowAtlas('speech_bubble');
		box.scrollFactor.set();
		box.animation.addByPrefix('normal', 'speech bubble normal', 24);
		box.animation.addByPrefix('angry', 'AHH speech bubble', 24);
		box.animation.addByPrefix('center', 'speech bubble middle', 24);
		box.animation.addByPrefix('center-angry', 'AHH Speech Bubble middle', 24);
		box.animation.play('normal', true);
		box.setGraphicSize(Std.int(box.width * 0.9));
		box.updateHitbox();
		add(box);

		FlxG.mouse.visible = true;

		var lineTxt:String;

		if (controls.mobileC)
		{
			lineTxt = "Press A to remove the current dialogue line, Press X to add another line after the current one.";
		}
		else
		{
			lineTxt = "Press O to remove the current dialogue line, Press P to add another line after the current one.";
		}

		var addLineText:FlxText = new FlxText(10, 10, FlxG.width - 20, lineTxt, 8);
		addLineText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		addLineText.scrollFactor.set();
		add(addLineText);

		selectedText = new FlxText(10, 32, FlxG.width - 20, '', 8);
		selectedText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		selectedText.scrollFactor.set();
		add(selectedText);

		animText = new FlxText(10, 62, FlxG.width - 20, '', 8);
		animText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		animText.scrollFactor.set();
		add(animText);

		daText = new TypedAlphabet(DialogueBoxPsych.DEFAULT_TEXT_X, DialogueBoxPsych.DEFAULT_TEXT_Y, DEFAULT_TEXT);
		daText.setScale(0.7);
		add(daText);
		
		addEditorBox();
		changeText();
		#if FEATURE_MOBILE_CONTROLS
		addTouchPad("LEFT_FULL", "A_B_X_Y");
		#end

		super.create();
	}

	var UI_box:ShadowTabMenu;

	function addEditorBox()
	{
		var tabs = [{name: 'Dialogue Line', label: 'Dialogue Line'}];
		var margin:Int = ShadowStyle.SPACING_LG;
		var panelWidth:Int = 350;
		var panelHeight:Int = 320;

		UI_box = new ShadowTabMenu(12, 103, tabs, panelWidth, panelHeight);
		UI_box.scrollFactor.set();
		addDialogueLineUI();
		add(UI_box);
	}

	var characterInputText:ShadowTextInput;
	var lineInputText:ShadowTextInput;
	var angryCheckbox:ShadowCheckbox;
	var speedStepper:ShadowStepper;
	var soundInputText:ShadowTextInput;

	function addDialogueLineUI()
	{
		var tab_group:FlxSpriteGroup = UI_box.getTabGroup("Dialogue Line");
		if (tab_group == null)
			return;

		var pad:Int = ShadowStyle.SPACING_MD;
		var rowGap:Int = ShadowStyle.SPACING_SM;
		var labelOffset:Int = ShadowStyle.FONT_SIZE_SM + 4;
		var rowStep:Int = labelOffset + ShadowStyle.HEIGHT_INPUT + rowGap;
		var fullW:Int = Std.int(@:privateAccess UI_box._width - pad * 2);

		var row0:Int = pad;
		var row1:Int = row0 + rowStep;
		var row2:Int = row1 + rowStep;
		var row3:Int = row2 + rowStep;
		var row4:Int = row3 + rowStep;
		var row5:Int = row4 + rowStep;

		var controlY0:Int = row0 + labelOffset;
		var controlY1:Int = row1 + labelOffset;
		var controlY2:Int = row2 + labelOffset;
		var controlY3:Int = row3 + labelOffset;
		var controlY4:Int = row4 + labelOffset;
		var checkboxOffset:Int = Std.int((ShadowStyle.HEIGHT_INPUT - ShadowStyle.HEIGHT_CHECKBOX) / 2);

		characterInputText = new ShadowTextInput(pad, controlY0, fullW - 20, DialogueCharacter.DEFAULT_CHARACTER);
		blockPressWhileTypingOn.push(characterInputText);
		characterInputText.callback = function(value:String)
		{
			dialogueFile.dialogue[curSelected].portrait = value;
			character.reloadCharacterJson(value);
			curAnim = 0;
			reloadCharacter();
			reloadText(false);
			updateTextBox();
		};

		speedStepper = new ShadowStepper(pad, controlY1, 0.005, 0.05, 0, 0.5, 3, null, 100);
		speedStepper.callback = function(value:Float)
		{
			dialogueFile.dialogue[curSelected].speed = value;
			if (Math.isNaN(dialogueFile.dialogue[curSelected].speed) || dialogueFile.dialogue[curSelected].speed == null || dialogueFile.dialogue[curSelected].speed < 0.001)
			{
				dialogueFile.dialogue[curSelected].speed = 0.0;
			}
			daText.delay = dialogueFile.dialogue[curSelected].speed;
			reloadText(false);
		};

		angryCheckbox = new ShadowCheckbox(pad + 120, controlY1 + checkboxOffset, "Angry Textbox");
		angryCheckbox.callback = function(checked:Bool)
		{
			updateTextBox();
			dialogueFile.dialogue[curSelected].boxState = (checked ? 'angry' : 'normal');
		};

		soundInputText = new ShadowTextInput(pad, controlY2, fullW - 20, '');
		blockPressWhileTypingOn.push(soundInputText);
		soundInputText.callback = function(value:String)
		{
			daText.finishText();
			dialogueFile.dialogue[curSelected].sound = value;
			daText.sound = value;
			if (daText.sound == null)
				daText.sound = '';
		};

		lineInputText = new ShadowTextInput(pad, controlY3, fullW - 20, DEFAULT_TEXT);
		blockPressWhileTypingOn.push(lineInputText);
		lineInputText.callback = function(value:String)
		{
			dialogueFile.dialogue[curSelected].text = value;
			if (daText.text == null)
				daText.text = '';
			reloadText(true);
		};

		var loadButton:ShadowButton = new ShadowButton(pad, controlY4, "Load Dialogue", function()
		{
			loadDialogue();
		}, 150);

		var saveButton:ShadowButton = new ShadowButton(pad + 160, controlY4, "Save Dialogue", function()
		{
			saveDialogue();
		}, 150);

		tab_group.add(new ShadowLabel(pad, row0, 'Character:', ShadowStyle.FONT_SIZE_SM, ShadowStyle.TEXT_SECONDARY));
		tab_group.add(new ShadowLabel(pad, row1, 'Interval/Speed (ms):', ShadowStyle.FONT_SIZE_SM, ShadowStyle.TEXT_SECONDARY));
		tab_group.add(new ShadowLabel(pad, row2, 'Sound file name:', ShadowStyle.FONT_SIZE_SM, ShadowStyle.TEXT_SECONDARY));
		tab_group.add(new ShadowLabel(pad, row3, 'Text:', ShadowStyle.FONT_SIZE_SM, ShadowStyle.TEXT_SECONDARY));

		tab_group.add(characterInputText);
		tab_group.add(speedStepper);
		tab_group.add(angryCheckbox);
		tab_group.add(soundInputText);
		tab_group.add(lineInputText);
		tab_group.add(loadButton);
		tab_group.add(saveButton);
	}

	function copyDefaultLine():DialogueLine
	{
		var copyLine:DialogueLine = {
			portrait: defaultLine.portrait,
			expression: defaultLine.expression,
			text: defaultLine.text,
			boxState: defaultLine.boxState,
			speed: defaultLine.speed,
			sound: ''
		};
		return copyLine;
	}

	function updateTextBox()
	{
		box.flipX = false;
		var isAngry:Bool = angryCheckbox.checked;
		var anim:String = isAngry ? 'angry' : 'normal';

		switch (character.jsonFile.dialogue_pos)
		{
			case 'left':
				box.flipX = true;
			case 'center':
				if (isAngry)
				{
					anim = 'center-angry';
				}
				else
				{
					anim = 'center';
				}
		}
		box.animation.play(anim, true);
		DialogueBoxPsych.updateBoxOffsets(box);
	}

	function reloadCharacter()
	{
		character.frames = Paths.getSparrowAtlas('dialogue/' + character.jsonFile.image);
		character.jsonFile = character.jsonFile;
		character.reloadAnimations();
		character.setGraphicSize(Std.int(character.width * DialogueCharacter.DEFAULT_SCALE * character.jsonFile.scale));
		character.updateHitbox();
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
		character.x += character.jsonFile.position[0];
		character.y += character.jsonFile.position[1];
		character.playAnim(); // Plays random animation
		characterAnimSpeed();

		if (character.animation.curAnim != null && character.jsonFile.animations != null)
		{
			if (controls.mobileC)
			{
				animText.text = 'Animation: '
					+ character.jsonFile.animations[curAnim].anim
						+ ' ('
						+ (curAnim + 1)
						+ ' / '
						+ character.jsonFile.animations.length
						+ ') - Press UP or DOWN to scroll';
			}
			else
			{
				animText.text = 'Animation: '
					+ character.jsonFile.animations[curAnim].anim
						+ ' ('
						+ (curAnim + 1)
						+ ' / '
						+ character.jsonFile.animations.length
						+ ') - Press W or S to scroll';
			}
		}
		else
		{
			animText.text = 'ERROR! NO ANIMATIONS FOUND';
		}
	}

	private static var DEFAULT_TEXT:String = "coolswag";
	private static var DEFAULT_SPEED:Float = 0.05;
	private static var DEFAULT_BUBBLETYPE:String = "normal";

	function reloadText(skipDialogue:Bool)
	{
		var textToType:String = lineInputText.text;
		if (textToType == null || textToType.length < 1)
			textToType = ' ';

		daText.text = textToType;

		if (skipDialogue)
			daText.finishText();
		else if (daText.delay > 0)
		{
			if (character.jsonFile.animations.length > curAnim && character.jsonFile.animations[curAnim] != null)
			{
				character.playAnim(character.jsonFile.animations[curAnim].anim);
			}
			characterAnimSpeed();
		}

		daText.y = DialogueBoxPsych.DEFAULT_TEXT_Y;
		if (daText.rows > 2)
			daText.y -= DialogueBoxPsych.LONG_TEXT_ADD;

		#if FEATURE_DISCORD_RPC
		var rpcText:String = lineInputText.text;
		if (rpcText == null || rpcText.length < 1)
			rpcText = '(Empty)';
		if (rpcText.length < 3)
			rpcText += '   ';
		DiscordClient.changePresence("Dialogue Editor", rpcText);
		#end
	}

	var curSelected:Int = 0;
	var curAnim:Int = 0;
	var blockPressWhileTypingOn:Array<ShadowTextInput> = [];
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
				if (character.animationIsLoop() && character.animation.curAnim.finished)
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
				{
					if (inputText == lineInputText)
					{
						// Dialogue format expects literal \n sequence
						inputText.text += '\\n';
						if (inputText.input != null)
							inputText.input.caretIndex += 2;
					}
					else
					{
						inputText.setFocus(false);
					}
				}
				break;
			}
		}

		if (!blockInput)
		{
			ClientPrefs.toggleVolumeKeys(true);
			if (FlxG.keys.justPressed.SPACE #if FEATURE_MOBILE_CONTROLS || touchPad.buttonY.justPressed #end)
			{
				reloadText(false);
			}
			if (FlxG.keys.justPressed.ESCAPE #if FEATURE_MOBILE_CONTROLS || touchPad.buttonB.justPressed #end)
			{
				MusicBeatState.switchState(new states.editors.MasterEditorMenu());
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 1);
				transitioning = true;
			}
			var negaMult:Array<Int> = [1, -1];
			var controlAnim:Array<Bool> = [
				FlxG.keys.justPressed.W #if FEATURE_MOBILE_CONTROLS || touchPad.buttonUp.justPressed #end,
				FlxG.keys.justPressed.S #if FEATURE_MOBILE_CONTROLS || touchPad.buttonDown.justPressed #end
			];
			var controlText:Array<Bool> = [
				FlxG.keys.justPressed.D #if FEATURE_MOBILE_CONTROLS || touchPad.buttonRight.justPressed #end,
				FlxG.keys.justPressed.A #if FEATURE_MOBILE_CONTROLS || touchPad.buttonLeft.justPressed #end
			];
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
						dialogueFile.dialogue[curSelected].expression = animToPlay;
					}
					if (controls.mobileC)
					{
						animText.text = 'Animation: ' + animToPlay + ' (' + (curAnim + 1) + ' / ' + character.jsonFile.animations.length
							+ ') - Press UP or DOWN to scroll';
					}
					else
					{
						animText.text = 'Animation: ' + animToPlay + ' (' + (curAnim + 1) + ' / ' + character.jsonFile.animations.length
							+ ') - Press W or S to scroll';
					}
				}
				if (controlText[i])
				{
					changeText(negaMult[i]);
				}
			}

			if (FlxG.keys.justPressed.O #if FEATURE_MOBILE_CONTROLS || touchPad.buttonA.justPressed #end)
			{
				dialogueFile.dialogue.remove(dialogueFile.dialogue[curSelected]);
				if (dialogueFile.dialogue.length < 1)
				{
					dialogueFile.dialogue = [copyDefaultLine()];
				}
				changeText();
			}
			else if (FlxG.keys.justPressed.P #if FEATURE_MOBILE_CONTROLS || touchPad.buttonX.justPressed #end)
			{
				dialogueFile.dialogue.insert(curSelected + 1, copyDefaultLine());
				changeText(1);
			}
		}
		super.update(elapsed);
	}

	function changeText(add:Int = 0)
	{
		curSelected += add;
		if (curSelected < 0)
			curSelected = dialogueFile.dialogue.length - 1;
		else if (curSelected >= dialogueFile.dialogue.length)
			curSelected = 0;

		var curDialogue:DialogueLine = dialogueFile.dialogue[curSelected];
		characterInputText.text = curDialogue.portrait;
		lineInputText.text = curDialogue.text;
		angryCheckbox.checked = (curDialogue.boxState == 'angry');
		speedStepper.value = curDialogue.speed;

		if (curDialogue.sound == null)
			curDialogue.sound = '';
		soundInputText.text = curDialogue.sound;

		daText.delay = speedStepper.value;
		daText.sound = soundInputText.text;
		if (daText.sound != null && daText.sound.trim() == '')
			daText.sound = 'dialogue';

		curAnim = 0;
		character.reloadCharacterJson(characterInputText.text);
		reloadCharacter();
		reloadText(false);
		updateTextBox();

		var leLength:Int = character.jsonFile.animations.length;
		if (leLength > 0)
		{
			for (i in 0...leLength)
			{
				var leAnim:DialogueAnimArray = character.jsonFile.animations[i];
				if (leAnim != null && leAnim.anim == curDialogue.expression)
				{
					curAnim = i;
					break;
				}
			}
			character.playAnim(character.jsonFile.animations[curAnim].anim, daText.finishedText);
			if (controls.mobileC)
			{
				animText.text = 'Animation: '
					+ character.jsonFile.animations[curAnim].anim
						+ ' ('
						+ (curAnim + 1)
						+ ' / '
						+ leLength
						+ ') - Press UP or DOWN to scroll';
			}
			else
			{
				animText.text = 'Animation: '
					+ character.jsonFile.animations[curAnim].anim
						+ ' ('
						+ (curAnim + 1)
						+ ' / '
						+ leLength
						+ ') - Press W or S to scroll';
			}
		}
		else
		{
			animText.text = 'ERROR! NO ANIMATIONS FOUND';
		}
		characterAnimSpeed();

		if (controls.mobileC)
		{
			selectedText.text = 'Line: (' + (curSelected + 1) + ' / ' + dialogueFile.dialogue.length + ') - Press LEFT or RIGHT to scroll';
		}
		else
		{
			selectedText.text = 'Line: (' + (curSelected + 1) + ' / ' + dialogueFile.dialogue.length + ') - Press A or D to scroll';
		}
	}

	function characterAnimSpeed()
	{
		if (character.animation.curAnim != null)
		{
			var speed:Float = speedStepper.value;
			var rate:Float = 24 - (((speed - 0.05) / 5) * 480);
			if (rate < 12)
				rate = 12;
			else if (rate > 48)
				rate = 48;
			character.animation.curAnim.frameRate = rate;
		}
	}

	function loadDialogue()
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
			var loadedDialog:DialogueFile = cast Json.parse(jsonStr);
			if (loadedDialog.dialogue != null && loadedDialog.dialogue.length > 0)
			{
				trace("Successfully loaded file.");
				dialogueFile = loadedDialog;
				changeText();
				return;
			}
		}
		#else
		trace("File couldn't be loaded! You aren't on Native, are you?");
		#end
	}

	function saveDialogue()
	{
		var data:String = Json.stringify(dialogueFile, null, "\t");
		if (data.length > 0)
		{
			var fileDialog:lime.ui.FileDialog = new lime.ui.FileDialog();
			fileDialog.save(data, null, "dialogue.json", null, "application/json");
		}
	}
}
