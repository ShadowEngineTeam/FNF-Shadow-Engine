package options;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.shapes.FlxShapeCircle;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;
import lime.system.Clipboard;
import flixel.util.FlxGradient;
import objects.StrumNote;
import objects.Note;
import flixel.addons.transition.FlxTransitionableState;
import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

@:nullSafety
class NotesSubState extends MusicBeatSubstate
{
	var onModeColumn:Bool = true;
	var curSelectedMode:Int = 0;
	var curSelectedNote:Int = 0;
	var onPixel:Bool = false;
	var dataArray:Array<Array<FlxColor>> = [];

	var hexTypeLine:FlxSprite = new FlxSprite();
	var hexTypeNum:Int = -1;
	var hexTypeVisibleTimer:Float = 0;

	var copyButton:FlxSprite = new FlxSprite();
	var pasteButton:FlxSprite = new FlxSprite();

	var colorGradient:FlxSprite = new FlxSprite();
	var colorGradientSelector:FlxSprite = new FlxSprite();
	var colorPalette:FlxSprite = new FlxSprite();
	var colorWheel:FlxSprite = new FlxSprite();
	var colorWheelSelector:FlxShapeCircle = new FlxShapeCircle(0, 0, 8, {thickness: 0}, FlxColor.WHITE);

	var alphabetR:Null<Alphabet> = null;
	var alphabetG:Null<Alphabet> = null;
	var alphabetB:Null<Alphabet> = null;
	var alphabetHex:Null<Alphabet> = null;

	var modeBG:FlxSprite = new FlxSprite();
	var notesBG:FlxSprite = new FlxSprite();

	// controller support
	var controllerPointer:FlxShapeCircle = new FlxShapeCircle(0, 0, 20, {thickness: 0}, FlxColor.WHITE);
	var _lastControllerMode:Bool = false;
	var tipTxt:FlxText = new FlxText();

	public function new()
	{
		super();

		controls.isInSubstate = true;

		#if FEATURE_DISCORD_RPC
		DiscordClient.changePresence("Note Colors Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite();
		var bgImg = Paths.image('menuDesat');
		if (bgImg != null) bg.loadGraphic(bgImg);
		bg.color = 0xFFEA71FD;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33FFFFFF, 0x0));
		grid.velocity.set(40, 40);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		add(grid);

		modeBG = new FlxSprite(215, 85).makeGraphic(315, 115, FlxColor.BLACK);
		modeBG.visible = false;
		modeBG.alpha = 0.4;
		add(modeBG);

		notesBG = new FlxSprite(140, 190).makeGraphic(480, 125, FlxColor.BLACK);
		notesBG.visible = false;
		notesBG.alpha = 0.4;
		add(notesBG);

		modeNotes = new FlxTypedGroup<FlxSprite>();
		add(modeNotes);

		myNotes = new FlxTypedGroup<StrumNote>();
		add(myNotes);

