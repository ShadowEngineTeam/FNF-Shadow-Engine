package states.editors;

import backend.Song;
import backend.Section;
import backend.Rating;
import backend.EaseUtil;
import objects.Note;
import objects.NoteSplash;
import objects.StrumNote;
import objects.SustainSplash;
import flixel.util.FlxSort;
import flixel.animation.FlxAnimationController;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import objects.Character;
import states.PlayState.Combo;
import openfl.utils.Assets as OpenFlAssets;

class EditorPlayState extends MusicBeatSubstate
{
	// Borrowed from original PlayState
	var finishTimer:FlxTimer = null;
	var noteKillOffset:Float = 350;
	var spawnTime:Float = 2000;
	var startingSong:Bool = true;

	var playbackRate:Float = 1;
	var vocals:FlxSound;
	var opponentVocals:FlxSound;
	var inst:FlxSound;

	var notes:FlxTypedGroup<Note>;
	var unspawnNotes:Array<Note> = [];
	var ratingsData:Array<Rating> = Rating.loadDefault();

	var strumLineNotes:FlxTypedGroup<StrumNote>;
	var opponentStrums:FlxTypedGroup<StrumNote>;
	var playerStrums:FlxTypedGroup<StrumNote>;
	var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	var grpHoldSplashes:FlxTypedGroup<SustainSplash>;

	var combo:Int = 0;
	var comboGroup:FlxTypedGroup<Combo>;
	var keysArray:Array<String> = ['note_left', 'note_down', 'note_up', 'note_right'];

	var songHits:Int = 0;
	var songMisses:Int = 0;
	var songLength:Float = 0;
	var songSpeed:Float = 1;

	var totalPlayed:Int = 0;
	var totalNotesHit:Float = 0.0;
	var ratingPercent:Float;
	var ratingFC:String;

	var showCombo:Bool = false;
	var showComboNum:Bool = true;
	var showRating:Bool = true;
	var noteTimingRating:FlxText;
	var noteTimingRatingTween:FlxTween;

	// Originals
	var startOffset:Float = 0;
	var startPos:Float = 0;
	var timerToStart:Float = 0;

	var vocalsOffset:Float = 0;
	var opponentVocalsOffset:Float = 0;

	var scoreTxt:FlxText;
	var dataTxt:FlxText;
	var guitarHeroSustains:Bool = false;

