package states.editors;

import flixel.graphics.FlxGraphic;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import flixel.FlxCamera;
import objects.Character;
import objects.HealthIcon;
import objects.Bar;

@:bitmap("assets/images/debugger/cursorCross.png")
private class GraphicCursorCross extends openfl.display.BitmapData {}

class CharacterEditorState extends MusicBeatState
{
	var character:Character;
	var ghost:FlxSprite;
	var animateGhost:FlxAnimate;
	var animateGhostImage:String;
	var cameraFollowPointer:FlxSprite;
	var isAnimateSprite:Bool = false;

	var silhouettes:FlxSpriteGroup;
	var dadPosition = FlxPoint.weak();
	var bfPosition = FlxPoint.weak();

	var helpBg:FlxSprite;
	var helpTexts:FlxSpriteGroup;
	var cameraZoomText:FlxText;
	var frameAdvanceText:FlxText;

	var healthBar:Bar;
	var healthIcon:HealthIcon;

	var copiedOffset:Array<Float> = [0, 0];
	var _char:String = null;
	var _goToPlayState:Bool = true;

	var anims = null;
	var animsTxtGroup:FlxTypedGroup<FlxText>;
	var curAnim = 0;

	private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;
	private var camOther:FlxCamera;

	var UI_box:ShadowTabMenu;
	var UI_characterbox:ShadowTabMenu;
	var UI_animListPanel:ShadowPanel;
	var UI_animList:ShadowList;
	var UI_healthPanel:ShadowPanel;
	var UI_healthColorRect:FlxSprite;
	var UI_help:ShadowPanel;
	var UI_helpOverlay:FlxSprite;

	public function new(char:String = null, goToPlayState:Bool = true)
	{
		this._char = char;
		this._goToPlayState = goToPlayState;
		if (this._char == null)
			this._char = Character.DEFAULT_CHARACTER;

		super();
	}

	override function create()
	{
		Paths.clearStoredMemory();

		FlxG.sound.music.stop();
		camEditor = initPsychCamera();

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;
		camOther.visible = false;
		FlxG.cameras.add(camOther, false);

		loadBG();

		animsTxtGroup = new FlxTypedGroup<FlxText>();
		silhouettes = new FlxSpriteGroup();
		add(silhouettes);

		var dad:FlxSprite = new FlxSprite(dadPosition.x, dadPosition.y).loadGraphic(Paths.image('editors/silhouetteDad'));
		dad.antialiasing = ClientPrefs.data.antialiasing;
		dad.active = false;
		dad.offset.set(-4, 1);
		silhouettes.add(dad);

		var boyfriend:FlxSprite = new FlxSprite(bfPosition.x, bfPosition.y + 350).loadGraphic(Paths.image('editors/silhouetteBF'));
		boyfriend.antialiasing = ClientPrefs.data.antialiasing;
		boyfriend.active = false;
		boyfriend.offset.set(-6, 2);
		silhouettes.add(boyfriend);

		silhouettes.alpha = 0.25;

		ghost = new FlxSprite();
		ghost.visible = false;
		ghost.alpha = ghostAlpha;
		add(ghost);

		addCharacter();

		cameraFollowPointer = new FlxSprite().loadGraphic(FlxGraphic.fromClass(GraphicCursorCross));
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();
		add(cameraFollowPointer);

		healthBar = new Bar(30, FlxG.height - 75);
		healthBar.scrollFactor.set();
		add(healthBar);
		healthBar.cameras = [camHUD];

		healthIcon = new HealthIcon(character.healthIcon);
		healthIcon.y = FlxG.height - 150;
		add(healthIcon);
		healthIcon.cameras = [camHUD];

		animsTxtGroup.cameras = [camHUD];
		add(animsTxtGroup);

		var tipText:FlxText = new FlxText(FlxG.width - 300, FlxG.height - 24, 300, 'Press ${(controls.mobileC) ? 'F' : 'F1'} for Help', 16);
		tipText.cameras = [camHUD];
		tipText.setFormat(null, 16, FlxColor.WHITE, RIGHT, OUTLINE_FAST, FlxColor.BLACK);
		tipText.borderColor = FlxColor.BLACK;
		tipText.scrollFactor.set();
		tipText.borderSize = 1;
		tipText.active = false;
		add(tipText);

		cameraZoomText = new FlxText(0, 50, 200, 'Zoom: 1x');
		cameraZoomText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		cameraZoomText.scrollFactor.set();
		cameraZoomText.borderSize = 1;
		cameraZoomText.screenCenter(X);
		cameraZoomText.cameras = [camHUD];
		add(cameraZoomText);

		frameAdvanceText = new FlxText(0, 75, 350, '');
		frameAdvanceText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		frameAdvanceText.scrollFactor.set();
		frameAdvanceText.borderSize = 1;
		frameAdvanceText.screenCenter(X);
		frameAdvanceText.cameras = [camHUD];
		add(frameAdvanceText);

		// addHelpScreen(); // Replaced with makeHelpUI()
		FlxG.mouse.visible = true;
		FlxG.camera.zoom = 1;

		makeUIMenu();

		updatePointerPos();
		updateHealthBar();
		character.finishAnimation();

		addTouchPad("LEFT_FULL", "CHARACTER_EDITOR");
		addTouchPadCamera(false);

		Paths.clearUnusedMemory();

		super.create();
	}

	function addHelpScreen()
	{
		var str:String;
		if (controls.mobileC)
		{
			str = "CAMERA
			\nX/Y - Camera Zoom In/Out
			\nZ - Reset Camera Zoom
			\n
			\nCHARACTER
			\nA - Reset Current Offset
			\nV/D - Previous/Next Animation
			\nArrow Buttons - Move Offset
			\n
			\nOTHER
			\nS - Toggle Silhouettes
			\nHold C - Move Offsets 10x faster and Camera 4x faster";
		}
		else
		{
			str = "CAMERA
			\nE/Q - Camera Zoom In/Out
			\nJ/K/L/I - Move Camera
			\nR - Reset Camera Zoom
			\n
			\nCHARACTER
			\nCtrl + R - Reset Current Offset
			\nCtrl + C - Copy Current Offset
			\nCtrl + V - Paste Copied Offset on Current Animation
			\nCtrl + Z - Undo Last Paste or Reset
			\nW/S - Previous/Next Animation
			\nSpace - Replay Animation
			\nArrow Keys/Mouse & Right Click - Move Offset
			\nA/D - Frame Advance (Back/Forward)
			\n
			\nOTHER
			\nF12 - Toggle Silhouettes
			\nHold Shift - Move Offsets 10x faster and Camera 4x faster
			\nHold Control - Move camera 4x slower";
		}

		helpBg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		helpBg.scale.set(FlxG.width, FlxG.height);
		helpBg.updateHitbox();
		helpBg.alpha = 0.6;
		helpBg.cameras = [camHUD];
		helpBg.active = helpBg.visible = false;
		add(helpBg);

		var arr = str.split('\n');
		helpTexts = new FlxSpriteGroup();
		helpTexts.cameras = [camHUD];
		for (i in 0...arr.length)
		{
			if (arr[i].length < 2)
				continue;

			var helpText:FlxText = new FlxText(0, 0, 600, arr[i], 16);
			helpText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
			helpText.borderColor = FlxColor.BLACK;
			helpText.scrollFactor.set();
			helpText.borderSize = 1;
			helpText.screenCenter();
			add(helpText);
			helpText.y += ((i - arr.length / 2) * 16);
			helpText.active = false;
			helpTexts.add(helpText);
		}
		helpTexts.active = helpTexts.visible = false;
		add(helpTexts);
	}

