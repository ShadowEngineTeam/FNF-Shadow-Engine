package psychlua;

@:keep
class ScriptedState extends MusicBeatState
{
	public var scriptFile:String;

	public function new(scriptFile:String)
	{
		this.scriptFile = scriptFile;
		super();
	}

	override function create()
	{
		#if FEATURE_HSCRIPT
		initHScript(this.scriptFile);
		#end

		super.create();

		callOnScripts('onCreatePost');
	}
}
