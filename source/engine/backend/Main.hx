package backend;

import flixel.addons.transition.FlxTransitionableState;
import states.MainMenuState;
import flixel.input.keyboard.FlxKey;
import debug.codename.Framerate;
import flixel.graphics.FlxGraphic;
import flixel.FlxGame;
import flixel.FlxState;
import haxe.io.Path;
import openfl.Assets;
import openfl.system.System;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import lime.system.System as LimeSystem;
import lime.app.Application;
#if native
import lime.ui.WindowVSyncMode;
#end
import states.TitleState;
import openfl.events.KeyboardEvent;
#if (linux && !debug)
import hxgamemode.GamemodeClient;
#end

class Main extends Sprite
{
	public static final game = {
		width: 1280, // game width
		height: 720, // game height
		initialState: TitleState, // initial game state
		zoom: -1.0, // game state bounds
		framerate: 60, // default framerate
		skipSplash: true, // if the flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public static var fpsVar:Framerate;

	@:noCompletion
	private static function __init__():Void
	{
		#if (linux && !debug)
		if (GamemodeClient.request_start() != 0)
		{
			Sys.println('Failed to request gamemode start: ${GamemodeClient.error_string()}...');
			// Sys.exit(1);
		}
		else
			Sys.println('Succesfully requested gamemode to start...');
		#end
	}

	public static function main():Void
	{
		Lib.current.addChild(new Main());
		#if cpp
		cpp.NativeGc.enable(true);
		#elseif hl
		hl.Gc.enable(true);
		#end
	}

	public function new()
	{
		backend.CrashHandler.init();
		#if mobile
		Sys.setCwd(StorageUtil.getStorageDirectory());
		#if android
		StorageUtil.requestPermissions();
		#end
		mobile.backend.io.Assets.init();
		#end
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		#if android
		if (!FileSystem.exists(haxe.io.Path.addTrailingSlash(lime.system.System.applicationStorageDirectory) + "useExternal.txt"))
		{
			File.saveContent(haxe.io.Path.addTrailingSlash(lime.system.System.applicationStorageDirectory) + "useExternal.txt", 'false');
			Sys.setCwd(StorageUtil.getStorageDirectory());
		}
		#end

		setupGame();
	}

	private function setupGame():Void
	{
		if (game.zoom == -1.0)
			game.zoom = 1.0;

		#if VIDEOS_ALLOWED
		hxvlc.util.Handle.init();
		#end

		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();

		final funkinGame:FlxGame = new FlxGame(game.width, game.height, game.initialState, #if (flixel < "5.0.0") game.zoom, #end game.framerate,
			game.framerate, game.skipSplash, game.startFullscreen);

		@:privateAccess
		{
			final soundFrontEnd:flixel.system.frontEnds.SoundFrontEnd = new objects.CustomSoundTray.CustomSoundFrontEnd();
			FlxG.sound = soundFrontEnd;
			funkinGame._customSoundTray = objects.CustomSoundTray.CustomSoundTray;
		}

		addChild(funkinGame);

		FlxG.game.addChild(fpsVar = new Framerate());
		debug.codename.SystemInfo.init();

		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		#if mobile
		//FlxG.game.stage.quality = openfl.display.StageQuality.LOW;
		#end
		if (fpsVar != null)
			fpsVar.visible = true;

		#if desktop
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, toggleFullScreen);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, emergencyEject);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, hotReload);
		#end

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end

		#if mobile
		LimeSystem.allowScreenTimeout = ClientPrefs.data.screensaver;
		#end

		#if android
		FlxG.android.preventDefaultKeys = [BACK];
		#end

		#if native
		FlxG.stage.application.window.setVSyncMode(ClientPrefs.data.vsync ? WindowVSyncMode.ON : WindowVSyncMode.OFF);
		#end

		// shader coords fix
		FlxG.signals.gameResized.add(function(w, h)
		{
			if (FlxG.cameras != null)
			{
				for (cam in FlxG.cameras.list)
				{
					if (cam != null && cam.filters != null)
						resetSpriteCache(cam.flashSprite);
				}
			}

			if (FlxG.game != null)
				resetSpriteCache(FlxG.game);
		});
	}

	static function resetSpriteCache(sprite:Sprite):Void
	{
		@:privateAccess
		{
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	function toggleFullScreen(event:KeyboardEvent):Void
	{
		if (Controls.instance.justReleased('fullscreen'))
			FlxG.fullscreen = !FlxG.fullscreen;
	}

	function emergencyEject(event:KeyboardEvent):Void
	{
		if (event.shiftKey && event.keyCode == FlxKey.F4)
		{
			FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
			FlxG.switchState(new MainMenuState());
			Paths.clearStoredMemory();
		}
	}

	function hotReload(event:KeyboardEvent):Void
	{
		if (event.shiftKey && event.keyCode == FlxKey.F5)
		{
			// SHADOW TODO: maybe do some real hot reloading in the future...
			FlxG.resetState();
		}
	}
}
