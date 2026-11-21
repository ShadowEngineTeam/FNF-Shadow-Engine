package macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.io.Path;

/**
 * Adds an XML `<include>` of a build file to the class's metadata.
 * The file is looked up relative to the directory of the class that uses this macro.
 * From FunkinCrew/Funkin's `funkin.util.macro.LinkerMacro`.
 */
class LinkerMacro
{
	public static function xml(fileName:String = 'Build.xml'):Array<Field>
	{
		final fields:Array<Field> = Context.getBuildFields();
		final cls:ClassType = Context.getLocalClass().get();
		final pos:Position = Context.currentPos();

		final sourcePath:String = Path.directory(Context.getPosInfos(pos).file);
		final absSourcePath:String = Path.removeTrailingSlashes(sys.FileSystem.absolutePath(sourcePath));
		final fileToInclude:String = Path.join([absSourcePath, fileName.length > 0 ? fileName : 'Build.xml']);

		if (!sys.FileSystem.exists(fileToInclude))
			Context.error('The specified file "$fileToInclude" could not be found at "$absSourcePath".', pos);

		final includeElement:Xml = Xml.createElement('include');
		includeElement.set('name', fileToInclude);

		cls.meta.add(':buildXml', [{expr: EConst(CString(haxe.xml.Printer.print(includeElement, true))), pos: pos}], pos);

		return fields;
	}
}
#end
