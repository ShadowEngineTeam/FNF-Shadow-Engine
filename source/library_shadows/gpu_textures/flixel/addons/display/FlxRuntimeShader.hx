package flixel.addons.display;

#if (nme || flash)
	#if (FLX_NO_COVERAGE_TEST && !(doc_gen))
		#error "FlxRuntimeShader isn't available with nme or flash."
	#end
#else
import flixel.graphics.tile.FlxGraphicsShader;
#end
#if lime
import lime.utils.Float32Array;
#end
import openfl.display.BitmapData;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

using StringTools;

/**
 * An wrapper for Flixel/OpenFL's shaders, which takes fragment and vertex source
 * in the constructor instead of using macros, so it can be provided data
 * at runtime (for example, when using mods).
 *
 * HOW TO USE:
 * 1. Create an instance of this class, passing the text of the `.frag` and `.vert` files.
 *    Note that you can set either of these to null (making them both null would make the shader do nothing???).
 * 2. Use `flxSprite.shader = runtimeShader` to apply the shader to the sprite.
 * 3. Use `runtimeShader.setFloat()`, `setBool()` etc. to modify any uniforms.
 * 4. Use `setBitmapData()` to add additional textures as `sampler2D` uniforms
 *
 * @author MasterEric
 * @see https://github.com/openfl/openfl/blob/develop/src/openfl/utils/_internal/ShaderMacro.hx
 * @see https://dixonary.co.uk/blog/shadertoy
 */
class FlxRuntimeShader extends FlxGraphicsShader
{
	#if FLX_DRAW_QUADS
	// We need to add stuff from FlxGraphicsShader too!
	#else
	// Only stuff from openfl.display.GraphicsShader is needed
	#end
	// These variables got copied from openfl.display.GraphicsShader
	// and from flixel.graphics.tile.FlxGraphicsShader.

    static final pragmaHeaderKeyword:EReg = ~/^[ \t]*#pragma[ \t]+header[ \t]*$/gm;
    static final pragmaBodyKeyword:EReg = ~/^[ \t]*#pragma[ \t]+body[ \t]*$/gm;
    static final attributeKeyword:EReg = ~/\battribute\s+([A-Za-z0-9_]+)\s+([A-Za-z0-9_]+)/g;
    static final varyingKeyword:EReg = ~/\bvarying\s+(?:lowp|mediump|highp\s+)?([A-Za-z0-9_]+)\s+([A-Za-z0-9_]+)/g;
    static final texture2DKeyword:EReg = ~/\btexture2D\b/g;
    static final glFragColorKeyword:EReg = ~/\bgl_FragColor\b/g;

	/**
	 * Constructs a GLSL shader.
	 * @param fragmentSource The fragment shader source.
	 * @param vertexSource The vertex shader source.
	 * Note you also need to `initialize()` the shader MANUALLY! It can't be done automatically.
	 */
	public function new(?fragmentSource:String, ?vertexSource:String, ?glslVersion:String):Void
	{
		if (glslVersion != null) {
			// Don't set the value (use getDefaultGLVersion) if it's null.
			this.glVersion = glslVersion;
		}

		if (fragmentSource == null)
		{
			this.glFragmentSource = __processFragmentSource(glFragmentSourceRaw);
		}
		else
		{
			this.glFragmentSource = __processFragmentSource(fragmentSource);
		}

		if (vertexSource == null)
		{
			var s = __processVertexSource(glVertexSourceRaw);
			this.glVertexSource = s;
		}
		else
		{
			var s = __processVertexSource(vertexSource);
			this.glVertexSource = s;
		}

		@:privateAccess {
			// This tells the shader that the glVertexSource/glFragmentSource have been updated.
			this.__glSourceDirty = true;
		}

		super();
	}

	/**
	 * Replace the `#pragma header` and `#pragma body` with the fragment shader header and body.
	 */
	@:noCompletion private function __processFragmentSource(input:String):String
	{
        switch (glVersion)
		{
            case "300 es", "310 es", "320 es":
				input = varyingKeyword.replace(input, "in $1 $2");
				input = texture2DKeyword.replace(input, "texture");
				input = glFragColorKeyword.replace(input, "openfl_FragColor");

			default:
				// we don't need do anything
		}

		var result = pragmaHeaderKeyword.replace(input, glFragmentHeaderRaw);
		result = pragmaBodyKeyword.replace(result, glFragmentBodyRaw);
		return result;
	}

