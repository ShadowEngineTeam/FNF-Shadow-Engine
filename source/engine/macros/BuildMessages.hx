package macros;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;

/**
 * Prints the build steps when they happen. Lime is done configuring once Haxe starts,
 * and hxcpp echoes the second message as it starts building.
 */
class BuildMessages
{
	public static function init():Void
	{
		if (Context.defined("display"))
			return;

		Sys.println("Configured project successfully!");

		if (Context.defined("cpp"))
			Compiler.addMetadata("@:buildXml('<echo value=\"Starting build...\"/>')", "backend.Main");
	}
}
#end