	public function new(playbackRate:Float)
	{
		super();

		/* setting up some important data */
		this.playbackRate = playbackRate;
		this.startPos = Conductor.songPosition;

		Conductor.offset = Song.getInstrumentalOffset(PlayState.SONG);
		vocalsOffset = Song.getVocalOffset(PlayState.SONG, PlayState.SONG.player1);
		opponentVocalsOffset = Song.getVocalOffset(PlayState.SONG, PlayState.SONG.player2);

		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * playbackRate;
		Conductor.songPosition -= startOffset;
		startOffset = Conductor.crochet;
		timerToStart = startOffset;

		/* borrowed from PlayState */
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		cachePopUpScore();
		guitarHeroSustains = ClientPrefs.data.guitarHeroSustains;
		if (ClientPrefs.data.hitsoundVolume > 0)
			Paths.sound('hitsound');

		/* setting up Editor PlayState stuff */
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set();
		bg.color = 0xFF101010;
		bg.alpha = 0.9;
		add(bg);

		add(comboGroup = new FlxTypedGroup<Combo>());

		if (ClientPrefs.data.showNoteTiming)
		{
			add(noteTimingRating = new FlxText(0, 0, 0, "0ms"));
			noteTimingRating.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
			noteTimingRating.scrollFactor.set();
			noteTimingRating.exists = false;
		}

		/**** NOTES ****/
		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		NoteSplash.mainGroup = grpNoteSplashes;
		add(grpNoteSplashes);
		grpHoldSplashes = new FlxTypedGroup<SustainSplash>();
		add(grpHoldSplashes);

		var splash:NoteSplash = new NoteSplash(100, 100);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.000001; // cant make it invisible or it won't allow precaching

		SustainSplash.init(grpHoldSplashes, Conductor.stepCrochet * 1.25 / 1000 / playbackRate, Math.floor(24 / 100 * PlayState.SONG.bpm));

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		generateStaticArrows(0);
		generateStaticArrows(1);
		/***************/

		scoreTxt = new FlxText(10, FlxG.height - 50, FlxG.width - 20, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		add(scoreTxt);

		dataTxt = new FlxText(10, 580, FlxG.width - 20, "Section: 0", 20);
		dataTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		dataTxt.scrollFactor.set();
		dataTxt.borderSize = 1.25;
		add(dataTxt);

		var daButton:String;
		if (Funkin.controls.mobileC)
			daButton = "P";
		else
			daButton = "ESC";

		var tipText:FlxText = new FlxText(10, FlxG.height - 24, 0, 'Press ' + daButton + ' to Go Back to Chart Editor', 16);
		tipText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tipText.borderSize = 2;
		tipText.scrollFactor.set();
		add(tipText);
		FlxG.mouse.visible = false;

		generateSong(PlayState.SONG.song);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		#if FEATURE_DISCORD_RPC
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence('Playtesting on Chart Editor', PlayState.SONG.song, null, true, songLength);
		#end

		#if FEATURE_MOBILE_CONTROLS
		addMobileControls(false);
		mobileControls.instance.visible = true;
		mobileControls.onButtonDown.add(onButtonPress);
		mobileControls.onButtonUp.add(onButtonRelease);
		addTouchPad("NONE", "P");
		addTouchPadCamera(false);
		mobileControls.instance.forEachAlive((button) ->
		{
			if (touchPad.buttonP != null)
				button.deadZones.push(touchPad.buttonP);
		});
		#end

		recalculateRating();
	}

	var started:Bool = false;

	override function update(elapsed:Float)
	{
		if (!started)
		{
			started = true;
		}
		else if (#if FEATURE_MOBILE_CONTROLS touchPad.buttonP.justPressed || #end FlxG.keys.justPressed.ESCAPE #if android || FlxG.android.justPressed.BACK #end)
		{
			#if FEATURE_MOBILE_CONTROLS
			mobileControls.instance.visible = false;
			#end
			endSong();
			super.update(elapsed);
			return;
		}

		if (startingSong)
		{
			timerToStart -= elapsed * 1000;
			Conductor.songPosition = startPos - timerToStart;
			if (timerToStart < 0)
				startSong();
		}
		else
			Conductor.songPosition += elapsed * 1000 * playbackRate;

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime * playbackRate;
			if (songSpeed < 1)
				time /= songSpeed;
			if (unspawnNotes[0].multSpeed < 1)
				time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		keysCheck();
		if (notes.length > 0)
		{
			var fakeCrochet:Float = (60 / PlayState.SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
				if (!daNote.mustPress)
					strumGroup = opponentStrums;

				var strum:StrumNote = strumGroup.members[daNote.noteData];
				daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
					opponentNoteHit(daNote);

				if (daNote.isSustainNote && strum.sustainReduce)
					daNote.clipToStrumNote(strum);

				// Kill extremely late notes and cause misses
				if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
				{
					if (daNote.mustPress && !daNote.ignoreNote && (daNote.tooLate || !daNote.wasGoodHit))
						noteMiss(daNote);

					daNote.active = daNote.visible = false;
					invalidateNote(daNote);
				}
			});
		}

		if (!ClientPrefs.data.hideHud)
		{
			for (s in comboGroup.members)
			{
				s.lifeTime -= elapsed * playbackRate;

				if (s.lifeTime <= 0)
				{
					s.alpha -= elapsed * 6 * playbackRate;

					if (s.alpha <= 0)
						s.kill();
				}
			}
		}

		var time:Float = CoolUtil.floorDecimal((Conductor.songPosition - ClientPrefs.data.noteOffset) / 1000, 1);
		dataTxt.text = 'Time: $time / ${CoolUtil.floorDecimal(songLength / 1000, 1)}
						\nSection: $curSection
						\nBeat: $curBeat
						\nStep: $curStep';
		super.update(elapsed);
	}

	var lastStepHit:Int = -1;

	override function stepHit()
	{
		if (PlayState.SONG.needsVoices && FlxG.sound.music.time >= -ClientPrefs.data.noteOffset)
		{
			final timeSub:Float = Conductor.songPosition - Conductor.offset;
			#if mobile
			final syncTime:Float = 75 * playbackRate;
			#else
			final syncTime:Float = 20 * playbackRate;
			#end

			if (Math.abs(FlxG.sound.music.time - timeSub) > syncTime
				|| PlayState.vocalsDesynced(vocals, timeSub - vocalsOffset, syncTime)
				|| PlayState.vocalsDesynced(opponentVocals, timeSub - opponentVocalsOffset, syncTime))
				resyncVocals();
		}
		super.stepHit();

		if (curStep == lastStepHit)
		{
			return;
		}
		lastStepHit = curStep;
	}

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		if (lastBeatHit >= curBeat)
		{
			// trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}
		notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		super.beatHit();
		lastBeatHit = curBeat;
	}

	override function sectionHit()
	{
		if (PlayState.SONG.notes[curSection] != null)
		{
			if (PlayState.SONG.notes[curSection].changeBPM)
				Conductor.bpm = PlayState.SONG.notes[curSection].bpm;
		}
		super.sectionHit();
	}

	override function destroy()
	{
		NoteSplash.mainGroup = null;

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		FlxG.mouse.visible = true;

		SustainSplash.close();
		Conductor.offset = 0;

		super.destroy();
	}

	function startSong():Void
	{
		startingSong = false;
		@:privateAccess
		FlxG.sound.playMusic(inst._sound, 1, false);
		final musicTime:Float = Math.max(0, startPos - Conductor.offset);
		FlxG.sound.music.time = musicTime;
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.onComplete = finishSong;
		Conductor.songPosition = musicTime + Conductor.offset;
		vocals.volume = 1;
		opponentVocals.volume = 1;
		PlayState.playVocals(vocals, musicTime - vocalsOffset, playbackRate);
		PlayState.playVocals(opponentVocals, musicTime - opponentVocalsOffset, playbackRate);

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length + Conductor.offset;
	}

	// Borrowed from PlayState
	function generateSong(dataPath:String)
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeed = PlayState.SONG.speed;
		var songSpeedType:String = ClientPrefs.getGameplaySetting('scrolltype');
		switch (songSpeedType)
		{
			case "multiplicative":
				songSpeed = PlayState.SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);

		var songData = PlayState.SONG;
		Conductor.bpm = songData.bpm;

		var boyfriendVocals:String = loadCharacterFile(PlayState.SONG.player1).vocals_file;
		var dadVocals:String = loadCharacterFile(PlayState.SONG.player2).vocals_file;

		vocals = new FlxSound();
		opponentVocals = new FlxSound();
		try
		{
			if (songData.needsVoices)
			{
				var playerVocals = Paths.voices(songData.song, (boyfriendVocals == null || boyfriendVocals.length < 1) ? 'Player' : boyfriendVocals + Difficulty.getSongPrefix());
				vocals.loadEmbedded(playerVocals != null ? playerVocals : Paths.voices(songData.song, Difficulty.getSongPrefix(null, false)));

				var oppVocals = Paths.voices(songData.song, (dadVocals == null || dadVocals.length < 1) ? 'Opponent' : dadVocals + Difficulty.getSongPrefix());
				if (oppVocals != null)
					opponentVocals.loadEmbedded(oppVocals);
			}
		}
		catch (e:Dynamic)
		{
		}

		vocals.volume = 0;
		opponentVocals.volume = 0;
		vocals.pitch = playbackRate;
		opponentVocals.pitch = playbackRate;
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(opponentVocals);

		inst = new FlxSound().loadEmbedded(Paths.inst(songData.song, Difficulty.getSongPrefix(null, false)));
		FlxG.sound.list.add(inst);
		FlxG.sound.music.volume = 0;

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				if (daStrumTime < startPos)
					continue;

				var daNoteData:Int = Std.int(songNotes[1] % 4);
				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, this);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				// swagNote.gfNote = (section.gfSection && (songNotes[1]<4));
				swagNote.noteType = songNotes[3];
				if (!Std.isOfType(songNotes[3], String))
					swagNote.noteType = ChartingState.noteTypeList[songNotes[3]]; // Backward compatibility + compatibility with Week 7 charts

