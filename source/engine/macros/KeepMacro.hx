// https://github.com/CodenameCrew/CodenameEngine/blob/304bbe12fda74feb843d68858a682528efa90932/source/funkin/backend/system/macros/Macros.hx
package macros;

#if macro
import haxe.macro.*;
import haxe.macro.Expr;

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
			// OPENFL SYSTEM
			"openfl.system",
			// VIDEOS
			#if FEATURE_VIDEOS
			"hxvlc.flixel",
			"hxvlc.openfl",
			#end
			// BASE HAXE
			"DateTools",
			"EReg",
			"Lambda",
			"StringBuf",
			"haxe.crypto",
			"haxe.display",
			"haxe.exceptions",
			"haxe.extern"
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
	}
}
#end