		var bg:FlxSprite = new FlxSprite(720).makeGraphic(FlxG.width - 720, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.25;
		add(bg);
		var bg:FlxSprite = new FlxSprite(750, 160).makeGraphic(FlxG.width - 780, 540, FlxColor.BLACK);
		bg.alpha = 0.25;
		add(bg);

		var sigh:String;
		var sighPosX:Int;

		if (controls.mobileC)
		{
			sigh = "PRESS";
			sighPosX = 44;
		}
		else
		{
			sigh = "CTRL";
			sighPosX = 50;
		}

		var text:Alphabet = new Alphabet(sighPosX, 86, sigh, false);
		text.alignment = CENTERED;
		text.setScale(0.4);
		add(text);

		copyButton = new FlxSprite(760, 50);
		var copyImg = Paths.image('noteColorMenu/copy');
		if (copyImg != null) copyButton.loadGraphic(copyImg);
		copyButton.alpha = 0.6;
		add(copyButton);

		pasteButton = new FlxSprite(1180, 50);
		var pasteImg = Paths.image('noteColorMenu/paste');
		if (pasteImg != null) pasteButton.loadGraphic(pasteImg);
		pasteButton.alpha = 0.6;
		add(pasteButton);

		colorGradient = FlxGradient.createGradientFlxSprite(60, 360, [FlxColor.WHITE, FlxColor.BLACK]);
		colorGradient.setPosition(780, 200);
		add(colorGradient);

		colorGradientSelector = new FlxSprite(770, 200).makeGraphic(80, 10, FlxColor.WHITE);
		colorGradientSelector.offset.y = 5;
		add(colorGradientSelector);

		colorPalette = new FlxSprite(820, 580);
		var palImg = Paths.image('noteColorMenu/palette');
		if (palImg != null) colorPalette.loadGraphic(palImg);
		colorPalette.scale.set(20, 20);
		colorPalette.updateHitbox();
		colorPalette.antialiasing = false;
		add(colorPalette);

		colorWheel = new FlxSprite(860, 200);
		var wheelImg = Paths.image('noteColorMenu/colorWheel');
		if (wheelImg != null) colorWheel.loadGraphic(wheelImg);
		colorWheel.setGraphicSize(360, 360);
		colorWheel.updateHitbox();
		add(colorWheel);

		colorWheelSelector = new FlxShapeCircle(0, 0, 8, {thickness: 0}, FlxColor.WHITE);
		colorWheelSelector.offset.set(8, 8);
		colorWheelSelector.alpha = 0.6;
		add(colorWheelSelector);

		var txtX = 980;
		var txtY = 90;
		alphabetR = makeColorAlphabet(txtX - 100, txtY);
		add(alphabetR);
		alphabetG = makeColorAlphabet(txtX, txtY);
		add(alphabetG);
		alphabetB = makeColorAlphabet(txtX + 100, txtY);
		add(alphabetB);
		alphabetHex = makeColorAlphabet(txtX, txtY - 55);
		add(alphabetHex);
		hexTypeLine = new FlxSprite(0, 20).makeGraphic(5, 62, FlxColor.WHITE);
		hexTypeLine.visible = false;
		add(hexTypeLine);

		spawnNotes();
		updateNotes(true);
		var snd = Paths.sound('scrollMenu'); if (snd != null) FlxG.sound.play(snd, 0.6);

		var tipX = 20;
		var tipY = 660;
		var tipText:String;

		if (controls.mobileC)
		{
			tipText = "Press C to Reset the selected Note Part.";
			tipY = 0;
		}
		else
		{
			tipText = "Press RELOAD to Reset the selected Note Part.";
		}

		var tip:FlxText = new FlxText(tipX, tipY, 0, tipText, 16);
		tip.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tip.borderSize = 2;
		add(tip);

		tipTxt = new FlxText(tipX, tipY + 24, 0, '', 16);
		tipTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tipTxt.borderSize = 2;
		add(tipTxt);
		updateTip();

		controllerPointer = new FlxShapeCircle(0, 0, 20, {thickness: 0}, FlxColor.WHITE);
		controllerPointer.offset.set(20, 20);
		controllerPointer.screenCenter();
		controllerPointer.alpha = 0.6;
		add(controllerPointer);

		FlxG.mouse.visible = !controls.controllerMode;
		controllerPointer.visible = controls.controllerMode;
		_lastControllerMode = controls.controllerMode;

		#if FEATURE_MOBILE_CONTROLS
		addTouchPad("NONE", "B_C");
		touchPad.buttonB.x = FlxG.width - 132;
		touchPad.buttonC.x = 0;
		touchPad.buttonC.y = FlxG.height - 135;
		#end
	}

	function updateTip()
	{
		if (!controls.mobileC)
			tipTxt.text = 'Hold ' + (!controls.controllerMode ? 'Shift' : 'Left Shoulder Button') + ' + Press RESET key to fully reset the selected Note.';
	}

	var _storedColor:FlxColor = FlxColor.WHITE;
	var changingNote:Bool = false;
	var holdingOnObj:Null<FlxSprite> = null;
	var allowedTypeKeys:Map<FlxKey, String> = [
		ZERO => '0',
		ONE => '1',
		TWO => '2',
		THREE => '3',
		FOUR => '4',
		FIVE => '5',
		SIX => '6',
		SEVEN => '7',
		EIGHT => '8',
		NINE => '9',
		NUMPADZERO => '0',
		NUMPADONE => '1',
		NUMPADTWO => '2',
		NUMPADTHREE => '3',
		NUMPADFOUR => '4',
		NUMPADFIVE => '5',
		NUMPADSIX => '6',
		NUMPADSEVEN => '7',
		NUMPADEIGHT => '8',
		NUMPADNINE => '9',
		A => 'A',
		B => 'B',
		C => 'C',
		D => 'D',
		E => 'E',
		F => 'F'
	];

