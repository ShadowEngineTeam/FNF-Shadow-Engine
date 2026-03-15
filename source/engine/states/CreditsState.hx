package states;

import objects.AttachedSprite;

class CreditsState extends MusicBeatState
{
	var curSelected:Int = -1;

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<AttachedSprite> = [];
	private var creditsStuff:Array<Array<String>> = [];

	var bg:FlxSprite;
	var descText:FlxText;
	var intendedColor:FlxColor;
	var descBox:AttachedSprite;

	var offsetThing:Float = -75;

	override function create()
	{
		#if FEATURE_DISCORD_RPC
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		persistentUpdate = true;
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		#if FEATURE_MODS
		for (mod in Mods.parseList().enabled)
			pushModCreditsToList(mod);
		#end

		var defaultList:Array<Array<String>> = [
			/*
				NAME
				ICON NAME
				DESC
				LINK
				COLOR
			*/
			["Shadow Engine Team"],
			[
				"Homura",
				"homura",
				"Main Programmer and Head of Shadow Engine",
				"https://www.youtube.com/@HomuHomu833",
				"FFFFFF"
			],
			[
				"Karim",
				"karim",
				"Lead Programmer and Co-Owner of Shadow Engine",
				"https://www.youtube.com/@Karim-Akra",
				"FFFFFF"
			],
			[""],
			["Engine Contributors"],
			[
				"Chaos",
				"",
				"",
				"",
				""
			],
			[
				"Modeus",
				"",
				"",
				"",
				""
			],
			[
				"Zanxt",
				"",
				"",
				"",
				""
			],
			[""],
			["Funkin' Crew"],
			[
				"ninjamuffin99",
				"ninjamuffin99",
				"Programmer of Friday Night Funkin'",
				"https://x.com/ninja_muffin99",
				"CF2D2D"
			],
			[
				"PhantomArcade",
				"phantomarcade",
				"Animator of Friday Night Funkin'",
				"https://x.com/PhantomArcade3K",
				"FADC45"
			],
			[
				"evilsk8r",
				"evilsk8r",
				"Artist of Friday Night Funkin'",
				"https://x.com/evilsk8r",
				"5ABD4B"
			],
			[
				"kawaisprite",
				"kawaisprite",
				"Composer of Friday Night Funkin'",
				"https://x.com/kawaisprite",
				"378FC7"
			],
			[""]
		];

		for (i in defaultList)
			creditsStuff.push(i);

		for (i => credit in creditsStuff)
		{
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(FlxG.width / 2, 300, credit[0], !isSelectable);
			optionText.isMenuItem = true;
			optionText.targetY = i;
			optionText.changeX = false;
			optionText.snapToPosition();
			grpOptions.add(optionText);

			if (isSelectable)
			{
				if (credit[5] != null)
					Mods.currentModDirectory = credit[5];

				var str:String = 'credits/missing_icon';
				if (credit[1] != null && credit[1].length > 0)
				{
					var fileName = 'credits/' + credit[1];
					if (Paths.fileExists('images/$fileName.png', IMAGE))
						str = fileName;
					else if (Paths.fileExists('images/$fileName-pixel.png', IMAGE))
						str = fileName + '-pixel';
				}

				var icon:AttachedSprite = new AttachedSprite(str);
				if (str.endsWith('-pixel'))
					icon.antialiasing = false;
				icon.xAdd = optionText.width + 10;
				icon.sprTracker = optionText;
				iconArray.push(icon);
				add(icon);
				Mods.currentModDirectory = '';

				if (curSelected == -1)
					curSelected = i;
			}
			else
				optionText.alignment = CENTERED;
		}

		descBox = new AttachedSprite();
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.xAdd = -10;
		descBox.yAdd = -10;
		descBox.alphaMult = 0.6;
		descBox.alpha = 0.6;
		add(descBox);

		descText = new FlxText(50, FlxG.height + offsetThing - 25, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		descText.scrollFactor.set();
		descBox.sprTracker = descText;
		add(descText);

		bg.color = CoolUtil.colorFromString(creditsStuff[curSelected][4]);
		intendedColor = bg.color;
		changeSelection();
		super.create();
	}

	var quitting:Bool = false;
	var holdTime:Float = 0;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
		}

		if (!quitting)
		{
			if (creditsStuff.length > 1)
			{
				var shiftMult:Int = 1;
				if (FlxG.keys.pressed.SHIFT)
					shiftMult = 3;

				var upP = controls.UI_UP_P;
				var downP = controls.UI_DOWN_P;

				if (upP)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
				}
				if (downP)
				{
					changeSelection(shiftMult);
					holdTime = 0;
				}

				if (controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					}
				}
			}

			if (controls.ACCEPT && (creditsStuff[curSelected][3] == null || creditsStuff[curSelected][3].length > 4))
			{
				CoolUtil.browserLoad(creditsStuff[curSelected][3]);
			}
			if (controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
				quitting = true;
			}
		}

		for (item in grpOptions.members)
		{
			if (!item.bold)
			{
				var lerpVal:Float = Math.exp(-elapsed * 12);
				if (item.targetY == 0)
				{
					var lastX:Float = item.x;
					item.screenCenter(X);
					item.x = FlxMath.lerp(item.x - 70, lastX, lerpVal);
				}
				else
				{
					item.x = FlxMath.lerp(200 + -40 * Math.abs(item.targetY), item.x, lerpVal);
				}
			}
		}
		super.update(elapsed);
	}

	var moveTween:FlxTween = null;

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		do
		{
			curSelected = FlxMath.wrap(curSelected + change, 0, creditsStuff.length - 1);
		}
		while (unselectableCheck(curSelected));

		var newColor:FlxColor = CoolUtil.colorFromString(creditsStuff[curSelected][4]);
		if (newColor != intendedColor)
		{
			intendedColor = newColor;
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 1, bg.color, intendedColor);
		}

		for (num => item in grpOptions.members)
		{
			item.targetY = num - curSelected;
			if (!unselectableCheck(num))
			{
				item.alpha = 0.6;
				if (item.targetY == 0)
				{
					item.alpha = 1;
				}
			}
		}

		descText.text = creditsStuff[curSelected][2];
		if (descText.text.trim().length > 0)
		{
			descText.visible = descBox.visible = true;
			descText.y = FlxG.height - descText.height + offsetThing - 60;

			if (moveTween != null)
				moveTween.cancel();
			moveTween = FlxTween.tween(descText, {y: descText.y + 75}, 0.25, {ease: FlxEase.sineOut});

			descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
			descBox.updateHitbox();
		}
		else
			descText.visible = descBox.visible = false;
	}

	#if FEATURE_MODS
	function pushModCreditsToList(folder:String)
	{
		var creditsFile:String = Paths.mods(folder + '/data/credits.txt');

		if (FileSystem.exists(creditsFile))
		{
			var firstarray:Array<String> = File.getContent(creditsFile).split('\n');
			for (i in firstarray)
			{
				var arr:Array<String> = i.replace('\\n', '\n').split("::");
				if (arr.length >= 5)
					arr.push(folder);
				creditsStuff.push(arr);
			}
			creditsStuff.push(['']);
		}
	}
	#end

	private function unselectableCheck(num:Int):Bool
		return creditsStuff[num].length <= 1;
}
