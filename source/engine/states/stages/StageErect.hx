package states.stages;

import flixel.graphics.FlxGraphic;
#if FEATURE_FUNKIN_CONTENT
import flixel.tweens.FlxEase.EaseFunction;
#end
import openfl.display.BlendMode;
import shaders.AdjustColorShader;

class StageErect extends BaseStage
{
	var peeps:BGSprite;

	#if FEATURE_FUNKIN_CONTENT
	var spotlightBG:FlxSprite;
	var spotlightDAD:BGSprite;
	var spotlightGF:BGSprite;
	var spotlightBF:BGSprite;
	var smokeGroup:FlxSpriteGroup;
	#end

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

		createSpotlights();
	}

	function createSpotlights()
	{
		#if FEATURE_FUNKIN_CONTENT
		spotlightBG = new FlxSprite(-300, -500).makeGraphic(1, 1, 0xFF000000);
		spotlightBG.scale.set(2000, 2000);
		spotlightBG.updateHitbox();
		add(spotlightBG);

		spotlightGF = new BGSprite('stages/mainStage/spotlight', 200, -90);
		spotlightGF.blend = BlendMode.ADD;
		add(spotlightGF);

		spotlightDAD = new BGSprite('stages/mainStage/spotlight', -190, -50);
		spotlightDAD.blend = BlendMode.ADD;
		add(spotlightDAD);

		spotlightBF = new BGSprite('stages/mainStage/spotlight', 690, -50);
		spotlightBF.blend = BlendMode.ADD;
		add(spotlightBF);

		smokeGroup = new FlxSpriteGroup();
		add(smokeGroup);
		for (i in 0...4)
		{
			var smok:BGSprite = new BGSprite('stages/mainStage/smoke');
			smok.flipX = i > 1;
			smok.x = -1100;
			if (i > 1)
				smok.x += 2200;
			smok.y = 700;
			smok.velocity.x = smok.flipX ? -10 : 10;
			smok.active = true;
			smokeGroup.add(smok);
		}

		spotlightDAD.alpha = spotlightBF.alpha = spotlightGF.alpha = smokeGroup.alpha = spotlightBG.alpha = 0.001;
		#end
	}

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		#if FEATURE_FUNKIN_CONTENT
		if (eventName != 'Dadbattle Spotlight' || value1 == null || value1.length < 1)
			return;

		var target:FlxSprite = switch (value1.toLowerCase().trim())
		{
			case 'dad' | 'opponent' | '1': spotlightDAD;
			case 'girlfriend' | 'gf' | '2': spotlightGF;
			case 'background' | 'bg' | '3': spotlightBG;
			case 'smoke' | '4': smokeGroup;
			default: spotlightBF;
		}

		var values:Array<String> = (value2 != null && value2.contains(',')) ? value2.split(',') : [value2, '0', 'classic'];
		var alphaFloat:Float = Std.parseFloat(values[0]);
		if (Math.isNaN(alphaFloat))
			alphaFloat = 0;

		var easeString:String = (values.length > 2 ? Std.string(values[2]) : 'classic').toLowerCase().trim();
		if (easeString == 'classic' || easeString.length < 1)
		{
			target.alpha = alphaFloat;
			return;
		}

		var durationFloat:Float = (values.length > 1) ? Std.parseFloat(values[1]) : 0;
		if (Math.isNaN(durationFloat))
			durationFloat = 0;

		var ease:EaseFunction = LuaUtils.getTweenEaseByString(easeString);
		FlxTween.tween(target, {alpha: alphaFloat}, Conductor.stepCrochet / 1000 * durationFloat, {ease: ease});
		#end
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
