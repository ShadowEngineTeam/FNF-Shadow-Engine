package states.editors;

import objects.Note;
import objects.StrumNote;
import objects.NoteSplash;

using StringTools;

class NoteSplashDebugState extends MusicBeatState
{
	var config:NoteSplashConfig;
	var forceFrame:Int = -1;
	var curSelected:Int = 0;
	var maxNotes:Int = 4;

	var selection:FlxSprite;
	var notes:FlxTypedGroup<StrumNote>;
	var splashes:FlxTypedGroup<FlxSprite>;

	var imageInputText:ShadowTextInput;
	var nameInputText:ShadowTextInput;
	var stepperMinFps:ShadowStepper;
	var stepperMaxFps:ShadowStepper;

	var offsetsText:FlxText;
	var curFrameText:FlxText;
	var curAnimText:FlxText;
	var savedText:FlxText;
	var selecArr:Array<Float> = null;
	var idk:Bool = (Controls.instance.mobileC) ? true : false; // im lazy to remove and add alot so idk

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	var UI_help:ShadowPanel;
	var UI_helpOverlay:FlxSprite;
	var UI_infoPanel:ShadowPanel;
	var UI_settingsPanel:ShadowPanel;
	var camOther:FlxCamera;

	public static final defaultTexture:String = 'noteSplashes';

