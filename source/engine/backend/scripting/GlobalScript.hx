package backend.scripting;

import haxe.io.Path;
import backend.Mods;
import backend.Paths;
import backend.io.FileSystem;
import flixel.FlxG;
import flixel.FlxState;

class GlobalScript
{
	public static var hscriptArray:Array<psychlua.HScript> = new Array<psychlua.HScript>();
	public static var luaArray:Array<psychlua.FunkinLua> = new Array<psychlua.FunkinLua>();

	private static var initialized:Bool = false;
	private static final hscriptExtensions:Array<String> = ['hx', 'hscript', 'hxs', 'hxc'];
	private static final luaExtensions:Array<String> = ['lua', 'luau'];

	public static function init()
	{
		if (initialized)
			return;

		initialized = true;
		loadAll();
		hookSignals();
	}

	static function loadAll()
	{
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'data/global/'))
		{
			if (!FileSystem.exists(folder))
				continue;

			for (file in FileSystem.readDirectory(folder))
			{
				var ext:String = Path.extension(file);
				var path:String = folder + file;

				#if FEATURE_HSCRIPT
				if (hscriptExtensions.contains(ext))
				{
					if (hscript.SScript.global.exists(path))
						continue;

					var script = new psychlua.HScript(null, path);
					if (script.parsingException != null)
					{
						reportError('GlobalScript ERROR: ${script.parsingException.message}');
						script.destroy();
						continue;
					}
					hscriptArray.push(script);
				}
				#end

				#if FEATURE_LUA
				if (luaExtensions.contains(ext))
				{
					var luaScript = new psychlua.FunkinLua(path);
					if (luaScript.lua == null)
						continue;

					var curState = psychlua.FunkinLua.getCurrentMusicState();
					if (curState != null)
						curState.luaArray.remove(luaScript);
					luaArray.push(luaScript);
				}
				#end
			}
		}
	}

	public static function reload()
	{
		#if FEATURE_HSCRIPT
		for (script in hscriptArray)
			if (script != null)
				script.destroy();
		hscriptArray.resize(0);
		hscript.SScript.global.clear();
		#end

		#if FEATURE_LUA
		for (script in luaArray)
			if (script != null)
			{
				script.call('onDestroy', []);
				script.stop();
			}
		luaArray.resize(0);
		#end

		loadAll();
	}

	static function hookSignals()
	{
		FlxG.signals.focusGained.add(function()
		{
			call("onFocusGained");
		});

		FlxG.signals.focusLost.add(function()
		{
			call("onFocusLost");
		});

		FlxG.signals.gameResized.add(function(w:Int, h:Int)
		{
			call("onGameResized", [w, h]);
		});

		FlxG.signals.postDraw.add(function()
		{
			call("onDrawPost");
		});

		FlxG.signals.preDraw.add(function()
		{
			call("onDrawPre");
		});

		FlxG.signals.preStateSwitch.add(function()
		{
			call("onStateSwitchPre");
		});

		FlxG.signals.postStateSwitch.add(function()
		{
			call("onStateSwitchPost");
		});

		FlxG.signals.preStateCreate.add(function(state:FlxState)
		{
			if (Std.isOfType(state, IMusicState))
			{
				var musicState:IMusicState = cast state;
				musicState.callOnScripts("onStateCreatePre", [state]);
			}
		});
	}

	static function call(func:String, ?args:Array<Dynamic>)
	{
		if (args == null)
			args = [];

		#if FEATURE_HSCRIPT
		for (script in hscriptArray)
		{
			if (script == null)
				continue;
			if (script.exists(func))
			{
				try
				{
					script.call(func, args);
				}
				catch (e:Dynamic)
				{
				}
			}
		}
		#end

		#if FEATURE_LUA
		for (script in luaArray)
		{
			if (script == null || script.closed)
				continue;
			try
			{
				script.call(func, args);
			}
			catch (e:Dynamic)
			{
			}
		}
		#end
	}

	static function reportError(msg:String)
	{
		if (FlxG.state != null && Std.isOfType(FlxG.state, MusicBeatState))
			cast(FlxG.state, MusicBeatState).addTextToDebug(msg, 0xFFFF0000);
	}

	public static function destroy()
	{
		#if FEATURE_HSCRIPT
		for (script in hscriptArray)
			if (script != null)
				script.destroy();
		hscriptArray = [];
		#end

		#if FEATURE_LUA
		for (script in luaArray)
			if (script != null)
			{
				script.call('onDestroy', []);
				script.stop();
			}
		luaArray = [];
		#end

		initialized = false;
	}
}
