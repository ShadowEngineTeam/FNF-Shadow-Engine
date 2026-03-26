package cutscenes;

import openfl.utils.Assets;
import objects.TypedAlphabet;
import cutscenes.DialogueCharacter;

// Gonna try to kind of make it compatible to Forever Engine,
// love u Shubs no homo :flushedh4:
typedef DialogueFile =
{
	var dialogue:Array<DialogueLine>;
}

typedef DialogueLine =
{
	var portrait:Null<String>;
	var expression:Null<String>;
	var text:Null<String>;
	var boxState:Null<String>;
	var speed:Null<Float>;
	var sound:Null<String>;
}

// TO DO: Clean code? Maybe? idk
@:nullSafety
class DialogueBoxPsych extends FlxSpriteGroup
{
	public static var DEFAULT_TEXT_X = 175;
	public static var DEFAULT_TEXT_Y = 460;
	public static var LONG_TEXT_ADD = 24;

	var scrollSpeed = 4000;

	var dialogue:Null<TypedAlphabet> = null;
	var dialogueList:Null<DialogueFile> = null;

	public var finishThing:Null<Void->Void> = null;
	public var nextDialogueThing:Null<Void->Void> = null;
	public var skipDialogueThing:Null<Void->Void> = null;

	var bgFade:Null<FlxSprite> = null;
	var box:Null<FlxSprite> = null;
	var textToType:String = '';

	var arrayCharacters:Array<DialogueCharacter> = [];

	var currentText:Int = 0;
	var offsetPos:Float = -600;

	var textBoxTypes:Array<String> = ['normal', 'angry'];

	var curCharacter:String = "";

	// var charPositionList:Array<String> = ['left', 'center', 'right'];

	public function new(dialogueList:DialogueFile, ?song:String = null)
	{
		super();

		// precache sounds
		Paths.sound('dialogue');
		Paths.sound('dialogueClose');

		if (song != null && song != '')
		{
			var musicPath = Paths.music(song);
			if (musicPath != null)
				FlxG.sound.playMusic(musicPath, 0);
			var music = FlxG.sound.music;
			if (music != null)
				music.fadeIn(2, 0, 1);
		}

		bgFade = new FlxSprite(-500, -500).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.WHITE);
		if (bgFade != null)
		{
			bgFade.scrollFactor.set();
			bgFade.visible = true;
			bgFade.alpha = 0;
			add(bgFade);
		}

		this.dialogueList = dialogueList;
		spawnCharacters();

		box = new FlxSprite(70, 370);
		if (box != null)
		{
			box.antialiasing = ClientPrefs.data.antialiasing;
			var boxAtlas = Paths.getSparrowAtlas('speech_bubble');
			if (boxAtlas != null)
				box.frames = boxAtlas;
			box.scrollFactor.set();
			box.animation.addByPrefix('normal', 'speech bubble normal', 24);
			box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
			box.animation.addByPrefix('angry', 'AHH speech bubble', 24);
			box.animation.addByPrefix('angryOpen', 'speech bubble loud open', 24, false);
			box.animation.addByPrefix('center-normal', 'speech bubble middle', 24);
			box.animation.addByPrefix('center-normalOpen', 'Speech Bubble Middle Open', 24, false);
			box.animation.addByPrefix('center-angry', 'AHH Speech Bubble middle', 24);
			box.animation.addByPrefix('center-angryOpen', 'speech bubble Middle loud open', 24, false);
			box.animation.play('normal', true);
			box.visible = false;
			box.setGraphicSize(Std.int(box.width * 0.9));
			box.updateHitbox();
			add(box);
		}

		alphabetText = new TypedAlphabet(DEFAULT_TEXT_X, DEFAULT_TEXT_Y, '');
		if (alphabetText != null)
		{
			alphabetText.setScale(0.7);
			add(alphabetText);
		}

