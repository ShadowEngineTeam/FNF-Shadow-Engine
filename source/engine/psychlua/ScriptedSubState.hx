package psychlua;

@:keep
@:nullSafety(Off)
class ScriptedSubState extends MusicBeatSubstate
{
	public static var instance:ScriptedSubState;

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

		callOnSubStateScripts('new', args);

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		super.update(elapsed);
	}

	public function callOnSubStateScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, excludeValues:Array<Dynamic> = null):Dynamic
	{
		#if (FEATURE_HSCRIPT || FEATURE_LUA)
		var musicState:MusicBeatSubstate = MusicBeatSubstate.instance;
		var excludedScripts = [#if FEATURE_LUA for (script in musicState.luaArray) script.scriptName #end].concat([#if FEATURE_HSCRIPT for (script in musicState.hscriptArray) script.origin #end]);
		excludedScripts.remove(scriptFile);

		return musicState.callOnScripts(funcToCall, args, ignoreStops, excludedScripts, excludeValues);
		#else
		return null;
		#end
	}
}
