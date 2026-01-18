package ui.components.controls;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import backend.Paths;
import ui.ShadowStyle;

class ShadowStepper extends FlxSpriteGroup
{
	public var value(get, set):Float;
	public var callback:Float->Void;

	public var min:Float;
	public var max:Float;
	public var step:Float;
	public var decimals:Int;

	var bg:FlxSprite;
	var valueText:FlxText;
	var upArrow:FlxSprite;
	var downArrow:FlxSprite;

	var _width:Int;
	var _height:Int;
	var _arrowWidth:Int = 16;
	var _upHovered:Bool = false;
	var _downHovered:Bool = false;
	var _value:Float = 0;
	var _textScroll:Float = 0;
	var _scrollSpeed:Float = 40;
	var _mousePos:FlxPoint = new FlxPoint();

	public function new(x:Float, y:Float, stepSize:Float = 1, defaultValue:Float = 0, minValue:Float = -999, maxValue:Float = 999, decimalPlaces:Int = 0, ?onChange:Float->Void, width:Int = 64)
	{
		super(x, y);

		step = stepSize;
		min = minValue;
		max = maxValue;
		decimals = decimalPlaces;
		callback = onChange;
		_width = width;
		_height = ShadowStyle.HEIGHT_INPUT;

		bg = new FlxSprite();
		drawBackground();
		add(bg);

		var arrowHeight = Std.int(_height / 2);
		upArrow = new FlxSprite(_width - _arrowWidth, 0);
		drawUpArrow(ShadowStyle.TEXT_SECONDARY, arrowHeight);
		add(upArrow);

		downArrow = new FlxSprite(_width - _arrowWidth, arrowHeight);
		drawDownArrow(ShadowStyle.TEXT_SECONDARY, arrowHeight);
		add(downArrow);

		var textWidth = _width - _arrowWidth - ShadowStyle.SPACING_XS * 2;
		valueText = new FlxText(ShadowStyle.SPACING_XS, 0, textWidth, "");
		valueText.setFormat(Paths.font(ShadowStyle.FONT_DEFAULT), ShadowStyle.FONT_SIZE_MD, ShadowStyle.TEXT_PRIMARY, CENTER);
		valueText.antialiasing = ShadowStyle.antialiasing;
		valueText.y = (_height - valueText.height) / 2;
		add(valueText);

		value = defaultValue;
	}

	function drawBackground()
	{
		bg.makeGraphic(_width, _height, ShadowStyle.BG_INPUT, true);
		for (i in 0..._width)
		{
			bg.pixels.setPixel32(i, 0, ShadowStyle.BORDER_DARK);
			bg.pixels.setPixel32(i, _height - 1, ShadowStyle.BORDER_DARK);
		}
		for (i in 0..._height)
		{
			bg.pixels.setPixel32(0, i, ShadowStyle.BORDER_DARK);
			bg.pixels.setPixel32(_width - 1, i, ShadowStyle.BORDER_DARK);
			bg.pixels.setPixel32(_width - _arrowWidth - 1, i, ShadowStyle.BORDER_DARK);
		}

		var midY = Std.int(_height / 2);
		for (i in (_width - _arrowWidth)..._width)
		{
			bg.pixels.setPixel32(i, midY, ShadowStyle.BORDER_DARK);
		}
	}

	function drawUpArrow(color:FlxColor, arrowHeight:Int)
	{
		upArrow.makeGraphic(_arrowWidth, arrowHeight, ShadowStyle.BG_MEDIUM, true);
		var cx = Std.int(_arrowWidth / 2);
		var cy = Std.int(arrowHeight / 2);
		// Draw upward pointing triangle
		for (row in 0...4)
		{
			for (col in 0...(row * 2 + 1))
			{
				var px = cx - row + col;
				var py = cy + row - 1;
				if (px >= 0 && px < _arrowWidth && py >= 0 && py < arrowHeight)
					upArrow.pixels.setPixel32(px, py, color);
			}
		}
	}

	function drawDownArrow(color:FlxColor, arrowHeight:Int)
	{
		downArrow.makeGraphic(_arrowWidth, arrowHeight, ShadowStyle.BG_MEDIUM, true);
		var cx = Std.int(_arrowWidth / 2);
		var cy = Std.int(arrowHeight / 2);
		// Draw downward pointing triangle
		for (row in 0...4)
		{
			for (col in 0...(row * 2 + 1))
			{
				var px = cx - row + col;
				var py = cy - row + 1;
				if (px >= 0 && px < _arrowWidth && py >= 0 && py < arrowHeight)
					downArrow.pixels.setPixel32(px, py, color);
			}
		}
	}

	function get_value():Float
		return _value;

	function set_value(v:Float):Float
	{
		_value = Math.max(min, Math.min(max, v));
		if (valueText != null)
		{
			if (decimals > 0)
				valueText.text = Std.string(Math.round(_value * Math.pow(10, decimals)) / Math.pow(10, decimals));
			else
				valueText.text = Std.string(Std.int(_value));
			_textScroll = 0;
		}
		return _value;
	}

	inline function isMouseOver(sprite:FlxSprite):Bool
		return FlxG.mouse.overlaps(sprite, camera);

	function getTextOverflow():Float
	{
		if (valueText == null || valueText.textField == null)
			return 0;
		var textW = valueText.textField.textWidth;
		var fieldW = valueText.fieldWidth;
		if (textW > fieldW)
			return textW - fieldW + 4;
		return 0;
	}

	override function update(elapsed:Float)
	{
		if (!visible || !active || !exists)
			return;

		super.update(elapsed);

		var arrowHeight = Std.int(_height / 2);
		var inputBlocked = ShadowDropdown.isClickCaptured() || ShadowDropdown.isAnyOpen();
		var overUp = !inputBlocked && isMouseOver(upArrow);
		var overDown = !inputBlocked && isMouseOver(downArrow);
		var overBg = !inputBlocked && isMouseOver(bg);

		if (overUp && !_upHovered)
		{
			_upHovered = true;
			drawUpArrow(ShadowStyle.ACCENT, arrowHeight);
		}
		else if (!overUp && _upHovered)
		{
			_upHovered = false;
			drawUpArrow(ShadowStyle.TEXT_SECONDARY, arrowHeight);
		}

		if (overDown && !_downHovered)
		{
			_downHovered = true;
			drawDownArrow(ShadowStyle.ACCENT, arrowHeight);
		}
		else if (!overDown && _downHovered)
		{
			_downHovered = false;
			drawDownArrow(ShadowStyle.TEXT_SECONDARY, arrowHeight);
		}

		if (FlxG.mouse.justPressed && !inputBlocked)
		{
			if (overUp)
			{
				value += step;
				if (callback != null)
					callback(_value);
			}
			else if (overDown)
			{
				value -= step;
				if (callback != null)
					callback(_value);
			}
		}

		if (valueText != null && valueText.textField != null)
			valueText.textField.scrollH = Std.int(_textScroll);

		if (overBg && FlxG.mouse.wheel != 0 && !inputBlocked)
		{
			var multiplier = FlxG.keys.pressed.SHIFT ? 10 : 1;
			value += step * FlxG.mouse.wheel * multiplier;
			if (callback != null)
				callback(_value);
		}
	}
}
