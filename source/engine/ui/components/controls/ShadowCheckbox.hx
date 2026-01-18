package ui.components.controls;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import backend.Paths;
import ui.ShadowStyle;

class ShadowCheckbox extends FlxSpriteGroup
{
	public var checked(get, set):Bool;
	public var callback:Bool->Void;
	public var box:FlxSprite;
	public var checkmark:FlxSprite;
	public var label:FlxText;

	var _size:Int;
	var _hovered:Bool = false;
	var _checked:Bool = false;
	var _mousePos:FlxPoint = new FlxPoint();

	public function new(x:Float, y:Float, text:String, defaultValue:Bool = false, ?onChange:Bool->Void)
	{
		super(x, y);
		_size = ShadowStyle.HEIGHT_CHECKBOX;
		callback = onChange;

		box = new FlxSprite();
		drawBox(ShadowStyle.BORDER_DARK);
		add(box);

		checkmark = new FlxSprite();
		drawCheckmark();
		checkmark.visible = false;
		add(checkmark);

		label = new FlxText(_size + ShadowStyle.SPACING_SM, 0, 0, text);
		label.setFormat(Paths.font(ShadowStyle.FONT_DEFAULT), ShadowStyle.FONT_SIZE_MD, ShadowStyle.TEXT_PRIMARY);
		label.antialiasing = ShadowStyle.antialiasing;
		label.y = (_size - label.height) / 2;
		add(label);

		checked = defaultValue;
	}

	function drawBox(borderColor:FlxColor)
	{
		box.makeGraphic(_size, _size, ShadowStyle.BG_INPUT, true);
		for (i in 0..._size)
		{
			box.pixels.setPixel32(i, 0, borderColor);
			box.pixels.setPixel32(i, _size - 1, borderColor);
			box.pixels.setPixel32(0, i, borderColor);
			box.pixels.setPixel32(_size - 1, i, borderColor);
		}
	}

	function drawCheckmark()
	{
		checkmark.makeGraphic(_size, _size, FlxColor.TRANSPARENT, true);
		var c = ShadowStyle.ACCENT;
		for (i in 0...4)
		{
			checkmark.pixels.setPixel32(3 + i, 8 + i, c);
			checkmark.pixels.setPixel32(4 + i, 8 + i, c);
		}
		for (i in 0...6)
		{
			checkmark.pixels.setPixel32(6 + i, 11 - i, c);
			checkmark.pixels.setPixel32(7 + i, 11 - i, c);
		}
	}

	function get_checked():Bool
	{
		return _checked;
	}

	function set_checked(value:Bool):Bool
	{
		_checked = value;
		if (checkmark != null)
			checkmark.visible = value;
		return value;
	}

	public function setChecked(value:Bool):Void
	{
		_checked = value;
		if (checkmark != null)
			checkmark.visible = value;
	}

	inline function isMouseOver():Bool
	{
		return FlxG.mouse.overlaps(box, camera) || FlxG.mouse.overlaps(label, camera);
	}

	override function set_visible(Value:Bool):Bool
	{
		var v = super.set_visible(Value);
		if (checkmark != null)
			checkmark.visible = v && _checked;
		return v;
	}

	override function update(elapsed:Float)
	{
		if (!visible || !active || !exists)
			return;

		super.update(elapsed);

		if (checkmark != null)
			checkmark.visible = _checked;

		var inputBlocked = ShadowDropdown.isClickCaptured() || ShadowDropdown.isAnyOpen();
		var mouseOver = !inputBlocked && isMouseOver();

		if (mouseOver && !_hovered)
		{
			_hovered = true;
			drawBox(ShadowStyle.ACCENT);
		}
		else if (!mouseOver && _hovered)
		{
			_hovered = false;
			drawBox(ShadowStyle.BORDER_DARK);
		}

		if (!inputBlocked && mouseOver && FlxG.mouse.justPressed)
		{
			checked = !checked;
			if (callback != null)
				callback(checked);
		}
	}
}
