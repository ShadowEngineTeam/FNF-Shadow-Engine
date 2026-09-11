package substates;

import objects.Character;
import flixel.FlxObject;
import states.StoryMenuState;
import states.FreeplayState;
import effects.RetroCameraFade;
import backend.StageData;
import haxe.Json;

class GameOverSubstate extends MusicBeatSubstate
{
	public static var instance:GameOverSubstate;
	public static var characterName:String = 'bf';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';
	public var boyfriend:Character;
	var camFollow:FlxObject;
	var suffix:String = '';
	var targetZoom:Float = 1;
	var camOffsetX:Float = 0;
	var camOffsetY:Float = 0;
	var usingLiveBoyfriend:Bool = false;
	var startedDeath:Bool = false;
	var isEnding:Bool = false;
	var released:Bool = false;

	public static function resetVariables():Void
	{
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';

		if(PlayState.SONG != null)
		{
			if (PlayState.SONG.gameOverChar?.length > 0)
				characterName = PlayState.SONG.gameOverChar;

			if (PlayState.SONG.gameOverSound?.length > 0)
				deathSoundName = PlayState.SONG.gameOverSound;

			if (PlayState.SONG.gameOverLoop?.length > 0)
				loopSoundName = PlayState.SONG.gameOverLoop;

			if (PlayState.SONG.gameOverEnd?.length > 0)
				endSoundName = PlayState.SONG.gameOverEnd;
		}
	}

	override function create():Void
	{
		instance = this;

		#if FEATURE_HAPTICS
		if (ClientPrefs.data.gameOverVibration)
			extension.haptics.Haptic.vibrateOneShot(0.5, 1, 1);
		#end

		Conductor.songPosition = 0;

		final game:PlayState = PlayState.instance;
		suffix = game.boyfriend.idleSuffix;

		for (name in game.boyfriend.animOffsets.keys())
		{
			if (!name.startsWith('firstDeath')) continue;
			usingLiveBoyfriend = true;
			break;
		}

		if (usingLiveBoyfriend)
		{
			game.remove(game.boyfriendGroup);
			add(game.boyfriendGroup);
			boyfriend = game.boyfriend;
		}
		else
		{
			add(boyfriend = new Character(game.boyfriend.x, game.boyfriend.y, characterName, true));
			boyfriend.x += boyfriend.positionArray[0] - game.boyfriend.positionArray[0];
			boyfriend.y += boyfriend.positionArray[1] - game.boyfriend.positionArray[1];
		}

		boyfriend.shader = null;
		boyfriend.color = FlxColor.WHITE;
		boyfriend.skipDance = true;

		for (cam in FlxG.cameras.list)
			cam.filters = [];

		playDeathAnim('firstDeath');
		FlxG.sound.play(Paths.sound(checkFile(deathSoundName, 'sounds')));

		targetZoom = StageData.getStageFile(PlayState.curStage)?.defaultZoom ?? 1;

		final json:Dynamic = Json.parse(Paths.getTextFromFile('characters/${boyfriend.curCharacter}.json'));
		if (json?.gameover != null)
		{
			if (json.gameover.offsets != null)
			{
				camOffsetX = json.gameover.offsets[0];
				camOffsetY = json.gameover.offsets[1];
			}

			if (json.gameover.zoom != null)
				targetZoom *= json.gameover.zoom;
		}

		add(camFollow = new FlxObject(0, 0, 1, 1));
		updateCamFollow();

		FlxG.camera.follow(camFollow, LOCKON, 0.6);

		setOnScripts('inGameOver', true);
		setOnScripts('boyfriend', boyfriend);
		callOnScripts('onGameOverStart', []);

		#if FEATURE_MOBILE_CONTROLS
		addTouchPad("NONE", "A_B");
		addTouchPadCamera(false);
		#end

		super.create();
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		callOnScripts('onUpdate', [elapsed]);

		if (Funkin.controls.ACCEPT)
			endBullshit();

		if (Funkin.controls.BACK)
		{
			#if FEATURE_DISCORD_RPC DiscordClient.resetClientID(); #end
			FlxG.sound.music?.stop();
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = PlayState.chartingMode = false;

			Mods.loadTopMod();
			Funkin.switchState(PlayState.isStoryMode ? StoryMenuState : FreeplayState);

			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			callOnScripts('onGameOverConfirm', [false]);
		}

		updateCamFollow();
		FlxG.camera.zoom = smoothLerpPrecision(FlxG.camera.zoom, targetZoom, elapsed, 0.5);

		if (!startedDeath && boyfriend.getAnimationName().startsWith('firstDeath') && boyfriend.isAnimationFinished())
		{
			startedDeath = true;
			playDeathAnim('deathLoop');
			FlxG.sound.playMusic(Paths.music(checkFile(loopSoundName, 'music')), 0.2);

			var quote:String = deathQuote();
			if (quote != '')
				FlxG.sound.play(Paths.sound(quote), 1, false, null, true, () -> FlxG.sound.music.fadeIn(4, 0.2, 1));
			else
				FlxG.sound.music.fadeIn(4, 0.2, 1);

			callOnScripts('onGameOverMusicStart');
		}

		if (FlxG.sound.music.playing)
			Conductor.songPosition = FlxG.sound.music.time;

		callOnScripts('onUpdatePost', [elapsed]);
	}

