package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import haxe.Json;
import openfl.net.FileReference;
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

		addEditorBox();
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
		changeText();
		addTouchPad("LEFT_FULL", "A_B_X_Y");
		super.create();
	}

	var UI_box:ShadowTabMenu;

	function addEditorBox()
	{
		var tabs = [{name: 'Dialogue Line', label: 'Dialogue Line'}];
		var margin = ShadowStyle.SPACING_LG;
		var panelWidth = 350;
		var panelHeight = 350;
		var panelX = FlxG.width - panelWidth - margin;
		var panelY = margin;

		UI_box = new ShadowTabMenu(panelX, panelY, tabs, panelWidth, panelHeight);
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
		var tab_group = UI_box.getTabGroup("Dialogue Line");
		if (tab_group == null)
			return;

		var pad = ShadowStyle.SPACING_MD;
		var rowGap = ShadowStyle.SPACING_SM;
		var labelOffset = ShadowStyle.FONT_SIZE_SM + 4;
		var rowStep = labelOffset + ShadowStyle.HEIGHT_INPUT + rowGap;
		var fullW = Std.int(@:privateAccess UI_box._width - pad * 2);

		var row0 = pad;
		var row1 = row0 + rowStep;
		var row2 = row1 + rowStep;
		var row3 = row2 + rowStep;
		var row4 = row3 + rowStep;
		var row5 = row4 + rowStep;

		var controlY0 = row0 + labelOffset;
		var controlY1 = row1 + labelOffset;
		var controlY2 = row2 + labelOffset;
		var controlY3 = row3 + labelOffset;
		var controlY4 = row4 + labelOffset;
		var checkboxOffset = Std.int((ShadowStyle.HEIGHT_INPUT - ShadowStyle.HEIGHT_CHECKBOX) / 2);

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

		var loadButton = new ShadowButton(pad, controlY4, "Load Dialogue", function()
		{
			loadDialogue();
		}, 150);

		var saveButton = new ShadowButton(pad + 160, controlY4, "Save Dialogue", function()
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

		#if DISCORD_ALLOWED
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
			if (FlxG.keys.justPressed.SPACE || touchPad.buttonY.justPressed)
			{
				reloadText(false);
			}
			if (FlxG.keys.justPressed.ESCAPE || touchPad.buttonB.justPressed)
			{
				MusicBeatState.switchState(new states.editors.MasterEditorMenu());
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 1);
				transitioning = true;
			}
			var negaMult:Array<Int> = [1, -1];
			var controlAnim:Array<Bool> = [
				FlxG.keys.justPressed.W || touchPad.buttonUp.justPressed,
				FlxG.keys.justPressed.S || touchPad.buttonDown.justPressed
			];
			var controlText:Array<Bool> = [
				FlxG.keys.justPressed.D || touchPad.buttonRight.justPressed,
				FlxG.keys.justPressed.A || touchPad.buttonLeft.justPressed
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

			if (FlxG.keys.justPressed.O || touchPad.buttonA.justPressed)
			{
				dialogueFile.dialogue.remove(dialogueFile.dialogue[curSelected]);
				if (dialogueFile.dialogue.length < 1)
				{
					dialogueFile.dialogue = [copyDefaultLine()];
				}
				changeText();
			}
			else if (FlxG.keys.justPressed.P || touchPad.buttonX.justPressed)
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

	var _file:FileReference = null;

	function loadDialogue()
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
			var loadedDialog:DialogueFile = cast Json.parse(jsonStr);
			if (loadedDialog.dialogue != null && loadedDialog.dialogue.length > 0)
			{
				trace("Successfully loaded file.");
				dialogueFile = loadedDialog;
				changeText();
				_file = null;
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
				var loadedDialog:DialogueFile = cast Json.parse(rawJson);
				if (loadedDialog.dialogue != null && loadedDialog.dialogue.length > 0)
				{
					var cutName:String = _file.name.substr(0, _file.name.length - 5);
					trace("Successfully loaded file: " + cutName);
					dialogueFile = loadedDialog;
					changeText();
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

	function saveDialogue()
	{
		var data:String = Json.stringify(dialogueFile, null, "\t");
		if (data.length > 0)
		{
			#if mobile
			var fileDialog = new lime.ui.FileDialog();
			fileDialog.onCancel.add(() -> onSaveCancel(null));
			fileDialog.onSave.add((path) -> onSaveComplete(null));
			fileDialog.save(data, null, "dialogue.json", null, "*/*");
			#else
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, "dialogue.json");
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

	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}
}