	override function update(elapsed:Float)
	{
		if (controls.BACK)
		{
			FlxG.mouse.visible = false;
			var snd = Paths.sound('cancelMenu'); if (snd != null) FlxG.sound.play(snd);
			ClientPrefs.saveSettings();
			controls.isInSubstate = false;
			close();
			return;
		}

		super.update(elapsed);

		// Early controller checking
		if (FlxG.gamepads.anyJustPressed(ANY))
			controls.controllerMode = true;
		else if (FlxG.mouse.justPressed || FlxG.mouse.deltaViewX != 0 || FlxG.mouse.deltaViewY != 0)
			controls.controllerMode = false;

		var changedToController:Bool = false;
		if (controls.controllerMode != _lastControllerMode)
		{
			// trace('changed controller mode');
			FlxG.mouse.visible = !controls.controllerMode;
			controllerPointer.visible = controls.controllerMode;

			// changed to controller mid state
			if (controls.controllerMode)
			{
				controllerPointer.x = FlxG.mouse.x;
				controllerPointer.y = FlxG.mouse.y;
				changedToController = true;
			}
			// changed to keyboard mid state
			/*else
				{
					FlxG.mouse.x = controllerPointer.x;
					FlxG.mouse.y = controllerPointer.y;
				}
				// apparently theres no easy way to change mouse position that i know, oh well
			 */
			_lastControllerMode = controls.controllerMode;
			updateTip();
		}

		// controller things
		var analogX:Float = 0;
		var analogY:Float = 0;
		var analogMoved:Bool = false;
		if (controls.controllerMode && (changedToController || FlxG.gamepads.anyInput()))
		{
			for (gamepad in FlxG.gamepads.getActiveGamepads())
			{
				analogX = gamepad.getXAxis(LEFT_ANALOG_STICK);
				analogY = gamepad.getYAxis(LEFT_ANALOG_STICK);
				analogMoved = (analogX != 0 || analogY != 0);
				if (analogMoved)
					break;
			}
			controllerPointer.x = Math.max(0, Math.min(FlxG.width, controllerPointer.x + analogX * 1000 * elapsed));
			controllerPointer.y = Math.max(0, Math.min(FlxG.height, controllerPointer.y + analogY * 1000 * elapsed));
		}
		var controllerPressed:Bool = (controls.controllerMode && controls.ACCEPT);

		if (FlxG.keys.justPressed.CONTROL)
		{
			onPixel = !onPixel;
			spawnNotes();
			updateNotes(true);
			var snd = Paths.sound('scrollMenu'); if (snd != null) FlxG.sound.play(snd, 0.6);
		}

		if (hexTypeNum > -1)
		{
			var keyPressed:FlxKey = cast(FlxG.keys.firstJustPressed(), FlxKey);
			hexTypeVisibleTimer += elapsed;
			var changed:Bool = false;
			if (changed = FlxG.keys.justPressed.LEFT)
				hexTypeNum--;
			else if (changed = FlxG.keys.justPressed.RIGHT)
				hexTypeNum++;
			else if (allowedTypeKeys.exists(keyPressed))
			{
				// trace('keyPressed: $keyPressed, lil str: ' + allowedTypeKeys.get(keyPressed));
				var curColor:String = alphabetHex != null ? alphabetHex.text : "000000";
				var keyPress = allowedTypeKeys.get(keyPressed);
				var newColor:String = keyPress != null ? curColor.substring(0, hexTypeNum) + keyPress + curColor.substring(hexTypeNum + 1) : curColor;

				var colorHex:Null<FlxColor> = FlxColor.fromString('#' + newColor);
				if (colorHex != null)
				{
					setShaderColor(colorHex);
					_storedColor = getShaderColor();
					updateColors();
				}

				// move you to next letter
				hexTypeNum++;
				changed = true;
			}
			else if (FlxG.keys.justPressed.ENTER)
				hexTypeNum = -1;

			var end:Bool = false;
			if (changed)
			{
				if (hexTypeNum > 5) // Typed last letter
				{
					hexTypeNum = -1;
					end = true;
					hexTypeLine.visible = false;
				}
				else
				{
					if (hexTypeNum < 0)
						hexTypeNum = 0;
					else if (hexTypeNum > 5)
						hexTypeNum = 5;
					centerHexTypeLine();
					hexTypeLine.visible = true;
				}
				var snd = Paths.sound('scrollMenu'); if (snd != null) FlxG.sound.play(snd, 0.6);
			}
			if (!end)
				hexTypeLine.visible = Math.floor(hexTypeVisibleTimer * 2) % 2 == 0;
		}
		else
		{
			var add:Int = 0;
			if (analogX == 0 && !changedToController)
			{
				if (controls.UI_LEFT_P)
					add = -1;
				else if (controls.UI_RIGHT_P)
					add = 1;
			}

			if (analogY == 0 && !changedToController && (controls.UI_UP_P || controls.UI_DOWN_P))
			{
				onModeColumn = !onModeColumn;
				modeBG.visible = onModeColumn;
				notesBG.visible = !onModeColumn;
			}

			if (add != 0)
			{
				if (onModeColumn)
					changeSelectionMode(add);
				else
					changeSelectionNote(add);
			}
			hexTypeLine.visible = false;
		}

		// Copy/Paste buttons
		var generalMoved:Bool = (FlxG.mouse.justMoved || analogMoved);
		var generalPressed:Bool = (FlxG.mouse.justPressed || controllerPressed);
		if (generalMoved)
		{
			copyButton.alpha = 0.6;
			pasteButton.alpha = 0.6;
		}

		if (pointerOverlaps(copyButton))
		{
			copyButton.alpha = 1;
			if (generalPressed)
			{
				Clipboard.text = getShaderColor().toHexString(false, false);
				var snd = Paths.sound('scrollMenu'); if (snd != null) FlxG.sound.play(snd, 0.6);
				trace('copied: ' + Clipboard.text);
			}
			hexTypeNum = -1;
		}
		else if (pointerOverlaps(pasteButton))
		{
			pasteButton.alpha = 1;
			if (generalPressed)
			{
				var formattedText = Clipboard.text.trim().toUpperCase().replace('#', '').replace('0x', '');
				var newColor:Null<FlxColor> = FlxColor.fromString('#' + formattedText);
				// trace('#${Clipboard.text.trim().toUpperCase()}');
				if (newColor != null && formattedText.length == 6)
				{
					setShaderColor(newColor);
					var snd2 = Paths.sound('scrollMenu'); if (snd2 != null) FlxG.sound.play(snd2, 0.6);
					_storedColor = getShaderColor();
					updateColors();
				}
				else // errored
				{
					var snd3 = Paths.sound('cancelMenu'); if (snd3 != null) FlxG.sound.play(snd3, 0.6);
				}
			}
			hexTypeNum = -1;
		}

		// Click
		if (generalPressed)
		{
			hexTypeNum = -1;
			if (pointerOverlaps(modeNotes))
			{
				modeNotes.forEachAlive(function(note:FlxSprite)
				{
					if (curSelectedMode != note.ID && pointerOverlaps(note))
					{
						modeBG.visible = notesBG.visible = false;
						curSelectedMode = note.ID;
						onModeColumn = true;
						updateNotes();
						var snd = Paths.sound('scrollMenu'); if (snd != null) FlxG.sound.play(snd, 0.6);
					}
				});
			}
			else if (pointerOverlaps(myNotes))
			{
				myNotes.forEachAlive(function(note:StrumNote)
				{
					if (curSelectedNote != note.ID && pointerOverlaps(note))
					{
						modeBG.visible = notesBG.visible = false;
						curSelectedNote = note.ID;
						onModeColumn = false;
						if (bigNote != null && bigNote.rgbShader != null)
						{
							bigNote.rgbShader.parent = Note.globalRgbShaders[note.ID];
							bigNote.shader = Note.globalRgbShaders[note.ID].shader;
						}
						updateNotes();
						var snd2 = Paths.sound('scrollMenu'); if (snd2 != null) FlxG.sound.play(snd2, 0.6);
					}
				});
			}
			else if (pointerOverlaps(colorWheel))
			{
				_storedColor = getShaderColor();
				holdingOnObj = colorWheel;
			}
			else if (pointerOverlaps(colorGradient))
			{
				_storedColor = getShaderColor();
				holdingOnObj = colorGradient;
			}
			else if (pointerOverlaps(colorPalette))
			{
				setShaderColor(colorPalette.pixels.getPixel32(Std.int((pointerX() - colorPalette.x) / colorPalette.scale.x),
					Std.int((pointerY() - colorPalette.y) / colorPalette.scale.y)));
				var snd = Paths.sound('scrollMenu'); if (snd != null) FlxG.sound.play(snd, 0.6);
				updateColors();
			}
			else if (pointerOverlaps(skinNote))
			{
				onPixel = !onPixel;
				spawnNotes();
				updateNotes(true);
				var snd2 = Paths.sound('scrollMenu'); if (snd2 != null) FlxG.sound.play(snd2, 0.6);
			}
			else if (pointerY() >= hexTypeLine.y && pointerY() < hexTypeLine.y + hexTypeLine.height && Math.abs(pointerX() - 1000) <= 84)
			{
				FlxG.stage.window.textInputEnabled = true;
				hexTypeNum = 0;
				if (alphabetHex != null)
				{
					for (letter in alphabetHex.letters)
					{
						if (letter.x - letter.offset.x + letter.width <= pointerX())
							hexTypeNum++;
						else
							break;
					}
				}
				if (hexTypeNum > 5)
					hexTypeNum = 5;
				hexTypeLine.visible = true;
				centerHexTypeLine();
			}
			else
				holdingOnObj = null;
		}
		// holding
		if (holdingOnObj != null)
		{
			if (FlxG.mouse.justReleased || (controls.controllerMode && controls.justReleased('accept')))
			{
				holdingOnObj = null;
				_storedColor = getShaderColor();
				updateColors();
				var snd3 = Paths.sound('scrollMenu'); if (snd3 != null) FlxG.sound.play(snd3, 0.6);
			}
			else if (generalMoved || generalPressed)
			{
				if (holdingOnObj == colorGradient)
				{
					var newBrightness = 1 - FlxMath.bound((pointerY() - colorGradient.y) / colorGradient.height, 0, 1);
					_storedColor.alpha = 1;
					if (_storedColor.brightness == 0) // prevent bug
						setShaderColor(FlxColor.fromRGBFloat(newBrightness, newBrightness, newBrightness));
					else
						setShaderColor(FlxColor.fromHSB(_storedColor.hue, _storedColor.saturation, newBrightness));
					updateColors(_storedColor);
				}
				else if (holdingOnObj == colorWheel)
				{
					var center:FlxPoint = FlxPoint.weak(colorWheel.x + colorWheel.width / 2, colorWheel.y + colorWheel.height / 2);
					var mouse:FlxPoint = pointerFlxPoint();
					var hue:Float = FlxMath.wrap(FlxMath.wrap(Std.int(mouse.degreesTo(center)), 0, 360) - 90, 0, 360);
					var sat:Float = FlxMath.bound(mouse.dist(center) / colorWheel.width * 2, 0, 1);
					// trace('$hue, $sat');
					if (sat != 0)
						setShaderColor(FlxColor.fromHSB(hue, sat, _storedColor.brightness));
					else
						setShaderColor(FlxColor.fromRGBFloat(_storedColor.brightness, _storedColor.brightness, _storedColor.brightness));
					updateColors();
				}
			}
		}
		else if (#if FEATURE_MOBILE_CONTROLS touchPad.buttonC.justPressed || #end controls.RESET && hexTypeNum < 0)
		{
			if (FlxG.keys.pressed.SHIFT || FlxG.gamepads.anyJustPressed(LEFT_SHOULDER))
			{
				for (i in 0...3)
				{
					var strumNote = myNotes.members[curSelectedNote];
					if (strumNote != null && strumNote.rgbShader != null)
					{
						var strumRGB:RGBShaderReference = strumNote.rgbShader;
						var color:FlxColor = !onPixel ? ClientPrefs.defaultData.arrowRGB[curSelectedNote][i] : ClientPrefs.defaultData.arrowRGBPixel[curSelectedNote][i];
						switch (i)
						{
							case 0:
								getShader().r = strumRGB.r = color;
							case 1:
								getShader().g = strumRGB.g = color;
							case 2:
								getShader().b = strumRGB.b = color;
						}
						dataArray[curSelectedNote][i] = color;
					}
				}
			}
			setShaderColor(!onPixel ? ClientPrefs.defaultData.arrowRGB[curSelectedNote][curSelectedMode] : ClientPrefs.defaultData.arrowRGBPixel[curSelectedNote][curSelectedMode]);
			var snd = Paths.sound('cancelMenu'); if (snd != null) FlxG.sound.play(snd, 0.6);
			updateColors();
		}
	}

	function pointerOverlaps(obj:Dynamic)
	{
		if (!controls.controllerMode)
			return FlxG.mouse.overlaps(obj);
		return FlxG.overlap(controllerPointer, obj);
	}

	function pointerX():Float
	{
		if (!controls.controllerMode)
			return FlxG.mouse.x;
		return controllerPointer.x;
	}

	function pointerY():Float
	{
		if (!controls.controllerMode)
			return FlxG.mouse.y;
		return controllerPointer.y;
	}

	function pointerFlxPoint():FlxPoint
	{
		if (!controls.controllerMode)
			return FlxG.mouse.getViewPosition();
		return controllerPointer.getScreenPosition();
	}

	function centerHexTypeLine()
	{
		// trace(hexTypeNum);
		if (alphabetHex == null) return;
		if (hexTypeNum > 0)
		{
			var letter = alphabetHex.letters[hexTypeNum - 1];
			hexTypeLine.x = letter.x - letter.offset.x + letter.width;
		}
		else
		{
			var letter = alphabetHex.letters[0];
			hexTypeLine.x = letter.x - letter.offset.x;
		}
		hexTypeLine.x += hexTypeLine.width;
		hexTypeVisibleTimer = 0;
	}

	function changeSelectionMode(change:Int = 0)
	{
		curSelectedMode += change;
		if (curSelectedMode < 0)
			curSelectedMode = 2;
		if (curSelectedMode >= 3)
			curSelectedMode = 0;

		modeBG.visible = true;
		notesBG.visible = false;
		updateNotes();
		var snd = Paths.sound('scrollMenu'); if (snd != null) FlxG.sound.play(snd);
	}

	function changeSelectionNote(change:Int = 0)
	{
		curSelectedNote += change;
		if (curSelectedNote < 0)
			curSelectedNote = dataArray.length - 1;
		if (curSelectedNote >= dataArray.length)
			curSelectedNote = 0;

		modeBG.visible = false;
		notesBG.visible = true;
		if (bigNote != null && bigNote.rgbShader != null)
		{
			bigNote.rgbShader.parent = Note.globalRgbShaders[curSelectedNote];
			bigNote.shader = Note.globalRgbShaders[curSelectedNote].shader;
		}
		updateNotes();
		var snd = Paths.sound('scrollMenu'); if (snd != null) FlxG.sound.play(snd);
	}

	// alphabets
	function makeColorAlphabet(x:Float = 0, y:Float = 0):Alphabet
	{
		var text:Alphabet = new Alphabet(x, y, '', true);
		text.alignment = CENTERED;
		text.setScale(0.6);
		add(text);
		return text;
	}

	// notes sprites functions
	var skinNote:Null<FlxSprite> = null;
	var modeNotes:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
	var myNotes:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	var bigNote:Null<Note> = null;

	public function spawnNotes()
	{
		dataArray = !onPixel ? ClientPrefs.data.arrowRGB : ClientPrefs.data.arrowRGBPixel;
		if (onPixel)
			PlayState.stageUI = "pixel";

		// clear groups
		modeNotes.forEachAlive(function(note:FlxSprite)
		{
			note.kill();
			note.destroy();
		});
		myNotes.forEachAlive(function(note:StrumNote)
		{
			note.kill();
			note.destroy();
		});
		modeNotes.clear();
		myNotes.clear();

		if (skinNote != null)
		{
			remove(skinNote);
			skinNote.destroy();
		}
		if (bigNote != null)
		{
			remove(bigNote);
			bigNote.destroy();
		}

		// respawn stuff
		var res:Int = onPixel ? 160 : 17;
		var skinImg = Paths.image('noteColorMenu/' + (onPixel ? 'note' : 'notePixel'));
		skinNote = new FlxSprite(48, 24);
		if (skinImg != null) skinNote.loadGraphic(skinImg, true, res, res);
		skinNote.antialiasing = ClientPrefs.data.antialiasing;
		skinNote.setGraphicSize(68);
		skinNote.updateHitbox();
		skinNote.animation.add('anim', [0], 24, true);
		skinNote.animation.play('anim', true);
		if (!onPixel)
			skinNote.antialiasing = false;
		add(skinNote);

		var res:Int = !onPixel ? 160 : 17;
		for (i in 0...3)
		{
			var noteImg = Paths.image('noteColorMenu/' + (!onPixel ? 'note' : 'notePixel'));
			var newNote:FlxSprite = new FlxSprite(230 + (100 * i), 100);
			if (noteImg != null) newNote.loadGraphic(noteImg, true, res, res);
			newNote.antialiasing = ClientPrefs.data.antialiasing;
			newNote.setGraphicSize(85);
			newNote.updateHitbox();
			newNote.animation.add('anim', [i], 24, true);
			newNote.animation.play('anim', true);
			newNote.ID = i;
			if (onPixel)
				newNote.antialiasing = false;
			modeNotes.add(newNote);
		}

		Note.globalRgbShaders = [];
		for (i in 0...dataArray.length)
		{
			Note.initializeGlobalRGBShader(i);
			var newNote:StrumNote = new StrumNote(150 + (480 / dataArray.length * i), 200, i, 0, '');
			newNote.setGraphicSize(102);
			newNote.useRGBShader = true;
			newNote.updateHitbox();
			newNote.ID = i;
			myNotes.add(newNote);
		}

		bigNote = new Note(0, 0, false, true);
		bigNote.setPosition(250, 325);
		bigNote.setGraphicSize(250);
		bigNote.updateHitbox();
		if (bigNote.rgbShader != null) bigNote.rgbShader.parent = Note.globalRgbShaders[curSelectedNote];
		bigNote.shader = Note.globalRgbShaders[curSelectedNote].shader;
		for (i in 0...Note.colArray.length)
		{
			if (!onPixel)
				bigNote.animation.addByPrefix('note$i', Note.colArray[i] + '0', 24, true);
			else
				bigNote.animation.add('note$i', [i + 4], 24, true);
		}
		insert(members.indexOf(myNotes) + 1, bigNote);
		_storedColor = getShaderColor();
		PlayState.stageUI = "normal";
	}

	function updateNotes(?instant:Bool = false)
	{
		for (note in modeNotes)
		{
			if (note != null)
				note.alpha = (curSelectedMode == note.ID) ? 1 : 0.6;
		}

		for (note in myNotes)
		{
			if (note == null) continue;
			var newAnim:String = curSelectedNote == note.ID ? 'confirm' : 'pressed';
			note.alpha = (curSelectedNote == note.ID) ? 1 : 0.6;
			if (note.animation.curAnim == null || note.animation.curAnim.name != newAnim)
				note.playAnim(newAnim, true);
			if (instant && note.animation.curAnim != null)
				note.animation.curAnim.finish();
		}
		if (bigNote != null)
			bigNote.animation.play('note$curSelectedNote', true);
		updateColors();
	}

	function updateColors(specific:Null<FlxColor> = null)
	{
		var color:FlxColor = getShaderColor();
		var wheelColor:FlxColor = specific == null ? getShaderColor() : specific;
		if (alphabetR != null) alphabetR.text = Std.string(color.red);
		if (alphabetG != null) alphabetG.text = Std.string(color.green);
		if (alphabetB != null) alphabetB.text = Std.string(color.blue);
		if (alphabetHex != null)
		{
			alphabetHex.text = color.toHexString(false, false);
			for (letter in alphabetHex.letters)
				letter.color = color;
		}

		colorWheel.color = FlxColor.fromHSB(0, 0, color.brightness);
		colorWheelSelector.setPosition(colorWheel.x + colorWheel.width / 2, colorWheel.y + colorWheel.height / 2);
		if (wheelColor.brightness != 0)
		{
			var hueWrap:Float = wheelColor.hue * Math.PI / 180;
			colorWheelSelector.x += Math.sin(hueWrap) * colorWheel.width / 2 * wheelColor.saturation;
			colorWheelSelector.y -= Math.cos(hueWrap) * colorWheel.height / 2 * wheelColor.saturation;
		}
		colorGradientSelector.y = colorGradient.y + colorGradient.height * (1 - color.brightness);

		var strumNote = myNotes.members[curSelectedNote];
		if (strumNote != null && strumNote.rgbShader != null)
		{
			var strumRGB:RGBShaderReference = strumNote.rgbShader;
			switch (curSelectedMode)
			{
				case 0:
					getShader().r = strumRGB.r = color;
				case 1:
					getShader().g = strumRGB.g = color;
				case 2:
					getShader().b = strumRGB.b = color;
			}
		}
	}

	function setShaderColor(value:FlxColor)
		dataArray[curSelectedNote][curSelectedMode] = value;

	function getShaderColor()
		return dataArray[curSelectedNote][curSelectedMode];

	function getShader()
		return Note.globalRgbShaders[curSelectedNote];
}
