package psychlua;

@:keep
class ScriptedState extends MusicBeatState
{
	public static var instance:ScriptedState;

	public var scriptFile:String;

	public function new(scriptFile:String)
	{
		this.scriptFile = scriptFile;
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
		startLuasNamed(scriptBase + '.lua');
		#end

		#if FEATURE_HSCRIPT
		startHScriptsNamed(scriptBase);
		#end

		super.create();
	}

	public static function implement(funk:FunkinLua)
	{
		funk.set("switchScriptedState", function(state:String)
		{
			FlxG.switchState(new ScriptedState(state));
		});

		funk.set("openScriptedSubState", function(substate:String)
		{
			if (FunkinLua.getCurrentMusicState() != null)
				FunkinLua.getCurrentMusicState().openSubState(new ScriptedSubState(substate));
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
}
