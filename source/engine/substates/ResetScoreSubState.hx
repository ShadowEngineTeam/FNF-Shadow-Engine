package substates;

import backend.WeekData;
import backend.Highscore;
import flixel.addons.transition.FlxTransitionableState;
import objects.HealthIcon;

@:nullSafety
class ResetScoreSubState extends MusicBeatSubstate
{
	var bg:Null<FlxSprite> = null;
	var alphabetArray:Array<Alphabet> = [];
	var icon:Null<HealthIcon> = null;
	var onYes:Bool = false;
	var yesText:Null<Alphabet> = null;
	var noText:Null<Alphabet> = null;

	var song:String = '';
	var difficulty:Int = 0;
	var week:Int = 0;

	public function new(song:String, difficulty:Int, character:String, week:Int = -1)
	{
		this.song = song;
		this.difficulty = difficulty;
		this.week = week;
		super();

		var name:String = song;
		if (week > -1)
		{
			var weekData = WeekData.weeksLoaded.get(WeekData.weeksList[week]);
			if (weekData != null)
				name = weekData.weekName;
		}
		name += ' (' + Difficulty.getString(difficulty) + ')?';

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var tooLong:Float = (name.length > 18) ? 0.8 : 1;
		var text:Alphabet = new Alphabet(0, 180, "Reset the score of", true);
		text.screenCenter(X);
		alphabetArray.push(text);
		text.alpha = 0;
		add(text);
		var text:Alphabet = new Alphabet(0, text.y + 90, name, true);
		text.scaleX = tooLong;
		text.screenCenter(X);
		if (week == -1)
			text.x += 60 * tooLong;
		alphabetArray.push(text);
		text.alpha = 0;
		add(text);
		if (week == -1)
		{
			icon = new HealthIcon(character);
			var iconRef = icon;
			if (iconRef != null)
			{
				iconRef.setGraphicSize(Std.int(iconRef.width * tooLong));
				iconRef.updateHitbox();
				iconRef.setPosition(text.x - iconRef.width + (10 * tooLong), text.y - 30);
				iconRef.alpha = 0;
				add(iconRef);
			}
		}

		yesText = new Alphabet(0, text.y + 150, 'Yes', true);
		yesText.screenCenter(X);
		yesText.x -= 200;
		add(yesText);
		noText = new Alphabet(0, text.y + 150, 'No', true);
		noText.screenCenter(X);
		noText.x += 200;
		add(noText);

		#if FEATURE_MOBILE_CONTROLS
		addTouchPad("LEFT_RIGHT", "A_B");
		addTouchPadCamera(false);
		#end

		updateOptions();
	}

	override function update(elapsed:Float)
	{
		var bgRef = bg;
		if (bgRef != null)
		{
			bgRef.alpha += elapsed * 1.5;
			if (bgRef.alpha > 0.6)
				bgRef.alpha = 0.6;
		}

		for (i in 0...alphabetArray.length)
		{
			var spr = alphabetArray[i];
			spr.alpha += elapsed * 2.5;
		}
		if (week == -1)
		{
			var iconRef = icon;
			if (iconRef != null)
				iconRef.alpha += elapsed * 2.5;
		}

		if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
		{
			var sound = Paths.sound('scrollMenu');
			if (sound != null)
				FlxG.sound.play(sound, 1);
			onYes = !onYes;
			updateOptions();
		}
		if (controls.BACK)
		{
			var sound = Paths.sound('cancelMenu');
			if (sound != null)
				FlxG.sound.play(sound, 1);
			ClientPrefs.saveSettings();
			close();
		}
		else if (controls.ACCEPT)
		{
			if (onYes)
			{
				if (week == -1)
				{
					Highscore.resetSong(song, difficulty);
				}
				else
				{
					Highscore.resetWeek(WeekData.weeksList[week], difficulty);
				}
			}
			var sound = Paths.sound('cancelMenu');
			if (sound != null)
				FlxG.sound.play(sound, 1);
			ClientPrefs.saveSettings();
			close();
		}
		#if FEATURE_MOBILE_CONTROLS
		if (touchPad == null)
		{
			addTouchPad("LEFT_RIGHT", "A_B");
			addTouchPadCamera(false);
		}
		#end
		super.update(elapsed);
	}

	function updateOptions()
	{
		var scales:Array<Float> = [0.75, 1];
		var alphas:Array<Float> = [0.6, 1.25];
		var confirmInt:Int = onYes ? 1 : 0;

		var yesTextRef = yesText;
		var noTextRef = noText;
		if (yesTextRef != null)
		{
			yesTextRef.alpha = alphas[confirmInt];
			yesTextRef.scale.set(scales[confirmInt], scales[confirmInt]);
		}
		if (noTextRef != null)
		{
			noTextRef.alpha = alphas[1 - confirmInt];
			noTextRef.scale.set(scales[1 - confirmInt], scales[1 - confirmInt]);
		}
		if (week == -1)
		{
			var iconRef = icon;
			if (iconRef != null && iconRef.animation != null && iconRef.animation.curAnim != null)
				iconRef.animation.curAnim.curFrame = confirmInt;
		}

		callOnScripts('onChangeSelection');
	}

	override function destroy()
	{
		bg = FlxDestroyUtil.destroy(bg);
		alphabetArray = FlxDestroyUtil.destroyArray(alphabetArray);
		icon = FlxDestroyUtil.destroy(icon);
		yesText = FlxDestroyUtil.destroy(yesText);
		noText = FlxDestroyUtil.destroy(noText);

		super.destroy();
	}
}
