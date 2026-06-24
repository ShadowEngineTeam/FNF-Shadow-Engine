package psychlua;

import flixel.sound.FlxSound;

class SoundFunctions
{
	// Sound functions
	public static function implement(funk:FunkinLua)
	{
		var game:Dynamic = FunkinLua.getCurrentMusicState();

		funk.set("playMusic", function(sound:String, volume:Float = 1, loop:Bool = false)
		{
			FlxG.sound.playMusic(Paths.music(sound), volume, loop);
		});
		funk.set("playSound", function(sound:String, volume:Float = 1, ?tag:String = null)
		{
			if (tag != null && tag.length > 0)
			{
				tag = tag.replace('.', '');
				if (game.modchartSounds.exists(tag))
				{
					game.modchartSounds.get(tag).stop();
				}
				game.modchartSounds.set(tag, FlxG.sound.play(Paths.sound(sound), volume, false, null, true, function()
				{
					game.modchartSounds.remove(tag);
					game.callOnLuas('onSoundFinished', [tag]);
				}));
				return;
			}
			FlxG.sound.play(Paths.sound(sound), volume);
		});
		funk.set("stopSound", function(tag:String)
		{
			if (tag != null && tag.length > 1 && game.modchartSounds.exists(tag))
			{
				game.modchartSounds.get(tag).stop();
				game.modchartSounds.remove(tag);
			}
		});
		funk.set("pauseSound", function(tag:String)
		{
			if (tag != null && tag.length > 1 && game.modchartSounds.exists(tag))
			{
				game.modchartSounds.get(tag).pause();
			}
		});
		funk.set("resumeSound", function(tag:String)
		{
			if (tag != null && tag.length > 1 && game.modchartSounds.exists(tag))
			{
				game.modchartSounds.get(tag).play();
			}
		});
		funk.set("soundFadeIn", function(tag:String, duration:Float, fromValue:Float = 0, toValue:Float = 1)
		{
			if (tag == null || tag.length < 1)
			{
				FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			}
			else if (game.modchartSounds.exists(tag))
			{
				game.modchartSounds.get(tag).fadeIn(duration, fromValue, toValue);
			}
		});
		funk.set("soundFadeOut", function(tag:String, duration:Float, toValue:Float = 0)
		{
			if (tag == null || tag.length < 1)
			{
				FlxG.sound.music.fadeOut(duration, toValue);
			}
			else if (game.modchartSounds.exists(tag))
			{
				game.modchartSounds.get(tag).fadeOut(duration, toValue);
			}
		});
		funk.set("soundFadeCancel", function(tag:String)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music.fadeTween != null)
				{
					FlxG.sound.music.fadeTween.cancel();
				}
			}
			else if (game.modchartSounds.exists(tag))
			{
				var theSound:FlxSound = game.modchartSounds.get(tag);
				if (theSound.fadeTween != null)
				{
					theSound.fadeTween.cancel();
					game.modchartSounds.remove(tag);
				}
			}
		});
		funk.set("getSoundVolume", function(tag:String)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music != null)
				{
					return FlxG.sound.music.volume;
				}
			}
			else if (game.modchartSounds.exists(tag))
			{
				return game.modchartSounds.get(tag).volume;
			}
			return 0;
		});
		funk.set("setSoundVolume", function(tag:String, value:Float)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music != null)
				{
					FlxG.sound.music.volume = value;
				}
			}
			else if (game.modchartSounds.exists(tag))
			{
				game.modchartSounds.get(tag).volume = value;
			}
		});
		funk.set("getSoundTime", function(tag:String)
		{
			if (tag != null && tag.length > 0 && game.modchartSounds.exists(tag))
			{
				return game.modchartSounds.get(tag).time;
			}
			return 0;
		});
		funk.set("setSoundTime", function(tag:String, value:Float)
		{
			if (tag != null && tag.length > 0 && game.modchartSounds.exists(tag))
			{
				var theSound:FlxSound = game.modchartSounds.get(tag);
				if (theSound != null)
				{
					var wasResumed:Bool = theSound.playing;
					theSound.pause();
					theSound.time = value;
					if (wasResumed)
						theSound.play();
				}
			}
		});
		funk.set("getSoundPitch", function(tag:String)
		{
			if (tag != null && tag.length > 0 && game.modchartSounds.exists(tag))
			{
				return game.modchartSounds.get(tag).pitch;
			}
			return 0;
		});
		funk.set("setSoundPitch", function(tag:String, value:Float, doPause:Bool = false)
		{
			if (tag != null && tag.length > 0 && game.modchartSounds.exists(tag))
			{
				var theSound:FlxSound = game.modchartSounds.get(tag);
				if (theSound != null)
				{
					var wasResumed:Bool = theSound.playing;
					if (doPause)
						theSound.pause();
					theSound.pitch = value;
					if (doPause && wasResumed)
						theSound.play();
				}
			}
		});
	}
}
