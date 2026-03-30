package options;

import backend.StageData;
import objects.Character;
import objects.Bar;
import flixel.addons.display.shapes.FlxShapeCircle;
import states.stages.Stage as BackgroundStage;
#if (target.threaded)
import sys.thread.Thread;
import sys.thread.Mutex;
#end

@:nullSafety
class NoteOffsetState extends MusicBeatState
{
	var stageDirectory:String = 'week1';
	var boyfriend:Null<Character> = null;
	var gf:Null<Character> = null;

	public var camHUD:Null<ShadowCamera> = null;
	public var camGame:Null<ShadowCamera> = null;
	public var camOther:Null<ShadowCamera> = null;

	var coolText:FlxText = new FlxText();
	var rating:FlxSprite = new FlxSprite();
	var comboNums:FlxSpriteGroup = new FlxSpriteGroup();
	var dumbTexts:FlxTypedGroup<FlxText> = new FlxTypedGroup<FlxText>();

	var barPercent:Float = 0;
	var delayMin:Int = -500;
	var delayMax:Int = 500;
	var timeBar:Null<Bar> = null;
	var timeTxt:FlxText = new FlxText();
	var beatText:Null<Alphabet> = null;
	var beatTween:Null<FlxTween> = null;

	var changeModeText:FlxText = new FlxText();

	var controllerPointer:Null<FlxSprite> = null;
	var _lastControllerMode:Bool = false;

	#if (target.threaded) var mutex:Mutex = new Mutex(); #end

	override public function create()
	{
		Paths.clearStoredMemory();
		#if FEATURE_DISCORD_RPC
		DiscordClient.changePresence("Delay/Combo Offset Menu", null);
		#end

		// Cameras
		camGame = initPsychCamera();

		camHUD = new ShadowCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		camOther = new ShadowCamera();
		camOther.bgColor.alpha = 0;
		FlxG.cameras.add(camOther, false);

		FlxG.camera.scroll.set(120, 130);

		persistentUpdate = true;
		FlxG.sound.pause();

		// Stage
		new BackgroundStage();

		// Characters
		if (!ClientPrefs.data.lowQuality)
		{
			gf = new Character(400, 130, 'gf');
			gf.x += gf.positionArray[0];
			gf.y += gf.positionArray[1];
			gf.scrollFactor.set(0.95, 0.95);
			add(gf);
		}
		boyfriend = new Character(770, 100, 'bf', true);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		add(boyfriend);

		// Combo stuff
		coolText = new FlxText(0, 0, 0, '', 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;

		var img = Paths.image('sick');
		if (img != null) rating.loadGraphic(img);
		rating.cameras = [camHUD];
		rating.antialiasing = ClientPrefs.data.antialiasing;
		rating.setGraphicSize(Std.int(rating.width * 0.7));
		rating.updateHitbox();

		add(rating);

		comboNums = new FlxSpriteGroup();
		comboNums.cameras = [camHUD];
		add(comboNums);

		var seperatedScore:Array<Int> = [];
		for (i in 0...3)
		{
			seperatedScore.push(FlxG.random.int(0, 9));
		}

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite(43 * daLoop);
			var numImg = Paths.image('num' + i);
			if (numImg != null) numScore.loadGraphic(numImg);
			numScore.cameras = [camHUD];
			numScore.antialiasing = ClientPrefs.data.antialiasing;
			numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			numScore.updateHitbox();
			comboNums.add(numScore);
			daLoop++;
		}

		dumbTexts = new FlxTypedGroup<FlxText>();
		dumbTexts.cameras = [camHUD];
		add(dumbTexts);
		createTexts();

		repositionCombo();

		// Note delay stuff
		beatText = new Alphabet(0, 0, 'Beat Hit!', true);
		beatText.setScale(0.6, 0.6);
		beatText.x += 260;
		beatText.alpha = 0;
		beatText.acceleration.y = 250;
		beatText.visible = false;
		add(beatText);

		timeTxt = new FlxText(0, 600, FlxG.width, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.borderSize = 2;
		timeTxt.visible = false;
		timeTxt.cameras = [camHUD];

		barPercent = ClientPrefs.data.noteOffset;
		updateNoteDelay();

		timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 3) + 50, 'timeBar', function() return barPercent, delayMin, delayMax);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.visible = false;
		timeBar.cameras = [camHUD];
		timeBar.leftBar.color = FlxColor.LIME;

		add(timeBar);
		add(timeTxt);

