package backend;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import debug.codename.Framerate;
import flixel.FlxGame;

#if desktop
import flixel.addons.transition.FlxTransitionableState;
import flixel.input.keyboard.FlxKey;
#end

class Main extends Sprite
{
	public static var fpsVar:Framerate;

	public static function main():Void
	{
		openfl.Lib.current.addChild(new Main());

		#if cpp
		cpp.NativeGc.enable(true);
		#end
	}

	public function new():Void
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

		stage != null ? init() : addEventListener(Event.ADDED_TO_STAGE, init);
	}

	function init(?e:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);

		#if android
		final file:String = haxe.io.Path.addTrailingSlash(lime.system.System.applicationStorageDirectory) + "useExternal.txt";
		if (!FileSystem.exists(file))
		{
			File.saveContent(file, 'false');
			Sys.setCwd(StorageUtil.getStorageDirectory());
		}
		#end

		setupGame();
	}

	function setupGame():Void
	{
		final gaym:FlxGame = new FlxGame(1280, 720, states.InitState, 60, 60, true, false);
		untyped FlxG.cameras = new backend.rendering.ShadowCameraFrontEnd();

		#if !html5
		@:privateAccess
		gaym._customSoundTray = objects.CustomSoundTray;
		#end

		addChild(gaym);

		@:privateAccess
		FlxG.game.addChildAt(fpsVar = new Framerate(), FlxG.game.getChildIndex(FlxG.game._inputContainer) + 1);
		debug.codename.SystemInfo.init();

		final mouseSprite:Sprite = new Sprite();
        FlxG.game.addChildAt(mouseSprite, FlxG.game.getChildIndex(fpsVar) + 1);
        untyped FlxG.mouse.cursorContainer = mouseSprite;

		FlxG.stage.align = "tl";
		FlxG.stage.scaleMode = NO_SCALE;

		#if FEATURE_HAPTICS
		extension.haptics.Haptic.initialize();
		#end

		if (fpsVar != null)
			fpsVar.visible = true;

		#if desktop
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, (e:KeyboardEvent) ->
		{
			if (Controls.instance?.justReleased('fullscreen'))
				FlxG.fullscreen = !FlxG.fullscreen;
		});

		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, (e:KeyboardEvent) ->
		{
			if (e.shiftKey && e.keyCode == FlxKey.F4)
			{
				FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
				Paths.clearStoredMemory();
				Funkin.switchState(states.MainMenuState);
			}
		});

		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, (e:KeyboardEvent) ->
		{
			if (e.shiftKey && e.keyCode == FlxKey.F5)
				FlxG.resetState();
		});
		#end

		// shader coords fix
		FlxG.signals.gameResized.add((w:Int, h:Int) ->
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

	static inline function resetSpriteCache(sprite:Sprite):Void
	{
		@:privateAccess
		{
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}
}