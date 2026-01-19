package backend.ui.components.controls;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import backend.Paths;
import backend.ui.ShadowStyle;

class ShadowSlider extends FlxSpriteGroup
{
	public var value(get, set):Float;
	public var callback:Float->Void;

	public var min:Float;
	public var max:Float;
	public var decimals:Int;
	public var showValue:Bool;

	var track:FlxSprite;
	var fill:FlxSprite;
	var thumb:FlxSprite;
	var valueText:FlxText;

	var _width:Int;
	var _height:Int;
	var _thumbWidth:Int = 12;
	var _thumbHeight:Int = 20;
	var _trackHeight:Int = 8;
	var _value:Float = 0;
	var _dragging:Bool = false;
	var _hovered:Bool = false;
	var _mousePos:FlxPoint = new FlxPoint();

	public function new(x:Float, y:Float, minValue:Float, maxValue:Float, defaultValue:Float, ?onChange:Float->Void, width:Int = 150, decimalPlaces:Int = 1, showValueLabel:Bool = true)
	{
		super(x, y);

		min = minValue;
		max = maxValue;
		decimals = decimalPlaces;
		callback = onChange;
		showValue = showValueLabel;
		_width = width;
		_height = ShadowStyle.HEIGHT_INPUT;

		var trackY = Std.int((_height - _trackHeight) / 2);
		track = new FlxSprite(0, trackY);
		drawTrack();
		add(track);

		fill = new FlxSprite(1, trackY + 1);
		fill.makeGraphic(1, _trackHeight - 2, ShadowStyle.ACCENT, true);
		add(fill);

		thumb = new FlxSprite(0, Std.int((_height - _thumbHeight) / 2));
		drawThumb(ShadowStyle.BG_LIGHT);
		add(thumb);

		if (showValue)
		{
			valueText = new FlxText(_width + ShadowStyle.SPACING_SM, 0, 50, "");
			valueText.setFormat(Paths.font(ShadowStyle.FONT_DEFAULT), ShadowStyle.FONT_SIZE_MD, ShadowStyle.TEXT_PRIMARY);
			valueText.antialiasing = ShadowStyle.antialiasing;
			valueText.y = (_height - valueText.height) / 2;
			add(valueText);
		}

		value = defaultValue;
	}

	function drawTrack()
	{
		track.makeGraphic(_width, _trackHeight, ShadowStyle.BG_INPUT, true);
		for (i in 0..._width)
		{
			track.pixels.setPixel32(i, 0, ShadowStyle.BORDER_DARK);
			track.pixels.setPixel32(i, _trackHeight - 1, ShadowStyle.BORDER_DARK);
		}
		for (i in 0..._trackHeight)
		{
			track.pixels.setPixel32(0, i, ShadowStyle.BORDER_DARK);
			track.pixels.setPixel32(_width - 1, i, ShadowStyle.BORDER_DARK);
		}
	}

	function drawThumb(borderColor:FlxColor)
	{
		thumb.makeGraphic(_thumbWidth, _thumbHeight, ShadowStyle.BG_MEDIUM, true);
		for (i in 0..._thumbWidth)
		{
			thumb.pixels.setPixel32(i, 0, borderColor);
			thumb.pixels.setPixel32(i, _thumbHeight - 1, borderColor);
		}
		for (i in 0..._thumbHeight)
		{
			thumb.pixels.setPixel32(0, i, borderColor);
			thumb.pixels.setPixel32(_thumbWidth - 1, i, borderColor);
		}

		var centerX = Std.int(_thumbWidth / 2);
		for (i in 4...(_thumbHeight - 4))
		{
			thumb.pixels.setPixel32(centerX, i, ShadowStyle.BORDER_LIGHT);
		}
	}

	function updateFill()
	{
		var percent = (max != min) ? (_value - min) / (max - min) : 0;
		var fillWidth = Std.int(Math.max(1, (_width - 2) * percent));
		var trackY = Std.int((_height - _trackHeight) / 2);
		fill.makeGraphic(fillWidth, _trackHeight - 2, ShadowStyle.ACCENT, true);
	}

	function updateThumbPosition()
	{
		var percent = (max != min) ? (_value - min) / (max - min) : 0;
		var usableWidth = _width - _thumbWidth;
		thumb.x = this.x + percent * usableWidth;
	}

	function get_value():Float
		return _value;

	function set_value(v:Float):Float
	{
		_value = Math.max(min, Math.min(max, v));

		updateFill();
		updateThumbPosition();

		if (valueText != null)
		{
			if (decimals > 0)
				valueText.text = Std.string(Math.round(_value * Math.pow(10, decimals)) / Math.pow(10, decimals));
			else
				valueText.text = Std.string(Std.int(_value));
		}

		return _value;
	}

	inline function isMouseOver(sprite:FlxSprite):Bool
		return FlxG.mouse.overlaps(sprite, camera);

	inline function isMouseOverSlider():Bool
		return isMouseOver(track) || isMouseOver(thumb);

	function getValueFromMouseX():Float
	{
		FlxG.mouse.getScreenPosition(camera, _mousePos);
		var localX = _mousePos.x - (this.x + _thumbWidth / 2);
		var usableWidth = _width - _thumbWidth;

		var percent = Math.max(0, Math.min(1, localX / usableWidth));
		return min + percent * (max - min);
	}

	override function update(elapsed:Float)
	{
		if (!visible || !active || !exists)
			return;

		super.update(elapsed);

		var inputBlocked = ShadowDropdown.isClickCaptured() || ShadowDropdown.isAnyOpen();
		var overThumb = !inputBlocked && isMouseOver(thumb);
		var overSlider = !inputBlocked && isMouseOverSlider();

		if ((overThumb || _dragging) && !_hovered)
		{
			_hovered = true;
			drawThumb(ShadowStyle.ACCENT);
		}
		else if (!overThumb && !_dragging && _hovered)
		{
			_hovered = false;
			drawThumb(ShadowStyle.BG_LIGHT);
		}

		if (FlxG.mouse.justPressed && !inputBlocked && overSlider)
		{
			_dragging = true;
			var newValue = getValueFromMouseX();
			if (newValue != _value)
			{
				value = newValue;
				if (callback != null)
					callback(_value);
			}
		}

		if (_dragging)
		{
			if (FlxG.mouse.pressed)
			{
				var newValue = getValueFromMouseX();
				if (newValue != _value)
				{
					value = newValue;
					if (callback != null)
						callback(_value);
				}
			}
			else
			{
				_dragging = false;
			}
		}

		// Mouse wheel support
		if (overSlider && FlxG.mouse.wheel != 0 && !inputBlocked)
		{
			var step = (max - min) / 20; // 5% increments
			var multiplier = FlxG.keys.pressed.SHIFT ? 5 : 1;
			var newValue = _value + step * FlxG.mouse.wheel * multiplier;
			newValue = Math.max(min, Math.min(max, newValue));
			if (newValue != _value)
			{
				value = newValue;
				if (callback != null)
					callback(_value);
			}
		}
	}
}