		var blackBox:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 40, FlxColor.BLACK);
		blackBox.scrollFactor.set();
		blackBox.alpha = 0.6;
		blackBox.cameras = [camHUD];
		add(blackBox);

		changeModeText = new FlxText(0, 4, FlxG.width, "", 32);
		changeModeText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		changeModeText.scrollFactor.set();
		changeModeText.cameras = [camHUD];
		add(changeModeText);

		controllerPointer = new FlxShapeCircle(0, 0, 20, {thickness: 0}, FlxColor.WHITE);
		controllerPointer.offset.set(20, 20);
		controllerPointer.screenCenter();
		controllerPointer.alpha = 0.6;
		controllerPointer.cameras = [camHUD];
		add(controllerPointer);

		updateMode();
		_lastControllerMode = true;

		Conductor.bpm = 128.0;
		#if (target.threaded)
		Thread.create(function()
		{
			mutex.acquire();
			var mus = Paths.music('offsetSong');
			if (mus != null) FlxG.sound.playMusic(mus, 1, true);
			mutex.release();
		});
		#else
		var mus2 = Paths.music('offsetSong');
		if (mus2 != null) FlxG.sound.playMusic(mus2, 1, true);
		#end

		#if FEATURE_MOBILE_CONTROLS
		addTouchPad("LEFT_FULL", "A_B_C");
		addTouchPadCamera(false);
		#end

		super.create();
		Paths.clearUnusedMemory();
	}

	var holdTime:Float = 0;
	var onComboMenu:Bool = true;
	var holdingObjectType:Null<Bool> = null;

	var startMousePos:FlxPoint = FlxPoint.get();
	var startComboOffset:FlxPoint = FlxPoint.get();

	override public function update(elapsed:Float)
	{
		var addNum:Int = 1;
		if (FlxG.keys.pressed.SHIFT || FlxG.gamepads.anyPressed(LEFT_SHOULDER))
		{
			if (onComboMenu)
				addNum = 10;
			else
				addNum = 3;
		}

		if (FlxG.gamepads.anyJustPressed(ANY))
			controls.controllerMode = true;
		else if (FlxG.mouse.justPressed)
			controls.controllerMode = false;

		if (controls.controllerMode != _lastControllerMode)
		{
			// trace('changed controller mode');
			FlxG.mouse.visible = !controls.controllerMode;
			if (controllerPointer != null) controllerPointer.visible = controls.controllerMode;

			// changed to controller mid state
			if (controls.controllerMode && controllerPointer != null)
			{
				var mousePos = FlxG.mouse.getViewPosition(camHUD);
				controllerPointer.x = mousePos.x;
				controllerPointer.y = mousePos.y;
			}
			updateMode();
			_lastControllerMode = controls.controllerMode;
		}

		if (onComboMenu)
		{
			if (FlxG.keys.justPressed.ANY || FlxG.gamepads.anyJustPressed(ANY))
			{
				var controlArray:Null<Array<Bool>> = null;
				if (!controls.controllerMode)
				{
					controlArray = [
						FlxG.keys.justPressed.LEFT,
						FlxG.keys.justPressed.RIGHT,
						FlxG.keys.justPressed.UP,
						FlxG.keys.justPressed.DOWN,

						FlxG.keys.justPressed.A,
						FlxG.keys.justPressed.D,
						FlxG.keys.justPressed.W,
						FlxG.keys.justPressed.S
					];
				}
				else
				{
					controlArray = [
						FlxG.gamepads.anyJustPressed(DPAD_LEFT),
						FlxG.gamepads.anyJustPressed(DPAD_RIGHT),
						FlxG.gamepads.anyJustPressed(DPAD_UP),
						FlxG.gamepads.anyJustPressed(DPAD_DOWN),

						FlxG.gamepads.anyJustPressed(RIGHT_STICK_DIGITAL_LEFT),
						FlxG.gamepads.anyJustPressed(RIGHT_STICK_DIGITAL_RIGHT),
						FlxG.gamepads.anyJustPressed(RIGHT_STICK_DIGITAL_UP),
						FlxG.gamepads.anyJustPressed(RIGHT_STICK_DIGITAL_DOWN)
					];
				}

				if (controlArray.contains(true))
				{
					for (i in 0...controlArray.length)
					{
						if (controlArray[i])
						{
							switch (i)
							{
								case 0:
									ClientPrefs.data.comboOffset[0] -= addNum;
								case 1:
									ClientPrefs.data.comboOffset[0] += addNum;
								case 2:
									ClientPrefs.data.comboOffset[1] += addNum;
								case 3:
									ClientPrefs.data.comboOffset[1] -= addNum;
								case 4:
									ClientPrefs.data.comboOffset[2] -= addNum;
								case 5:
									ClientPrefs.data.comboOffset[2] += addNum;
								case 6:
									ClientPrefs.data.comboOffset[3] += addNum;
								case 7:
									ClientPrefs.data.comboOffset[3] -= addNum;
							}
						}
					}
					repositionCombo();
				}
			}

			// controller things
			var analogX:Float = 0;
			var analogY:Float = 0;
			var analogMoved:Bool = false;
			var gamepadPressed:Bool = false;
			var gamepadReleased:Bool = false;
			if (controls.controllerMode && controllerPointer != null)
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
				gamepadPressed = !FlxG.gamepads.anyJustPressed(START) && controls.ACCEPT;
				gamepadReleased = !FlxG.gamepads.anyJustReleased(START) && controls.justReleased('accept');
			}

			// probably there's a better way to do this but, oh well.
			if (FlxG.mouse.justPressed || gamepadPressed)
			{
				holdingObjectType = null;
				if (!controls.controllerMode)
					FlxG.mouse.getViewPosition(camHUD, startMousePos);
				else if (controllerPointer != null)
					controllerPointer.getScreenPosition(startMousePos, camHUD);

				if (startMousePos.x - comboNums.x >= 0
					&& startMousePos.x - comboNums.x <= comboNums.width
					&& startMousePos.y - comboNums.y >= 0
					&& startMousePos.y - comboNums.y <= comboNums.height)
				{
					holdingObjectType = true;
					startComboOffset.x = ClientPrefs.data.comboOffset[2];
					startComboOffset.y = ClientPrefs.data.comboOffset[3];
					// trace('yo bro');
				}
				else if (startMousePos.x - rating.x >= 0
					&& startMousePos.x - rating.x <= rating.width
					&& startMousePos.y - rating.y >= 0
					&& startMousePos.y - rating.y <= rating.height)
				{
					holdingObjectType = false;
					startComboOffset.x = ClientPrefs.data.comboOffset[0];
					startComboOffset.y = ClientPrefs.data.comboOffset[1];
					// trace('heya');
				}
			}
			if (FlxG.mouse.justReleased || gamepadReleased)
			{
				holdingObjectType = null;
				// trace('dead');
			}

			if (holdingObjectType != null)
			{
				if (FlxG.mouse.justMoved || analogMoved)
				{
					var mousePos:Null<FlxPoint> = null;
					if (!controls.controllerMode)
						mousePos = FlxG.mouse.getViewPosition(camHUD);
					else if (controllerPointer != null)
						mousePos = controllerPointer.getScreenPosition(camHUD);

					if (mousePos != null)
					{
						var addNum:Int = holdingObjectType ? 2 : 0;
						ClientPrefs.data.comboOffset[addNum + 0] = Math.round((mousePos.x - startMousePos.x) + startComboOffset.x);
						ClientPrefs.data.comboOffset[addNum + 1] = -Math.round((mousePos.y - startMousePos.y) - startComboOffset.y);
						repositionCombo();
					}
				}
			}

			if (controls.RESET #if FEATURE_MOBILE_CONTROLS || touchPad.buttonC.justPressed #end)
			{
				for (i in 0...ClientPrefs.data.comboOffset.length)
				{
					ClientPrefs.data.comboOffset[i] = 0;
				}
				repositionCombo();
			}
		}
		else
		{
			if (controls.UI_LEFT_P)
			{
				barPercent = Math.max(delayMin, Math.min(ClientPrefs.data.noteOffset - 1, delayMax));
				updateNoteDelay();
			}
			else if (controls.UI_RIGHT_P)
			{
				barPercent = Math.max(delayMin, Math.min(ClientPrefs.data.noteOffset + 1, delayMax));
				updateNoteDelay();
			}

			var mult:Int = 1;
			if (controls.UI_LEFT || controls.UI_RIGHT)
			{
				holdTime += elapsed;
				if (controls.UI_LEFT)
					mult = -1;
			}

			if (controls.UI_LEFT_R || controls.UI_RIGHT_R)
				holdTime = 0;

			if (holdTime > 0.5)
			{
				barPercent += 100 * addNum * elapsed * mult;
				barPercent = Math.max(delayMin, Math.min(barPercent, delayMax));
				updateNoteDelay();
			}

			if (controls.RESET #if FEATURE_MOBILE_CONTROLS || touchPad.buttonC.justPressed #end)
			{
				holdTime = 0;
				barPercent = 0;
				updateNoteDelay();
			}
		}

		if ((!controls.controllerMode && controls.ACCEPT) || (controls.controllerMode && FlxG.gamepads.anyJustPressed(START)))
		{
			onComboMenu = !onComboMenu;
			updateMode();
		}

		if (controls.BACK)
		{
			if (zoomTween != null)
				zoomTween.cancel();
			if (beatTween != null)
				beatTween.cancel();

			persistentUpdate = false;
			MusicBeatState.switchState(new options.OptionsState());
			if (OptionsState.onPlayState)
			{
				if (ClientPrefs.data.pauseMusic != 'None')
				{
					var mus = Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic));
					if (mus != null) FlxG.sound.playMusic(mus);
				}
				else
					FlxG.sound.music.volume = 0;
			}
			else
			{
				var mus2 = Paths.music('freakyMenu');
				if (mus2 != null) FlxG.sound.playMusic(mus2);
			}
			FlxG.mouse.visible = false;
		}

		Conductor.songPosition = FlxG.sound.music.time;
		super.update(elapsed);
	}

	var zoomTween:Null<FlxTween> = null;
	var lastBeatHit:Int = -1;

	override public function beatHit()
	{
		super.beatHit();

		if (lastBeatHit == curBeat)
		{
			return;
		}

		if (curBeat % 2 == 0)
		{
			if (boyfriend != null) boyfriend.dance();
			if (!ClientPrefs.data.lowQuality && gf != null) gf.dance();
		}

		if (curBeat % 4 == 2)
		{
			FlxG.camera.zoom = 1.15;

			if (zoomTween != null)
				zoomTween.cancel();
			zoomTween = FlxTween.tween(FlxG.camera, {zoom: 1}, 1, {
				ease: FlxEase.circOut,
				onComplete: function(twn:FlxTween)
				{
					zoomTween = null;
				}
			});

		if (beatText != null)
		{
			beatText.alpha = 1;
			beatText.y = 320;
			beatText.velocity.y = -150;
		}
		if (beatTween != null)
			beatTween.cancel();
		beatTween = FlxTween.tween(beatText, {alpha: 0}, 1, {
			ease: FlxEase.sineIn,
			onComplete: function(twn:FlxTween)
			{
				beatTween = null;
			}
		});
		}

		lastBeatHit = curBeat;
	}

	function repositionCombo()
	{
		rating.screenCenter();
		rating.x = coolText.x - 40 + ClientPrefs.data.comboOffset[0];
		rating.y -= 60 + ClientPrefs.data.comboOffset[1];

		comboNums.screenCenter();
		comboNums.x = coolText.x - 90 + ClientPrefs.data.comboOffset[2];
		comboNums.y += 80 - ClientPrefs.data.comboOffset[3];
		reloadTexts();
	}

	function createTexts()
	{
		for (i in 0...4)
		{
			var text:FlxText = new FlxText(10, 48 + (i * 30), 0, '', 24);
			text.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.scrollFactor.set();
			text.borderSize = 2;
			dumbTexts.add(text);
			if (camHUD != null) text.cameras = [camHUD];

			if (i > 1)
			{
				text.y += 24;
			}
		}
	}

	function reloadTexts()
	{
		for (i in 0...dumbTexts.length)
		{
			switch (i)
			{
				case 0:
					dumbTexts.members[i].text = 'Rating Offset:';
				case 1:
					dumbTexts.members[i].text = '[' + ClientPrefs.data.comboOffset[0] + ', ' + ClientPrefs.data.comboOffset[1] + ']';
				case 2:
					dumbTexts.members[i].text = 'Numbers Offset:';
				case 3:
					dumbTexts.members[i].text = '[' + ClientPrefs.data.comboOffset[2] + ', ' + ClientPrefs.data.comboOffset[3] + ']';
			}
		}
	}

	function updateNoteDelay()
	{
		ClientPrefs.data.noteOffset = Math.round(barPercent);
		timeTxt.text = 'Current offset: ' + Math.floor(barPercent) + ' ms';
	}

	function updateMode()
	{
		rating.visible = onComboMenu;
		comboNums.visible = onComboMenu;
		dumbTexts.visible = onComboMenu;

		if (timeBar != null) timeBar.visible = !onComboMenu;
		timeTxt.visible = !onComboMenu;
		if (beatText != null) beatText.visible = !onComboMenu;

		if (controllerPointer != null) controllerPointer.visible = false;
		FlxG.mouse.visible = false;
		if (onComboMenu)
		{
			FlxG.mouse.visible = !controls.controllerMode;
			if (controllerPointer != null) controllerPointer.visible = controls.controllerMode;
		}

		var str:String;
		var str2:String;
		if (onComboMenu)
			str = 'Combo Offset';
		else
			str = 'Note/Beat Delay';

		if (controls.mobileC)
		{
			str2 = '(Press A to Switch)';
		}
		else
		{
			if (!controls.controllerMode)
				str2 = '(Press Accept to Switch)';
			else
				str2 = '(Press Start to Switch)';
		}

		changeModeText.text = '< ${str.toUpperCase()} ${str2.toUpperCase()} >';
	}

	override function destroy()
	{
		startMousePos.put();
		startComboOffset.put();
		super.destroy();
	}
}
