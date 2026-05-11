
package psychlua;

@:keep
class ScriptedSubState extends MusicBeatSubstate
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
