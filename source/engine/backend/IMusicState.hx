package backend;

import flixel.FlxBasic;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxSave;
import backend.PsychCamera;

interface IMusicState
{
	public var stateInstance:FlxState;

	public var members(default, null):Array<FlxBasic>;

	public var persistentDraw:Bool;
	public var persistentUpdate:Bool;

	private var curSection:Int;
	private var stepsToDo:Int;

	private var curStep:Int;
	private var curBeat:Int;

	private var curDecStep:Float;
	private var curDecBeat:Float;

	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScript>;
	public final hscriptExtensions:Array<String>;
	public var instancesExclude:Array<String>;
	#end

	public var modchartTweens:Map<String, FlxTween>;
	public var modchartSprites:Map<String, ModchartSprite>;
	public var modchartTimers:Map<String, FlxTimer>;
	public var modchartSounds:Map<String, FlxSound>;
	public var modchartTexts:Map<String, FlxText>;
	public var modchartSaves:Map<String, FlxSave>;
	public var modchartCameras:Map<String, FlxCamera>;

	#if LUA_ALLOWED
	public var luaArray:Array<FunkinLua>;
	#end

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	private var luaDebugGroup:FlxTypedGroup<psychlua.DebugLuaText>;
	private var luaDebugCam:FlxCamera;
	private var currentClassName:String;
	#end

	public var variables:Map<String, Dynamic>;

	public var controls(get, never):Controls;

	private function get_controls():Controls;

	public var touchPad:TouchPad;
	public var touchPadCam:FlxCamera;
	public var luaTouchPad:TouchPad;
	public var luaTouchPadCam:FlxCamera;
	public var mobileControls:IMobileControls;
	public var mobileControlsCam:FlxCamera;

	public function remove(basic:FlxBasic, splice:Bool = false):FlxBasic;

	public function addTouchPad(DPad:String, Action:String):Void;
	public function removeTouchPad():Void;
	public function addMobileControls(defaultDrawTarget:Bool = false):Void;
	public function removeMobileControls():Void;
	public function addTouchPadCamera(defaultDrawTarget:Bool = false):Void;
	public function makeLuaTouchPad(DPadMode:String, ActionMode:String):Void;
	public function addLuaTouchPad():Void;
	public function addLuaTouchPadCamera(defaultDrawTarget:Bool = false):Void;
	public function removeLuaTouchPad():Void;
	public function luaTouchPadPressed(button:Dynamic):Bool;
	public function luaTouchPadJustPressed(button:Dynamic):Bool;
	public function luaTouchPadJustReleased(button:Dynamic):Bool;
	public function luaTouchPadReleased(button:Dynamic):Bool;

	public function openSubState(subState:FlxSubState):Void;
	public function closeSubState():Void;

	private function updateSection():Void;
	private function rollbackSection():Void;
	private function updateBeat():Void;
	private function updateCurStep():Void;
	public function stepHit():Void;
	public function beatHit():Void;
	public function sectionHit():Void;
	function getBeatsOnSection():Null<Float>;

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	public function addTextToDebug(text:String, color:FlxColor):Void;
	#end

	public function getLuaObject(tag:String, text:Bool = true):FlxSprite;

	#if LUA_ALLOWED
	public function startLuasNamed(luaFile:String):Bool;
	#end

	#if HSCRIPT_ALLOWED
	public function startHScriptsNamed(scriptFile:String, ?doFileMethod:String->Bool):Bool;
	public function initHScript(file:String):Void;
	#end

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops:Bool = false, exclusions:Array<String> = null,
		excludeValues:Array<Dynamic> = null):Dynamic;

	public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops:Bool = false, exclusions:Array<String> = null,
		excludeValues:Array<Dynamic> = null):Dynamic;

	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null,
		excludeValues:Array<Dynamic> = null):Dynamic;

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null):Void;
	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null):Void;
	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null):Void;
}
