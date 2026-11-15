package substates;

/**
 * Picks the mix and instrumental of a song before playing it, like Funkin's Freeplay.
 */
class FreeplayOptionsSubState extends MusicBeatSubstate
{
	public static inline final DEFAULT_MIX:String = 'default';

	var mixes:Array<String>;
	var instrumentals:Map<String, Array<String>>;
	var onConfirm:(String, String) -> Void;

	var curMix:Int = 0;
	var curInstrumental:Int = 0;
	var curRow:Int = 0;

	// The press that opened this would also confirm it on the same frame.
	var canInput:Bool = false;

	var bg:FlxSprite;
	var box:FlxSprite;
	var title:FlxText;
	var mixText:FlxText;
	var instrumentalText:FlxText;

	/**
	 * @param mixes The mixes the song has, the default one first.
	 * @param instrumentals The instrumentals each mix can play, its own one first.
	 * @param onConfirm Called with the picked mix and instrumental.
	 */
	public function new(mixes:Array<String>, instrumentals:Map<String, Array<String>>, onConfirm:(String, String) -> Void)
	{
		this.mixes = mixes;
		this.instrumentals = instrumentals;
		this.onConfirm = onConfirm;
		super();

		bg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		box = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		box.scale.set(620, 250);
		box.updateHitbox();
		box.alpha = 0.7;
		box.screenCenter();
		box.scrollFactor.set();
		add(box);

		title = makeText(box.y + 20, 'SONG OPTIONS');
		mixText = makeText(box.y + 100, '');
		instrumentalText = makeText(box.y + 170, '');

		#if FEATURE_MOBILE_CONTROLS
		addTouchPad("LEFT_FULL", "A_B");
		addTouchPadCamera(false);
		#end

		updateTexts();
	}

	function makeText(y:Float, text:String):FlxText
	{
		final txt:FlxText = new FlxText(0, y, box.width, text);
		txt.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		txt.borderSize = 2;
		txt.x = box.x;
		txt.scrollFactor.set();
		add(txt);
		return txt;
	}

	function curInstrumentals():Array<String>
		return instrumentals.get(mixes[curMix]) ?? [DEFAULT_MIX];

	/**
	 * The rows that can be changed: 0 for the mix, 1 for the instrumental.
	 */
	function rows():Array<Int>
	{
		final list:Array<Int> = [];
		if (mixes.length > 1)
			list.push(0);
		if (curInstrumentals().length > 1)
			list.push(1);
		return list;
	}

	static function label(id:String):String
		return id.toUpperCase();

	function updateTexts():Void
	{
		final rowList:Array<Int> = rows();
		curRow = Std.int(FlxMath.bound(curRow, 0, Math.max(rowList.length - 1, 0)));
		final selected:Int = rowList.length > 0 ? rowList[curRow] : -1;

		final mixLabel:String = label(mixes[curMix]);
		mixText.text = 'MIX: ' + (mixes.length > 1 ? '< $mixLabel >' : mixLabel);
		mixText.alpha = selected == 0 ? 1 : 0.6;

		final insts:Array<String> = curInstrumentals();
		final instLabel:String = label(insts[curInstrumental]);
		instrumentalText.text = 'INST: ' + (insts.length > 1 ? '< $instLabel >' : instLabel);
		instrumentalText.alpha = selected == 1 ? 1 : 0.6;
	}

	override function update(elapsed:Float):Void
	{
		bg.alpha = Math.min(bg.alpha + elapsed * 1.5, 0.6);

		if (!canInput)
		{
			canInput = true;
			super.update(elapsed);
			return;
		}

		final rowList:Array<Int> = rows();
		if (Funkin.controls.UI_UP_P || Funkin.controls.UI_DOWN_P)
		{
			if (rowList.length > 1)
			{
				curRow = (curRow + (Funkin.controls.UI_UP_P ? -1 : 1) + rowList.length) % rowList.length;
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				updateTexts();
			}
		}
		else if ((Funkin.controls.UI_LEFT_P || Funkin.controls.UI_RIGHT_P) && rowList.length > 0)
		{
			final change:Int = Funkin.controls.UI_LEFT_P ? -1 : 1;
			switch (rowList[curRow])
			{
				case 0:
					curMix = (curMix + change + mixes.length) % mixes.length;
					curInstrumental = 0;
				case 1:
					final insts:Array<String> = curInstrumentals();
					curInstrumental = (curInstrumental + change + insts.length) % insts.length;
			}
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			updateTexts();
		}

		if (Funkin.controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
		}
		else if (Funkin.controls.ACCEPT)
		{
			final mix:String = mixes[curMix];
			final instrumental:String = curInstrumentals()[curInstrumental];
			final confirm:(String, String) -> Void = onConfirm;
			close();
			confirm(mix, instrumental);
		}

		super.update(elapsed);
	}

	override function destroy():Void
	{
		onConfirm = null;
		super.destroy();
	}
}
