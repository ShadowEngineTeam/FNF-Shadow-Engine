
package psychlua;

import backend.WeekData;
import backend.Highscore;
import backend.Song;
import openfl.Lib;
import openfl.utils.Assets;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
#if !flash
import flixel.addons.display.FlxRuntimeShader;
#end
import flixel.util.typeLimit.OneOfTwo;
import cutscenes.DialogueBoxPsych;
import objects.StrumNote;
import objects.Note;
import objects.NoteSplash;
import objects.Character;
import states.MainMenuState;
import substates.PauseSubState;
import substates.GameOverSubstate;
import psychlua.LuaUtils;
import psychlua.LuaUtils.LuaTweenOptions;
#if HSCRIPT_ALLOWED
import psychlua.HScript;
#end
import psychlua.DebugLuaText;
import psychlua.ModchartSprite;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;
import mobile.psychlua.Functions;

class FunkinLua
{
	private var game(get, never):Dynamic;

	inline private function get_game()
		return cast FunkinLua.getCurrentMusicState();

	#if LUA_ALLOWED
	public var lua:State = null;
	#end

	public var camTarget:FlxCamera;
	public var scriptName:String = '';
	public var modFolder:String = null;
	public var closed:Bool = false;

	#if HSCRIPT_ALLOWED
	public var hscript:HScript = null;
	#end

	public var callbacks:Map<String, Dynamic> = new Map<String, Dynamic>();

	public static var customFunctions:Map<String, Dynamic> = new Map<String, Dynamic>();