				swagNote.scrollFactor.set();

				unspawnNotes.push(swagNote);

				final susLength:Float = swagNote.sustainLength / Conductor.stepCrochet;
				final floorSus:Int = Math.floor(susLength);

				if (floorSus > 0)
				{
					for (susNote in 0...floorSus + 1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote), daNoteData, oldNote, true, this);
						sustainNote.mustPress = gottaHitNote;
						// sustainNote.gfNote = (section.gfSection && (songNotes[1]<4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);
						swagNote.tail.push(sustainNote);

						sustainNote.correctionOffset = swagNote.height / 2;
						if (!PlayState.isPixelStage)
						{
							if (oldNote.isSustainNote)
							{
								oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
								oldNote.scale.y /= playbackRate;
								oldNote.updateHitbox();
							}

							if (ClientPrefs.data.downScroll)
								sustainNote.correctionOffset = 0;
						}
						else if (oldNote.isSustainNote)
						{
							oldNote.scale.y /= playbackRate;
							oldNote.updateHitbox();
						}

						if (sustainNote.mustPress)
							sustainNote.x += FlxG.width / 2; // general offset
						else if (ClientPrefs.data.middleScroll)
						{
							sustainNote.x += 310;
							if (daNoteData > 1) // Up and Right
								sustainNote.x += FlxG.width / 2 + 25;
						}
					}
				}

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if (ClientPrefs.data.middleScroll)
				{
					swagNote.x += 310;
					if (daNoteData > 1) // Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}
			}
		}

		unspawnNotes.sort(PlayState.sortByTime);
	}

	private function generateStaticArrows(player:Int):Void
	{
		var strumLineX:Float = ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X;
		var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1)
			{
				if (!ClientPrefs.data.opponentStrums)
					targetAlpha = 0;
				else if (ClientPrefs.data.middleScroll)
					targetAlpha = 0.35;
			}

			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player, null);
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			babyArrow.alpha = targetAlpha;

			if (player == 1)
				playerStrums.add(babyArrow);
			else
			{
				if (ClientPrefs.data.middleScroll)
				{
					babyArrow.x += 310;
					if (i > 1) // Up and Right
					{
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	public function finishSong():Void
	{
		if (ClientPrefs.data.noteOffset <= 0)
		{
			endSong();
		}
		else
		{
			finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer)
			{
				endSong();
			});
		}
	}

	public function endSong()
	{
		vocals.pause();
		vocals.destroy();
		opponentVocals.pause();
		opponentVocals.destroy();
		if (finishTimer != null)
		{
			finishTimer.cancel();
			finishTimer.destroy();
		}
		close();
	}

	private function cachePopUpScore()
	{
		for (rating in ratingsData)
			Paths.image(rating.image);

		for (i in 0...10)
			Paths.image('num' + i);
	}

	private function popUpScore(note:Note = null):Void
	{
		var noteDiffNoAbs:Float = note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset;
		var noteDiff:Float = Math.abs(noteDiffNoAbs);

		vocals.volume = 1;

		var judgment:String = Rating.judgeNote(noteDiff);
		var score:Int = Rating.scoreNote(noteDiff);

		// tryna do PBOT1 based judgment due to popular demand
		var daRating:Rating = switch (judgment)
		{
			case 'sick':
				ratingsData[0]; // sick
			case 'good':
				ratingsData[1]; // good
			case 'bad':
				ratingsData[2]; // bad
			case 'shit':
				ratingsData[3]; // shit
			default:
				ratingsData[3]; // default to shit
		};

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if (!note.ratingDisabled)
			daRating.hits++;
		note.rating = daRating.name;

		if (daRating.noteSplash && !note.noteSplashData.disabled)
			spawnNoteSplashOnNote(note);

		if (!note.ratingDisabled)
		{
			songHits++;
			totalPlayed++;
			recalculateRating(false);
		}

		if (!ClientPrefs.data.popUpRating)
			return;

		// The same pop-ups as PlayState's, held still while the chart editor's camera scrolls.
		final stageUI:String = PlayState.stageUI;
		final isPixelStage:Bool = PlayState.isPixelStage;
		final uiPrefix:String = stageUI != "normal" ? '${stageUI}UI/' : '';
		final uiSuffix:String = isPixelStage ? '-pixel' : '';
		final antialias:Bool = ClientPrefs.data.antialiasing && (stageUI == "normal" || !isPixelStage);
		final lifetime:Float = Conductor.crochet * 0.001 / playbackRate;
		final placement:Float = FlxG.width * 0.35;
		var yoRating:Float = 0;

		inline function setUp(spr:Combo):Void
		{
			spr.screenCenter();
			spr.alpha = 1;
			spr.velocity.set();
			spr.antialiasing = antialias;
			spr.pixelPerfectRender = spr.pixelPerfectPosition = !antialias;
			spr.scrollFactor.set();
			spr.lifeTime = lifetime;
			spr.ID = Std.int(Conductor.songPosition);
		}

		if (showRating)
		{
			final rating:Combo = comboGroup.recycle(Combo);
			rating.loadGraphic(Paths.image(uiPrefix + daRating.image + uiSuffix));
			setUp(rating);
			rating.x = placement - 40 + ClientPrefs.data.comboOffset[0];
			rating.y -= 60 + ClientPrefs.data.comboOffset[1];
			rating.acceleration.set(0, 550 * playbackRate * playbackRate);
			rating.velocity.x -= FlxG.random.int(-10, 10) * playbackRate;
			rating.velocity.y -= FlxG.random.int(130, 160) * playbackRate;
			rating.setGraphicSize(Std.int(rating.width * (isPixelStage ? PlayState.daPixelZoom * 0.85 : 0.7)));
			rating.updateHitbox();
			yoRating = rating.y + rating.height;
		}

		if (showCombo)
		{
			final comboSpr:Combo = comboGroup.recycle(Combo);
			comboSpr.loadGraphic(Paths.image(uiPrefix + 'combo' + uiSuffix));
			setUp(comboSpr);
			comboSpr.x = placement + 40 + ClientPrefs.data.comboOffset[0];
			comboSpr.y += 50 + ClientPrefs.data.comboOffset[1];
			comboSpr.acceleration.set(0, FlxG.random.int(200, 300) * playbackRate * playbackRate);
			comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
			comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * (isPixelStage ? PlayState.daPixelZoom * 0.75 : 0.6)));
			comboSpr.updateHitbox();
		}

		if (ClientPrefs.data.showNoteTiming && showRating)
		{
			noteTimingRating.color = switch (daRating.name)
			{
				case 'sick': FlxColor.CYAN;
				case 'good': FlxColor.LIME;
				default: FlxColor.RED;
			}

			noteTimingRating.text = FlxMath.roundDecimal(noteDiffNoAbs / playbackRate, 3) + "ms";
			noteTimingRating.alpha = 1;
			noteTimingRating.exists = true;
			noteTimingRating.setPosition(placement + ClientPrefs.data.comboOffset[0] + 100, yoRating + (isPixelStage ? 60 : 0));
			noteTimingRatingTween?.cancel();

			noteTimingRatingTween = FlxTween.tween(noteTimingRating, {alpha: 0}, 0.2 / playbackRate, {
				startDelay: Conductor.crochet * 0.001 / playbackRate,
				onComplete: (_) -> noteTimingRating.exists = false,
				ease: isPixelStage ? EaseUtil.stepped(2) : null
			});
		}

		if (showComboNum)
		{
			final sepScore:String = '$combo';

			for (i in 0...sepScore.length)
			{
				final numScore:Combo = comboGroup.recycle(Combo);
				numScore.loadGraphic(Paths.image(uiPrefix + 'num' + Std.parseInt(sepScore.charAt(i)) + uiSuffix));
				setUp(numScore);
				numScore.x = (placement - 30 + ClientPrefs.data.comboOffset[2]) - (sepScore.length * 43 / 2) + i * 43;
				numScore.y += 80 - ClientPrefs.data.comboOffset[3];
				numScore.setGraphicSize(Std.int(numScore.width * (isPixelStage ? PlayState.daPixelZoom : 0.5)));
				numScore.updateHitbox();
				numScore.velocity.x -= FlxG.random.float(-10, 10) * playbackRate;
				numScore.velocity.y -= FlxG.random.int(135, 155) * playbackRate;
				numScore.acceleration.set(0, FlxG.random.int(200, 300) * playbackRate * playbackRate);
			}
		}

		comboGroup.sort((o:Int, a:Combo, b:Combo) -> return FlxSort.byValues(FlxSort.ASCENDING, a.ID, b.ID));
	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = PlayState.getKeyFromEvent(keysArray, eventKey);
		// trace('Pressed: ' + eventKey);

		if (!Funkin.controls.controllerMode)
		{
			#if debug
			// Prevents crash specifically on debug without needing to try catch shit
			@:privateAccess if (!FlxG.keys._keyListMap.exists(eventKey))
				return;
			#end

			if (FlxG.keys.checkStatus(eventKey, JUST_PRESSED))
				keyPressed(key);
		}
	}

	private function keyPressed(key:Int)
	{
		if (key < 0)
			return;

		// more accurate hit time for the ratings?
		var lastTime:Float = Conductor.songPosition;
		if (Conductor.songPosition >= 0)
			Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

		// obtain notes that the player can hit
		var plrInputNotes:Array<Note> = notes.members.filter(function(n:Note) return n != null && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit
			&& !n.blockHit && !n.isSustainNote && n.noteData == key);

		plrInputNotes.sort(PlayState.sortHitNotes);

		var shouldMiss:Bool = !ClientPrefs.data.ghostTapping;

		if (plrInputNotes.length != 0) // slightly faster than doing "> 0" lol
		{
			var funnyNote:Note = plrInputNotes[0]; // front note

			if (plrInputNotes.length > 1)
			{
				var doubleNote:Note = plrInputNotes[1];

				if (doubleNote.noteData == funnyNote.noteData)
				{
					// if the note has a 0ms distance (is on top of the current note), kill it
					if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0)
						invalidateNote(doubleNote);
					else if (doubleNote.strumTime < funnyNote.strumTime)
					{
						// replace the note if its ahead of time (or at least ensure "doubleNote" is ahead)
						funnyNote = doubleNote;
					}
				}
			}

			goodNoteHit(funnyNote);
		}

		// more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
		Conductor.songPosition = lastTime;

		var spr:StrumNote = playerStrums.members[key];
		if (spr != null && spr.animation.curAnim.name != 'confirm')
		{
			spr.playAnim('pressed');
			spr.resetAnim = 0;
		}
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = PlayState.getKeyFromEvent(keysArray, eventKey);
		// trace('Pressed: ' + eventKey);

		if (!Funkin.controls.controllerMode && key > -1)
			keyReleased(key);
	}

	private function keyReleased(key:Int)
	{
		var spr:StrumNote = playerStrums.members[key];
		if (spr != null)
		{
			spr.playAnim('static');
			spr.resetAnim = 0;
		}
	}

	#if FEATURE_MOBILE_CONTROLS
	private function onButtonPress(button:TouchButton):Void
	{
		if (button.IDs.filter(id -> id.toString().startsWith("EXTRA")).length > 0)
			return;

		var buttonCode:Int = (button.IDs[0].toString().startsWith('NOTE')) ? button.IDs[0] : button.IDs[1];
		if (button.justPressed)
			keyPressed(buttonCode);
	}

	private function onButtonRelease(button:TouchButton):Void
	{
		if (button.IDs.filter(id -> id.toString().startsWith("EXTRA")).length > 0)
			return;

		var buttonCode:Int = (button.IDs[0].toString().startsWith('NOTE')) ? button.IDs[0] : button.IDs[1];
		if (buttonCode > -1)
			keyReleased(buttonCode);
	}
	#end

	// Hold notes
	private function keysCheck():Void
	{
		// HOLDING
		var holdArray:Array<Bool> = [];
		var pressArray:Array<Bool> = [];
		var releaseArray:Array<Bool> = [];
		for (key in keysArray)
		{
			holdArray.push(Funkin.controls.pressed(key));
			if (Funkin.controls.controllerMode)
			{
				pressArray.push(Funkin.controls.justPressed(key));
				releaseArray.push(Funkin.controls.justReleased(key));
			}
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (Funkin.controls.controllerMode && pressArray.contains(true))
			for (i in 0...pressArray.length)
				if (pressArray[i])
					keyPressed(i);

		// rewritten inputs???
		if (notes.length > 0)
		{
			for (n in notes) // I can't do a filter here, that's kinda awesome
			{
				var canHit:Bool = (n != null && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit);

				if (guitarHeroSustains)
					canHit = canHit && n.parent != null && n.parent.wasGoodHit;

				if (canHit && n.isSustainNote)
				{
					var released:Bool = !holdArray[n.noteData];

					if (!released)
						goodNoteHit(n);
				}
			}
		}

		for (i => hold in holdArray)
			if (hold)
				SustainSplash.showAtData(i);
			else
				SustainSplash.hideAtData(i);

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (Funkin.controls.controllerMode && releaseArray.contains(true))
			for (i in 0...releaseArray.length)
				if (releaseArray[i])
					keyReleased(i);
	}

	function opponentNoteHit(note:Note):Void
	{
		if (PlayState.SONG.needsVoices && opponentVocals.length <= 0)
			vocals.volume = 1;

		var strum:StrumNote = opponentStrums.members[Std.int(Math.abs(note.noteData))];
		if (strum != null)
		{
			strum.playAnim('confirm', true);
			strum.resetAnim = Conductor.stepCrochet * 1.25 / 1000 / playbackRate;
		}
		note.hitByOpponent = true;

		spawnHoldSplashOnNote(note);

		if (!note.isSustainNote)
			invalidateNote(note);
	}

	function goodNoteHit(note:Note):Void
	{
		if (note.wasGoodHit)
			return;

		note.wasGoodHit = true;
		if (ClientPrefs.data.hitsoundVolume > 0 && !note.hitsoundDisabled)
			FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.data.hitsoundVolume);

		if (note.hitCausesMiss)
		{
			noteMiss(note);
			if (!note.noteSplashData.disabled && !note.isSustainNote)
				spawnNoteSplashOnNote(note);

			if (!note.isSustainNote)
				invalidateNote(note);
			return;
		}

		if (!note.isSustainNote)
		{
			combo++;
			//if (combo > 9999)
			//	combo = 9999;
			popUpScore(note);
		}

		var spr:StrumNote = playerStrums.members[note.noteData];
		if (spr != null)
			spr.playAnim('confirm', true);
		vocals.volume = 1;

		spawnHoldSplashOnNote(note);

		if (!note.isSustainNote)
			invalidateNote(note);
	}

	function noteMiss(daNote:Note):Void // You didn't hit the key and let it go offscreen, also used by Hurt Notes
	{
		// Dupe note remove
		notes.forEachAlive(function(note:Note)
		{
			if (daNote != note
				&& daNote.mustPress
				&& daNote.noteData == note.noteData
				&& daNote.isSustainNote == note.isSustainNote
				&& Math.abs(daNote.strumTime - note.strumTime) < 1)
				invalidateNote(daNote);
		});

		if (daNote != null && guitarHeroSustains && daNote.parent == null)
		{
			if (daNote.tail.length > 0)
			{
				daNote.alpha = 0.35;
				for (childNote in daNote.tail)
				{
					childNote.alpha = daNote.alpha;
					childNote.missed = true;
					childNote.canBeHit = false;
					childNote.ignoreNote = true;
					childNote.tooLate = true;
				}
				daNote.missed = true;
				daNote.canBeHit = false;
			}

			if (daNote.missed)
				return;
		}

		if (daNote != null && guitarHeroSustains && daNote.parent != null && daNote.isSustainNote)
		{
			if (daNote.missed)
				return;

			var parentNote:Note = daNote.parent;
			if (parentNote.wasGoodHit && parentNote.tail.length > 0)
			{
				for (child in parentNote.tail)
					if (child != daNote)
					{
						child.missed = true;
						child.canBeHit = false;
						child.ignoreNote = true;
						child.tooLate = true;
					}
			}
		}

		// score and data
		songMisses++;
		totalPlayed++;
		recalculateRating(true);
		vocals.volume = 0;
		combo = 0;
	}

	public function invalidateNote(note:Note):Void
	{
		notes.remove(note, true);
		note.destroy();
	}

	public function spawnHoldSplashOnNote(note:Note)
	{
		if (note == null)
			return;

		if (note.tail.length > 0 && !note.isSustainNote)
		{
			var lastSustain:Note = note.tail[note.tail.length - 1];
			var strumNote:StrumNote = note.mustPress ? playerStrums.members[note.noteData] : opponentStrums.members[note.noteData];
			SustainSplash.generateSustainSplash(strumNote, lastSustain.strumTime, note.mustPress);
		}
		else if(note.isSustainNote && note.parent != null && note.parent.tail.length > 0 && !SustainSplash.hasSplashAtData(note.noteData, note.mustPress))
		{
			var lastSustain:Note = note.parent.tail[note.parent.tail.length - 1];
			var strumNote:StrumNote = note.mustPress ? playerStrums.members[note.noteData] : opponentStrums.members[note.noteData];
			SustainSplash.generateSustainSplash(strumNote, lastSustain.strumTime, note.mustPress);
		}
	}

	function spawnNoteSplashOnNote(note:Note)
	{
		if (note != null)
		{
			var strum:StrumNote = playerStrums.members[note.noteData];
			if (strum != null)
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
		}
	}

	function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null)
	{
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, note);
		grpNoteSplashes.add(splash);
	}

	function resyncVocals():Void
	{
		if (finishTimer != null)
			return;

		FlxG.sound.music.play();
		FlxG.sound.music.pitch = playbackRate;
		Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;
		PlayState.playVocals(vocals, FlxG.sound.music.time - vocalsOffset, playbackRate);
		PlayState.playVocals(opponentVocals, FlxG.sound.music.time - opponentVocalsOffset, playbackRate);
	}

	function recalculateRating(badHit:Bool = false)
	{
		if (totalPlayed != 0) // Prevent divide by 0
			ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));

		fullComboUpdate();
		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce -Ghost
	}

	function updateScore(miss:Bool = false)
	{
		var str:String = '?';
		if (totalPlayed != 0)
		{
			var percent:Float = CoolUtil.floorDecimal(ratingPercent * 100, 2);
			str = '$percent% - $ratingFC';
		}
		scoreTxt.text = 'Hits: $songHits | Misses: $songMisses | Rating: $str';
	}

	function fullComboUpdate()
	{
		var sicks:Int = ratingsData[0].hits;
		var goods:Int = ratingsData[1].hits;
		var bads:Int = ratingsData[2].hits;
		var shits:Int = ratingsData[3].hits;

		ratingFC = 'Clear';
		if (songMisses < 1)
		{
			if (bads > 0 || shits > 0)
				ratingFC = 'FC';
			else if (goods > 0)
				ratingFC = 'GFC';
			else if (sicks > 0)
				ratingFC = 'SFC';
		}
		else if (songMisses < 10)
			ratingFC = 'SDCB';
	}

	function loadCharacterFile(char:String):CharacterFile
	{
		var characterPath:String = 'characters/' + char + '.json';
		var path:String;

		#if FEATURE_MODS
		var modPath:String = Paths.modFolders(characterPath);
		if (FileSystem.exists(modPath))
			path = modPath;
		else
			path = Paths.getSharedPath(characterPath);
		#else
		path = Paths.getSharedPath(characterPath);
		#end

		if (!FileSystem.exists(path))
			path = Paths.getSharedPath('characters/' + Character.DEFAULT_CHARACTER + '.json');

		var rawJson = File.getContent(path);
		return cast Json.parse(rawJson, path);
	}
}
