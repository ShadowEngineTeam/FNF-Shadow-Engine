package states.stages;

#if FEATURE_FUNKIN_CONTENT
import flixel.tweens.FlxEase.EaseFunction;
#end

class Stage extends BaseStage
{
	#if FEATURE_FUNKIN_CONTENT
	var spotlightBG:FlxSprite;
	var spotlightDAD:BGSprite;
	var spotlightGF:BGSprite;
	var spotlightBF:BGSprite;
	var smokeGroup:FlxSpriteGroup;
	#end

	override function create()
	{
		var bg:BGSprite = new BGSprite('stages/week1/stageback', -600, -200, 0.9, 0.9);
		add(bg);

		var stageFront:BGSprite = new BGSprite('stages/week1/stagefront', -650, 600, 0.9, 0.9);
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		add(stageFront);
		if (!ClientPrefs.data.lowQuality)
		{
			var stageLight:BGSprite = new BGSprite('stages/week1/stage_light', -125, -100, 0.9, 0.9);
			stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
			stageLight.updateHitbox();
			add(stageLight);
			var stageLight:BGSprite = new BGSprite('stages/week1/stage_light', 1225, -100, 0.9, 0.9);
			stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
			stageLight.updateHitbox();
			stageLight.flipX = true;
			add(stageLight);

			var stageCurtains:BGSprite = new BGSprite('stages/week1/stagecurtains', -500, -300, 1.3, 1.3);
			stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
			stageCurtains.updateHitbox();
			add(stageCurtains);
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

		spotlightGF = new BGSprite('stages/mainStage/spotlight', 493, -90);
		spotlightGF.blend = ADD;
		add(spotlightGF);

		spotlightDAD = new BGSprite('stages/mainStage/spotlight', 50, -100);
		spotlightDAD.blend = ADD;
		add(spotlightDAD);

		spotlightBF = new BGSprite('stages/mainStage/spotlight', 700, -100);
		spotlightBF.blend = ADD;
		add(spotlightBF);

		smokeGroup = new FlxSpriteGroup();
		add(smokeGroup);
		for (i in 0...4)
		{
			var smok:BGSprite = new BGSprite('stages/mainStage/smoke');
			smok.flipX = i > 1;
			smok.x = -700;
			if (i > 1)
				smok.x += 1800;
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
}
