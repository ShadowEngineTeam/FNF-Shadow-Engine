package states.stages;

import flixel.graphics.FlxGraphic;
import openfl.display.BlendMode;
import shaders.AdjustColorShader;

class StageErect extends BaseStage
{
	var peeps:BGSprite;

	override function create()
	{
		var bg:FlxSprite = makeSolidColor(new FlxSprite(-500, -1000), 2400, 2000, 0xFF222026);
		add(bg);

		if (!ClientPrefs.data.lowQuality)
		{
			peeps = new BGSprite('stages/week1/erect/crowd', 682, 290, 0.8, 0.8, ["idle"], true);
			peeps.animation.curAnim.frameRate = 12;
			add(peeps);

			var lightSmol = new BGSprite('stages/week1/erect/brightLightSmall', 967, -103, 1.2, 1.2);
			lightSmol.blend = BlendMode.ADD;
			add(lightSmol);
		}

		var stageFront:BGSprite = new BGSprite('stages/week1/erect/bg', -765, -247);
		add(stageFront);

		var server:BGSprite = new BGSprite('stages/week1/erect/server', -991, 205);
		add(server);

		if (!ClientPrefs.data.lowQuality)
		{
			var greenLight:BGSprite = new BGSprite('stages/week1/erect/lightgreen', -171, 242);
			greenLight.blend = BlendMode.ADD;
			add(greenLight);

			var redLight:BGSprite = new BGSprite('stages/week1/erect/lightred', -101, 560);
			redLight.blend = BlendMode.ADD;
			add(redLight);

			var orangeLight:BGSprite = new BGSprite('stages/week1/erect/orangeLight', 189, -500);
			orangeLight.blend = BlendMode.ADD;
			add(orangeLight);
		}

		var beamLol:BGSprite = new BGSprite('stages/week1/erect/lights', -847, -245, 1.2, 1.2);
		add(beamLol);

		if (!ClientPrefs.data.lowQuality)
		{
			var TheOneAbove:BGSprite = new BGSprite('stages/week1/erect/lightAbove', 804, -117);
			TheOneAbove.blend = BlendMode.ADD;
			add(TheOneAbove);
		}
	}

	override function createPost()
	{
		super.createPost();
		if (ClientPrefs.data.shaders)
		{
			gf.shader = makeCoolShader(-9, 0, -30, -4);
			dad.shader = makeCoolShader(-32, 0, -33, -23);
			boyfriend.shader = makeCoolShader(12, 0, -23, 7);
		}
	}

	function makeSolidColor(sprite:FlxSprite, width:Int, height:Int, color:FlxColor = FlxColor.WHITE):FlxSprite
	{
		final graphic:FlxGraphic = FlxG.bitmap.create(2, 2, color, false, 'solid#${color.toHexString(true, false)}');
		sprite.frames = graphic.imageFrame;
		sprite.scale.set(width / 2.0, height / 2.0);
		sprite.updateHitbox();
		return sprite;
	}

	function makeCoolShader(hue:Float, sat:Float, bright:Float, contrast:Float)
	{
		var coolShader:AdjustColorShader = new AdjustColorShader();
		coolShader.hue = hue;
		coolShader.saturation = sat;
		coolShader.brightness = bright;
		coolShader.contrast = contrast;
		return coolShader;
	}
}
