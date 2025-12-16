package backend;

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
import lime.ui.WindowVSyncMode;
import states.TitleState;
import openfl.events.KeyboardEvent;
#if (linux && !debug)
import hxgamemode.GamemodeClient;
#end

#if windows
@:buildXml('
<target id="haxe">
	<lib name="wininet.lib" if="windows" />
	<lib name="dwmapi.lib" if="windows" />
</target>
')
@:cppFileCode('
#include <windows.h>
#include <winuser.h>
')
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
		#end

		#if (cpp && windows)
		untyped __cpp__("
			SetProcessDPIAware(); // allows for more crisp visuals
			SetConsoleOutputCP(CP_UTF8);
			DisableProcessWindowsGhosting() // lets you move the window and such if it's not responding
		");
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

		addChild(fpsVar = new Framerate());
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

		FlxG.stage.application.window.setVSyncMode(ClientPrefs.data.vsync ? WindowVSyncMode.ON : WindowVSyncMode.OFF);

		// shader coords fix
		FlxG.signals.gameResized.add(function(w, h)
		{
			if (fpsVar != null)
				fpsVar.setScale(Math.min(Lib.current.stage.stageWidth / FlxG.width, Lib.current.stage.stageHeight / FlxG.height));

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
}
