package backend;

import flixel.util.FlxSave;
import openfl.utils.Assets;
#if linux
import sys.io.Process;
#end

class CoolUtil
{
	public static function quantize(f:Float, snap:Float)
	{
		// changed so this actually works lol
		var m:Float = Math.fround(f * snap);
		// trace(snap);
		return (m / snap);
	}

	public static function capitalize(text:String)
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:String = null;
		var formatted:Array<String> = path.split(':'); // prevent "shared:", "preload:" and other library names on file path
		path = formatted[formatted.length - 1];
		if (FileSystem.exists(path))
			daList = File.getContent(path);
		return daList != null ? listFromString(daList) : [];
	}

	public static function colorFromString(color:String):FlxColor
	{
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if (color.startsWith('0x'))
			color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if (colorNum == null)
			colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	public static function listFromString(string:String):Array<String>
	{
		if (string == null)
			return [""];

		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
			daList[i] = daList[i].trim();

		return daList;
	}

	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if (decimals < 1)
			return Math.floor(value);

		var tempMult:Float = 1;
		for (i in 0...decimals)
			tempMult *= 10;

		var newValue:Float = Math.floor(value * tempMult);
		return newValue / tempMult;
	}

	public static function dominantColor(sprite:flixel.FlxSprite):Int
	{
		var countByColor:Map<Int, Int> = [];
		for (col in 0...sprite.frameWidth)
		{
			for (row in 0...sprite.frameHeight)
			{
				var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
				if (colorOfThisPixel != 0)
				{
					if (countByColor.exists(colorOfThisPixel))
						countByColor[colorOfThisPixel] = countByColor[colorOfThisPixel] + 1;
					else if (countByColor[colorOfThisPixel] != 13520687 - (2 * 13520687))
						countByColor[colorOfThisPixel] = 1;
				}
			}
		}

		var maxCount = 0;
		var maxKey:Int = 0; // after the loop this will store the max color
		countByColor[FlxColor.BLACK] = 0;
		for (key in countByColor.keys())
		{
			if (countByColor[key] >= maxCount)
			{
				maxCount = countByColor[key];
				maxKey = key;
			}
		}
		countByColor = [];
		return maxKey;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
			dumbArray.push(i);

		return dumbArray;
	}

	public static function browserLoad(site:String)
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	public static function openFolder(folder:String, absolute:Bool = false)
	{
		#if sys
		if (!absolute)
			folder = Sys.getCwd() + '$folder';

		folder = folder.replace('/', '\\');
		if (folder.endsWith('/'))
			folder.substr(0, folder.length - 1);

		#if linux
		var command:String = '/usr/bin/xdg-open';
		#else
		var command:String = 'explorer.exe';
		#end
		Sys.command(command, [folder]);
		trace('$command $folder');
		#else
		FlxG.log.error("Platform is not supported for CoolUtil.openFolder");
		#end
	}

	/**
		Helper Function to Fix Save Files for Flixel 5

		-- EDIT: [November 29, 2023] --

		this function is used to get the save path, period.
		since newer flixel versions are being enforced anyways.
		@crowplexus
	**/
	@:access(flixel.util.FlxSave.validate)
	public static function getSavePath():String
	{
		final company:String = FlxG.stage.application.meta.get('company');
		// #if (flixel < "5.0.0") return company; #else
		return '${company}/${flixel.util.FlxSave.validate(FlxG.stage.application.meta.get('file'))}';
		// #end
	}

	public static function loadSong(?name:String = null, ?difficultyNum:Int = -1)
	{
		if (name == null || name.length < 1)
			name = PlayState.SONG.song;
		if (difficultyNum == -1)
			difficultyNum = PlayState.storyDifficulty;

		var poop:String = Highscore.formatSong(name, difficultyNum);
		PlayState.SONG = Song.loadFromJson(poop, name);
		PlayState.storyDifficulty = difficultyNum;
		LoadingState.prepareToSong();
		LoadingState.loadAndSwitchState(new PlayState());

		// FlxG.sound.music.pause();
		// FlxG.sound.music.volume = 0;
	}

	public static function setTextBorderFromString(text:FlxText, border:String)
	{
		switch (border.toLowerCase().trim())
		{
			case 'shadow':
				text.borderStyle = SHADOW;
			case 'outline':
				text.borderStyle = OUTLINE;
			case 'outline_fast', 'outlinefast':
				text.borderStyle = OUTLINE_FAST;
			default:
				text.borderStyle = NONE;
		}
	}

	public static function showPopUp(message:String, title:String):Void
	{
		/*#if android
		AndroidTools.showAlertDialog(title, message, {name: "OK", func: null}, null);
		#else*/
		#if linux
		function findAndRun(cmd:String, args:Array<String>):Bool
		{
			if (!FileSystem.exists(cmd))
				return false;
			var p:Process = new Process(cmd, args);
			p.exitCode();
			p.close();
			return true;
		}

		if (findAndRun("/usr/bin/kdialog", ["--title", title, "--error", message]))
			return;
		if (findAndRun("/usr/bin/zenity", ["--error", "--title", title, "--text", message]))
			return;
		if (findAndRun("/usr/bin/yad", ["--error", "--title", title, "--text", message, "--button=OK:0"]))
			return;
		if (findAndRun("/usr/bin/xmessage", ["-center", title + "\n\n" + message]))
			return;

		trace('$title\n$message\n');
		#else
		FlxG.stage.window.alert(message, title);
		#end
	}

	private static var sizeLabels:Array<String> = ["B", "KB", "MB", "GB", "TB"];

	public static inline function addZeros(str:String, num:Int)
	{
		while (str.length < num)
			str = '0${str}';
		return str;
	}

	public static inline function getFPSRatio(ratio:Float, ?delta:Float):Float
		return 1.0 - Math.pow(1.0 - ratio, (delta == null ? FlxG.elapsed : delta) * 60);

	public static inline function fpsLerp(v1:Float, v2:Float, ratio:Float):Float
		return FlxMath.lerp(v1, v2, getFPSRatio(ratio));

	public static function getSizeString(size:Float):String
	{
		var rSize:Float = size;
		var label:Int = 0;
		var len = sizeLabels.length;
		while (rSize >= 1024 && label < len - 1)
		{
			label++;
			rSize /= 1024;
		}
		return Std.int(rSize) + ((label <= 1) ? "" : "." + addZeros(Std.string(Std.int((rSize % 1) * 100)), 2)) + sizeLabels[label];
	}

	public static function getSizeString64(size:#if cpp cpp.Float64 #else Float #end):String
	{
		var rSize:#if cpp cpp.Float64 #else Float #end = size;
		var label:Int = 0;
		var len = sizeLabels.length;
		while (rSize >= 1024 && label < len - 1)
		{
			label++;
			rSize /= 1024;
		}
		return Std.int(rSize) + ((label <= 1) ? "" : "." + addZeros(Std.string(Std.int((rSize % 1) * 100)), 2)) + sizeLabels[label];
	}

	public static function easeInOutCirc(x:Float):Float
	{
		if (x <= 0.0)
			return 0.0;
		if (x >= 1.0)
			return 1.0;
		var result:Float = (x < 0.5) ? (1 - Math.sqrt(1 - 4 * x * x)) / 2 : (Math.sqrt(1 - 4 * (1 - x) * (1 - x)) + 1) / 2;
		return (result == Math.NaN) ? 1.0 : result;
	}

	public static function easeInBack(x:Float, ?c:Float = 1.70158):Float
	{
		if (x <= 0.0)
			return 0.0;
		if (x >= 1.0)
			return 1.0;
		return (1 + c) * x * x * x - c * x * x;
	}

	public static function easeOutBack(x:Float, ?c:Float = 1.70158):Float
	{
		if (x <= 0.0)
			return 0.0;
		if (x >= 1.0)
			return 1.0;
		return 1 + (c + 1) * Math.pow(x - 1, 3) + c * Math.pow(x - 1, 2);
	}
}