	/**
	 * Replace the `#pragma header` and `#pragma body` with the vertex shader header and body.
	 */
	@:noCompletion private function __processVertexSource(input:String):String
	{
        switch (glVersion)
		{
            case "300 es", "310 es", "320 es":
                input = attributeKeyword.replace(input, "in $1 $2");
				input = varyingKeyword.replace(input, "out $1 $2");
				input = texture2DKeyword.replace(input, "texture");
				input = glFragColorKeyword.replace(input, "openfl_FragColor");

			default:
                // we don't need do anything
		}

		var result = pragmaHeaderKeyword.replace(input, glVertexHeaderRaw);
		result = pragmaBodyKeyword.replace(result, glVertexBodyRaw);
		return result;
	}

	/**
	 * Modify a float parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setFloat(name:String, value:Float):Void
	{
		var prop:ShaderParameter<Float> = Reflect.field(this.data, name);
		@:privateAccess
		if (prop == null)
		{
			trace('Shader float property ${name} not found.');
			return;
		}
		prop.value = [value];
	}

	/**
	 * Modify a float array parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setFloatArray(name:String, value:Array<Float>):Void
	{
		var prop:ShaderParameter<Float> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('Shader float[] property ${name} not found.');
			return;
		}
		prop.value = value;
	}

	/**
	 * Modify an integer parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setInt(name:String, value:Int):Void
	{
		var prop:ShaderParameter<Int> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('Shader int property ${name} not found.');
			return;
		}
		prop.value = [value];
	}

	/**
	 * Modify an integer array parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setIntArray(name:String, value:Array<Int>):Void
	{
		var prop:ShaderParameter<Int> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('Shader int[] property ${name} not found.');
			return;
		}
		prop.value = value;
	}

	/**
	 * Modify a boolean parameter of the shader.
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setBool(name:String, value:Bool):Void
	{
		var prop:ShaderParameter<Bool> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('Shader bool property ${name} not found.');
			return;
		}
		prop.value = [value];
	}

	/**
	 * Modify a boolean array parameter of the shader.
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setBoolArray(name:String, value:Array<Bool>):Void
	{
		var prop:ShaderParameter<Bool> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('Shader bool[] property ${name} not found.');
			return;
		}
		prop.value = value;
	}

	/**
	 * Modify a bitmap data parameter of the shader.
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setBitmapData(name:String, value:openfl.display.BitmapData):Void
	{
		var prop:ShaderInput<openfl.display.BitmapData> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('Shader sampler2D property ${name} not found.');
			return;
		}
		prop.input = value;
	}

	/**
	 * Retrieve a float parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getFloat(name:String):Null<Float>
	{
		var prop:ShaderParameter<Float> = Reflect.field(this.data, name);
		if (prop == null || prop.value.length == 0)
		{
			trace('Shader float property ${name} not found.');
			return null;
		}
		return prop.value[0];
	}

	/**
	 * Retrieve a float array parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getFloatArray(name:String):Null<Array<Float>>
	{
		var prop:ShaderParameter<Float> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('Shader float[] property ${name} not found.');
			return null;
		}
		return prop.value;
	}

	/**
	 * Retrieve an integer parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getInt(name:String):Null<Int>
	{
		var prop:ShaderParameter<Int> = Reflect.field(this.data, name);
		if (prop == null || prop.value.length == 0)
		{
			trace('Shader int property ${name} not found.');
			return null;
		}
		return prop.value[0];
	}

	/**
	 * Retrieve an integer array parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getIntArray(name:String):Null<Array<Int>>
	{
		var prop:ShaderParameter<Int> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('Shader int[] property ${name} not found.');
			return null;
		}
		return prop.value;
	}

	/**
	 * Retrieve a boolean parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getBool(name:String):Null<Bool>
	{
		var prop:ShaderParameter<Bool> = Reflect.field(this.data, name);
		if (prop == null || prop.value.length == 0)
		{
			trace('Shader bool property ${name} not found.');
			return null;
		}
		return prop.value[0];
	}

	/**
	 * Retrieve a boolean array parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getBoolArray(name:String):Null<Array<Bool>>
	{
		var prop:ShaderParameter<Bool> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('Shader bool[] property ${name} not found.');
			return null;
		}
		return prop.value;
	}

	/**
	 * Retrieve a bitmap data parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getBitmapData(name:String):Null<openfl.display.BitmapData>
	{
		var prop:ShaderInput<openfl.display.BitmapData> = Reflect.field(this.data, name);
		if (prop == null)
		{
			trace('Shader sampler2D property ${name} not found.');
			return null;
		}
		return prop.input;
	}

	public function toString():String
	{
		return 'FlxRuntimeShader';
	}
}