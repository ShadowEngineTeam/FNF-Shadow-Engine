package states;

import backend.InputFormatter;
import backend.WeekData;
import backend.Highscore;
import backend.Song;
import objects.HealthIcon;
import objects.MusicPlayer;
import substates.GameplayChangersSubstate;
import substates.ResetScoreSubState;
import flixel.math.FlxMath;

class FreeplayState extends MusicBeatState
{
	public static var vocals:FlxSound = null;
	static inline final _drawDistance:Int = 4;
	static var curSelected:Int = 0;

	//double-edged sword litteraly
	//if you make curDifficulty:Diff then if you change diff that doesnt go in order like ["normal", "erect", "nightmare"]
	//then there will be bug and only EASY, NORMAL, HARD will be instead of NORMAL, ERECT, NIGHTMARE
	//BUT
	//if you save old change diff logic
	//if (curDifficulty < 0)
	//	curDifficulty = Difficulty.list.length - 1;
	//if (curDifficulty >= Difficulty.list.length)
	//	curDifficulty = 0;
	//then you'll have error 'Cannot compare backend.Diff and String'
	//isnt that funny?)
	static var curDifficulty:Int = -1;
	var grpSongs:FlxTypedGroup<Alphabet>;
	var selector:FlxText;
	var scoreText:FlxText;
	var diffText:FlxText;
	var bottomText:FlxText;
	var missingText:FlxText;
	var bg:FlxSprite;
	var scoreBG:FlxSprite;
	var missingTextBG:FlxSprite;
	var bottomBG:FlxSprite;
	var colorTween:FlxTween;
	var player:MusicPlayer;
	var songs:Array<SongMetadata> = [];
	var iconArray:Array<HealthIcon> = [];
	var _lastVisibles:Array<Int> = [];
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	var intendedColor:Int;
	var instPlaying:Int = -1;
	var lerpRating:Float = 0;
	var intendedRating:Float = 0;
	var lerpSelected:Float = 0;
	var holdTime:Float = 0;
	var curPlaying:Bool = false;
	var bottomString:String;

	override function create():Void
	{
		Paths.clearStoredMemory();

		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if FEATURE_DISCORD_RPC
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		for (i in 0...WeekData.weeksList.length)
		{
			if (weekIsLocked(WeekData.weeksList[i]))
				continue;

			final leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			WeekData.setDirectoryFromWeek(leWeek);

			for (song in leWeek.songs)
			{
				final colors:Array<Int> = song[2]?.length == 3 ? song[2] : [146, 113, 253];
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}

		Mods.loadTopMod();

		add(bg = new FlxSprite(Paths.image('menuDesat')));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.screenCenter();

		add(grpSongs = new FlxTypedGroup<Alphabet>());

		for (i in 0...songs.length)
		{
			final songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
			songText.targetY = i;
			grpSongs.add(songText);

			songText.scaleX = Math.min(1, 980 / songText.width);
			songText.snapToPosition();

			Mods.currentModDirectory = songs[i].folder;

			final icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			songText.visible = songText.active = songText.isMenuItem = false;
			icon.visible = icon.active = false;

			iconArray.push(icon);
			add(icon);
		}

		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		add(scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000));
		scoreBG.alpha = 0.6;

		add(diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24));
		diffText.font = scoreText.font;

		add(scoreText);

