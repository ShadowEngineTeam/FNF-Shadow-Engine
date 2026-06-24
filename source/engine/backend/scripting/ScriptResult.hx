package backend.scripting;

enum abstract ScriptResult(String)
{
	public var Continue = "##PSYCHLUA_FUNCTIONCONTINUE";
	public var Stop = "##PSYCHLUA_FUNCTIONSTOP";
	public var StopLua = "##PSYCHLUA_FUNCTIONSTOPLUA";
	public var StopHScript = "##PSYCHLUA_FUNCTIONSTOPHSCRIPT";
	public var StopAll = "##PSYCHLUA_FUNCTIONSTOPALL";
}
