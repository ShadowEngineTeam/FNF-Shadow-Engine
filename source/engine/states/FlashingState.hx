package states;

import flixel.effects.FlxFlicker;
import lime.app.Application;
import flixel.addons.transition.FlxTransitionableState;

@:nullSafety
class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;

	@:nullSafety(Off) var warnText:FlxText;

	override function create()
	{
		super.create();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		final buttonBack:String = Funkin.controls.mobileC ? 'B' : 'ESCAPE';
		final buttonAccept:String = Funkin.controls.mobileC ? 'A' : 'ENTER';

		warnText = new FlxText(0, 0, FlxG.width, 'Hey, watch out!\n
			This Engine contains some flashing lights!\n
			Press $buttonAccept to disable them now or go to Options Menu.\n
			Press $buttonBack to ignore this message.\n
			You\'ve been warned!', 32);
		warnText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		add(warnText);

		#if FEATURE_MOBILE_CONTROLS
		addTouchPad("NONE", "A_B");
		#end
	}

	override function update(elapsed:Float)
	{
		if (!leftState)
		{
			var back:Bool = Funkin.controls.BACK;
			if (Funkin.controls.ACCEPT || back)
			{
				leftState = true;
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				if (!back)
				{
					ClientPrefs.data.flashing = false;
					ClientPrefs.saveSettings();
					FlxG.sound.play(Paths.sound('confirmMenu'));
					FlxFlicker.flicker(warnText, 1, 0.1, false, true, function(flk:FlxFlicker)
					{
						new FlxTimer().start(0.5, function(tmr:FlxTimer)
						{
							Funkin.switchState(TitleState);
						});
					});
				}
				else
				{
					ClientPrefs.data.flashing = true;
					ClientPrefs.saveSettings();
					FlxG.sound.play(Paths.sound('cancelMenu'));
					FlxTween.tween(warnText, {alpha: 0}, 1, {
						onComplete: function(twn:FlxTween)
						{
							Funkin.switchState(TitleState);
						}
					});
				}
			}
		}
		super.update(elapsed);
	}
}