	override function create()
	{
		initPsychCamera();
		FlxG.camera.bgColor = FlxColor.fromHSL(0, 0, 0.5);

		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;
		camOther.visible = false;
		FlxG.cameras.add(camOther, false);

		selection = new FlxSprite(0, 270).makeGraphic(150, 150, FlxColor.BLACK);
		selection.alpha = 0.4;
		add(selection);

		notes = new FlxTypedGroup<StrumNote>();
		add(notes);

		splashes = new FlxTypedGroup<FlxSprite>();
		add(splashes);

		for (i in 0...maxNotes)
		{
			var x = i * 220 + 240;
			var y = 290;
			var note:StrumNote = new StrumNote(x, y, i, 0, null);
			note.alpha = 0.75;
			note.playAnim('static');
			notes.add(note);

			var splash:FlxSprite = new FlxSprite(x, y);
			splash.setPosition(splash.x - Note.swagWidth * 0.95, splash.y - Note.swagWidth);
			splash.shader = note.rgbShader.parent.shader;
			splash.antialiasing = ClientPrefs.data.antialiasing;
			splashes.add(splash);
		}

		var settingsPanelW = 400;
		var settingsPanelH = 200;
		UI_settingsPanel = new ShadowPanel(ShadowStyle.SPACING_LG, FlxG.height - settingsPanelH - ShadowStyle.SPACING_LG, settingsPanelW, settingsPanelH);
		UI_settingsPanel.scrollFactor.set();
		add(UI_settingsPanel);

		var innerX = ShadowStyle.SPACING_SM;
		var innerY = ShadowStyle.SPACING_SM;

		var imageName = new ShadowLabel(innerX, innerY, 'Image Name:', ShadowStyle.FONT_SIZE_MD);
		UI_settingsPanel.add(imageName);

		imageInputText = new ShadowTextInput(innerX, innerY + 22, 360, defaultTexture);
		imageInputText.input.callback = function(text:String, action:String)
		{
			if (action == ShadowInputText.ENTER_ACTION)
			{
				imageInputText.setFocus(false);
				textureName = text;
				try
				{
					loadFrames();
				}
				catch (e:Dynamic)
				{
					trace('ERROR! $e');
					textureName = defaultTexture;
					loadFrames();

					missingText.text = 'ERROR WHILE LOADING IMAGE:\n$text';
					missingText.screenCenter(Y);
					missingText.visible = true;
					missingTextBG.visible = true;
					FlxG.sound.play(Paths.sound('cancelMenu'));

					new FlxTimer().start(2.5, function(tmr:FlxTimer)
					{
						missingText.visible = false;
						missingTextBG.visible = false;
					});
				}
			}
			else
			{
				trace('changed image to $text');
			}
		};
		UI_settingsPanel.add(imageInputText);

		var fpsLabel = new ShadowLabel(innerX, innerY + 60, 'Min/Max Framerate:', ShadowStyle.FONT_SIZE_MD);
		UI_settingsPanel.add(fpsLabel);

		stepperMinFps = new ShadowStepper(innerX, innerY + 82, 1, 22, 1, 60, 0);
		stepperMaxFps = new ShadowStepper(innerX + 60, innerY + 82, 1, 26, 1, 60, 0);

		stepperMinFps.callback = function(value:Float)
		{
			if (value > stepperMaxFps.value)
				stepperMaxFps.value = value;
			if (config != null)
				config.minFps = Std.int(value);
		};
		stepperMaxFps.callback = function(value:Float)
		{
			if (value < stepperMinFps.value)
				stepperMinFps.value = value;
			if (config != null)
				config.maxFps = Std.int(value);
		};

		UI_settingsPanel.add(stepperMinFps);
		UI_settingsPanel.add(stepperMaxFps);

		var animName = new ShadowLabel(innerX, innerY + 120, 'Animation Name:', ShadowStyle.FONT_SIZE_MD);
		UI_settingsPanel.add(animName);

		nameInputText = new ShadowTextInput(innerX, innerY + 142, 360, '');
		nameInputText.input.callback = function(text:String, action:String)
		{
			if (action == ShadowInputText.ENTER_ACTION)
				nameInputText.setFocus(false);

			trace('changed anim name to $text');
			if (config != null)
			{
				config.anim = text;
				curAnim = 1;
				reloadAnims();
			}
		};
		UI_settingsPanel.add(nameInputText);

		var infoPanelW = 500;
		var infoPanelH = 90;
		UI_infoPanel = new ShadowPanel((FlxG.width - infoPanelW) / 2, ShadowStyle.SPACING_LG, infoPanelW, infoPanelH);
		UI_infoPanel.scrollFactor.set();
		add(UI_infoPanel);

		curAnimText = new FlxText(ShadowStyle.SPACING_SM, ShadowStyle.SPACING_SM, infoPanelW - ShadowStyle.SPACING_SM * 2, '', 16);
		curAnimText.setFormat(Paths.font(ShadowStyle.FONT_DEFAULT), ShadowStyle.FONT_SIZE_MD, ShadowStyle.TEXT_PRIMARY, CENTER);
		curAnimText.scrollFactor.set();
		UI_infoPanel.add(curAnimText);

		curFrameText = new FlxText(ShadowStyle.SPACING_SM, ShadowStyle.SPACING_SM + 28, infoPanelW - ShadowStyle.SPACING_SM * 2, '', 16);
		curFrameText.setFormat(Paths.font(ShadowStyle.FONT_DEFAULT), ShadowStyle.FONT_SIZE_MD, ShadowStyle.TEXT_SECONDARY, CENTER);
		curFrameText.scrollFactor.set();
		UI_infoPanel.add(curFrameText);

		offsetsText = new FlxText(ShadowStyle.SPACING_SM, ShadowStyle.SPACING_SM + 56, infoPanelW - ShadowStyle.SPACING_SM * 2, '', 16);
		offsetsText.setFormat(Paths.font(ShadowStyle.FONT_DEFAULT), ShadowStyle.FONT_SIZE_MD, ShadowStyle.TEXT_SECONDARY, CENTER);
		offsetsText.scrollFactor.set();
		UI_infoPanel.add(offsetsText);

		var tipText = new FlxText(0, FlxG.height - 30, FlxG.width, "Press F1 for Help", 16);
		tipText.setFormat(null, ShadowStyle.FONT_SIZE_MD, FlxColor.WHITE, CENTER);
		tipText.scrollFactor.set();
		add(tipText);

		savedText = new FlxText(0, 340, FlxG.width, '', 24);
		savedText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		savedText.scrollFactor.set();
		add(savedText);

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);

		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		makeHelpUI();
		loadFrames();
		changeSelection();
		super.create();
		addTouchPad("NOTE_SPLASH_DEBUG", "NOTE_SPLASH_DEBUG");
		FlxG.mouse.visible = true;
	}

	var curAnim:Int = 1;
	var visibleTime:Float = 0;
	var pressEnterToSave:Float = 0;

	override function update(elapsed:Float)
	{
		if (UI_help != null && UI_help.visible)
		{
			ClientPrefs.toggleVolumeKeys(false);
			FlxG.mouse.enabled = false;
			if (FlxG.keys.justPressed.F1 || FlxG.keys.justPressed.ESCAPE)
			{
				UI_help.visible = false;
				UI_helpOverlay.visible = false;
				camOther.visible = false;
				ClientPrefs.toggleVolumeKeys(true);
				FlxG.mouse.enabled = true;
				FlxG.mouse.visible = true;
			}
			super.update(elapsed);
			return;
		}

		if (FlxG.keys.justPressed.F1)
		{
			UI_help.visible = true;
			UI_helpOverlay.visible = true;
			camOther.visible = true;
			ClientPrefs.toggleVolumeKeys(false);
			FlxG.mouse.visible = false;
			return;
		}

		var notTyping:Bool = !nameInputText.hasFocus() && !imageInputText.hasFocus();
		if (controls.BACK && notTyping)
		{
			MusicBeatState.switchState(new MasterEditorMenu());
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			FlxG.mouse.visible = false;
		}
		super.update(elapsed);

		if (!notTyping)
			return;

		if (FlxG.keys.justPressed.A || touchPad.buttonUp.justPressed)
			changeSelection(-1);
		else if (FlxG.keys.justPressed.D || touchPad.buttonDown.justPressed)
			changeSelection(1);

		if (maxAnims < 1)
			return;

		if (selecArr != null)
		{
			var movex = 0;
			var movey = 0;
			if (FlxG.keys.justPressed.LEFT || touchPad.buttonLeft2.justPressed)
				movex = -1;
			else if (FlxG.keys.justPressed.RIGHT || touchPad.buttonRight2.justPressed)
				movex = 1;

			if (FlxG.keys.justPressed.UP || touchPad.buttonUp2.justPressed)
				movey = 1;
			else if (FlxG.keys.justPressed.DOWN || touchPad.buttonDown2.justPressed)
				movey = -1;

			if (FlxG.keys.pressed.SHIFT || touchPad.buttonZ.pressed)
			{
				movex *= 10;
				movey *= 10;
			}

			if (movex != 0 || movey != 0)
			{
				selecArr[0] -= movex;
				selecArr[1] += movey;
				updateOffsetText();
				splashes.members[curSelected].offset.set(10 + selecArr[0], 10 + selecArr[1]);
			}
		}

		if (FlxG.keys.pressed.CONTROL || idk)
		{
			if (FlxG.keys.justPressed.C || touchPad.buttonC.justPressed)
			{
				var arr:Array<Float> = selectedArray();
				if (copiedArray == null)
					copiedArray = [0, 0];
				copiedArray[0] = arr[0];
				copiedArray[1] = arr[1];
			}
			else if ((FlxG.keys.justPressed.V || touchPad.buttonV.justPressed))
			{
				if (copiedArray != null)
				{
					var offs:Array<Float> = selectedArray();
					offs[0] = copiedArray[0];
					offs[1] = copiedArray[1];
					splashes.members[curSelected].offset.set(10 + offs[0], 10 + offs[1]);
					updateOffsetText();
				}
			}
		}

		pressEnterToSave -= elapsed;
		if (visibleTime >= 0)
		{
			visibleTime -= elapsed;
			if (visibleTime <= 0)
				savedText.visible = false;
		}

		if (FlxG.keys.justPressed.ENTER || touchPad.buttonA.justPressed)
		{
			if (controls.mobileC)
			{
				savedText.text = 'Press A again to save.';
			}
			else
			{
				savedText.text = 'Press ENTER again to save.';
			}
			if (pressEnterToSave > 0) // save
			{
				saveFile();
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.4);
				pressEnterToSave = 0;
				visibleTime = 3;
			}
			else
			{
				pressEnterToSave = 0.5;
				visibleTime = 0.5;
			}
			savedText.visible = true;
		}

		// Reset anim & change anim
		if (FlxG.keys.justPressed.SPACE || touchPad.buttonY.justPressed)
			changeAnim();
		else if (FlxG.keys.justPressed.S || touchPad.buttonLeft.justPressed)
			changeAnim(-1);
		else if (FlxG.keys.justPressed.W || touchPad.buttonRight.justPressed)
			changeAnim(1);

		// Force frame
		var updatedFrame:Bool = false;
		if (updatedFrame = FlxG.keys.justPressed.Q || touchPad.buttonX.justPressed)
			forceFrame--;
		else if (updatedFrame = FlxG.keys.justPressed.E || touchPad.buttonE.justPressed)
			forceFrame++;

		if (updatedFrame)
		{
			if (forceFrame < 0)
				forceFrame = 0;
			else if (forceFrame >= maxFrame)
				forceFrame = maxFrame - 1;
			// trace('curFrame: $forceFrame');

			curFrameText.text = 'Force Frame: ${forceFrame + 1} / $maxFrame\n(Press Q/E to change)';
			splashes.forEachAlive(function(spr:FlxSprite)
			{
				spr.animation.curAnim.paused = true;
				spr.animation.curAnim.curFrame = forceFrame;
			});
		}
	}

	function updateOffsetText()
	{
		selecArr = selectedArray();
		offsetsText.text = selecArr.toString();
	}

	var textureName:String = defaultTexture;
	var texturePath:String = '';
	var copiedArray:Array<Float> = null;

	function loadFrames()
	{
		texturePath = 'noteSplashes/' + textureName;
		if (!Paths.fileExists('images/' + texturePath + '.${Paths.IMAGE_EXT}', IMAGE) && !Paths.fileExists('images/' + texturePath + '.${Paths.GPU_IMAGE_EXT}', Paths.getImageAssetType(Paths.GPU_IMAGE_EXT)))
			texturePath = textureName;
		splashes.forEachAlive(function(spr:FlxSprite)
		{
			spr.frames = Paths.getSparrowAtlas(texturePath);
		});

		// Initialize config
		NoteSplash.configs.clear();
		config = NoteSplash.precacheConfig(texturePath);
		if (config == null)
			config = NoteSplash.precacheConfig(NoteSplash.defaultNoteSplash);
		nameInputText.text = config.anim;
		stepperMinFps.value = config.minFps;
		stepperMaxFps.value = config.maxFps;

		reloadAnims();
	}

	function saveFile()
	{
		#if sys
		var maxLen:Int = maxAnims * Note.colArray.length;
		var curLen:Int = config.offsets.length;
		while (curLen > maxLen)
		{
			config.offsets.pop();
			curLen = config.offsets.length;
		}

		var strToSave = config.anim + '\n' + config.minFps + ' ' + config.maxFps;
		for (offGroup in config.offsets)
			strToSave += '\n' + offGroup[0] + ' ' + offGroup[1];

		var pathSplit:Array<String> = (Paths.getPath('images/$texturePath.png', IMAGE, true).split('.png')[0]).split(':');
		var path:String = pathSplit[pathSplit.length - 1].trim() + '.txt';
		var assetsDir:String = '';
		savedText.text = 'Saved to: $path';
		File.saveContent(path, strToSave);

		// trace(strToSave);
		#else
		savedText.text = 'Can\'t save on this platform, too bad.';
		#end
	}

	var maxAnims:Int = 0;

	function reloadAnims()
	{
		var loopContinue:Bool = true;
		splashes.forEachAlive(function(spr:FlxSprite)
		{
			spr.animation.destroyAnimations();
		});

		maxAnims = 0;
		while (loopContinue)
		{
			var animID:Int = maxAnims + 1;
			splashes.forEachAlive(function(spr:FlxSprite)
			{
				for (i in 0...Note.colArray.length)
				{
					var animName = 'note$i-$animID';
					if (!addAnimAndCheck(spr, animName, '${config.anim} ${Note.colArray[i]} $animID', 24, false))
					{
						loopContinue = false;
						return;
					}
					spr.animation.play(animName, true);
				}
			});
			if (loopContinue)
				maxAnims++;
		}
		trace('maxAnims: $maxAnims');
		changeAnim();
	}

	var maxFrame:Int = 0;

	function changeAnim(change:Int = 0)
	{
		maxFrame = 0;
		forceFrame = -1;
		if (maxAnims > 0)
		{
			curAnim += change;
			if (curAnim > maxAnims)
				curAnim = 1;
			else if (curAnim < 1)
				curAnim = maxAnims;
			if (controls.mobileC)
			{
				curAnimText.text = 'Current Animation: $curAnim / $maxAnims\n(Press Top UP/DOWN to change)';
				curFrameText.text = 'Force Frame Disabled\n(Press X/E to change)';
			}
			else
			{
				curAnimText.text = 'Current Animation: $curAnim / $maxAnims\n(Press W/S to change)';
				curFrameText.text = 'Force Frame Disabled\n(Press Q/E to change)';
			}

			for (i in 0...maxNotes)
			{
				var spr:FlxSprite = splashes.members[i];
				spr.animation.play('note$i-$curAnim', true);

				if (maxFrame < spr.animation.curAnim.numFrames)
					maxFrame = spr.animation.curAnim.numFrames;

				spr.animation.curAnim.frameRate = FlxG.random.int(config.minFps, config.maxFps);
				var offs:Array<Float> = selectedArray(i);
				spr.offset.set(10 + offs[0], 10 + offs[1]);
			}
		}
		else
		{
			curAnimText.text = 'INVALID ANIMATION NAME';
			curFrameText.text = '';
		}
		updateOffsetText();
	}

	function changeSelection(change:Int = 0)
	{
		var max:Int = Note.colArray.length;
		curSelected += change;
		if (curSelected < 0)
			curSelected = max - 1;
		else if (curSelected >= max)
			curSelected = 0;

		selection.x = curSelected * 220 + 220;
		updateOffsetText();
	}

	function selectedArray(sel:Int = -1)
	{
		if (sel < 0)
			sel = curSelected;
		var animID:Int = sel + ((curAnim - 1) * Note.colArray.length);
		if (config.offsets[animID] == null)
		{
			while (config.offsets[animID] == null)
				config.offsets.push(config.offsets[FlxMath.wrap(animID, 0, config.offsets.length - 1)].copy());
		}
		return config.offsets[FlxMath.wrap(animID, 0, config.offsets.length - 1)];
	}

	function addAnimAndCheck(spr:FlxSprite, name:String, anim:String, ?framerate:Int = 24, ?loop:Bool = false)
	{
		spr.animation.addByPrefix(name, anim, framerate, loop);
		return spr.animation.getByName(name) != null;
	}

	function makeHelpUI()
	{
		UI_helpOverlay = new FlxSprite();
		UI_helpOverlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		UI_helpOverlay.alpha = 0.6;
		UI_helpOverlay.cameras = [camOther];
		UI_helpOverlay.scrollFactor.set();
		UI_helpOverlay.visible = false;
		add(UI_helpOverlay);

		var panelWidth = 750;
		var panelHeight = 400;
		UI_help = new ShadowPanel((FlxG.width - panelWidth) / 2, (FlxG.height - panelHeight) / 2, panelWidth, panelHeight);
		UI_help.cameras = [camOther];
		UI_help.scrollFactor.set();
		UI_help.visible = false;
		add(UI_help);

		var titleText = new FlxText(0, ShadowStyle.SPACING_LG, panelWidth, "Controls Help", 24);
		titleText.setFormat(Paths.font(ShadowStyle.FONT_DEFAULT), 24, ShadowStyle.TEXT_PRIMARY, CENTER);
		titleText.scrollFactor.set();
		UI_help.add(titleText);

		var helpContent:String;
		if (controls.mobileC)
		{
			helpContent = "Y - Reset/Play animation\n" + "A (twice) - Save to loaded Note Splash PNG's folder\n" + "Top LEFT/RIGHT - Change selected note\n"
				+ "Arrow Keys - Change offset\n" + "W/S - Change animation\n" + "X/E - Change frame\n" + "C/V - Copy & Paste offsets\n"
				+ "BACK - Return to Editor Menu";
		}
		else
		{
			helpContent = "SPACE - Reset/Play animation\n"
				+ "ENTER (twice) - Save to loaded Note Splash PNG's folder\n"
				+ "A/D - Change selected note\n"
				+ "Arrow Keys - Change offset (Hold SHIFT for 10x)\n"
				+ "W/S - Change animation\n"
				+ "Q/E - Change frame\n"
				+ "Ctrl + C/V - Copy & Paste offsets\n"
				+ "ESCAPE - Return to Editor Menu";
		}

		var contentText = new FlxText(ShadowStyle.SPACING_LG, ShadowStyle.SPACING_LG + 50, panelWidth - ShadowStyle.SPACING_LG * 2, helpContent);
		contentText.setFormat(Paths.font(ShadowStyle.FONT_DEFAULT), ShadowStyle.FONT_SIZE_LG, ShadowStyle.TEXT_SECONDARY);
		contentText.scrollFactor.set();
		UI_help.add(contentText);

		var closeText = new FlxText(0, panelHeight - 40, panelWidth, "Press F1 or ESC to close");
		closeText.setFormat(Paths.font(ShadowStyle.FONT_DEFAULT), ShadowStyle.FONT_SIZE_MD, ShadowStyle.TEXT_SECONDARY, CENTER);
		closeText.scrollFactor.set();
		UI_help.add(closeText);
	}

	override function destroy()
	{
		super.destroy();
	}
}