		add(missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK));
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;

		add(missingText = new FlxText(50, 0, FlxG.width - 100, '', 24));
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;

		if (curSelected >= songs.length)
			curSelected = 0;

		bg.color = songs[curSelected].color;
		intendedColor = bg.color;
		lerpSelected = curSelected;

		add(bottomBG = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000));
		bottomBG.alpha = 0.6;

		bottomString = Funkin.controls.mobileC ? 'Press ${Funkin.controls.controllerMode ? InputFormatter.getGamepadName(START).toUpperCase() : 'X'} to listen to the Song / Press ${Funkin.controls.controllerMode ? InputFormatter.getGamepadName(LEFT_STICK_CLICK).toUpperCase() : 'C'} to open the Gameplay Changers Menu / Press ${Funkin.controls.controllerMode ? InputFormatter.getGamepadName(BACK).toUpperCase() : 'Y'} to Reset your Score and Accuracy.' : 'Press ${Funkin.controls.controllerMode ? InputFormatter.getGamepadName(START).toUpperCase() : 'SPACE'} to listen to the Song / Press ${Funkin.controls.controllerMode ? InputFormatter.getGamepadName(LEFT_STICK_CLICK).toUpperCase() : 'CTRL'} to open the Gameplay Changers Menu / Press ${Funkin.controls.controllerMode ? InputFormatter.getGamepadName(BACK).toUpperCase() : 'R'} to Reset your Score and Accuracy.';

		add(bottomText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width, bottomString, 16));
		bottomText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		bottomText.scrollFactor.set();

		add(player = new MusicPlayer(this));

		changeSelection();
		updateTexts();

		#if FEATURE_MOBILE_CONTROLS
		addTouchPad("LEFT_FULL", "A_B_C_X_Y_Z");
		#end

		super.create();
		Paths.clearUnusedMemory();
	}

	override function closeSubState():Void
	{
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();

		#if FEATURE_MOBILE_CONTROLS
		removeTouchPad();
		addTouchPad("LEFT_FULL", "A_B_C_X_Y_Z");
		#end
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int):Void
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));

	function weekIsLocked(name:String):Bool
	{
		final leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return !leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore));
	}

	override function update(elapsed:Float):Void
	{
		if (FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
		lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if (ratingSplit.length < 2) // No decimals, add an empty space
			ratingSplit.push('');

		while (ratingSplit[1].length < 2) // Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';

		var shiftMult:Int = 1;
		if ((FlxG.keys.pressed.SHIFT #if FEATURE_MOBILE_CONTROLS || touchPad.buttonZ.pressed #end) && !player.playingMusic)
			shiftMult = 3;

		if (!player.playingMusic)
		{
			scoreText.text = 'PERSONAL BEST: ' + FlxStringUtil.formatMoney(lerpScore, false) + ' (' + ratingSplit.join('.') + '%)';
			positionHighscore();

			if (songs.length > 1)
			{
				if (FlxG.keys.justPressed.HOME)
				{
					curSelected = 0;
					changeSelection();
					holdTime = 0;
				}
				else if (FlxG.keys.justPressed.END)
				{
					curSelected = songs.length - 1;
					changeSelection();
					holdTime = 0;
				}

				if (Funkin.controls.UI_UP_P || Funkin.controls.UI_DOWN_P)
				{
					changeSelection(Funkin.controls.UI_UP_P ? -shiftMult : shiftMult);
					holdTime = 0;
				}

				if (Funkin.controls.UI_DOWN || Funkin.controls.UI_UP)
				{
					final checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					final checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						changeSelection((checkNewHold - checkLastHold) * (Funkin.controls.UI_UP ? -shiftMult : shiftMult));
				}

				if (FlxG.mouse.deltaWheel.y != 0)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					changeSelection(-shiftMult * Math.round(FlxG.mouse.deltaWheel.y), false);
				}
			}

			if (Funkin.controls.UI_LEFT_P || Funkin.controls.UI_RIGHT_P)
				changeDiff(Funkin.controls.UI_LEFT_P ? -1 : 1);
		}

		if (Funkin.controls.BACK)
		{
			if (player.playingMusic)
			{
				FlxG.sound.music.stop();
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				instPlaying = -1;

				player.playingMusic = false;
				player.switchPlayMusic();

				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
				FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);
			}
			else
			{
				persistentUpdate = false;
				colorTween?.cancel();

				FlxG.sound.play(Paths.sound('cancelMenu'));
				Funkin.switchState(MainMenuState);
			}
		}

		if ((FlxG.keys.justPressed.CONTROL #if FEATURE_MOBILE_CONTROLS || touchPad.buttonC.justPressed #end || FlxG.gamepads.anyJustPressed(LEFT_STICK_CLICK)) && !player.playingMusic)
		{
			persistentUpdate = false;
			switchSubState(GameplayChangersSubstate);
			#if FEATURE_MOBILE_CONTROLS
			removeTouchPad();
			#end
		}
		else if (FlxG.keys.justPressed.SPACE #if FEATURE_MOBILE_CONTROLS || touchPad.buttonX.justPressed #end || FlxG.gamepads.anyJustPressed(START))
		{
			if (instPlaying != curSelected && !player.playingMusic)
			{
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;

				Mods.currentModDirectory = songs[curSelected].folder;
				try
				{
					var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
					PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
					/*if (PlayState.SONG.needsVoices)
					{
						vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
						FlxG.sound.list.add(vocals);
						vocals.persist = true;
						vocals.looped = true;
					}
					else if (vocals != null)
					{
						vocals.stop();
						vocals.destroy();
						vocals = null;
					}*/

					FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song, Difficulty.getSongPrefix(curDifficulty, false)), 0.8);
					/*if (vocals != null) // Sync vocals to Inst
					{
						vocals.play();
						vocals.volume = 0.8;
					}*/
					instPlaying = curSelected;

					player.playingMusic = true;
					player.curTime = 0;
					player.switchPlayMusic();
				}
				catch (e:Dynamic)
				{
					trace('ERROR! $e');

					missingText.text = 'ERROR WHILE LOADING CHART:\n${e.toString()}';
					missingText.screenCenter(Y);
					missingText.visible = missingTextBG.visible = true;

					FlxG.sound.play(Paths.sound('cancelMenu'));
					updateTexts(elapsed);
					super.update(elapsed);
					return;
				}
			}
			else if (instPlaying == curSelected && player.playingMusic)
				player.pauseOrResume(player.paused);
		}
		else if (Funkin.controls.ACCEPT && !player.playingMusic)
		{
			persistentUpdate = false;

			final songPath:String = Paths.formatToSongPath(songs[curSelected].songName);
			final json:String = Highscore.formatSong(songPath, curDifficulty);

			try
			{
				PlayState.SONG = Song.loadFromJson(json, songPath);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;
				trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
				colorTween?.cancel();
			}
			catch (e:Dynamic)
			{
				trace('ERROR! $e');
				missingText.text = 'ERROR WHILE LOADING CHART:\n${e.toString()}';
				missingText.screenCenter(Y);
				missingText.visible = missingTextBG.visible = true;

				FlxG.sound.play(Paths.sound('cancelMenu'));
				updateTexts(elapsed);
				super.update(elapsed);
				return;
			}

			LoadingState.prepareToSong();
			LoadingState.loadAndSwitchState(PlayState);
			// FlxG.sound.music.volume = 0;
			destroyFreeplayVocals();

			#if (FEATURE_MODS && FEATURE_DISCORD_RPC)
			DiscordClient.loadModRPC();
			#end
		}
		else if ((Funkin.controls.RESET #if FEATURE_MOBILE_CONTROLS || touchPad.buttonY.justPressed #end) && !player.playingMusic)
		{
			persistentUpdate = false;
			switchSubState(ResetScoreSubState, [songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter]);

			#if FEATURE_MOBILE_CONTROLS
			removeTouchPad();
			#end

			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		updateTexts(elapsed);
		super.update(elapsed);
	}

	public static function destroyFreeplayVocals():Void
	{
		if (vocals != null)
		{
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}

	function changeDiff(change:Int = 0):Void
	{
		if (player.playingMusic) return;

		//readin week list if theres normal
		//then we take index of normal, otherwise any first diff
		//same for story menu
		if (curDifficulty == -1)
		{
			final normalIndex:Int = Difficulty.list.indexOf(NORMAL);
			curDifficulty = normalIndex != -1 ? normalIndex : 0;
		}
		else
			curDifficulty = (curDifficulty + change + Difficulty.list.length) % Difficulty.list.length;

		callOnScripts('onChangeDifficulty');

		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);

		final diffStr:String = Difficulty.getByIndex(curDifficulty);
		diffText.text = Difficulty.list.length > 1 ? '< ${diffStr.toUpperCase()} >' : diffStr.toUpperCase();

		positionHighscore();
		missingText.visible = missingTextBG.visible = false;
	}

	function changeSelection(change:Int = 0, playSound:Bool = true):Void
	{
		if (player.playingMusic)
			return;

		if (playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected = (curSelected + change + songs.length) % songs.length;

		callOnScripts('onChangeSelection');

		final newColor:Int = songs[curSelected].color;
		if (newColor != intendedColor)
		{
			colorTween?.cancel();

			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: (twn:FlxTween) -> colorTween = null
			});
		}

		for (i in 0...iconArray.length)
			iconArray[i].alpha = i == curSelected ? 1 : 0.6;

		for (item in grpSongs.members)
			item.alpha = item.targetY == curSelected ? 1 : 0.6;

		Mods.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;
		Difficulty.loadFromWeek();

		changeDiff();
	}

	function positionHighscore():Void
	{
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}

	public function updateTexts(elapsed:Float = 0):Void
	{
		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));

		for (i in _lastVisibles)
		{
			grpSongs.members[i].visible = grpSongs.members[i].active = false;
			iconArray[i].visible = iconArray[i].active = false;
		}

		_lastVisibles = [];

		final min:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected - _drawDistance)));
		final max:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected + _drawDistance)));

		for (i in min...max)
		{
			final item:Alphabet = grpSongs.members[i];
			item.visible = item.active = true;
			item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
			item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;

			final icon:HealthIcon = iconArray[i];
			icon.visible = icon.active = true;
			_lastVisibles.push(i);
		}
	}

	override function destroy():Void
	{
		super.destroy();

		FlxG.autoPause = ClientPrefs.data.autoPause;

		if (!FlxG.sound.music.playing)
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Mods.currentModDirectory ?? '';
	}
}