	function addCharacter(reload:Bool = false)
	{
		var pos:Int = -1;
		if (character != null)
		{
			pos = members.indexOf(character);
			remove(character);
			character.destroy();
		}

		var isPlayer = (reload ? character.isPlayer : !predictCharacterIsNotPlayer(_char));
		character = new Character(0, 0, _char, isPlayer);
		if (!reload && character.editorIsPlayer != null && isPlayer != character.editorIsPlayer)
		{
			character.isPlayer = !character.isPlayer;
			character.flipX = (character.originalFlipX != character.isPlayer);
			if (check_player != null)
				check_player.checked = character.isPlayer;
		}
		character.debugMode = true;

		if (pos > -1)
			insert(pos, character);
		else
			add(character);
		updateCharacterPositions();
		reloadAnimList();
		if (healthBar != null && healthIcon != null)
			updateHealthBar();
	}

	function makeUIMenu()
	{
		var mainTabs = [{name: 'Ghost', label: 'Ghost'}, {name: 'Settings', label: 'Settings'}];
		var margin = ShadowStyle.SPACING_LG;
		var topWidth = 300;
		var topHeight = 145;
		var bottomWidth = 420;
		var bottomHeight = 365;
		var topX = FlxG.width - topWidth - margin;
		var topY = margin;
		var bottomX = FlxG.width - bottomWidth - margin;
		var bottomY = topY + topHeight + margin;

		UI_box = new ShadowTabMenu(topX, topY, mainTabs, topWidth, topHeight);
		UI_box.cameras = [camHUD];
		UI_box.scrollFactor.set();

		var characterTabs = [
			{name: 'Character', label: 'Character'},
			{name: 'Animations', label: 'Animations'},
		];
		UI_characterbox = new ShadowTabMenu(bottomX, bottomY, characterTabs, bottomWidth, bottomHeight);
		UI_characterbox.cameras = [camHUD];
		UI_characterbox.scrollFactor.set();
		add(UI_characterbox);
		add(UI_box);

		addGhostUI();
		addSettingsUI();
		addAnimationsUI();
		addCharacterUI();

		makeAnimListUI();
		makeHealthIconUI();
		makeHelpUI();

		reloadAnimList();

		UI_box.selectedTab = 1;
		UI_characterbox.selectedTab = 0;
	}

	var ghostAlpha:Float = 0.6;

	function addGhostUI()
	{
		var tab_group = UI_box.getTabGroup("Ghost");
		if (tab_group == null)
			return;

		var pad = ShadowStyle.SPACING_MD;
		var rowGap = ShadowStyle.SPACING_SM;
		var labelOffset = ShadowStyle.FONT_SIZE_SM + 4;
		var rowStep = labelOffset + ShadowStyle.HEIGHT_BUTTON + rowGap;
		var checkboxOffset = Std.int((ShadowStyle.HEIGHT_BUTTON - ShadowStyle.HEIGHT_CHECKBOX) / 2);
		var buttonWidth = 110;
		var stepperWidth = 100;
		var row0 = pad;
		var row1 = row0 + rowStep;

		var makeGhostButton = new ShadowButton(pad, row0, "Make Ghost", function()
		{
			var anim = anims[curAnim];
			if (!character.isAnimationNull())
			{
				var myAnim = anims[curAnim];
				if (!character.isAnimateAtlas)
				{
					ghost.loadGraphic(character.graphic);
					ghost.frames.frames = character.frames.frames;
					ghost.animation.copyFrom(character.animation);
					ghost.animation.play(character.animation.curAnim.name, true, false, character.animation.curAnim.curFrame);
					ghost.animation.pause();
				}
				else
					if (myAnim != null) // This is VERY unoptimized and bad, I hope to find a better replacement that loads only a specific frame as bitmap in the future.
				{
					if (animateGhost == null) // If I created the animateGhost on create() and you didn't load an atlas, it would crash the game on destroy, so we create it here
					{
						animateGhost = new FlxAnimate(ghost.x, ghost.y);
						insert(members.indexOf(ghost), animateGhost);
						animateGhost.active = false;
					}

					if (animateGhost == null || animateGhostImage != character.imageFile)
						animateGhost.frames = Paths.getTextureAtlas(character.imageFile);

					if (myAnim.indices != null && myAnim.indices.length > 0)
						animateGhost.anim.addBySymbolIndices('anim', myAnim.name, myAnim.indices, 0, false);
					else
						animateGhost.anim.addBySymbol('anim', myAnim.name, 0, false);

					animateGhost.anim.play('anim', true, false, character.anim.curAnim.curFrame);
					animateGhost.anim.pause();

					animateGhostImage = character.imageFile;
				}

				var spr:FlxSprite = character.spriteType == TEXTURE_ATLAS ? animateGhost : ghost;
				if (spr != null)
				{
					spr.setPosition(character.x, character.y);
					spr.antialiasing = character.antialiasing;
					spr.flipX = character.flipX;
					spr.alpha = ghostAlpha;

					spr.scale.set(character.scale.x, character.scale.y);
					spr.updateHitbox();

					spr.offset.set(character.offset.x, character.offset.y);
					spr.visible = true;

					var otherSpr:FlxSprite = (spr == animateGhost) ? ghost : animateGhost;
					if (otherSpr != null)
						otherSpr.visible = false;
				}
				/*hideGhostButton.active = true;
					hideGhostButton.alpha = 1; */
				trace('created ghost image');
			}
		}, buttonWidth);

		var highlightGhost = new ShadowCheckbox(makeGhostButton.x + buttonWidth + ShadowStyle.SPACING_MD, makeGhostButton.y + checkboxOffset,
			"Highlight Ghost", false, function(checked:Bool)
		{
			var value = checked ? 125 : 0;
			ghost.colorTransform.redOffset = value;
			ghost.colorTransform.greenOffset = value;
			ghost.colorTransform.blueOffset = value;
			if (animateGhost != null)
			{
				animateGhost.colorTransform.redOffset = value;
				animateGhost.colorTransform.greenOffset = value;
				animateGhost.colorTransform.blueOffset = value;
			}
		});

		var ghostAlphaLabel = new ShadowLabel(pad, row1, "Opacity:", ShadowStyle.FONT_SIZE_SM, ShadowStyle.TEXT_SECONDARY);
		var ghostAlphaStepper = new ShadowStepper(pad, row1 + labelOffset, 0.05, ghostAlpha, 0, 1, 2, function(value:Float)
		{
			ghostAlpha = value;
			ghost.alpha = ghostAlpha;
			if (animateGhost != null)
				animateGhost.alpha = ghostAlpha;
		}, stepperWidth);

		tab_group.add(makeGhostButton);
		tab_group.add(highlightGhost);
		tab_group.add(ghostAlphaLabel);
		tab_group.add(ghostAlphaStepper);
	}

	var check_player:ShadowCheckbox;
	var charDropDown:ShadowDropdown;