	function endBullshit():Void
	{
		if (isEnding)
			return;

		isEnding = true;
		playDeathAnim('deathConfirm');
		FlxG.sound.music?.stop();
		FlxG.sound.playMusic(Paths.music(checkFile(endSoundName, 'music')), 1, false);

		new FlxTimer().start(FlxG.sound.music.length / 7000, (_) ->
		{
			if (PlayState.isPixelStage)
			{
				RetroCameraFade.fadeToBlack(FlxG.camera, 10, 2);
				new FlxTimer().start(2.05, (_) ->
				{
					releaseBoyfriend();
					Funkin.resetState();
				});
			}
			else
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, () ->
				{
					releaseBoyfriend();
					Funkin.resetState();
				});
			}
		});
		callOnScripts('onGameOverConfirm', [true]);
	}

	function updateCamFollow():Void
	{
		final midpoint:FlxPoint = boyfriend.getMidpoint();
		final stageOffset:Array<Float> = PlayState.instance?.boyfriendCameraOffset ?? [0, 0];
		camFollow.setPosition(midpoint.x - 100 - (boyfriend.cameraPosition[0] - stageOffset[0] - camOffsetX), midpoint.y - 100 + (boyfriend.cameraPosition[1] + stageOffset[1] + camOffsetY));
		midpoint.put();
	}

	inline function playDeathAnim(anim:String):Void
		boyfriend.playAnim(anim + (boyfriend.animOffsets.exists(anim + suffix) ? suffix : ''), true);

	inline function smoothLerpPrecision(base:Float, target:Float, deltaTime:Float, duration:Float, precision:Float = 1 / 100):Float
		return deltaTime == 0 || base == target ? 0 : FlxMath.lerp(target, base, Math.pow(precision, deltaTime / duration));

	function releaseBoyfriend():Void
	{
		if (released)
			return;

		released = true;

		if (usingLiveBoyfriend)
		{
			var group:FlxSpriteGroup = PlayState.instance.boyfriendGroup;
			remove(group);
			PlayState.instance.add(group);
		}
		else
		{
			remove(boyfriend);
			boyfriend.destroy();
		}
	}

	function deathQuote():String
	{
		var path:String = 'data/' + Paths.formatToSongPath(PlayState.SONG.song);

		if (PlayState.SONG.variant?.length > 0)
			path += '/${PlayState.SONG.variant}';

		path += '/deathQuote.txt';

		final contents:String = Paths.getTextFromFile(path);
		if (contents == null)
			return '';

		final quotes:Array<String> = contents.split('\n');
		return quotes[FlxG.random.int(0, quotes.length - 1)];
	}

	function checkFile(file:String, folder:String):String
	{
		if (!PlayState.isPixelStage)
			return file;

		final pixelName:String = '$file-pixel';
		for (ext in Paths.SOUND_EXTS)
		{
			if (Paths.fileExists('$folder/$pixelName.$ext', SOUND))
				return pixelName;
		}
		return file;
	}

	override function destroy():Void
	{
		instance = null;
		releaseBoyfriend();
		super.destroy();
	}
}
