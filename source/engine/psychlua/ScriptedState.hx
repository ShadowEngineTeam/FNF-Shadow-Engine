package psychlua;

@:keep
class ScriptedState extends MusicBeatState
{
	public static var instance:ScriptedState;

	public var scriptFile:String;
	public var args:Array<Dynamic>;

	public function new(scriptFile:String, args:Array<Dynamic>)
	{
		this.scriptFile = scriptFile;
		this.args = args;
		super();
	}

	override function create()
	{
		instance = this;

		var scriptBase:String = this.scriptFile;
		var ext:String = haxe.io.Path.extension(scriptBase);
		if (ext != null)
			scriptBase = scriptBase.substr(0, scriptBase.length - ext.length - 1);

		#if FEATURE_LUA
		startLuasNamed(scriptBase);
		#end

		#if FEATURE_HSCRIPT
		startHScriptsNamed(scriptBase);
		#end

		callOnStateScripts('new', args);

		super.create();
	}

	public static function implement(funk:FunkinLua)
	{
		funk.set("switchScriptedState", function(state:String, args:Array<Dynamic>)
		{
			FlxG.switchState(new ScriptedState(state, args));
		});

		funk.set("openScriptedSubState", function(substate:String, args:Array<Dynamic>)
		{
			if (FunkinLua.getCurrentMusicState() != null)
				FunkinLua.getCurrentMusicState().openSubState(new ScriptedSubState(substate, args));
		});

		funk.set("closeScriptedSubState", function()
		{
			if (FunkinLua.getCurrentMusicState() != null)
				FunkinLua.getCurrentMusicState().closeSubState();
		});
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		super.update(elapsed);
	}

	public function callOnStateScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, excludeValues:Array<Dynamic> = null):Dynamic
	{
		#if (FEATURE_HSCRIPT || FEATURE_LUA)
		var musicState:MusicBeatState = MusicBeatState.getState();
		var excludedScripts = [#if FEATURE_LUA for (script in musicState.luaArray) script.scriptName #end].concat([#if FEATURE_HSCRIPT for (script in musicState.hscriptArray) script.origin #end]);
		excludedScripts.remove(scriptFile);

		return musicState.callOnScripts(funcToCall, args, ignoreStops, excludedScripts, excludeValues);
		#else
		return null;
		#end
	}
}