	function addSettingsUI()
	{
		var tab_group = UI_box.getTabGroup("Settings");
		if (tab_group == null)
			return;

		var pad = ShadowStyle.SPACING_MD;
		var rowGap = ShadowStyle.SPACING_SM;
		var labelOffset = ShadowStyle.FONT_SIZE_SM + 4;
		var rowStep = labelOffset + ShadowStyle.HEIGHT_INPUT + rowGap;
		var panelWidth = Std.int(UI_box.width);
		var colGap = ShadowStyle.SPACING_MD;
		var rightColWidth = 120;
		var rightX = panelWidth - pad - rightColWidth;
		var leftX = pad;
		var leftW = rightX - colGap - leftX;
		var row0 = pad;
		var row1 = row0 + rowStep;
		var controlY0 = row0 + labelOffset;
		var controlY1 = row1 + labelOffset;
		var checkboxOffset = Std.int((ShadowStyle.HEIGHT_INPUT - ShadowStyle.HEIGHT_CHECKBOX) / 2);

		check_player = new ShadowCheckbox(leftX, controlY1 + checkboxOffset, "Playable Character", character.isPlayer, function(checked:Bool)
		{
			character.isPlayer = checked;
			character.flipX = (character.originalFlipX != character.isPlayer);
			updateCharacterPositions();
			updatePointerPos(false);
		});

		var reloadCharacter = new ShadowButton(rightX, controlY0, "Reload Char", function()
		{
			addCharacter(true);
			updatePointerPos();
			reloadCharacterOptions();
			reloadCharacterDropDown();
		}, rightColWidth);

		var templateCharacter = new ShadowButton(rightX, controlY1, "Load Template", function()
		{
			final _template:CharacterFile = {
				animations: [
					newAnim('idle', 'BF idle dance'),
					newAnim('singLEFT', 'BF NOTE LEFT0'),
					newAnim('singDOWN', 'BF NOTE DOWN0'),
					newAnim('singUP', 'BF NOTE UP0'),
					newAnim('singRIGHT', 'BF NOTE RIGHT0')
				],
				no_antialiasing: false,
				flip_x: false,
				healthicon: 'face',
				image: 'characters/BOYFRIEND',
				sing_duration: 4,
				scale: 1,
				healthbar_colors: [161, 161, 161],
				camera_position: [0, 0],
				position: [0, 0],
				vocals_file: null
			};

			character.loadCharacterFile(_template);
			character.color = FlxColor.WHITE;
			character.alpha = 1;
			reloadAnimList();
			reloadCharacterOptions();
			updateCharacterPositions();
			updatePointerPos();
			reloadCharacterDropDown();
			updateHealthBar();
		}, rightColWidth);

		charDropDown = new ShadowDropdown(leftX, controlY0, [''], function(index:Int)
		{
			var intended = characterList[index];
			if (intended == null || intended.length < 1)
				return;

			var characterPath:String = 'characters/$intended.json';
			var path:String = Paths.getPath(characterPath, TEXT, null, true);
			if (FileSystem.exists(path))
			{
				_char = intended;
				addCharacter();
				reloadCharacterOptions();
				reloadCharacterDropDown();
				updatePointerPos();
			}
			else
			{
				reloadCharacterDropDown();
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
		}, leftW);
		reloadCharacterDropDown();

		tab_group.add(new ShadowLabel(leftX, row0, "Character:", ShadowStyle.FONT_SIZE_SM, ShadowStyle.TEXT_SECONDARY));
		tab_group.add(check_player);
		tab_group.add(reloadCharacter);
		tab_group.add(templateCharacter);
		tab_group.add(charDropDown);
	}

	var animationDropDown:ShadowDropdown;
	var animationInputText:ShadowTextInput;
	var animationFrameLabelCheckBox:ShadowCheckbox;
	var animationNameInputText:ShadowTextInput;
	var animationIndicesInputText:ShadowTextInput;
	var animationFramerate:ShadowStepper;
	var animationLoopCheckBox:ShadowCheckbox;
	var animationInfoLabel:ShadowLabel;

	function addAnimationsUI()
	{
		var tab_group = UI_characterbox.getTabGroup("Animations");
		if (tab_group == null)
			return;

		var pad = ShadowStyle.SPACING_MD;
		var rowGap = ShadowStyle.SPACING_SM;
		var labelOffset = ShadowStyle.FONT_SIZE_SM + 4;
		var rowStep = labelOffset + ShadowStyle.HEIGHT_INPUT + rowGap;
		var panelWidth = Std.int(UI_characterbox.width);
		var colGap = ShadowStyle.SPACING_MD;
		var rightColWidth = 180;
		var rightX = panelWidth - pad - rightColWidth;
		var leftX = pad;
		var leftW = rightX - colGap - leftX;
		var fullW = panelWidth - pad * 2;
		var row0 = pad;
		var row1 = row0 + rowStep;
		var row2 = row1 + rowStep;
		var row3 = row2 + rowStep;
		var row4 = row3 + rowStep;
		var row5 = row4 + rowStep;
		var row6 = row5 + rowStep;
		var controlY0 = row0 + labelOffset;
		var controlY1 = row1 + labelOffset;
		var controlY2 = row2 + labelOffset;
		var controlY3 = row3 + labelOffset;
		var controlY4 = row4 + labelOffset;
		var controlY5 = row5 + labelOffset;
		var checkboxOffset = Std.int((ShadowStyle.HEIGHT_INPUT - ShadowStyle.HEIGHT_CHECKBOX) / 2);
		var buttonWidth = 120;
		var buttonGap = ShadowStyle.SPACING_SM;

		animationInputText = new ShadowTextInput(leftX, controlY1, leftW, "");
		animationFrameLabelCheckBox = new ShadowCheckbox(rightX, controlY0 + checkboxOffset, "Frame Label (Textuer Atlas)");
		animationNameInputText = new ShadowTextInput(leftX, controlY2, leftW, "");
		animationIndicesInputText = new ShadowTextInput(leftX, controlY3, fullW, "");
		animationFramerate = new ShadowStepper(leftX, controlY4, 1, 24, 0, 240, 0, null, 70);
		animationLoopCheckBox = new ShadowCheckbox(rightX, controlY4 + checkboxOffset, "Should it Loop?");

		animationDropDown = new ShadowDropdown(leftX, controlY0, [''], function(index:Int)
		{
			var anim:AnimArray = character.animationsArray[index];
			if (anim == null)
				return;
			animationInputText.text = anim.anim;
			animationFrameLabelCheckBox.checked = anim.isFrameLabel;
			animationNameInputText.text = anim.name;
			animationLoopCheckBox.checked = anim.loop;
			animationFramerate.value = anim.fps;

			var indicesStr:String = anim.indices.toString();
			animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
		}, leftW);

		var addUpdateButton = new ShadowButton(leftX, controlY5, "Add/Update", function()
		{
			var indices:Array<Int> = [];
			var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');
			if (indicesStr.length > 1)
			{
				for (i in 0...indicesStr.length)
				{
					var index:Int = Std.parseInt(indicesStr[i]);
					if (indicesStr[i] != null && indicesStr[i] != '' && !Math.isNaN(index) && index > -1)
					{
						indices.push(index);
					}
				}
			}

			var lastAnim:String = (character.animationsArray[curAnim] != null) ? character.animationsArray[curAnim].anim : '';
			var lastOffsets:Array<Int> = [0, 0];
			for (anim in character.animationsArray)
				if (animationInputText.text == anim.anim)
				{
					lastOffsets = anim.offsets;
					if (character.animOffsets.exists(animationInputText.text))
						character.animation.remove(animationInputText.text);
					character.animationsArray.remove(anim);
				}

			var addedAnim:AnimArray = newAnim(animationInputText.text, animationNameInputText.text);
			addedAnim.fps = Math.round(animationFramerate.value);
			addedAnim.isFrameLabel = animationFrameLabelCheckBox.checked;
			addedAnim.loop = animationLoopCheckBox.checked;
			addedAnim.indices = indices;
			addedAnim.offsets = lastOffsets;
			addAnimation(addedAnim.anim, addedAnim.name, addedAnim.fps, addedAnim.loop, addedAnim.indices, addedAnim.isFrameLabel);
			character.animationsArray.push(addedAnim);

			reloadAnimList();
			@:arrayAccess curAnim = Std.int(Math.max(0, character.animationsArray.indexOf(addedAnim)));
			character.playAnim(addedAnim.anim, true);
			trace('Added/Updated animation: ' + animationInputText.text);
		}, buttonWidth);

		var removeButton = new ShadowButton(leftX + buttonWidth + buttonGap, controlY5, "Remove", function()
		{
			for (anim in character.animationsArray)
				if (animationInputText.text == anim.anim)
				{
					var resetAnim:Bool = false;
					if (anim.anim == character.getAnimationName())
						resetAnim = true;
					if (character.animOffsets.exists(anim.anim))
					{
						character.animation.remove(anim.anim);
						character.animOffsets.remove(anim.anim);
						character.animationsArray.remove(anim);
					}

					if (resetAnim && character.animationsArray.length > 0)
					{
						curAnim = FlxMath.wrap(curAnim, 0, anims.length - 1);
						character.playAnim(anims[curAnim].anim, true);
						updateTextColors();
					}
					reloadAnimList();
					trace('Removed animation: ' + animationInputText.text);
					break;
				}
		}, buttonWidth);
		reloadAnimList();

		tab_group.add(new ShadowLabel(leftX, row0, "Animations:", ShadowStyle.FONT_SIZE_SM, ShadowStyle.TEXT_SECONDARY));
		tab_group.add(new ShadowLabel(leftX, row1, "Animation name:", ShadowStyle.FONT_SIZE_SM, ShadowStyle.TEXT_SECONDARY));
		tab_group.add(new ShadowLabel(leftX, row2, "Animation Symbol Name/Tag:", ShadowStyle.FONT_SIZE_SM, ShadowStyle.TEXT_SECONDARY));
		tab_group.add(new ShadowLabel(leftX, row3, "ADVANCED - Animation Indices:", ShadowStyle.FONT_SIZE_SM, ShadowStyle.TEXT_SECONDARY));
		tab_group.add(new ShadowLabel(leftX, row4, "Framerate:", ShadowStyle.FONT_SIZE_SM, ShadowStyle.TEXT_SECONDARY));

		tab_group.add(animationInputText);
		tab_group.add(animationFrameLabelCheckBox);
		tab_group.add(animationNameInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationFramerate);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(animationDropDown);
		animationInfoLabel = new ShadowLabel(leftX, row6, "Animation: None | Offset: (0, 0)", ShadowStyle.FONT_SIZE_SM, ShadowStyle.TEXT_SECONDARY, fullW);
		tab_group.add(animationInfoLabel);
		updateAnimationInfo();
	}

	var imageInputText:ShadowTextInput;
	var healthIconInputText:ShadowTextInput;
	var vocalsInputText:ShadowTextInput;

	var singDurationStepper:ShadowStepper;
	var scaleStepper:ShadowStepper;
	var positionXStepper:ShadowStepper;
	var positionYStepper:ShadowStepper;
	var positionCameraXStepper:ShadowStepper;
	var positionCameraYStepper:ShadowStepper;

	var flipXCheckBox:ShadowCheckbox;
	var noAntialiasingCheckBox:ShadowCheckbox;

	var healthColorStepperR:ShadowStepper;
	var healthColorStepperG:ShadowStepper;
	var healthColorStepperB:ShadowStepper;

	function addCharacterUI()
	{
		var tab_group = UI_characterbox.getTabGroup("Character");
		if (tab_group == null)
			return;

		var pad = ShadowStyle.SPACING_MD;
		var rowGap = ShadowStyle.SPACING_SM;
		var labelOffset = ShadowStyle.FONT_SIZE_SM + 4;
		var rowStep = labelOffset + ShadowStyle.HEIGHT_INPUT + rowGap;
		var panelWidth = Std.int(UI_characterbox.width);
		var colGap = ShadowStyle.SPACING_MD;
		var rightColWidth = 140;
		var rightX = panelWidth - pad - rightColWidth;
		var leftX = pad;
		var leftW = rightX - colGap - leftX;
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
		var controlY5 = row5 + labelOffset;
		var checkboxOffset = Std.int((ShadowStyle.HEIGHT_INPUT - ShadowStyle.HEIGHT_CHECKBOX) / 2);
		var leftStepperWidth = 70;
		var rightStepperGap = ShadowStyle.SPACING_SM;
		var rightStepperWidth = Std.int((rightColWidth - rightStepperGap) / 2);
		var colorStepperWidth = 55;
		var colorGap = ShadowStyle.SPACING_SM;

		imageInputText = new ShadowTextInput(leftX, controlY0, leftW, character.imageFile, function(text:String)
		{
			character.imageFile = text;
		});
		var reloadImage = new ShadowButton(rightX, controlY0, "Reload Image", function()
		{
			var lastAnim = character.getAnimationName();
			character.imageFile = imageInputText.text;
			reloadCharacterImage();
			if (!character.isAnimationNull())
			{
				character.playAnim(lastAnim, true);
			}
		}, rightColWidth);

		var decideIconColor = new ShadowButton(rightX, controlY1, "Get Icon Color", function()
		{
			var coolColor:FlxColor = FlxColor.fromInt(CoolUtil.dominantColor(healthIcon));
			character.healthColorArray[0] = coolColor.red;
			character.healthColorArray[1] = coolColor.green;
			character.healthColorArray[2] = coolColor.blue;
			updateHealthBar();
		}, rightColWidth);

		healthIconInputText = new ShadowTextInput(leftX, controlY1, leftW, healthIcon.getCharacter(), function(text:String)
		{
			var lastIcon = healthIcon.getCharacter();
			healthIcon.changeIcon(text);
			character.healthIcon = text;
			if (lastIcon != healthIcon.getCharacter())
				updatePresence();
		});

		vocalsInputText = new ShadowTextInput(leftX, controlY2, leftW, character.vocalsFile != null ? character.vocalsFile : '', function(text:String)
		{
			character.vocalsFile = text;
		});

		singDurationStepper = new ShadowStepper(leftX, controlY3, 0.1, 4, 0, 999, 1, function(value:Float)
		{
			character.singDuration = value;
		}, leftStepperWidth);

		scaleStepper = new ShadowStepper(leftX, controlY4, 0.1, 1, 0.05, 10, 1, function(value:Float)
		{
			reloadCharacterImage();
			character.jsonScale = value;
			character.scale.set(character.jsonScale, character.jsonScale);
			character.updateHitbox();
			updatePointerPos(false);
		}, leftStepperWidth);

		flipXCheckBox = new ShadowCheckbox(leftX + leftStepperWidth + colGap, controlY3 + checkboxOffset, "Flip X", character.originalFlipX,
			function(checked:Bool)
			{
				character.originalFlipX = checked;
				character.flipX = (character.originalFlipX != character.isPlayer);
			});

		noAntialiasingCheckBox = new ShadowCheckbox(leftX + leftStepperWidth + colGap, controlY4 + checkboxOffset, "No Antialiasing",
			character.noAntialiasing, function(checked:Bool)
		{
			character.antialiasing = !checked && ClientPrefs.data.antialiasing;
			character.noAntialiasing = checked;
		});

		positionXStepper = new ShadowStepper(rightX, controlY3, 10, character.positionArray[0], -9000, 9000, 0, function(value:Float)
		{
			character.positionArray[0] = value;
			updateCharacterPositions();
		}, rightStepperWidth);
		positionYStepper = new ShadowStepper(rightX + rightStepperWidth + rightStepperGap, controlY3, 10, character.positionArray[1], -9000, 9000, 0,
			function(value:Float)
			{
				character.positionArray[1] = value;
				updateCharacterPositions();
			}, rightStepperWidth);

		positionCameraXStepper = new ShadowStepper(rightX, controlY4, 10, character.cameraPosition[0], -9000, 9000, 0, function(value:Float)
		{
			character.cameraPosition[0] = value;
			updatePointerPos();
		}, rightStepperWidth);
		positionCameraYStepper = new ShadowStepper(rightX + rightStepperWidth + rightStepperGap, controlY4, 10, character.cameraPosition[1], -9000, 9000, 0,
			function(value:Float)
			{
				character.cameraPosition[1] = value;
				updatePointerPos();
			}, rightStepperWidth);

		var saveCharacterButton = new ShadowButton(rightX, controlY5, "Save Character", function()
		{
			saveCharacter();
		}, rightColWidth);

		healthColorStepperR = new ShadowStepper(leftX, controlY5, 20, character.healthColorArray[0], 0, 255, 0, function(value:Float)
		{
			character.healthColorArray[0] = Math.round(value);
			updateHealthBar();
		}, colorStepperWidth);
		healthColorStepperG = new ShadowStepper(leftX + colorStepperWidth + colorGap, controlY5, 20, character.healthColorArray[1], 0, 255, 0,
			function(value:Float)
			{
				character.healthColorArray[1] = Math.round(value);
				updateHealthBar();
			}, colorStepperWidth);
		healthColorStepperB = new ShadowStepper(leftX + (colorStepperWidth + colorGap) * 2, controlY5, 20, character.healthColorArray[2], 0, 255, 0,
			function(value:Float)
			{
				character.healthColorArray[2] = Math.round(value);
				updateHealthBar();
			}, colorStepperWidth);

		tab_group.add(new ShadowLabel(leftX, row0, "Image file name:", ShadowStyle.FONT_SIZE_SM, ShadowStyle.TEXT_SECONDARY));
		tab_group.add(new ShadowLabel(leftX, row1, "Health icon name:", ShadowStyle.FONT_SIZE_SM, ShadowStyle.TEXT_SECONDARY));
		tab_group.add(new ShadowLabel(leftX, row2, "Vocals File Postfix:", ShadowStyle.FONT_SIZE_SM, ShadowStyle.TEXT_SECONDARY));
		tab_group.add(new ShadowLabel(leftX, row3, "Sing Animation length:", ShadowStyle.FONT_SIZE_SM, ShadowStyle.TEXT_SECONDARY));
		tab_group.add(new ShadowLabel(leftX, row4, "Scale:", ShadowStyle.FONT_SIZE_SM, ShadowStyle.TEXT_SECONDARY));
		tab_group.add(new ShadowLabel(rightX, row3, "Character X/Y:", ShadowStyle.FONT_SIZE_SM, ShadowStyle.TEXT_SECONDARY));
		tab_group.add(new ShadowLabel(rightX, row4, "Camera X/Y:", ShadowStyle.FONT_SIZE_SM, ShadowStyle.TEXT_SECONDARY));
		tab_group.add(new ShadowLabel(leftX, row5, "Health bar R/G/B:", ShadowStyle.FONT_SIZE_SM, ShadowStyle.TEXT_SECONDARY));
		tab_group.add(imageInputText);
		tab_group.add(reloadImage);
		tab_group.add(decideIconColor);
		tab_group.add(healthIconInputText);
		tab_group.add(vocalsInputText);
		tab_group.add(singDurationStepper);
		tab_group.add(scaleStepper);
		tab_group.add(flipXCheckBox);
		tab_group.add(noAntialiasingCheckBox);
		tab_group.add(positionXStepper);
		tab_group.add(positionYStepper);
		tab_group.add(positionCameraXStepper);
		tab_group.add(positionCameraYStepper);
		tab_group.add(healthColorStepperR);
		tab_group.add(healthColorStepperG);
		tab_group.add(healthColorStepperB);
		tab_group.add(saveCharacterButton);
	}

	function makeAnimListUI()
	{
		var margin = ShadowStyle.SPACING_LG;
		var panelWidth = 280;
		var panelHeight = 450;
		var panelX = margin;
		var panelY = margin;

		UI_animListPanel = new ShadowPanel(panelX, panelY, panelWidth, panelHeight);
		UI_animListPanel.cameras = [camHUD];
		UI_animListPanel.scrollFactor.set();
		add(UI_animListPanel);

		var titleLabel = new ShadowLabel(ShadowStyle.SPACING_MD, ShadowStyle.SPACING_MD, "Animation List", ShadowStyle.FONT_SIZE_LG, ShadowStyle.TEXT_PRIMARY);
		UI_animListPanel.add(titleLabel);

		var listX = ShadowStyle.SPACING_MD;
		var listY = ShadowStyle.SPACING_MD + 30;
		var listWidth = panelWidth - (ShadowStyle.SPACING_MD * 2);
		var listHeight = panelHeight - listY - ShadowStyle.SPACING_MD;

		UI_animList = new ShadowList(listX, listY, listWidth, listHeight, []);
		UI_animList.callback = function(index:Int)
		{
			if (index >= 0 && index < anims.length)
			{
				curAnim = index;
				character.playAnim(anims[curAnim].anim, true);
				updateAnimationInfo();
			}
		};
		UI_animListPanel.add(UI_animList);
	}

	function makeHealthIconUI()
	{
		var margin = ShadowStyle.SPACING_LG;
		var panelWidth = 280;
		var panelHeight = 120;
		var panelX = margin;
		var panelY = margin + 450 + ShadowStyle.SPACING_MD;

		UI_healthPanel = new ShadowPanel(panelX, panelY, panelWidth, panelHeight);
		UI_healthPanel.cameras = [camHUD];
		UI_healthPanel.scrollFactor.set();
		add(UI_healthPanel);

		var titleLabel = new ShadowLabel(ShadowStyle.SPACING_MD, ShadowStyle.SPACING_MD, "Character Icon", ShadowStyle.FONT_SIZE_LG, ShadowStyle.TEXT_PRIMARY);
		UI_healthPanel.add(titleLabel);

		if (healthIcon != null)
		{
			remove(healthIcon);
			healthIcon.setPosition(-10, 5);
			healthIcon.scale.set(0.7, 0.7);
			UI_healthPanel.add(healthIcon);
		}

		var offsetWX = 30;

		var colorX = ShadowStyle.SPACING_MD + 90 + offsetWX;
		var colorY = ShadowStyle.SPACING_MD + 40;
		var colorWidth = 170 - offsetWX;
		var colorHeight = 50;

		UI_healthColorRect = new FlxSprite(colorX - 5, colorY);
		UI_healthColorRect.makeGraphic(colorWidth, colorHeight, FlxColor.WHITE);
		UI_healthPanel.add(UI_healthColorRect);

		var colorLabel = new ShadowLabel(colorX - 5, colorY - 18, "Health Bar Color", ShadowStyle.FONT_SIZE_SM, ShadowStyle.TEXT_SECONDARY);
		UI_healthPanel.add(colorLabel);

		if (healthBar != null)
		{
			healthBar.visible = false;
		}
	}

	function makeHelpUI()
	{
		UI_helpOverlay = new FlxSprite();
		UI_helpOverlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		UI_helpOverlay.alpha = 0.3;
		UI_helpOverlay.cameras = [camOther];
		UI_helpOverlay.scrollFactor.set();
		UI_helpOverlay.visible = false;
		add(UI_helpOverlay);

		var panelWidth = 600;
		var panelHeight = 400;
		var panelX = (FlxG.width - panelWidth) / 2;
		var panelY = (FlxG.height - panelHeight) / 2;

		UI_help = new ShadowPanel(panelX, panelY, panelWidth, panelHeight);
		UI_help.cameras = [camOther];
		UI_help.scrollFactor.set();
		UI_help.visible = false;
		UI_help.active = false;
		add(UI_help);

		var pad = ShadowStyle.SPACING_LG;

		var titleLabel = new ShadowLabel(pad, pad, "Controls Help", ShadowStyle.FONT_SIZE_LG, ShadowStyle.TEXT_PRIMARY);
		UI_help.add(titleLabel);

		var str:String;
		if (controls.mobileC)
		{
			str = "CAMERA\nX/Y - Camera Zoom In/Out\nZ - Reset Camera Zoom\n\nCHARACTER\nA - Reset Current Offset\nV/D - Previous/Next Animation\nArrow Buttons - Move Offset\n\nOTHER\nS - Toggle Silhouettes\nHold C - Move Offsets 10x faster and Camera 4x faster";
		}
		else
		{
			str = "CAMERA\nE/Q - Camera Zoom In/Out\nJ/K/L/I - Move Camera\nR - Reset Camera Zoom\n\nCHARACTER\nCtrl + R - Reset Current Offset\nCtrl + C - Copy Current Offset\nCtrl + V - Paste Copied Offset on Current Animation\nCtrl + Z - Undo Last Paste or Reset\nW/S - Previous/Next Animation\nSpace - Replay Animation\nArrow Keys/Mouse & Right Click - Move Offset\nA/D - Frame Advance (Back/Forward)\n\nOTHER\nF12 - Toggle Silhouettes\nHold Shift - Move Offsets 10x faster and Camera 4x faster\nHold Control - Move camera 4x slower";
		}

		var helpText = new ShadowLabel(pad, pad + 30, str, ShadowStyle.FONT_SIZE_MD, ShadowStyle.TEXT_PRIMARY, panelWidth - (pad * 2));
		UI_help.add(helpText);

		var closeText = new ShadowLabel(pad, panelHeight - pad - 20, "Press ESC or F1 to close", ShadowStyle.FONT_SIZE_SM, ShadowStyle.TEXT_SECONDARY);
		UI_help.add(closeText);
	}

	function reloadCharacterImage()
	{
		var lastAnim:String = character.getAnimationName();
		var anims:Array<AnimArray> = character.animationsArray.copy();

		character.isAnimateAtlas = false;
		character.color = FlxColor.WHITE;
		character.alpha = 1;
		if (Paths.fileExists('images/' + character.imageFile + '/Animation.json', TEXT))
		{
			character.frames = Paths.getTextureAtlas(character.imageFile);
			character.isAnimateAtlas = true;
		}
		else if (Paths.fileExists('images/' + character.imageFile + '.txt', TEXT))
			character.frames = Paths.getPackerAtlas(character.imageFile);
		else if (Paths.fileExists('images/' + character.imageFile + '.json', TEXT))
			character.frames = Paths.getAsepriteAtlas(character.imageFile);
		else
			character.frames = Paths.getSparrowAtlas(character.imageFile);

		for (anim in anims)
		{
			var animAnim:String = '' + anim.anim;
			var animName:String = '' + anim.name;
			var animFps:Int = anim.fps;
			var animLoop:Bool = !!anim.loop; // Bruh
			var animIndices:Array<Int> = anim.indices;
			addAnimation(animAnim, animName, animFps, animLoop, animIndices, anim.isFrameLabel);
		}

		if (anims.length > 0)
		{
			if (lastAnim != '')
				character.playAnim(lastAnim, true);
			else
				character.dance();
		}
	}

	function reloadCharacterOptions()
	{
		if (UI_characterbox == null)
			return;

		check_player.checked = character.isPlayer;
		imageInputText.text = character.imageFile;
		healthIconInputText.text = character.healthIcon;
		vocalsInputText.text = character.vocalsFile != null ? character.vocalsFile : '';
		singDurationStepper.value = character.singDuration;
		scaleStepper.value = character.jsonScale;
		flipXCheckBox.checked = character.originalFlipX;
		noAntialiasingCheckBox.checked = character.noAntialiasing;
		positionXStepper.value = character.positionArray[0];
		positionYStepper.value = character.positionArray[1];
		positionCameraXStepper.value = character.cameraPosition[0];
		positionCameraYStepper.value = character.cameraPosition[1];
		reloadAnimationDropDown();
		updateHealthBar();
	}

	var holdingArrowsTime:Float = 0;
	var holdingArrowsElapsed:Float = 0;
	var holdingFrameTime:Float = 0;
	var holdingFrameElapsed:Float = 0;
	var undoOffsets:Array<Float> = null;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (UI_help != null && UI_help.visible)
		{
			ClientPrefs.toggleVolumeKeys(false);
			FlxG.mouse.enabled = false;

			if ((FlxG.keys.justPressed.F1 || touchPad.buttonF.justPressed) || FlxG.keys.justPressed.ESCAPE)
			{
				if (controls.mobileC)
				{
					touchPad.forEachAlive(function(button:TouchButton)
					{
						if (button.tag != 'F')
							button.visible = !button.visible;
					});
				}
				UI_help.visible = false;
				UI_help.active = false;
				UI_helpOverlay.visible = false;
				camOther.visible = false;
				FlxG.mouse.enabled = true;

				if (helpBg != null)
					helpBg.visible = false;
				if (helpTexts != null)
					helpTexts.visible = false;
			}
			return;
		}

		if ((animationInputText != null && animationInputText.hasFocus())
			|| (animationNameInputText != null && animationNameInputText.hasFocus())
			|| (animationIndicesInputText != null && animationIndicesInputText.hasFocus())
			|| (imageInputText != null && imageInputText.hasFocus())
			|| (healthIconInputText != null && healthIconInputText.hasFocus())
			|| (vocalsInputText != null && vocalsInputText.hasFocus()))
		{
			ClientPrefs.toggleVolumeKeys(false);
			return;
		}
		ClientPrefs.toggleVolumeKeys(true);

		var shiftMult:Float = 1;
		var ctrlMult:Float = 1;
		var shiftMultBig:Float = 1;
		if (FlxG.keys.pressed.SHIFT || touchPad.buttonC.pressed)
		{
			shiftMult = 4;
			shiftMultBig = 10;
		}
		if (FlxG.keys.pressed.CONTROL /*|| touchPad.buttonC.pressed*/)
			ctrlMult = 0.25;

		// CAMERA CONTROLS
		if (FlxG.keys.pressed.J)
			FlxG.camera.scroll.x -= elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.K)
			FlxG.camera.scroll.y += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.L)
			FlxG.camera.scroll.x += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.I)
			FlxG.camera.scroll.y -= elapsed * 500 * shiftMult * ctrlMult;

		var lastZoom = FlxG.camera.zoom;
		if (FlxG.keys.justPressed.R && !FlxG.keys.pressed.CONTROL || touchPad.buttonZ.justPressed)
			FlxG.camera.zoom = 1;
		else if ((FlxG.keys.pressed.E || touchPad.buttonX.pressed) && FlxG.camera.zoom < 3)
		{
			FlxG.camera.zoom += elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
			if (FlxG.camera.zoom > 3)
				FlxG.camera.zoom = 3;
		}
		else if ((FlxG.keys.pressed.Q || touchPad.buttonY.pressed) && FlxG.camera.zoom > 0.1)
		{
			FlxG.camera.zoom -= elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
			if (FlxG.camera.zoom < 0.1)
				FlxG.camera.zoom = 0.1;
		}

		if (lastZoom != FlxG.camera.zoom)
			cameraZoomText.text = 'Zoom:' + " " + FlxMath.roundDecimal(FlxG.camera.zoom, 2) + 'x';

		// CHARACTER CONTROLS
		var changedAnim:Bool = false;
		if (anims.length > 1)
		{
			if ((FlxG.keys.justPressed.W || touchPad.buttonV.justPressed) && (changedAnim = true))
				curAnim--;
			else if ((FlxG.keys.justPressed.S || touchPad.buttonD.justPressed) && (changedAnim = true))
				curAnim++;

			if (changedAnim)
			{
				undoOffsets = null;
				curAnim = FlxMath.wrap(curAnim, 0, anims.length - 1);
				character.playAnim(anims[curAnim].anim, true);
				updateTextColors();
				updateAnimationInfo();
			}
		}

		var changedOffset = false;
		var moveKeysP;
		var moveKeys;
		if (controls.mobileC)
		{
			moveKeysP = [
				touchPad.buttonLeft.justPressed,
				touchPad.buttonRight.justPressed,
				touchPad.buttonUp.justPressed,
				touchPad.buttonDown.justPressed
			];
			moveKeys = [
				touchPad.buttonLeft.pressed,
				touchPad.buttonRight.pressed,
				touchPad.buttonUp.pressed,
				touchPad.buttonDown.pressed
			];
		}
		else
		{
			moveKeysP = [
				FlxG.keys.justPressed.LEFT,
				FlxG.keys.justPressed.RIGHT,
				FlxG.keys.justPressed.UP,
				FlxG.keys.justPressed.DOWN
			];
			moveKeys = [
				FlxG.keys.pressed.LEFT,
				FlxG.keys.pressed.RIGHT,
				FlxG.keys.pressed.UP,
				FlxG.keys.pressed.DOWN
			];
		}
		if (moveKeysP.contains(true))
		{
			character.offset.x += ((moveKeysP[0] ? 1 : 0) - (moveKeysP[1] ? 1 : 0)) * shiftMultBig;
			character.offset.y += ((moveKeysP[2] ? 1 : 0) - (moveKeysP[3] ? 1 : 0)) * shiftMultBig;
			changedOffset = true;
		}

		if (moveKeys.contains(true))
		{
			holdingArrowsTime += elapsed;
			if (holdingArrowsTime > 0.6)
			{
				holdingArrowsElapsed += elapsed;
				while (holdingArrowsElapsed > (1 / 60))
				{
					character.offset.x += ((moveKeys[0] ? 1 : 0) - (moveKeys[1] ? 1 : 0)) * shiftMultBig;
					character.offset.y += ((moveKeys[2] ? 1 : 0) - (moveKeys[3] ? 1 : 0)) * shiftMultBig;
					holdingArrowsElapsed -= (1 / 60);
					changedOffset = true;
				}
			}
		}
		else
			holdingArrowsTime = 0;

		if (FlxG.mouse.pressedRight && (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0))
		{
			character.offset.x -= FlxG.mouse.deltaScreenX;
			character.offset.y -= FlxG.mouse.deltaScreenY;
			changedOffset = true;
		}

		if (FlxG.keys.pressed.CONTROL)
		{
			if (FlxG.keys.justPressed.C)
			{
				copiedOffset[0] = character.offset.x;
				copiedOffset[1] = character.offset.y;
				changedOffset = true;
			}
			else if (FlxG.keys.justPressed.V)
			{
				undoOffsets = [character.offset.x, character.offset.y];
				character.offset.x = copiedOffset[0];
				character.offset.y = copiedOffset[1];
				changedOffset = true;
			}
			else if (FlxG.keys.justPressed.R)
			{
				undoOffsets = [character.offset.x, character.offset.y];
				character.offset.set(0, 0);
				changedOffset = true;
			}
			else if (FlxG.keys.justPressed.Z && undoOffsets != null)
			{
				character.offset.x = undoOffsets[0];
				character.offset.y = undoOffsets[1];
				changedOffset = true;
			}
		}
		if (touchPad.buttonA.justPressed)
		{
			undoOffsets = [character.offset.x, character.offset.y];
			character.offset.x = copiedOffset[0];
			character.offset.y = copiedOffset[1];
			changedOffset = true;
		}

		var anim = anims[curAnim];
		if (changedOffset && anim != null && anim.offsets != null)
		{
			anim.offsets[0] = Std.int(character.offset.x);
			anim.offsets[1] = Std.int(character.offset.y);

			// Update just this item in the list
			if (UI_animList != null)
			{
				UI_animList.updateItem(curAnim, anim.anim + ": " + anim.offsets);
			}

			character.addOffset(anim.anim, character.offset.x, character.offset.y);
			updateAnimationInfo();
		}

		var txt = 'ERROR: No Animation Found';
		var clr = FlxColor.RED;
		if (!character.isAnimationNull())
		{
			if (FlxG.keys.pressed.A || FlxG.keys.pressed.D)
			{
				holdingFrameTime += elapsed;
				if (holdingFrameTime > 0.5)
					holdingFrameElapsed += elapsed;
			}
			else
				holdingFrameTime = 0;

			if (FlxG.keys.justPressed.SPACE)
				character.playAnim(character.getAnimationName(), true);

			var frames:Int = 0;
			var length:Int = 0;
			frames = character.animation.curAnim.curFrame;
			length = character.animation.curAnim.numFrames;

			if (FlxG.keys.justPressed.A || FlxG.keys.justPressed.D || holdingFrameTime > 0.5)
			{
				var isLeft = false;
				if ((holdingFrameTime > 0.5 && FlxG.keys.pressed.A) || FlxG.keys.justPressed.A)
					isLeft = true;
				character.animPaused = true;

				if (holdingFrameTime <= 0.5 || holdingFrameElapsed > 0.1)
				{
					frames = FlxMath.wrap(frames + Std.int(isLeft ? -shiftMult : shiftMult), 0, length - 1);
					character.animation.curAnim.curFrame = frames;
					holdingFrameElapsed -= 0.1;
				}
			}

			txt = 'Frames: ( $frames / ${length - 1} )';
			// if(character.animation.curAnim.paused) txt += ' - PAUSED';
			clr = FlxColor.WHITE;
		}
		if (txt != frameAdvanceText.text)
			frameAdvanceText.text = txt;
		frameAdvanceText.color = clr;

		// OTHER CONTROLS
		if (FlxG.keys.justPressed.F12 || touchPad.buttonS.justPressed)
			silhouettes.visible = !silhouettes.visible;

		// Open help (closing is handled at the top of update)
		if (FlxG.keys.justPressed.F1 || touchPad.buttonF.justPressed)
		{
			if (controls.mobileC)
			{
				touchPad.forEachAlive(function(button:TouchButton)
				{
					if (button.tag != 'F')
						button.visible = !button.visible;
				});
			}
			UI_help.visible = true;
			UI_help.active = true;
			UI_helpOverlay.visible = true;
			camOther.visible = true;
			FlxG.mouse.enabled = false; // Disable mouse input

			// Hide old help elements
			if (helpBg != null)
				helpBg.visible = false;
			if (helpTexts != null)
				helpTexts.visible = false;
		}
		else if (FlxG.keys.justPressed.ESCAPE || touchPad.buttonB.justPressed)
		{
			FlxG.mouse.visible = false;
			if (!_goToPlayState)
			{
				MusicBeatState.switchState(new states.editors.MasterEditorMenu());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
			else
				MusicBeatState.switchState(new PlayState());
			return;
		}
	}

	final assetFolder = 'week1'; // load from assets/week1/

	inline function loadBG()
	{
		// bg data
		var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
		add(bg);

		var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		add(stageFront);

		dadPosition.set(100, 100);
		bfPosition.set(770, 100);
	}

	inline function updatePointerPos(?snap:Bool = true)
	{
		var offX:Float = 0;
		var offY:Float = 0;
		if (!character.isPlayer)
		{
			offX = character.getMidpoint().x + 150 + character.cameraPosition[0];
			offY = character.getMidpoint().y - 100 + character.cameraPosition[1];
		}
		else
		{
			offX = character.getMidpoint().x - 100 - character.cameraPosition[0];
			offY = character.getMidpoint().y - 100 + character.cameraPosition[1];
		}
		cameraFollowPointer.setPosition(offX, offY);

		if (snap)
		{
			FlxG.camera.scroll.x = cameraFollowPointer.getMidpoint().x - FlxG.width / 2;
			FlxG.camera.scroll.y = cameraFollowPointer.getMidpoint().y - FlxG.height / 2;
		}
	}

	inline function updateHealthBar()
	{
		healthColorStepperR.value = character.healthColorArray[0];
		healthColorStepperG.value = character.healthColorArray[1];
		healthColorStepperB.value = character.healthColorArray[2];

		var healthColor = FlxColor.fromRGB(character.healthColorArray[0], character.healthColorArray[1], character.healthColorArray[2]);
		healthBar.leftBar.color = healthBar.rightBar.color = healthColor;
		healthIcon.changeIcon(character.healthIcon);

		// Update UI health color preview
		if (UI_healthColorRect != null)
		{
			UI_healthColorRect.color = healthColor;
		}

		updatePresence();
	}

	inline function updatePresence()
	{
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Character Editor", "Character: " + _char, healthIcon.getCharacter());
		#end
	}

	inline function reloadAnimList()
	{
		anims = character.animationsArray;
		if (anims.length > 0)
			character.playAnim(anims[0].anim, true);
		curAnim = 0;

		// Update the ShadowList with animation names and offsets
		if (UI_animList != null)
		{
			var animStrings:Array<String> = [];
			for (anim in anims)
				animStrings.push(anim.anim + ": " + anim.offsets);

			UI_animList.setItems(animStrings);
			UI_animList.selectedIndex = curAnim;
		}

		// Hide old animation text group
		for (text in animsTxtGroup)
		{
			text.visible = false;
			text.active = false;
		}

		updateAnimationInfo();
		if (animationDropDown != null)
			reloadAnimationDropDown();
	}

	inline function updateTextColors()
	{
		// Update selected index in ShadowList
		if (UI_animList != null)
		{
			UI_animList.selectedIndex = curAnim;
		}
	}

	inline function updateAnimationInfo()
	{
		if (animationInfoLabel == null)
			return;

		var animName = 'None';
		var offsetX = 0;
		var offsetY = 0;
		if (anims != null && curAnim >= 0 && curAnim < anims.length)
		{
			var currentAnim = anims[curAnim];
			if (currentAnim != null)
			{
				animName = currentAnim.anim;
				if (currentAnim.offsets != null && currentAnim.offsets.length > 1)
				{
					offsetX = Std.int(currentAnim.offsets[0]);
					offsetY = Std.int(currentAnim.offsets[1]);
				}
			}
		}

		var framesInfo = '';
		if (!character.isAnimationNull() && character.animation.curAnim != null)
		{
			var frameCur = character.animation.curAnim.curFrame;
			var totalFrames = character.animation.curAnim.numFrames;
			if (totalFrames > 0)
				framesInfo = ' | Frame: ' + frameCur + ' / ' + (totalFrames - 1);
		}

		animationInfoLabel.text = 'Animation: ' + animName + ' | Offset: (' + offsetX + ', ' + offsetY + ')' + framesInfo;
	}

	inline function updateCharacterPositions()
	{
		if ((character != null && !character.isPlayer) || (character == null && predictCharacterIsNotPlayer(_char)))
			character.setPosition(dadPosition.x, dadPosition.y);
		else
			character.setPosition(bfPosition.x, bfPosition.y);

		character.x += character.positionArray[0];
		character.y += character.positionArray[1];
	}

	inline function predictCharacterIsNotPlayer(name:String)
	{
		return (name != 'bf' && !name.startsWith('bf-') && !name.endsWith('-player') && !name.endsWith('-dead'))
			|| name.endsWith('-opponent')
			|| name.startsWith('gf-')
			|| name.endsWith('-gf')
			|| name == 'gf';
	}

	function addAnimation(anim:String, name:String, fps:Float, loop:Bool, indices:Array<Int>, frameLabel:Bool = false)
	{
		if (!character.isAnimateAtlas)
		{
			if (indices != null && indices.length > 0)
				character.animation.addByIndices(anim, name, indices, "", fps, loop);
			else
				character.animation.addByPrefix(anim, name, fps, loop);
		}
		else
		{
			if (frameLabel)
			{
				if (indices != null && indices.length > 0)
					character.anim.addByFrameLabelIndices(anim, name, indices, fps, loop);
				else
					character.anim.addBySymbol(anim, name, fps, loop);
			}
			else
			{
				if (indices != null && indices.length > 0)
					character.anim.addBySymbolIndices(anim, name, indices, fps, loop);
				else
					character.anim.addBySymbol(anim, name, fps, loop);
			}
		}

		if (!character.animOffsets.exists(anim))
			character.addOffset(anim, 0, 0);
	}

	inline function newAnim(anim:String, name:String):AnimArray
	{
		return {
			offsets: [0, 0],
			loop: false,
			fps: 24,
			anim: anim,
			indices: [],
			name: name
		};
	}

	var characterList:Array<String> = [];

	function reloadCharacterDropDown()
	{
		characterList = Mods.mergeAllTextsNamed('data/characterList.txt', Paths.getSharedPath());
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'characters/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder))
				if (file.toLowerCase().endsWith('.json'))
				{
					var charToCheck:String = file.substr(0, file.length - 5);
					if (!characterList.contains(charToCheck))
						characterList.push(charToCheck);
				}
		if (characterList.length < 1)
			characterList.push('');
		if (charDropDown != null)
		{
			charDropDown.setOptions(characterList);
			var selectedIndex = characterList.indexOf(_char);
			charDropDown.selectedIndex = selectedIndex > -1 ? selectedIndex : 0;
		}
	}

	function reloadAnimationDropDown()
	{
		var animList:Array<String> = [];
		for (anim in anims)
			animList.push(anim.anim);
		if (animList.length < 1)
			animList.push('NO ANIMATIONS'); // Prevents crash

		if (animationDropDown != null)
		{
			animationDropDown.setOptions(animList);
			var selectedIndex = Std.int(Math.max(0, Math.min(animList.length - 1, curAnim)));
			animationDropDown.selectedIndex = selectedIndex;
		}
	}

	// save
	var _file:FileReference;

	function onSaveComplete(_):Void
	{
		if (_file == null)
			return;
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
		if (_file == null)
			return;
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
		if (_file == null)
			return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}

	function saveCharacter()
	{
		if (_file != null)
			return;

		var json:Dynamic = {
			"animations": character.animationsArray,
			"image": character.imageFile,
			"scale": character.jsonScale,
			"sing_duration": character.singDuration,
			"healthicon": character.healthIcon,

			"position": character.positionArray,
			"camera_position": character.cameraPosition,

			"flip_x": character.originalFlipX,
			"no_antialiasing": character.noAntialiasing,
			"healthbar_colors": character.healthColorArray,
			"vocals_file": character.vocalsFile,
			"_editor_isPlayer": character.isPlayer
		};

		var data:String = Json.stringify(json, "\t");

		if (data.length > 0)
		{
			#if mobile
			var fileDialog = new lime.ui.FileDialog();
			fileDialog.onCancel.add(() -> onSaveCancel(null));
			fileDialog.onSave.add((path) -> onSaveComplete(null));
			fileDialog.save(data, null, '$_char' + ".json", null, "*/*");
			#else
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, '$_char.json');
			#end
		}
	}
}
