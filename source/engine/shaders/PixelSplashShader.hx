package shaders;

class PixelSplashShaderRef
{
	public var shader:PixelSplashShader = new PixelSplashShader();

	public function copyValues(tempShader:RGBPalette)
	{
		var enabled:Bool = false;
		if (tempShader != null)
			enabled = true;

		if (enabled)
		{
			for (i in 0...3)
			{
				shader.r.value[i] = tempShader.shader.r.value[i];
				shader.g.value[i] = tempShader.shader.g.value[i];
				shader.b.value[i] = tempShader.shader.b.value[i];
			}
			shader.mult.value[0] = tempShader.shader.mult.value[0];
		}
		else
			shader.mult.value[0] = 0.0;
	}

	public function new()
	{
		shader.r.value = [0, 0, 0];
		shader.g.value = [0, 0, 0];
		shader.b.value = [0, 0, 0];
		shader.mult.value = [1];

		var pixel:Float = 1;
		/*if (PlayState.isPixelStage)
			pixel = PlayState.daPixelZoom;*/
		shader.uBlocksize.value = [pixel, pixel];
		// trace('Created shader ' + Conductor.songPosition);
	}
}

class PixelSplashShader extends FlxShader
{
	#if (!ios && !macos)
	@:glVersion('100')
	#end
	@:glFragmentHeader('
		#pragma header
		
		uniform vec3 r;
		uniform vec3 g;
		uniform vec3 b;
		uniform float mult;
		uniform vec2 uBlocksize;

		vec4 flixel_texture2DCustom(sampler2D bitmap, vec2 coord) {
			vec2 blocks = openfl_TextureSize / uBlocksize;
			vec4 color = flixel_texture2D(bitmap, floor(coord * blocks) / blocks);
			if (!hasTransform) {
				return color;
			}

			if(color.a == 0.0 || mult == 0.0) {
				return color * openfl_Alphav;
			}

			vec4 newColor = color;
			newColor.rgb = min(color.r * r + color.g * g + color.b * b, vec3(1.0));
			newColor.a = color.a;
			
			color = mix(color, newColor, mult);
			
			if(color.a > 0.0) {
				return vec4(color.rgb, color.a);
			}
			return vec4(0.0, 0.0, 0.0, 0.0);
		}')
	@:glFragmentSource('
		#pragma header

		void main() {
			gl_FragColor = flixel_texture2DCustom(bitmap, openfl_TextureCoordv);
		}')
	public function new()
	{
		super();
	}
}
