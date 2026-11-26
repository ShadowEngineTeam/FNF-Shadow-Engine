package objects;

import backend.SRTUtil;
import backend.SRTUtil.KaraokeSyllable;
import flixel.sound.FlxSound;

/**
 * Shows the lines of an `.srt` file in time with a sound, as in Funkin.
 * Lines with karaoke tags color each syllable as it is sung.
 */
class Subtitles extends FlxSpriteGroup
{
	var subtitleText:SubtitlesText;
	var background:FlxSprite;
	var subtitlesData:Array<SubtitleEntry>;
	var assignedSound:FlxSound;

	// Whether each sung syllable was sung while the player was missing
	var missedSyllables:Map<KaraokeSyllable, Bool> = [];
	var missing:Bool = false;

	static inline final KARAOKE_COLOR:String = 'FFD54A';
	static inline final MISS_COLOR:String = 'FF3B3B';

	static final instances:Array<Subtitles> = [];

	public var offsets(default, set):Array<Float> = [0, 0];
	public var alignment(default, set):SubtitlesAlignment = SUBTITLES_BOTTOM;

	public function new(x:Float = 0, y:Float = 0, alignment:SubtitlesAlignment = SUBTITLES_BOTTOM, ?font:String)
	{
		super(0, 0);

		background = new FlxSprite();
		background.alpha = 0.5;
		add(background);

		subtitleText = new SubtitlesText(0, 0, 30, font ?? Paths.font('vcr.ttf'));
		add(subtitleText);

		this.offsets = [x, y];
		this.alignment = alignment;

		setText([], true);

		instances.push(this);
	}

	override function destroy():Void
	{
		instances.remove(this);
		super.destroy();
	}

	/**
	 * The player missed a note at `time`: the karaoke sung then, and until `noteHit`, shows red.
	 */
	public static function noteMissed(time:Float):Void
	{
		for (subtitles in instances)
			subtitles.markMissed(time);
	}

	/**
	 * The player hit a note, so the karaoke sung from now on shows normally again.
	 */
	public static function noteHit():Void
	{
		for (subtitles in instances)
			subtitles.missing = false;
	}

	function markMissed(time:Float):Void
	{
		missing = true;
		if (subtitlesData == null)
			return;

		for (data in subtitlesData)
			if (data.syllables != null && time >= data.start && time <= data.end)
				for (syllable in data.syllables)
					if (time >= syllable.start && time < syllable.end)
						missedSyllables.set(syllable, true);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (assignedSound == null || subtitlesData == null)
			return;

		final time:Float = assignedSound.time;
		final currentLines:Array<String> = [];
		for (data in subtitlesData)
			if (time >= data.start && time <= data.end)
				currentLines.unshift(data.syllables != null ? karaokeText(data, time) : data.text);

		setText(currentLines, currentLines.length == 0);
	}

	/**
	 * Loads `data/<key>.srt` and shows it in time with `sound`.
	 */
	public function assignSubtitles(key:String, sound:FlxSound):Void
	{
		setText([], true);

		subtitlesData = null;
		assignedSound = null;
		missedSyllables.clear();
		missing = false;

		if (sound == null)
			return;

		final data:Array<SubtitleEntry> = SRTParser.parseFromFile(key);
		if (data.length == 0)
			return;

		subtitlesData = data;
		assignedSound = sound;
	}

	// The syllables that were sung get colored, like karaoke, and red where the player missed
	function karaokeText(entry:SubtitleEntry, time:Float):String
	{
		final sungColor:String = entry.color ?? KARAOKE_COLOR;
		var result:String = '';
		var run:String = '';
		var runColor:Null<String> = null;
		for (syllable in entry.syllables)
		{
			var color:Null<String> = null;
			if (time >= syllable.start)
			{
				if (missing && time < syllable.end)
					missedSyllables.set(syllable, true);
				else if (!missedSyllables.exists(syllable))
					missedSyllables.set(syllable, missing);
				color = missedSyllables.get(syllable) ? MISS_COLOR : sungColor;
			}

			if (color != runColor)
			{
				result += colored(run, runColor);
				run = '';
				runColor = color;
			}
			run += syllable.text.htmlEscape();
		}
		return result + colored(run, runColor);
	}

	static function colored(text:String, color:Null<String>):String
	{
		if (text.length == 0 || color == null)
			return text;
		return '<font color="#$color">$text</font>';
	}

	function setText(lines:Array<String>, hide:Bool = false):Void
	{
		visible = !hide;

		final targetText:String = lines.join('\n');
		if (subtitleText.text == targetText)
			return;

		subtitleText.text = targetText;
		background.makeGraphic(Math.ceil(subtitleText.width), Math.ceil(subtitleText.height), FlxColor.BLACK, true);

		updatePosition();
	}

	function updatePosition():Void
	{
		if (subtitleText == null)
			return;

		screenCenter(X);
		x += offsets[0];

		switch (alignment)
		{
			case SUBTITLES_TOP:
				y = offsets[1];
			case SUBTITLES_BOTTOM:
				y = FlxG.height - height - offsets[1];
		}
	}

	function set_alignment(value:SubtitlesAlignment):SubtitlesAlignment
	{
		alignment = value;
		updatePosition();
		return alignment;
	}

	function set_offsets(value:Array<Float>):Array<Float>
	{
		offsets = value;
		updatePosition();
		return offsets;
	}
}

/**
 * An `FlxText` that sets `htmlText`, so `.srt` tags such as `<i>` work.
 */
class SubtitlesText extends FlxText
{
	public function new(x:Float = 0, y:Float = 0, size:Int, font:String)
	{
		super(x, y, 0, '', size);

		this.font = font;
		this.size = size;
		this.alignment = CENTER;
	}

	override function set_text(value:String):String
	{
		text = value;
		if (textField != null)
		{
			final old:String = textField.htmlText;
			textField.htmlText = value;
			_regen = (textField.htmlText != old) || _regen;
		}
		return value;
	}

	override function applyFormats(_:openfl.text.TextFormat, __:Bool = false):Void {}
}

enum abstract SubtitlesAlignment(String) from String to String
{
	var SUBTITLES_TOP = 'top';
	var SUBTITLES_BOTTOM = 'bottom';
}
