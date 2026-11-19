package backend;

using StringTools;

class SubtitleEntry
{
	public var id:Int;
	public var start:Float; // ms
	public var end:Float; // ms
	public var text:String;
	// set when the line has karaoke tags like `{\k25}Spa{\k18}ghet`
	public var syllables:Null<Array<KaraokeSyllable>>;
	// set when a karaoke line is wrapped in `<font color="#RRGGBB">`, the color it is sung in
	public var color:Null<String>;

	public function new(id:Int = 0, start:Float = 0, end:Float = 0, text:String = '')
	{
		this.id = id;
		this.start = start;
		this.end = end;
		this.text = text;
	}
}

class KaraokeSyllable
{
	public var text:String;
	public var start:Float; // ms
	public var end:Float; // ms

	public function new(text:String, start:Float, end:Float)
	{
		this.text = text;
		this.start = start;
		this.end = end;
	}
}

class SRTParser
{
	public static var convertBracesToAngles:Bool = true;

	static final timeArrowPatterns:Array<String> = ['-->', '->', '—>', '–>'];

	public static function parseFromString(s:String):Array<SubtitleEntry>
	{
		final out:Array<SubtitleEntry> = [];
		if (s == null)
			return out;

		var normalized:String = s.replace('\r\n', '\n').replace('\r', '\n');
		if (normalized.length > 0 && normalized.charCodeAt(0) == 0xFEFF)
			normalized = normalized.substr(1);

		for (block in normalized.split('\n\n'))
		{
			final trimmed:String = block.trim();
			if (trimmed.length == 0)
				continue;

			final lines:Array<String> = trimmed.split('\n');
			var idx:Int = 0;
			var number:Int = 0;

			if (isNumeric(lines[0]))
			{
				number = Std.parseInt(lines[0]);
				idx = 1;
			}
			if (idx >= lines.length)
				continue;

			final times:Null<{start:Float, end:Float}> = parseTimeLine(lines[idx]);
			if (times == null)
				continue;

			final entry:SubtitleEntry = new SubtitleEntry(number, times.start, times.end, lines.slice(idx + 1).join('\n'));
			parseKaraoke(entry);
			if (convertBracesToAngles)
				entry.text = entry.text.replace('{', '<').replace('}', '>');

			out.push(entry);
		}

		out.sort((a:SubtitleEntry, b:SubtitleEntry) -> a.id - b.id);
		return out;
	}

	/**
	 * Parses `data/<key>.srt`, looking in mods first.
	 */
	public static function parseFromFile(key:String):Array<SubtitleEntry>
	{
		return parseFromString(Paths.getTextFromFile('data/$key.srt'));
	}

	/**
	 * Reads ASS karaoke tags (`{\k}`, `{\kf}`, `{\ko}`, in centiseconds) into syllables, like Aegisub writes them.
	 */
	static function parseKaraoke(entry:SubtitleEntry):Void
	{
		final tag:EReg = ~/\{\\[kK][fo]?(\d+)\}/;
		if (!tag.match(entry.text))
			return;

		final font:EReg = ~/^<font color="#([0-9a-fA-F]{6})">([\s\S]*)<\/font>$/;
		if (font.match(entry.text))
		{
			entry.color = font.matched(1);
			entry.text = font.matched(2);
		}

		final syllables:Array<KaraokeSyllable> = [];
		var rest:String = entry.text;
		var time:Float = entry.start;
		var duration:Float = 0;
		while (true)
		{
			final found:Bool = tag.match(rest);
			final piece:String = found ? tag.matchedLeft() : rest;
			if (piece.length > 0)
				syllables.push(new KaraokeSyllable(piece, time, time + duration));
			time += duration;
			if (!found)
				break;

			duration = Std.parseInt(tag.matched(1)) * 10;
			rest = tag.matchedRight();
		}

		entry.syllables = syllables;
		entry.text = [for (syllable in syllables) syllable.text].join('');
	}

	public static function parseTimeLine(line:String):Null<{start:Float, end:Float}>
	{
		for (arrow in timeArrowPatterns)
		{
			final parts:Array<String> = line.split(arrow);
			if (parts.length == 2)
			{
				final start:Float = parseTimecode(parts[0]);
				final end:Float = parseTimecode(parts[1]);
				return (start < 0 || end < 0) ? null : {start: start, end: end};
			}
		}
		return null;
	}

	public static function parseTimecode(t:String):Float
	{
		final parts:Array<String> = t.trim().replace(',', '.').split(':');
		if (parts.length != 3)
			return -1;

		final secParts:Array<String> = parts[2].split('.');
		var ms:Int = 0;
		if (secParts.length > 1)
		{
			var frac:String = secParts[1];
			if (frac.length > 3)
				frac = frac.substr(0, 3);
			while (frac.length < 3)
				frac += '0';
			ms = Std.parseInt(frac);
		}
		return ((Std.parseInt(parts[0]) * 3600 + Std.parseInt(parts[1]) * 60 + Std.parseInt(secParts[0])) * 1000) + ms;
	}

	static function isNumeric(s:String):Bool
	{
		final t:String = s.trim();
		if (t.length == 0)
			return false;
		for (i in 0...t.length)
		{
			final code:Int = t.charCodeAt(i);
			if (code < '0'.code || code > '9'.code)
				return false;
		}
		return true;
	}
}
