package shaders;

import openfl.display.BitmapData;
import openfl.display.BlendMode;

@:nullSafety
class RuntimeCustomBlendShader extends RuntimePostEffectShader
{
	// only different name purely for hashlink fix
	public var sourceSwag(default, set):Null<BitmapData> = null;

	function set_sourceSwag(value:Null<BitmapData>):Null<BitmapData>
	{
		if (value != null)
			this.setBitmapData("sourceSwag", value);
		return sourceSwag = value;
	}

	public var backgroundSwag(default, set):Null<BitmapData> = null;

	function set_backgroundSwag(value:BitmapData):BitmapData
	{
		this.setBitmapData("backgroundSwag", value);
		return backgroundSwag = value;
	}

	// name change make sure it's not the same variable name as whatever is in the shader file
	public var blendSwag(default, set):BlendMode;

	function set_blendSwag(value:BlendMode):BlendMode
	{
		this.setInt("blendMode", cast value);
		return blendSwag = value;
	}

	public function new()
	{
		super(File.getContent(Paths.getPath('shaders/customBlend.frag', TEXT, null, false)));
	}
}