	public function new(scriptName:String)
	{
		#if LUA_ALLOWED
		var times:Float = Date.now().getTime();
		lua = LuaL.newstate();
		LuaL.openlibs(lua);

		// trace('Lua version: ' + Lua.version());
		// trace("LuaJIT version: " + Lua.versionJIT());

		// LuaL.dostring(lua, CLENSE);

		this.scriptName = scriptName.trim();
		game.luaArray.push(this);

		var myFolder:Array<String> = this.scriptName.split('/');
		#if MODS_ALLOWED
		if (myFolder[0] + '/' == Paths.mods()
			&& (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) // is inside mods folder
			this.modFolder = myFolder[1];
		#end

		// Lua shit
		set('Function_StopLua', LuaUtils.Function_StopLua);
		set('Function_StopHScript', LuaUtils.Function_StopHScript);
		set('Function_StopAll', LuaUtils.Function_StopAll);
		set('Function_Stop', LuaUtils.Function_Stop);
		set('Function_Continue', LuaUtils.Function_Continue);
		set('luaDebugMode', false);
		set('luaDeprecatedWarnings', true);
		set('inChartEditor', false);

		if (FunkinLua.getCurrentMusicState() is PlayState)
		{
			set('bpm', PlayState.SONG.bpm);
			set('scrollSpeed', PlayState.SONG.speed);
			set('songName', PlayState.SONG.song);
			set('songPath', Paths.formatToSongPath(PlayState.SONG.song));
			set('curStage', PlayState.SONG.stage);

			set('isStoryMode', PlayState.isStoryMode);
			set('difficulty', PlayState.storyDifficulty);
			set('songLength', FlxG.sound.music.length);
			set('startedCountdown', false);

			set('difficultyName', Difficulty.getString());
			set('difficultyPath', Paths.formatToSongPath(Difficulty.getString()));
			set('weekRaw', PlayState.storyWeek);
			set('week', WeekData.weeksList[PlayState.storyWeek]);
			set('seenCutscene', PlayState.seenCutscene);
			set('hasVocals', PlayState.SONG.needsVoices);

			set('inGameOver', false);
			set('mustHitSection', false);
			set('altAnim', false);
			set('gfSection', false);

			// Gameplay settings
			set('healthGainMult', game.healthGain);
			set('healthLossMult', game.healthLoss);

			#if FLX_PITCH
			set('playbackRate', game.playbackRate);
			#else
			set('playbackRate', 1);
			#end

			set('guitarHeroSustains', game.guitarHeroSustains);
			set('instakillOnMiss', game.instakillOnMiss);
			set('botPlay', game.cpuControlled);
			set('practice', game.practiceMode);

			set('score', 0);
			set('misses', 0);
			set('hits', 0);
			set('combo', 0);

			set('rating', 0);
			set('ratingName', '');
			set('ratingFC', '');

			for (i in 0...4)
			{
				set('defaultPlayerStrumX' + i, 0);
				set('defaultPlayerStrumY' + i, 0);
				set('defaultOpponentStrumX' + i, 0);
				set('defaultOpponentStrumY' + i, 0);
			}

			// Default character
			set('defaultBoyfriendX', game.BF_X);
			set('defaultBoyfriendY', game.BF_Y);
			set('defaultOpponentX', game.DAD_X);
			set('defaultOpponentY', game.DAD_Y);
			set('defaultGirlfriendX', game.GF_X);
			set('defaultGirlfriendY', game.GF_Y);

			// Character shit
			set('boyfriendName', PlayState.SONG.player1);
			set('dadName', PlayState.SONG.player2);
			set('gfName', PlayState.SONG.gfVersion);

			// Tween shit, but for strums
			set("noteTweenX", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
			{
				LuaUtils.cancelTween(tag);
				if (note < 0)
					note = 0;
				var testicle:StrumNote = cast(game, PlayState).strumLineNotes.members[note % cast(cast(game, PlayState).strumLineNotes.length, Int)];

				if (testicle != null)
				{
					game.modchartTweens.set(tag, FlxTween.tween(testicle, {x: value}, duration, {
						ease: LuaUtils.getTweenEaseByString(ease),
						onComplete: function(twn:FlxTween)
						{
							game.callOnLuas('onTweenCompleted', [tag]);
							game.modchartTweens.remove(tag);
						}
					}));
				}
			});
			set("noteTweenY", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
			{
				LuaUtils.cancelTween(tag);
				if (note < 0)
					note = 0;
				var testicle:StrumNote = cast(game, PlayState).strumLineNotes.members[note % cast(cast(game, PlayState).strumLineNotes.length, Int)];

				if (testicle != null)
				{
					game.modchartTweens.set(tag, FlxTween.tween(testicle, {y: value}, duration, {
						ease: LuaUtils.getTweenEaseByString(ease),
						onComplete: function(twn:FlxTween)
						{
							game.callOnLuas('onTweenCompleted', [tag]);
							game.modchartTweens.remove(tag);
						}
					}));
				}
			});
			set("noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
			{
				LuaUtils.cancelTween(tag);
				if (note < 0)
					note = 0;
				var testicle:StrumNote = cast(game, PlayState).strumLineNotes.members[note % cast(cast(game, PlayState).strumLineNotes.length, Int)];

				if (testicle != null)
				{
					game.modchartTweens.set(tag, FlxTween.tween(testicle, {angle: value}, duration, {
						ease: LuaUtils.getTweenEaseByString(ease),
						onComplete: function(twn:FlxTween)
						{
							game.callOnLuas('onTweenCompleted', [tag]);
							game.modchartTweens.remove(tag);
						}
					}));
				}
			});
			set("noteTweenDirection", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
			{
				LuaUtils.cancelTween(tag);
				if (note < 0)
					note = 0;
				var testicle:StrumNote = cast(game, PlayState).strumLineNotes.members[note % cast(cast(game, PlayState).strumLineNotes.length, Int)];

				if (testicle != null)
				{
					game.modchartTweens.set(tag, FlxTween.tween(testicle, {direction: value}, duration, {
						ease: LuaUtils.getTweenEaseByString(ease),
						onComplete: function(twn:FlxTween)
						{
							game.callOnLuas('onTweenCompleted', [tag]);
							game.modchartTweens.remove(tag);
						}
					}));
				}
			});
			set("noteTweenAlpha", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
			{
				LuaUtils.cancelTween(tag);
				if (note < 0)
					note = 0;
				var testicle:StrumNote = cast(game, PlayState).strumLineNotes.members[note % cast(cast(game, PlayState).strumLineNotes.length, Int)];

				if (testicle != null)
				{
					game.modchartTweens.set(tag, FlxTween.tween(testicle, {alpha: value}, duration, {
						ease: LuaUtils.getTweenEaseByString(ease),
						onComplete: function(twn:FlxTween)
						{
							game.callOnLuas('onTweenCompleted', [tag]);
							game.modchartTweens.remove(tag);
						}
					}));
				}
			});

			// stupid bietch ass functions
			set("addScore", function(value:Int = 0)
			{
				cast(game, PlayState).songScore += value;
				cast(game, PlayState).RecalculateRating();
			});
			set("addMisses", function(value:Int = 0)
			{
				cast(game, PlayState).songMisses += value;
				cast(game, PlayState).RecalculateRating();
			});
			set("addHits", function(value:Int = 0)
			{
				cast(game, PlayState).songHits += value;
				cast(game, PlayState).RecalculateRating();
			});
			set("setScore", function(value:Int = 0)
			{
				cast(game, PlayState).songScore = value;
				cast(game, PlayState).RecalculateRating();
			});
			set("setMisses", function(value:Int = 0)
			{
				cast(game, PlayState).songMisses = value;
				cast(game, PlayState).RecalculateRating();
			});
			set("setHits", function(value:Int = 0)
			{
				cast(game, PlayState).songHits = value;
				cast(game, PlayState).RecalculateRating();
			});
			set("getScore", function()
			{
				return cast(game, PlayState).songScore;
			});
			set("getMisses", function()
			{
				return cast(game, PlayState).songMisses;
			});
			set("getHits", function()
			{
				return cast(game, PlayState).songHits;
			});

			set("setHealth", function(value:Float = 0)
			{
				cast(game, PlayState).health = value;
			});
			set("addHealth", function(value:Float = 0)
			{
				cast(game, PlayState).health += value;
			});
			set("getHealth", function()
			{
				return cast(game, PlayState).health;
			});

			// precaching
			set("addCharacterToList", function(name:String, type:String)
			{
				var charType:Int = 0;
				switch (type.toLowerCase())
				{
					case 'dad':
						charType = 1;
					case 'gf' | 'girlfriend':
						charType = 2;
				}
				cast(game, PlayState).addCharacterToList(name, charType);
			});

			// others
			set("triggerEvent", function(name:String, arg1:Dynamic, arg2:Dynamic)
			{
				var value1:String = arg1;
				var value2:String = arg2;
				cast(game, PlayState).triggerEvent(name, value1, value2, Conductor.songPosition);
				// trace('Triggered event: ' + name + ', ' + value1 + ', ' + value2);
				return true;
			});

			set("startCountdown", cast(game, PlayState).startCountdown);
			set("endSong", function()
			{
				cast(game, PlayState).KillNotes();
				cast(game, PlayState).endSong();
				return true;
			});
			set("restartSong", function(?skipTransition:Bool = false)
			{
				cast(game, PlayState).persistentUpdate = false;
				FlxG.camera.followLerp = 0;
				PauseSubState.restartSong(skipTransition);
				return true;
			});
			set("exitSong", function(?skipTransition:Bool = false)
			{
				if (skipTransition)
				{
					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
				}

				MusicBeatState.switchState(new states.FreeplayState());

				#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				PlayState.changedDifficulty = false;
				PlayState.chartingMode = false;
				cast(game, PlayState).transitioning = true;
				FlxG.camera.followLerp = 0;
				Mods.loadTopMod();
				return true;
			});
			set("getSongPosition", function()
			{
				return Conductor.songPosition;
			});

			set("getCharacterX", function(type:String)
			{
				switch (type.toLowerCase())
				{
					case 'dad' | 'opponent':
						return cast(game, PlayState).dadGroup.x;
					case 'gf' | 'girlfriend':
						return cast(game, PlayState).gfGroup.x;
					default:
						return cast(game, PlayState).boyfriendGroup.x;
				}
			});
			set("setCharacterX", function(type:String, value:Float)
			{
				switch (type.toLowerCase())
				{
					case 'dad' | 'opponent':
						cast(game, PlayState).dadGroup.x = value;
					case 'gf' | 'girlfriend':
						cast(game, PlayState).gfGroup.x = value;
					default:
						cast(game, PlayState).boyfriendGroup.x = value;
				}
			});
			set("getCharacterY", function(type:String)
			{
				switch (type.toLowerCase())
				{
					case 'dad' | 'opponent':
						return cast(game, PlayState).dadGroup.y;
					case 'gf' | 'girlfriend':
						return cast(game, PlayState).gfGroup.y;
					default:
						return cast(game, PlayState).boyfriendGroup.y;
				}
			});
			set("setCharacterY", function(type:String, value:Float)
			{
				switch (type.toLowerCase())
				{
					case 'dad' | 'opponent':
						cast(game, PlayState).dadGroup.y = value;
					case 'gf' | 'girlfriend':
						cast(game, PlayState).gfGroup.y = value;
					default:
						cast(game, PlayState).boyfriendGroup.y = value;
				}
			});
			set("cameraSetTarget", function(target:String)
			{
				var isDad:Bool = false;
				if (target == 'dad')
				{
					isDad = true;
				}
				cast(game, PlayState).moveCamera(isDad);
				return isDad;
			});
			set("setRatingPercent", function(value:Float)
			{
				cast(game, PlayState).ratingPercent = value;
			});
			set("setRatingName", function(value:String)
			{
				cast(game, PlayState).ratingName = value;
			});
			set("setRatingFC", function(value:String)
			{
				cast(game, PlayState).ratingFC = value;
			});

			set("characterDance", function(character:String)
			{
				switch (character.toLowerCase())
				{
					case 'dad':
						cast(game, PlayState).dad.dance();
					case 'gf' | 'girlfriend':
						if (cast(game, PlayState).gf != null)
							cast(game, PlayState).gf.dance();
					default:
						cast(game, PlayState).boyfriend.dance();
				}
			});

			set("setHealthBarColors", function(left:String, right:String)
			{
				cast(game, PlayState).healthBar.setColors(CoolUtil.colorFromString(left), CoolUtil.colorFromString(right));
			});
			set("setTimeBarColors", function(left:String, right:String)
			{
				cast(game, PlayState).timeBar.setColors(CoolUtil.colorFromString(left), CoolUtil.colorFromString(right));
			});

			set("startDialogue", function(dialogueFile:String, music:String = null)
			{
				var path:String;
				#if MODS_ALLOWED
				path = Paths.modsJson(Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile);
				if (!FileSystem.exists(path))
				#end
				path = Paths.json(Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile);

				luaTrace('startDialogue: Trying to load dialogue: ' + path);

				if (FileSystem.exists(path))
				{
					var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);
					if (shit.dialogue.length > 0)
					{
						cast(game, PlayState).startDialogue(shit, music);
						luaTrace('startDialogue: Successfully loaded dialogue', false, false, FlxColor.GREEN);
						return true;
					}
					else
					{
						luaTrace('startDialogue: Your dialogue file is badly formatted!', false, false, FlxColor.RED);
					}
				}
			else
			{
				luaTrace('startDialogue: Dialogue file not found', false, false, FlxColor.RED);
				if (cast(game, PlayState).endingSong)
				{
					cast(game, PlayState).endSong();
				}
				else
				{
					cast(game, PlayState).startCountdown();
				}
			}
				return false;
			});
			set("startVideo", function(videoFile:String)
			{
				#if VIDEOS_ALLOWED
				if (FileSystem.exists(Paths.video(videoFile)))
				{
					cast(game, PlayState).startVideo(videoFile);
					return true;
				}
				else
				{
					luaTrace('startVideo: Video file not found: ' + videoFile, false, false, FlxColor.RED);
				}
				return false;
				#else
				if (cast(game, PlayState).endingSong)
				{
					cast(game, PlayState).endSong();
				}
				else
				{
					cast(game, PlayState).startCountdown();
				}
				return true;
				#end
			});
		}

		// Song/Week shit
		set('curBpm', Conductor.bpm);
		set('crochet', Conductor.crochet);
		set('stepCrochet', Conductor.stepCrochet);

		// Camera poo
		set('cameraX', 0);
		set('cameraY', 0);

		// Screen stuff
		set('screenWidth', FlxG.width);
		set('screenHeight', FlxG.height);

		set('curSection', 0);
		set('curBeat', 0);
		set('curStep', 0);
		set('curDecBeat', 0);
		set('curDecStep', 0);

		set('version', MainMenuState.psychEngineVersion.trim());
		set('shadowVersion', MainMenuState.shadowEngineVersion.trim());

		// Other settings
		set('downscroll', ClientPrefs.data.downScroll);
		set('middlescroll', ClientPrefs.data.middleScroll);
		set('framerate', ClientPrefs.data.framerate);
		set('ghostTapping', ClientPrefs.data.ghostTapping);
		set('hideHud', ClientPrefs.data.hideHud);
		set('timeBarType', ClientPrefs.data.timeBarType);
		set('scoreZoom', ClientPrefs.data.scoreZoom);
		set('cameraZoomOnBeat', ClientPrefs.data.camZooms);
		set('flashingLights', ClientPrefs.data.flashing);
		set('noteOffset', ClientPrefs.data.noteOffset);
		set('healthBarAlpha', ClientPrefs.data.healthBarAlpha);
		set('noResetButton', ClientPrefs.data.noReset);
		set('lowQuality', ClientPrefs.data.lowQuality);
		set('shadersEnabled', ClientPrefs.data.shaders);
		set('scriptName', scriptName);
		set('currentModDirectory', Mods.currentModDirectory);

		// Noteskin/Splash
		set('noteSkin', ClientPrefs.data.noteSkin);
		set('noteSkinPostfix', Note.getNoteSkinPostfix());
		set('splashSkin', ClientPrefs.data.splashSkin);
		set('splashSkinPostfix', NoteSplash.getSplashSkinPostfix());
		set('splashAlpha', ClientPrefs.data.splashAlpha);

		// build target (windows, mac, linux, etc.)
		set('buildTarget', LuaUtils.getBuildTarget());

		for (name => func in customFunctions)
		{
			if (func != null)
				set(name, func);
		}

		//
		set("getRunningScripts", function()
		{
			var runningScripts:Array<String> = [];
			for (script in cast(game.luaArray, Array<Dynamic>))
			{
				final funk:FunkinLua = cast(script, FunkinLua);
				runningScripts.push(funk.scriptName);
			}

			return runningScripts;
		});

		addLocalCallback("setOnScripts", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null)
		{
			if (exclusions == null)
				exclusions = [];
			if (ignoreSelf && !exclusions.contains(scriptName))
				exclusions.push(scriptName);
			game.setOnScripts(varName, arg, exclusions);
		});
		addLocalCallback("setOnHScript", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null)
		{
			if (exclusions == null)
				exclusions = [];
			if (ignoreSelf && !exclusions.contains(scriptName))
				exclusions.push(scriptName);
			game.setOnHScript(varName, arg, exclusions);
		});
		addLocalCallback("setOnLuas", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null)
		{
			if (exclusions == null)
				exclusions = [];
			if (ignoreSelf && !exclusions.contains(scriptName))
				exclusions.push(scriptName);
			game.setOnLuas(varName, arg, exclusions);
		});

		addLocalCallback("callOnScripts",
			function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops = false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null,
					?excludeValues:Array<Dynamic> = null)
			{
				if (excludeScripts == null)
					excludeScripts = [];
				if (ignoreSelf && !excludeScripts.contains(scriptName))
					excludeScripts.push(scriptName);
				game.callOnScripts(funcName, args, ignoreStops, excludeScripts, excludeValues);
				return true;
			});
		addLocalCallback("callOnLuas",
			function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops = false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null,
					?excludeValues:Array<Dynamic> = null)
			{
				if (excludeScripts == null)
					excludeScripts = [];
				if (ignoreSelf && !excludeScripts.contains(scriptName))
					excludeScripts.push(scriptName);
				game.callOnLuas(funcName, args, ignoreStops, excludeScripts, excludeValues);
				return true;
			});
		addLocalCallback("callOnHScript",
			function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops = false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null,
					?excludeValues:Array<Dynamic> = null)
			{
				if (excludeScripts == null)
					excludeScripts = [];
				if (ignoreSelf && !excludeScripts.contains(scriptName))
					excludeScripts.push(scriptName);
				game.callOnHScript(funcName, args, ignoreStops, excludeScripts, excludeValues);
				return true;
			});

		set("callScript", function(luaFile:String, funcName:String, ?args:Array<Dynamic> = null)
		{
			if (args == null)
			{
				args = [];
			}

			var foundScript:String = findScript(luaFile);
			if (foundScript != null)
				for (luaInstance in cast(game.luaArray, Array<Dynamic>))
				{
					final funk:FunkinLua = cast(luaInstance, FunkinLua);
					if (funk.scriptName == foundScript)
					{
						funk.call(funcName, args);
						return;
					}
				}
		});

		set("getGlobalFromScript", function(luaFile:String, global:String)
		{ // returns the global from a script
			var foundScript:String = findScript(luaFile);
			if (foundScript != null)
				for (_luaInstance in cast(game.luaArray, Array<Dynamic>))
				{
					var luaInstance:FunkinLua = cast _luaInstance;
					final funk:FunkinLua = cast(luaInstance, FunkinLua);
					if (funk.scriptName == foundScript)
					{
						Lua.getglobal(funk.lua, global);
						var value:Dynamic = Convert.fromLua(funk.lua, -1);
						Lua.pop(funk.lua, 1); // remove the global from funk.lua
						Convert.toLua(lua, value); // push the value to the current lua state
						return;
					}
				}
		});
		set("setGlobalFromScript", function(luaFile:String, global:String, val:Dynamic)
		{ // returns the global from a script
			var foundScript:String = findScript(luaFile);
			if (foundScript != null)
				for (luaInstance in cast(game.luaArray, Array<Dynamic>))
				{
					final funk:FunkinLua = cast(luaInstance, FunkinLua);
					if (funk.scriptName == foundScript)
						funk.set(global, val);
				}
		});
		set("isRunning", function(luaFile:String)
		{
			var foundScript:String = findScript(luaFile);
			if (foundScript != null)
				for (luaInstance in cast(game.luaArray, Array<Dynamic>))
				{
					final funk:FunkinLua = cast(luaInstance, FunkinLua);
					if (funk.scriptName == foundScript)
						return true;
				}
			return false;
		});

		set("setVar", function(varName:String, value:Dynamic)
		{
			FunkinLua.getCurrentMusicState().variables.set(varName, value);
			return value;
		});
		set("getVar", FunkinLua.getCurrentMusicState().variables.get);

		set("addLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false)
		{ // would be dope asf.
			var foundScript:String = findScript(luaFile);
			if (foundScript != null)
			{
				if (!ignoreAlreadyRunning)
					for (luaInstance in cast(game.luaArray, Array<Dynamic>))
					{
						final funk:FunkinLua = cast(luaInstance, FunkinLua);
						if (funk.scriptName == foundScript)
						{
							luaTrace('addLuaScript: The script "' + foundScript + '" is already running!');
							return;
						}
					}

				new FunkinLua(foundScript);
				return;
			}
			luaTrace("addLuaScript: Script doesn't exist!", false, false, FlxColor.RED);
		});
		set("addHScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false)
		{
			#if HSCRIPT_ALLOWED
			var foundScript:String = findScript(luaFile, '.hx');
			if (foundScript != null)
			{
				if (!ignoreAlreadyRunning)
					for (script in cast(game.hscriptArray, Array<Dynamic>))
					{
						final hs:HScript = cast(script, HScript);
						if (hs.origin == foundScript)
						{
							luaTrace('addHScript: The script "' + foundScript + '" is already running!');
							return;
						}
					}

				FunkinLua.getCurrentMusicState().initHScript(foundScript);
				return;
			}
			luaTrace("addHScript: Script doesn't exist!", false, false, FlxColor.RED);
			#else
			luaTrace("addHScript: HScript is not supported on this platform!", false, false, FlxColor.RED);
			#end
		});
		set("removeLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false)
		{
			var foundScript:String = findScript(luaFile);
			if (foundScript != null)
			{
				if (!ignoreAlreadyRunning)
					for (luaInstance in cast(game.luaArray, Array<Dynamic>))
					{
						final funk:FunkinLua = cast(luaInstance, FunkinLua);
						if (funk.scriptName == foundScript)
						{
							funk.stop();
							trace('Closing script ' + funk.scriptName);
							return true;
						}
					}
			}
			luaTrace('removeLuaScript: Script $luaFile isn\'t running!', false, false, FlxColor.RED);
			return false;
		});
		set("removeHScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false)
		{
			#if HSCRIPT_ALLOWED
			var foundScript:String = findScript(luaFile, '.hx');
			if (foundScript != null)
			{
				if (!ignoreAlreadyRunning)
					for (script in cast(game.hscriptArray, Array<Dynamic>))
					{
						final hs:HScript = cast(script, HScript);
						if (hs.origin == foundScript)
						{
							trace('Closing script ' + (hs.origin != null ? hs.origin : luaFile));
							hs.destroy();
							return true;
						}
					}
			}
			luaTrace('removeHScript: Script $luaFile isn\'t running!', false, false, FlxColor.RED);
			return false;
			#else
			luaTrace("removeHScript: HScript is not supported on this platform!", false, false, FlxColor.RED);
			#end
		});

		set("loadSong", function(?name:String = null, ?difficultyNum:Int = -1)
		{
			if (name == null || name.length < 1)
				name = PlayState.SONG.song;
			if (difficultyNum == -1)
				difficultyNum = PlayState.storyDifficulty;

			var poop = Highscore.formatSong(name, difficultyNum);
			PlayState.SONG = Song.loadFromJson(poop, name);
			PlayState.storyDifficulty = difficultyNum;
			game.persistentUpdate = false;
			LoadingState.loadAndSwitchState(new PlayState());

			FlxG.sound.music.pause();
			FlxG.sound.music.volume = 0;
			if (game.vocals != null)
			{
				game.vocals.pause();
				game.vocals.volume = 0;
			}
			FlxG.camera.followLerp = 0;
		});

		set("loadGraphic", function(variable:String, image:String, ?gridX:Int = 0, ?gridY:Int = 0)
		{
			var split:Array<String> = variable.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			var animated = gridX != 0 || gridY != 0;

			if (split.length > 1)
			{
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (spr != null && image != null && image.length > 0)
			{
				spr.loadGraphic(Paths.image(image), animated, gridX, gridY);
			}
		});
		set("loadFrames", function(variable:String, image:String, spriteType:String = "sparrow")
		{
			var split:Array<String> = variable.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (spr != null && image != null && image.length > 0)
			{
				LuaUtils.loadFrames(spr, image, spriteType);
			}
		});

		// shitass stuff for epic coders like me B)  *image of obama giving himself a medal*
		set("getObjectOrder", function(obj:String)
		{
			var split:Array<String> = obj.split('.');
			var leObj:FlxBasic = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (leObj != null)
			{
				return LuaUtils.getTargetInstance().members.indexOf(leObj);
			}
			luaTrace("getObjectOrder: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return -1;
		});
		set("setObjectOrder", function(obj:String, position:Int)
		{
			var split:Array<String> = obj.split('.');
			var leObj:FlxBasic = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (leObj != null)
			{
				LuaUtils.getTargetInstance().remove(leObj, true);
				LuaUtils.getTargetInstance().insert(position, leObj);
				return;
			}
			luaTrace("setObjectOrder: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
		});

		// gay ass tweens
		set("startTween", function(tag:String, vars:String, values:Any = null, duration:Float, options:Any = null)
		{
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if (penisExam != null)
			{
				if (values != null)
				{
					var myOptions:LuaTweenOptions = LuaUtils.getLuaTween(options);
					game.modchartTweens.set(tag, FlxTween.tween(penisExam, values, duration, {
						type: myOptions.type,
						ease: myOptions.ease,
						startDelay: myOptions.startDelay,
						loopDelay: myOptions.loopDelay,

						onUpdate: function(twn:FlxTween)
						{
							if (myOptions.onUpdate != null)
								game.callOnLuas(myOptions.onUpdate, [tag, vars]);
						},
						onStart: function(twn:FlxTween)
						{
							if (myOptions.onStart != null)
								game.callOnLuas(myOptions.onStart, [tag, vars]);
						},
						onComplete: function(twn:FlxTween)
						{
							if (myOptions.onComplete != null)
								game.callOnLuas(myOptions.onComplete, [tag, vars]);
							if (twn.type == FlxTweenType.ONESHOT || twn.type == FlxTweenType.BACKWARD)
								game.modchartTweens.remove(tag);
						}
					}));
				}
				else
				{
					luaTrace('startTween: No values on 2nd argument!', false, false, FlxColor.RED);
				}
			}
			else
			{
				luaTrace('startTween: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});

		set("doTweenX", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			oldTweenFunction(tag, vars, {x: value}, duration, ease, 'doTweenX');
		});
		set("doTweenY", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			oldTweenFunction(tag, vars, {y: value}, duration, ease, 'doTweenY');
		});
		set("doTweenAngle", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			oldTweenFunction(tag, vars, {angle: value}, duration, ease, 'doTweenAngle');
		});
		set("doTweenAlpha", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			oldTweenFunction(tag, vars, {alpha: value}, duration, ease, 'doTweenAlpha');
		});
		set("doTweenZoom", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			oldTweenFunction(tag, vars, {zoom: value}, duration, ease, 'doTweenZoom');
		});
		set("doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ease:String)
		{
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if (penisExam != null)
			{
				var curColor:FlxColor = penisExam.color;
				curColor.alphaFloat = penisExam.alpha;
				game.modchartTweens.set(tag, FlxTween.color(penisExam, duration, curColor, CoolUtil.colorFromString(targetColor), {
					ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						game.modchartTweens.remove(tag);
						game.callOnLuas('onTweenCompleted', [tag, vars]);
					}
				}));
			}
			else
			{
				luaTrace('doTweenColor: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});

		set("mouseClicked", function(button:String)
		{
			var click:Bool = FlxG.mouse.justPressed;
			switch (button.trim().toLowerCase())
			{
				case 'middle':
					click = FlxG.mouse.justPressedMiddle;
				case 'right':
					click = FlxG.mouse.justPressedRight;
			}
			return click;
		});
		set("mousePressed", function(button:String)
		{
			var press:Bool = FlxG.mouse.pressed;
			switch (button.trim().toLowerCase())
			{
				case 'middle':
					press = FlxG.mouse.pressedMiddle;
				case 'right':
					press = FlxG.mouse.pressedRight;
			}
			return press;
		});
		set("mouseReleased", function(button:String)
		{
			var released:Bool = FlxG.mouse.justReleased;
			switch (button.trim().toLowerCase())
			{
				case 'middle':
					released = FlxG.mouse.justReleasedMiddle;
				case 'right':
					released = FlxG.mouse.justReleasedRight;
			}
			return released;
		});

		set("cancelTween", LuaUtils.cancelTween);
		set("runTimer", function(tag:String, time:Float = 1, loops:Int = 1)
		{
			LuaUtils.cancelTimer(tag);
			game.modchartTimers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer)
			{
				if (tmr.finished)
				{
					game.modchartTimers.remove(tag);
				}
				final args:Array<Dynamic> = [tag, tmr.loops, tmr.loopsLeft];
				game.callOnLuas('onTimerCompleted', args);
				// trace('Timer Completed: ' + tag);
			}, loops));
		});
		set("cancelTimer", LuaUtils.cancelTimer);

		// Identical functions
		set("FlxColor", FlxColor.fromString);
		set("getColorFromName", FlxColor.fromString);
		set("getColorFromString", FlxColor.fromString);
		set("getColorFromHex", function(color:String) return FlxColor.fromString('#$color'));

		// precaaching
		set("precacheImage", function(name:String)
		{
			Paths.image(name);
		});
		set("precacheSound", Paths.sound);
		set("precacheMusic", Paths.music);

		set("cameraShake", function(camera:String, intensity:Float, duration:Float)
		{
			LuaUtils.cameraFromString(camera).shake(intensity, duration);
		});

		set("cameraFlash", function(camera:String, color:String, duration:Float, forced:Bool)
		{
			LuaUtils.cameraFromString(camera).flash(CoolUtil.colorFromString(color), duration, null, forced);
		});
		set("cameraFade", function(camera:String, color:String, duration:Float, forced:Bool)
		{
			LuaUtils.cameraFromString(camera).fade(CoolUtil.colorFromString(color), duration, false, null, forced);
		});
		set("getMouseX", function(camera:String)
		{
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).x;
		});
		set("getMouseY", function(camera:String)
		{
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).y;
		});

		set("getMidpointX", function(variable:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getMidpoint().x;

			return 0;
		});
		set("getMidpointY", function(variable:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getMidpoint().y;

			return 0;
		});
		set("getGraphicMidpointX", function(variable:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getGraphicMidpoint().x;

			return 0;
		});
		set("getGraphicMidpointY", function(variable:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getGraphicMidpoint().y;

			return 0;
		});
		set("getScreenPositionX", function(variable:String, ?camera:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getScreenPosition().x;

			return 0;
		});
		set("getScreenPositionY", function(variable:String, ?camera:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getScreenPosition().y;

			return 0;
		});

		set("makeLuaSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0)
		{
			tag = tag.replace('.', '');
			LuaUtils.resetSpriteTag(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			if (image != null && image.length > 0)
			{
				leSprite.loadGraphic(Paths.image(image));
			}
			game.modchartSprites.set(tag, leSprite);
			leSprite.active = true;
		});
		set("makeAnimatedLuaSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0, ?spriteType:String = "sparrow")
		{
			tag = tag.replace('.', '');
			LuaUtils.resetSpriteTag(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);

			LuaUtils.loadFrames(leSprite, image, spriteType);
			game.modchartSprites.set(tag, leSprite);
		});

		set("makeGraphic", function(obj:String, width:Int = 256, height:Int = 256, color:String = 'FFFFFF')
		{
			var spr:FlxSprite = LuaUtils.getObjectDirectly(obj, false);
			if (spr != null)
				spr.makeGraphic(width, height, CoolUtil.colorFromString(color));
		});

		set("makeLuaCamera", function(tag:String, ?ddt:Bool)
		{
			if (ddt == null)
				ddt = false;
			var camera:FlxCamera = new FlxCamera();
			camera.bgColor.alpha = 0;
			FlxG.cameras.add(camera, ddt);
			game.modchartCameras.set(tag, camera);
		});
		set("addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true)
		{
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
			if (obj != null && obj.animation != null)
			{
				obj.animation.addByPrefix(name, prefix, framerate, loop);
				if (obj.animation.curAnim == null)
				{
					if (obj.playAnim != null)
						obj.playAnim(name, true);
					else
						obj.animation.play(name, true);
				}
				return true;
			}
			return false;
		});

		set("addAnimation", function(obj:String, name:String, frames:Array<Int>, framerate:Int = 24, loop:Bool = true)
		{
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
			if (obj != null && obj.animation != null)
			{
				obj.animation.add(name, frames, framerate, loop);
				if (obj.animation.curAnim == null)
				{
					obj.animation.play(name, true);
				}
				return true;
			}
			return false;
		});

		set("addAnimationByIndices", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24, loop:Bool = false)
		{
			return LuaUtils.addAnimByIndices(obj, name, prefix, indices, framerate, loop);
		});

		set("playAnim", function(obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0)
		{
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
			if (obj.playAnim != null)
			{
				obj.playAnim(name, forced, reverse, startFrame);
				return true;
			}
			else
			{
				if (obj.anim != null)
					obj.anim.play(name, forced, reverse, startFrame); // FlxAnimate
				else
					obj.animation.play(name, forced, reverse, startFrame);
				return true;
			}
			return false;
		});
		set("addOffset", function(obj:String, anim:String, x:Float, y:Float)
		{
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
			if (obj != null && obj.addOffset != null)
			{
				obj.addOffset(anim, x, y);
				return true;
			}
			return false;
		});

		set("setScrollFactor", function(obj:String, scrollX:Float, scrollY:Float)
		{
			if (game.getLuaObject(obj, false) != null)
			{
				game.getLuaObject(obj, false).scrollFactor.set(scrollX, scrollY);
				return;
			}

			var object:FlxObject = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if (object != null)
			{
				object.scrollFactor.set(scrollX, scrollY);
			}
		});

		set("addLuaSprite", function(tag:String, front:Bool = false)
		{
			var mySprite:FlxSprite = null;
			if (game.modchartSprites.exists(tag))
				mySprite = cast(game.modchartSprites.get(tag), FlxSprite);
			else if (game.variables.exists(tag))
				mySprite = cast(game.variables.get(tag), FlxSprite);

			if (mySprite == null)
				return false;

			if (front)
				LuaUtils.getTargetInstance().add(mySprite);
			else
			{
				if (!game.isDead)
					game.insert(game.members.indexOf(LuaUtils.getLowestCharacterGroup()), mySprite);
				else
					GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), mySprite);
			}
			return true;
		});
		set("setGraphicSize", function(obj:String, x:Int, y:Int = 0, updateHitbox:Bool = true)
		{
			if (game.getLuaObject(obj) != null)
			{
				var shit:FlxSprite = cast(game.getLuaObject(obj), FlxSprite);
				shit.setGraphicSize(x, y);
				if (updateHitbox)
					shit.updateHitbox();
				return;
			}

			var split:Array<String> = obj.split('.');
			var poop:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				poop = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (poop != null)
			{
				poop.setGraphicSize(x, y);
				if (updateHitbox)
					poop.updateHitbox();
				return;
			}
			luaTrace('setGraphicSize: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		set("scaleObject", function(obj:String, x:Float, y:Float, updateHitbox:Bool = true)
		{
			if (game.getLuaObject(obj) != null)
			{
				var shit:FlxSprite = cast(game.getLuaObject(obj), FlxSprite);
				shit.scale.set(x, y);
				if (updateHitbox)
					shit.updateHitbox();
				return;
			}

			var split:Array<String> = obj.split('.');
			var poop:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				poop = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (poop != null)
			{
				poop.scale.set(x, y);
				if (updateHitbox)
					poop.updateHitbox();
				return;
			}
			luaTrace('scaleObject: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		set("updateHitbox", function(obj:String)
		{
			if (game.getLuaObject(obj) != null)
			{
				var shit:FlxSprite = cast(game.getLuaObject(obj), FlxSprite);
				shit.updateHitbox();
				return;
			}

			var poop:FlxSprite = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if (poop != null)
			{
				poop.updateHitbox();
				return;
			}
			luaTrace('updateHitbox: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		set("updateHitboxFromGroup", function(group:String, index:Int)
		{
			if (Std.isOfType(Reflect.getProperty(LuaUtils.getTargetInstance(), group), FlxTypedGroup))
			{
				Reflect.getProperty(LuaUtils.getTargetInstance(), group).members[index].updateHitbox();
				return;
			}
			Reflect.getProperty(LuaUtils.getTargetInstance(), group)[index].updateHitbox();
		});

		set("removeLuaSprite", function(tag:String, destroy:Bool = true)
		{
			if (!game.modchartSprites.exists(tag))
			{
				return;
			}

			var pee:ModchartSprite = cast(game.modchartSprites.get(tag), ModchartSprite);
			LuaUtils.getTargetInstance().remove(pee, true);
			if (destroy)
			{
				pee.kill();
				pee.destroy();
				game.modchartSprites.remove(tag);
			}
		});

		set("luaSpriteExists", game.modchartSprites.exists);
		set("luaTextExists", game.modchartTexts.exists);
		set("luaSoundExists", game.modchartSounds.exists);

		set("setObjectCamera", function(obj:String, camera:String = '')
		{
			var real:FlxSprite = cast(game.getLuaObject(obj), FlxSprite);
			if (real != null)
			{
				real.cameras = [LuaUtils.cameraFromString(camera)];
				return true;
			}

			var split:Array<String> = obj.split('.');
			var object:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				object = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (object != null)
			{
				object.cameras = [LuaUtils.cameraFromString(camera)];
				return true;
			}
			luaTrace("setObjectCamera: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		set("setBlendMode", function(obj:String, blend:String = '')
		{
			var real:FlxSprite = cast(game.getLuaObject(obj), FlxSprite);
			if (real != null)
			{
				real.blend = LuaUtils.blendModeFromString(blend);
				return true;
			}

			var split:Array<String> = obj.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (spr != null)
			{
				spr.blend = LuaUtils.blendModeFromString(blend);
				return true;
			}
			luaTrace("setBlendMode: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		set("screenCenter", function(obj:String, pos:String = 'xy')
		{
			var spr:FlxSprite = cast(game.getLuaObject(obj), FlxSprite);

			if (spr == null)
			{
				var split:Array<String> = obj.split('.');
				spr = LuaUtils.getObjectDirectly(split[0]);
				if (split.length > 1)
				{
					spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
				}
			}

			if (spr != null)
			{
				switch (pos.trim().toLowerCase())
				{
					case 'x':
						spr.screenCenter(X);
						return;
					case 'y':
						spr.screenCenter(Y);
						return;
					default:
						spr.screenCenter(XY);
						return;
				}
			}
			luaTrace("screenCenter: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
		});
		set("objectsOverlap", function(obj1:String, obj2:String)
		{
			var namesArray:Array<String> = [obj1, obj2];
			var objectsArray:Array<FlxSprite> = [];
			for (i in 0...namesArray.length)
			{
				var real:FlxSprite = cast(game.getLuaObject(namesArray[i]), FlxSprite);
				if (real != null)
				{
					objectsArray.push(real);
				}
				else
				{
					objectsArray.push(Reflect.getProperty(LuaUtils.getTargetInstance(), namesArray[i]));
				}
			}

			if (!objectsArray.contains(null) && FlxG.overlap(objectsArray[0], objectsArray[1]))
			{
				return true;
			}
			return false;
		});
		set("getPixelColor", function(obj:String, x:Int, y:Int)
		{
			var split:Array<String> = obj.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (spr != null)
				return spr.pixels.getPixel32(x, y);
			return FlxColor.BLACK;
		});
		set("playMusic", function(sound:String, volume:Float = 1, loop:Bool = false)
		{
			FlxG.sound.playMusic(Paths.music(sound), volume, loop);
		});
		set("playSound", function(sound:String, volume:Float = 1, ?tag:String = null)
		{
			if (tag != null && tag.length > 0)
			{
				tag = tag.replace('.', '');
				if (game.modchartSounds.exists(tag))
				{
					game.modchartSounds.get(tag).stop();
				}
				game.modchartSounds.set(tag, FlxG.sound.play(Paths.sound(sound), volume, false, null, true, function()
				{
					game.modchartSounds.remove(tag);
					game.callOnLuas('onSoundFinished', [tag]);
				}));
				return;
			}
			FlxG.sound.play(Paths.sound(sound), volume);
		});
		set("stopSound", function(tag:String)
		{
			if (tag != null && tag.length > 1 && game.modchartSounds.exists(tag))
			{
				game.modchartSounds.get(tag).stop();
				game.modchartSounds.remove(tag);
			}
		});
		set("pauseSound", function(tag:String)
		{
			if (tag != null && tag.length > 1 && game.modchartSounds.exists(tag))
			{
				game.modchartSounds.get(tag).pause();
			}
		});
		set("resumeSound", function(tag:String)
		{
			if (tag != null && tag.length > 1 && game.modchartSounds.exists(tag))
			{
				game.modchartSounds.get(tag).play();
			}
		});
		set("soundFadeIn", function(tag:String, duration:Float, fromValue:Float = 0, toValue:Float = 1)
		{
			if (tag == null || tag.length < 1)
			{
				FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			}
			else if (game.modchartSounds.exists(tag))
			{
				game.modchartSounds.get(tag).fadeIn(duration, fromValue, toValue);
			}
		});
		set("soundFadeOut", function(tag:String, duration:Float, toValue:Float = 0)
		{
			if (tag == null || tag.length < 1)
			{
				FlxG.sound.music.fadeOut(duration, toValue);
			}
			else if (game.modchartSounds.exists(tag))
			{
				game.modchartSounds.get(tag).fadeOut(duration, toValue);
			}
		});
		set("soundFadeCancel", function(tag:String)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music.fadeTween != null)
				{
					FlxG.sound.music.fadeTween.cancel();
				}
			}
			else if (game.modchartSounds.exists(tag))
			{
				var theSound:FlxSound = game.modchartSounds.get(tag);
				if (theSound.fadeTween != null)
				{
					theSound.fadeTween.cancel();
					game.modchartSounds.remove(tag);
				}
			}
		});
		set("getSoundVolume", function(tag:String)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music != null)
				{
					return FlxG.sound.music.volume;
				}
			}
			else if (game.modchartSounds.exists(tag))
			{
				return game.modchartSounds.get(tag).volume;
			}
			return 0;
		});
		set("setSoundVolume", function(tag:String, value:Float)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music != null)
				{
					FlxG.sound.music.volume = value;
				}
			}
			else if (game.modchartSounds.exists(tag))
			{
				game.modchartSounds.get(tag).volume = value;
			}
		});
		set("getSoundTime", function(tag:String)
		{
			if (tag != null && tag.length > 0 && game.modchartSounds.exists(tag))
			{
				return game.modchartSounds.get(tag).time;
			}
			return 0;
		});
		set("setSoundTime", function(tag:String, value:Float)
		{
			if (tag != null && tag.length > 0 && game.modchartSounds.exists(tag))
			{
				var theSound:FlxSound = game.modchartSounds.get(tag);
				if (theSound != null)
				{
					var wasResumed:Bool = theSound.playing;
					theSound.pause();
					theSound.time = value;
					if (wasResumed)
						theSound.play();
				}
			}
		});

		#if FLX_PITCH
		set("getSoundPitch", function(tag:String)
		{
			if (tag != null && tag.length > 0 && game.modchartSounds.exists(tag))
			{
				return game.modchartSounds.get(tag).pitch;
			}
			return 0;
		});
		set("setSoundPitch", function(tag:String, value:Float, doPause:Bool = false)
		{
			if (tag != null && tag.length > 0 && game.modchartSounds.exists(tag))
			{
				var theSound:FlxSound = game.modchartSounds.get(tag);
				if (theSound != null)
				{
					var wasResumed:Bool = theSound.playing;
					if (doPause)
						theSound.pause();
					theSound.pitch = value;
					if (doPause && wasResumed)
						theSound.play();
				}
			}
		});
		#end

		// mod settings
		#if MODS_ALLOWED
		addLocalCallback("getModSetting", function(saveTag:String, ?modName:String = null)
		{
			if (modName == null)
			{
				if (this.modFolder == null)
				{
					FunkinLua.luaTrace('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', false, false, FlxColor.RED);
					return null;
				}
				modName = this.modFolder;
			}
			return LuaUtils.getModSetting(saveTag, modName);
		});
		#end
		//

		set("debugPrint", function(text:Dynamic = '', color:String = 'WHITE') FunkinLua.getCurrentMusicState().addTextToDebug(text, CoolUtil.colorFromString(color)));

		addLocalCallback("close", function()
		{
			closed = true;
			trace('Closing script $scriptName');
			return closed;
		});

		#if DISCORD_ALLOWED DiscordClient.addLuaCallbacks(this); #end
		#if HSCRIPT_ALLOWED HScript.implement(this); #end
		ReflectionFunctions.implement(this);
		TextFunctions.implement(this);
		ExtraFunctions.implement(this);
		CustomSubstate.implement(this);
		ShaderFunctions.implement(this);
		DeprecatedFunctions.implement(this);
		MobileFunctions.implement(this);
		#if MODCHARTS_ALLOWED modcharting.ModchartFuncs.loadLuaFunctions(this); #end
		#if android AndroidFunctions.implement(this); #end

		try
		{
			var isString:Bool = !FileSystem.exists(scriptName);
			var result:Dynamic = null;
			if (!isString)
				result = sys.FileSystem.exists(scriptName) ? LuaL.dofile(lua, scriptName) : LuaL.dostring(lua, File.getContent(scriptName));
			else
				result = LuaL.dostring(lua, scriptName);

			var resultStr:String = Lua.tostring(lua, result);
			if (resultStr != null && result != 0)
			{
				trace(resultStr);
				CoolUtil.showPopUp(resultStr, 'Error on lua script!');
				luaTrace('$scriptName\n$resultStr', true, false, FlxColor.RED);
				lua = null;
				return;
			}
			if (isString)
				scriptName = 'unknown';
		}
		catch (e:Dynamic)
		{
			trace('$scriptName: $e');
			return;
		}
		call('onCreate', []);
		trace('lua file loaded succesfully: $scriptName (${Std.int(Date.now().getTime() - times)}ms)');
		#end
	}

	// main
	public var lastCalledFunction:String = '';

	public static var lastCalledScript:FunkinLua = null;

	public function call(func:String, args:Array<Dynamic>):Dynamic
	{
		if (closed)
			return LuaUtils.Function_Continue;

		lastCalledFunction = func;
		lastCalledScript = this;
		#if LUA_ALLOWED
		try
		{
			if (lua == null)
				return LuaUtils.Function_Continue;

			Lua.getglobal(lua, func);
			var type:Int = Lua.type(lua, -1);

			if (type != Lua.TFUNCTION)
			{
				if (type > Lua.TNIL)
					luaTrace("ERROR (" + func + "): attempt to call a " + LuaUtils.typeToString(type) + " value", false, false, FlxColor.RED);

				Lua.pop(lua, 1);
				return LuaUtils.Function_Continue;
			}

			for (arg in args)
				Convert.toLua(lua, arg);
			var status:Int = Lua.pcall(lua, args.length, 1, 0);

			// Checks if it's not successful, then show a error.
			if (status != Lua.OK)
			{
				var error:String = getErrorMessage(status);
				luaTrace("ERROR (" + func + "): " + error, false, false, FlxColor.RED);
				return LuaUtils.Function_Continue;
			}

			// If successful, pass and then return the result.
			var result:Dynamic = cast Convert.fromLua(lua, -1);
			if (result == null)
				result = LuaUtils.Function_Continue;

			Lua.pop(lua, 1);
			if (closed)
				stop();
			return result;
		}
		catch (e:Dynamic)
		{
			trace(e);
		}
		#end
		return LuaUtils.Function_Continue;
	}

	public function set(variable:String, data:Dynamic)
	{
		#if LUA_ALLOWED
		if (lua == null)
			return;

		if (Type.typeof(data) == TFunction)
		{
			Convert.addCallback(lua, variable, data);
			return;
		}

		Convert.toLua(lua, data);
		Lua.setglobal(lua, variable);
		#end
	}

	public function stop()
	{
		closed = true;

		#if LUA_ALLOWED
		if (lua == null)
		{
			return;
		}
		Lua.close(lua);
		lua = null;
		#end
		#if HSCRIPT_ALLOWED
		if (hscript != null)
		{
			hscript.destroy();
			hscript = null;
		}
		#end
	}

	function oldTweenFunction(tag:String, vars:String, tweenValue:Any, duration:Float, ease:String, funcName:String)
	{
		var target:Dynamic = LuaUtils.tweenPrepare(tag, vars);
		if (target != null)
		{
			FunkinLua.getCurrentMusicState().modchartTweens.set(tag, FlxTween.tween(target, tweenValue, duration, {
				ease: LuaUtils.getTweenEaseByString(ease),
				onComplete: function(twn:FlxTween)
				{
					FunkinLua.getCurrentMusicState().modchartTweens.remove(tag);
					FunkinLua.getCurrentMusicState().callOnLuas('onTweenCompleted', [tag, vars]);
				}
			}));
		}
		else
		{
			luaTrace('$funcName: Couldnt find object: $vars', false, false, FlxColor.RED);
		}
	}

	public static function luaTrace(text:String, ignoreCheck:Bool = false, deprecated:Bool = false, color:FlxColor = FlxColor.WHITE)
	{
		if (ignoreCheck || getBool('luaDebugMode'))
		{
			if (deprecated && !getBool('luaDeprecatedWarnings'))
			{
				return;
			}
			FunkinLua.getCurrentMusicState().addTextToDebug(text, color);
		}
	}

	public static function getBool(variable:String)
	{
		if (lastCalledScript == null)
			return false;

		#if LUA_ALLOWED
		var lua:State = lastCalledScript.lua;
		if (lua == null)
			return false;

		var result:String = null;
		Lua.getglobal(lua, variable);
		result = Convert.fromLua(lua, -1);
		Lua.pop(lua, 1);

		if (result == null)
		{
			return false;
		}
		return (result == 'true');
		#else
		return false;
		#end
	}

	function findScript(scriptFile:String, ext:String = '.lua')
	{
		if (!scriptFile.endsWith(ext))
			scriptFile += ext;
		var preloadPath:String = Paths.getSharedPath(scriptFile);
		#if MODS_ALLOWED
		var path:String = Paths.modFolders(scriptFile);
		if (FileSystem.exists(scriptFile))
			return scriptFile;
		else if (FileSystem.exists(path))
			return path;

		if (FileSystem.exists(preloadPath))
		#else
		if (Assets.exists(preloadPath))
		#end
		{
			return preloadPath;
		}
		return null;
	}

	public function getErrorMessage(status:Int):String
	{
		#if LUA_ALLOWED
		var v:String = Lua.tostring(lua, -1);
		Lua.pop(lua, 1);

		if (v != null)
			v = v.trim();
		if (v == null || v == "")
		{
			switch (status)
			{
				case type if (type == Lua.ERRRUN):
					return "Runtime Error";
				case type if (type == Lua.ERRMEM):
					return "Memory Allocation Error";
				case type if (type == Lua.ERRERR):
					return "Critical Error";
			}
			return "Unknown Error";
		}

		return v;
		#else
		return null;
		#end
	}

	public function addLocalCallback(name:String, myFunction:Dynamic)
	{
		#if LUA_ALLOWED
		callbacks.set(name, myFunction);
		Convert.addCallback(lua, name, null); // just so that it gets called
		#end
	}

	#if !flash
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	#end

	public function initLuaShader(name:String)
	{
		if (!ClientPrefs.data.shaders)
			return false;

		#if !flash
		if (runtimeShaders.exists(name))
		{
			var shaderData:Array<String> = runtimeShaders.get(name);
			if (shaderData != null && (shaderData[0] != null || shaderData[1] != null))
			{
				luaTrace('Shader $name was already initialized!');
				return true;
			}
		}

		#if MODS_ALLOWED
		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Mods.currentModDirectory + '/shaders/'));

		for (mod in Mods.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));

		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;
				if (FileSystem.exists(frag))
				{
					frag = File.getContent(frag);
					found = true;
				}
				else
					frag = null;

				if (FileSystem.exists(vert))
				{
					vert = File.getContent(vert);
					found = true;
				}
				else
					vert = null;

				if (found)
				{
					runtimeShaders.set(name, [frag, vert]);
					// trace('Found shader $name!');
					return true;
				}
			}
		}
		#else
		final folder:String = Paths.getSharedPath('shaders/');
		var frag:String = folder + name + '.frag';
		var vert:String = folder + name + '.vert';
		var found:Bool = false;
		if (Assets.exists(frag))
		{
			frag = Assets.getText(frag);
			found = true;
		}
		else
			frag = null;

		if (Assets.exists(vert))
		{
			vert = Assets.getText(vert);
			found = true;
		}
		else
			vert = null;

		if (found)
		{
			runtimeShaders.set(name, [frag, vert]);
			// trace('Found shader $name!');
			return true;
		}
		#end
		luaTrace('Missing shader $name .frag AND .vert files!', false, false, FlxColor.RED);
		#else
		luaTrace('This platform doesn\'t support Runtime Shaders!', false, false, FlxColor.RED);
		#end
		return false;
	}

	public static function getCurrentMusicState():Dynamic
	{
		final s = FlxG.state;
		if (s.subState != null && Std.isOfType(s.subState, MusicBeatSubstate))
			return cast(s.subState, MusicBeatSubstate);
		return Std.isOfType(s, MusicBeatState) ? cast(s, MusicBeatState) : null;
	}
}

#if LUA_ALLOWED
typedef State = cpp.RawPointer<Lua_State>;
#end
