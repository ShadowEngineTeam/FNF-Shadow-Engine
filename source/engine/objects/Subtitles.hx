package objects;

import backend.SRTUtil;
import flixel.sound.FlxSound;

/**
 * Shows the lines of an `.srt` file in time with a sound, as in Funkin.
 */
class Subtitles extends FlxSpriteGroup
{
	var subtitleText:SubtitlesText;
	var background:FlxSprite;
	var subtitlesData:Array<SubtitleEntry>;
	var assignedSound:FlxSound;

	public var offsets(default, set):Array<Float> = [0, 0];
	public var alignment(default, set):SubtitlesAlignment = SUBTITLES_BOTTOM;

	public function new(x:Float = 0, y:Float = 0, alignment:SubtitlesAlignment = SUBTITLES_BOTTOM)
	{
		super(0, 0);

		background = new FlxSprite();
		background.alpha = 0.5;
		add(background);

		subtitleText = new SubtitlesText(0, 0, 30, Paths.font('vcr.ttf'));
		add(subtitleText);

		this.offsets = [x, y];
		this.alignment = alignment;

		setText([], true);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (assignedSound == null || subtitlesData == null)
			return;

		final currentLines:Array<String> = [];
		for (data in subtitlesData)
			if (assignedSound.time >= data.start && assignedSound.time <= data.end)
				currentLines.unshift(data.text);

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

		if (sound == null)
			return;

		final data:Array<SubtitleEntry> = SRTParser.parseFromFile(key);
		if (data.length == 0)
			return;

		subtitlesData = data;
		assignedSound = sound;
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
