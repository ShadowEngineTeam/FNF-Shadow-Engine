package psychlua;

@:keep
class ScriptedSubState extends MusicBeatSubstate
{
	public static var instance:ScriptedSubState;

	public var scriptFile:String;

	public function new(scriptFile:String)
	{
		instance = this;
		this.scriptFile = scriptFile;
		super();
	}

	override function create()
	{
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

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		super.update(elapsed);
	}
}