		startNextDialog();
	}

	var dialogueStarted:Bool = false;
	var dialogueEnded:Bool = false;

	public static var LEFT_CHAR_X:Float = -60;
	public static var RIGHT_CHAR_X:Float = -100;
	public static var DEFAULT_CHAR_Y:Float = 60;

	function spawnCharacters()
	{
		if (dialogueList == null)
			return;
		var charsMap:Map<String, Bool> = new Map<String, Bool>();
		for (i in 0...dialogueList.dialogue.length)
		{
			if (dialogueList.dialogue[i] != null)
			{
				var charToAdd:Null<String> = dialogueList.dialogue[i].portrait;
				if (charToAdd != null && (!charsMap.exists(charToAdd) || charsMap.get(charToAdd) != true))
				{
					charsMap.set(charToAdd, true);
				}
			}
		}

		for (individualChar in charsMap.keys())
		{
			var x:Float = LEFT_CHAR_X;
			var y:Float = DEFAULT_CHAR_Y;
			var char:DialogueCharacter = new DialogueCharacter(x + offsetPos, y, individualChar);
			var jsonFile = char.jsonFile;
			if (jsonFile != null)
			{
				char.setGraphicSize(Std.int(char.width * DialogueCharacter.DEFAULT_SCALE * jsonFile.scale));
				char.updateHitbox();
				char.scrollFactor.set();
				char.alpha = 0.00001;
				add(char);

				var saveY:Bool = false;
				switch (jsonFile.dialogue_pos)
				{
					case 'center':
						char.x = FlxG.width / 2;
						char.x -= char.width / 2;
						y = char.y;
						char.y = FlxG.height + 50;
						saveY = true;
					case 'right':
						x = FlxG.width - char.width + RIGHT_CHAR_X;
						char.x = x - offsetPos;
				}
				if (jsonFile.position != null && jsonFile.position.length >= 2)
				{
					x += jsonFile.position[0];
					y += jsonFile.position[1];
					char.x += jsonFile.position[0];
					char.y += jsonFile.position[1];
				}
				char.startingPos = (saveY ? y : x);
			}
			arrayCharacters.push(char);
		}
	}

	var alphabetText:Null<TypedAlphabet> = null;
	var ignoreThisFrame:Bool = true; // First frame is reserved for loading dialogue images

	public var closeSound:String = 'dialogueClose';
	public var closeVolume:Float = 1;

	override function update(elapsed:Float)
	{
		if (ignoreThisFrame)
		{
			ignoreThisFrame = false;
			super.update(elapsed);
			return;
		}

		if (!dialogueEnded)
		{
			if (bgFade != null)
			{
				bgFade.alpha += 0.5 * elapsed;
				if (bgFade.alpha > 0.5)
					bgFade.alpha = 0.5;
			}

			var justTouched:Bool = false;
			for (touch in FlxG.touches.list)
				if (touch.justPressed)
					justTouched = true;

			var acceptPressed:Bool = false;
			var controls = Controls.instance;
			if (controls != null)
				acceptPressed = controls.ACCEPT;

			if (acceptPressed || justTouched)
			{
				if (alphabetText != null && !alphabetText.finishedText)
				{
					alphabetText.finishText();
					if (skipDialogueThing != null)
					{
						skipDialogueThing();
					}
				}
				else if (dialogueList != null && currentText >= dialogueList.dialogue.length)
				{
					dialogueEnded = true;
					for (i in 0...textBoxTypes.length)
					{
						var checkArray:Array<String> = ['', 'center-'];
						if (box != null && box.animation != null && box.animation.curAnim != null)
						{
							var animName:String = box.animation.curAnim.name;
							for (j in 0...checkArray.length)
							{
								if (animName == checkArray[j] + textBoxTypes[i] || animName == checkArray[j] + textBoxTypes[i] + 'Open')
								{
									box.animation.play(checkArray[j] + textBoxTypes[i] + 'Open', true);
								}
							}
						}
					}

					if (box != null && box.animation != null && box.animation.curAnim != null)
					{
						box.animation.curAnim.curFrame = box.animation.curAnim.frames.length - 1;
						box.animation.curAnim.reverse();
					}
					if (alphabetText != null)
					{
						remove(alphabetText);
						alphabetText.kill();
						alphabetText.destroy();
					}
					if (box != null)
						updateBoxOffsets(box);
					FlxG.sound.music.fadeOut(1, 0);
				}
				else
				{
					startNextDialog();
				}
				var soundPath = Paths.sound(closeSound);
				if (soundPath != null)
					FlxG.sound.play(soundPath, closeVolume);
			}
			else if (alphabetText != null && alphabetText.finishedText)
			{
				var char:Null<DialogueCharacter> = arrayCharacters[lastCharacter];
				if (char != null && char.animation != null && char.animation.curAnim != null && char.animationIsLoop() && char.animation.finished)
				{
					var animName = char.animation.curAnim.name;
					if (animName != null)
						char.playAnim(animName, true);
				}
			}
			else if (alphabetText != null)
			{
				var char:Null<DialogueCharacter> = arrayCharacters[lastCharacter];
				if (char != null && char.animation != null && char.animation.curAnim != null && char.animation.finished)
				{
					char.animation.curAnim.restart();
				}
			}

			if (box != null && box.animation != null && box.animation.curAnim != null && box.animation.curAnim.finished)
			{
				for (i in 0...textBoxTypes.length)
				{
					var checkArray:Array<String> = ['', 'center-'];
					var animName:String = box.animation.curAnim.name;
					for (j in 0...checkArray.length)
					{
						if (animName == checkArray[j] + textBoxTypes[i] || animName == checkArray[j] + textBoxTypes[i] + 'Open')
						{
							box.animation.play(checkArray[j] + textBoxTypes[i], true);
						}
					}
				}
				updateBoxOffsets(box);
			}

			if (lastCharacter != -1 && arrayCharacters.length > 0)
			{
				for (i in 0...arrayCharacters.length)
				{
					var char = arrayCharacters[i];
					if (char != null)
					{
						var jsonFile = char.jsonFile;
						var pos:String = (jsonFile != null) ? jsonFile.dialogue_pos : 'left';
						if (i != lastCharacter)
						{
							switch (pos)
							{
								case 'left':
									char.x -= scrollSpeed * elapsed;
									if (char.x < char.startingPos + offsetPos)
										char.x = char.startingPos + offsetPos;
								case 'center':
									char.y += scrollSpeed * elapsed;
									if (char.y > char.startingPos + FlxG.height)
										char.y = char.startingPos + FlxG.height;
								case 'right':
									char.x += scrollSpeed * elapsed;
									if (char.x > char.startingPos - offsetPos)
										char.x = char.startingPos - offsetPos;
							}
							char.alpha -= 3 * elapsed;
							if (char.alpha < 0.00001)
								char.alpha = 0.00001;
						}
						else
						{
							switch (pos)
							{
								case 'left':
									char.x += scrollSpeed * elapsed;
									if (char.x > char.startingPos)
										char.x = char.startingPos;
								case 'center':
									char.y -= scrollSpeed * elapsed;
									if (char.y < char.startingPos)
										char.y = char.startingPos;
								case 'right':
									char.x -= scrollSpeed * elapsed;
									if (char.x < char.startingPos)
										char.x = char.startingPos;
							}
							char.alpha += 3 * elapsed;
							if (char.alpha > 1)
								char.alpha = 1;
						}
					}
				}
			}
		}
		else // Dialogue ending
		{
			if (box != null && box.animation != null && box.animation.curAnim != null && box.animation.curAnim.curFrame <= 0)
			{
				remove(box);
				box.kill();
				box.destroy();
				box = null;
			}

			if (bgFade != null)
			{
				bgFade.alpha -= 0.5 * elapsed;
				if (bgFade.alpha <= 0)
				{
					remove(bgFade);
					bgFade.destroy();
					bgFade = null;
				}
			}

			for (i in 0...arrayCharacters.length)
			{
				var char:Null<DialogueCharacter> = arrayCharacters[i];
				if (char != null)
				{
					var jsonFile = char.jsonFile;
					var pos:String = (jsonFile != null) ? jsonFile.dialogue_pos : 'left';
					switch (pos)
					{
						case 'left':
							char.x -= scrollSpeed * elapsed;
						case 'center':
							char.y += scrollSpeed * elapsed;
						case 'right':
							char.x += scrollSpeed * elapsed;
					}
					char.alpha -= elapsed * 10;
				}
			}

			if (box == null && bgFade == null)
			{
				for (i in 0...arrayCharacters.length)
				{
					var char:Null<DialogueCharacter> = arrayCharacters[0];
					if (char != null)
					{
						arrayCharacters.remove(char);
						remove(char);
						char.destroy();
					}
				}
				if (finishThing != null)
					finishThing();
				kill();
			}
		}
		super.update(elapsed);
	}

	var lastCharacter:Int = -1;
	var lastBoxType:String = '';

	function startNextDialog():Void
	{
		if (dialogueList == null)
			return;
		var curDialogue:Null<DialogueLine> = null;
		do
		{
			curDialogue = dialogueList.dialogue[currentText];
		}
		while (curDialogue == null);

		if (curDialogue.text == null || curDialogue.text.length < 1)
			curDialogue.text = ' ';
		if (curDialogue.boxState == null)
			curDialogue.boxState = 'normal';
		if (curDialogue.speed == null || Math.isNaN(curDialogue.speed))
			curDialogue.speed = 0.05;

		var animName:String = (curDialogue.boxState != null) ? curDialogue.boxState : 'normal';
		var boxType:String = textBoxTypes[0];
		for (i in 0...textBoxTypes.length)
		{
			if (textBoxTypes[i] == animName)
			{
				boxType = animName;
			}
		}

		var character:Int = 0;
		if (box != null)
			box.visible = true;
		for (i in 0...arrayCharacters.length)
		{
			var arrChar = arrayCharacters[i];
			if (arrChar != null && arrChar.curCharacter == curDialogue.portrait)
			{
				character = i;
				break;
			}
		}
		var centerPrefix:String = '';
		var lePosition:String = 'left';
		var arrChar = arrayCharacters[character];
		if (arrChar != null)
		{
			var jsonFile = arrChar.jsonFile;
			if (jsonFile != null)
				lePosition = jsonFile.dialogue_pos;
		}
		if (lePosition == 'center')
			centerPrefix = 'center-';

		if (character != lastCharacter)
		{
			if (box != null)
			{
				box.animation.play(centerPrefix + boxType + 'Open', true);
				updateBoxOffsets(box);
				box.flipX = (lePosition == 'left');
			}
		}
		else if (boxType != lastBoxType)
		{
			if (box != null)
			{
				box.animation.play(centerPrefix + boxType, true);
				updateBoxOffsets(box);
			}
		}
		lastCharacter = character;
		lastBoxType = boxType;

		if (alphabetText != null && curDialogue.text != null)
			alphabetText.text = curDialogue.text;
		if (alphabetText != null && curDialogue.speed != null)
			alphabetText.delay = curDialogue.speed;
		if (alphabetText != null)
		{
			alphabetText.sound = (curDialogue.sound != null) ? curDialogue.sound : 'dialogue';
			var soundTrimmed = alphabetText.sound.trim();
			if (soundTrimmed == null || soundTrimmed == '')
				alphabetText.sound = 'dialogue';

			alphabetText.y = DEFAULT_TEXT_Y;
			if (alphabetText.rows > 2)
				alphabetText.y -= LONG_TEXT_ADD;
		}

		var char:Null<DialogueCharacter> = arrayCharacters[character];
		if (char != null)
		{
			var expression = curDialogue.expression;
			var finished = (alphabetText != null) ? alphabetText.finishedText : false;
			char.playAnim(expression, finished);
			if (char.animation != null && char.animation.curAnim != null)
			{
				var rate:Float = 24 - (((curDialogue.speed - 0.05) / 5) * 480);
				if (rate < 12)
					rate = 12;
				else if (rate > 48)
					rate = 48;
				char.animation.curAnim.frameRate = rate;
			}
		}
		currentText++;

		if (nextDialogueThing != null)
		{
			nextDialogueThing();
		}
	}

	public static function parseDialogue(path:String):Null<DialogueFile>
	{
		if (FileSystem.exists(path))
		{
			var content = File.getContent(path);
			if (content != null)
				return cast Json.parse(content, path);
		}
		return null;
	}

	// Had to make it static because of the editors
	public static function updateBoxOffsets(box:Null<FlxSprite>):Void
	{
		if (box == null)
			return;
		box.centerOffsets();
		box.updateHitbox();
		if (box.animation != null && box.animation.curAnim != null && box.animation.curAnim.name != null)
		{
			if (box.animation.curAnim.name.startsWith('angry'))
			{
				box.offset.set(50, 65);
			}
			else if (box.animation.curAnim.name.startsWith('center-angry'))
			{
				box.offset.set(50, 30);
			}
			else
			{
				box.offset.set(10, 0);
			}
		}
		else
		{
			box.offset.set(10, 0);
		}

		if (!box.flipX)
			box.offset.y += 10;
	}
}
