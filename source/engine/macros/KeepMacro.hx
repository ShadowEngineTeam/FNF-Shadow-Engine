// https://github.com/CodenameCrew/CodenameEngine/blob/304bbe12fda74feb843d68858a682528efa90932/source/funkin/backend/system/macros/Macros.hx
package macros;

#if macro
import haxe.macro.*;
import haxe.macro.Expr;

@:nullSafety
class KeepMacro
{
	public static function keepClasses()
	{
		for (inc in [
			// FLIXEL
			"flixel.animation",
			"flixel.effects",
			"flixel.graphics",
			"flixel.group",
			"flixel.input",
			"flixel.math",
			"flixel.path",
			"flixel.sound",
			"flixel.system.debug",
			"flixel.system.frontEnds",
			"flixel.system.replay",
			"flixel.system.scaleModes",
			"flixel.system.ui",
			"flixel.text",
			"flixel.tile",
			"flixel.tweens",
			"flixel.ui",
			"flixel.util",
			// FLIXEL ADDONS
			"flixel.addons.api",
			"flixel.addons.display",
			// "flixel.addons.editors",
			"flixel.addons.effects",
			// "flixel.addons.nape",
			"flixel.addons.plugin",
			"flixel.addons.text",
			"flixel.addons.tile",
			"flixel.addons.transition",
			"flixel.addons.util",
			"flixel.addons.weapon",
			// FLIXEL ANIMATE
			"animate",
			// OPENFL
			"openfl.display",
			"openfl.display3D",
			"openfl.errors",
			"openfl.events",
			"openfl.filters",
			"openfl.geom",
			"openfl.media",
			"openfl.system",
			"openfl.text",
			"openfl.ui",
			"openfl.utils",
			// LIME
			"lime.app",
			"lime.graphics",
			"lime.media",
			"lime.system",
			"lime.ui",
			"lime.utils",
			// HXVLC & HXCODEC WRAPPERS
			#if FEATURE_VIDEOS
			"hxcodec",
			"hxcodec.flixel",
			"hxcodec.openfl",
			"hxvlc.flixel",
			"hxvlc.openfl",
			"vlc",
			#end
			#if FEATURE_DISCORD_RPC
			"hxdiscord_rpc",
			#end
			#if FEATURE_LUA
			"hxluau",
			#end
			#if FEATURE_HSCRIPT
			"hscript",
			#end
			"psychlua",
			// BASE HAXE
			"DateTools",
			"EReg",
			"Lambda",
			"StringBuf",
			"haxe.CallStack",
			"haxe.Constraints",
			"haxe.crypto",
			"haxe.display",
			"haxe.ds",
			"haxe.exceptions",
			"haxe.extern",
			"haxe.format",
			"haxe.Int64",
			"haxe.io",
			"haxe.iterators",
			"haxe.Json",
			"haxe.Timer",
			// SHADOW ENGINE
			"engine",
			"backend",
			"states",
			"substates",
			"objects",
			"cutscenes",
			"debug",
			"options",
			"shaders",
		])
			Compiler.include(inc);

		var compathx4 = [
			"sys.db.Sqlite",
			"sys.db.Mysql",
			"sys.db.Connection",
			"sys.db.ResultSet",
			"haxe.remoting.Proxy",
		];

		if (Context.defined("sys"))
		{
			for (inc in ["sys", "openfl.net"])
				Compiler.include(inc, compathx4);
		}

		if (Context.defined("FEATURE_FUNKIN_CONTENT"))
			Compiler.include("funkin.vis");
	}
}
#end
