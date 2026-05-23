package backend.scripting;

import psychlua.ScriptedState;
import psychlua.ScriptedSubState;

class ModsStateRedirect
{
	static var redirects:Map<String, String> = new Map<String, String>();
	static var loaded:Bool = false;

	public static function loadRedirects():Void
	{
		redirects = new Map<String, String>();
		loaded = true;

		#if FEATURE_MODS
		for (mod in Mods.getGlobalMods())
		{
			var path:String = Paths.mods(mod + '/data/redirects.txt');
			if (FileSystem.exists(path))
				loadRedirectFile(path);
		}

		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
		{
			var path:String = Paths.mods(Mods.currentModDirectory + '/data/redirects.txt');
			if (FileSystem.exists(path))
				loadRedirectFile(path);
		}
		#end

		var path:String = Paths.getSharedPath('data/redirects.txt');
		if (FileSystem.exists(path))
			loadRedirectFile(path);
	}

	static function loadRedirectFile(path:String):Void
	{
		try
		{
			var content:String = File.getContent(path);
			var lines:Array<String> = content.split('\n');
			for (line in lines)
			{
				line = line.trim();
				if (line.length == 0 || line.startsWith('#'))
					continue;

				var parts:Array<String> = line.split(':');
				if (parts.length >= 2)
				{
					var originalState:String = parts[0].trim();
					var redirectState:String = parts[1].trim();
					if (!redirects.exists(originalState))
						redirects.set(originalState, redirectState);
				}
			}
		}
		catch (e:Dynamic)
		{
			trace('Failed to load redirects from $path: $e');
		}
	}

	public static function redirect(state:Class<FlxState>, arguments:Array<Dynamic>):FlxState
	{
		if (state == null)
			return null;
		if (!loaded)
			loadRedirects();

		var className:String = getClassName(state);
		if (className == null)
			return Type.createInstance(state, arguments);

		var redirectTarget:String = redirects.get(className);
		if (redirectTarget != null && redirectTarget.length > 0)
		{
			// trace('State redirect: $className -> $redirectTarget');
			return new ScriptedState(redirectTarget, arguments);
		}

		return Type.createInstance(state, arguments);
	}

	public static function redirectSubstate(subState:Class<FlxSubState>, arguments:Array<Dynamic>):FlxSubState
	{
		if (subState == null)
			return null;
		if (!loaded)
			loadRedirects();

		var className:String = getClassName(subState);
		if (className == null)
			return Type.createInstance(subState, arguments);

		var redirectTarget:String = redirects.get(className);
		if (redirectTarget != null && redirectTarget.length > 0)
		{
			// trace('Substate redirect: $className -> $redirectTarget');
			return new ScriptedSubState(redirectTarget, arguments);
		}

		return Type.createInstance(subState, arguments);
	}

	static function getClassName(obj:Class<Dynamic>):Null<String>
	{
		var className:String = Type.getClassName(obj);
		if (className == null)
			return null;

		var dotIndex:Int = className.lastIndexOf('.');
		if (dotIndex >= 0)
			className = className.substr(dotIndex + 1);

		return className;
	}
}
