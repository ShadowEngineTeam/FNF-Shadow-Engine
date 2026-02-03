package backend.ui.components.controls;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import backend.Paths;
import backend.ui.ShadowStyle;

class ShadowButton extends FlxSpriteGroup
{
	public var bg:FlxSprite;
	public var label:FlxText;
	public var callback:Void->Void;

	var _width:Int;
	var _height:Int;
	var _hovered:Bool = false;
	var _pressed:Bool = false;
	var _mousePos:FlxPoint = new FlxPoint();

	public function new(x:Float, y:Float, text:String, ?onClick:Void->Void, width:Int = 100, height:Int = 28)
	{
		super(x, y);
		_width = width;
		_height = height;
		callback = onClick;

		bg = new FlxSprite();
		drawBackground(ShadowStyle.BG_MEDIUM, ShadowStyle.BORDER_DARK);
		add(bg);

		label = new FlxText(0, 0, width, text);
		label.setFormat(Paths.font(ShadowStyle.FONT_DEFAULT), ShadowStyle.FONT_SIZE_MD, ShadowStyle.TEXT_PRIMARY, CENTER);
		label.antialiasing = ShadowStyle.antialiasing;
		label.y = (_height - label.height) / 2;
		add(label);
	}

	function drawBackground(fillColor:FlxColor, borderColor:FlxColor)
	{
		bg.makeGraphic(_width, _height, fillColor, true);
		for (i in 0..._width)
		{
			bg.pixels.setPixel32(i, 0, borderColor);
			bg.pixels.setPixel32(i, _height - 1, borderColor);
		}
		for (i in 0..._height)
		{
			bg.pixels.setPixel32(0, i, borderColor);
			bg.pixels.setPixel32(_width - 1, i, borderColor);
		}
	}

	inline function isMouseOver():Bool
	{
		return FlxG.mouse.overlaps(bg, camera);
	}

	override function update(elapsed:Float)
	{
		if (!visible || !active || !exists)
			return;

		super.update(elapsed);

		var inputBlocked:Bool = (ShadowDropdown.isClickCaptured() || ShadowDropdown.isAnyOpen());
		var mouseOver:Bool = (!inputBlocked && isMouseOver());
		var mousePressed:Bool = FlxG.mouse.pressed;
		var mouseJustPressed:Bool = FlxG.mouse.justPressed;

		if (mouseOver && !_hovered)
		{
			_hovered = true;
			drawBackground(ShadowStyle.BG_LIGHT, ShadowStyle.ACCENT);
		}
		else if (!mouseOver && _hovered)
		{
			_hovered = false;
			drawBackground(ShadowStyle.BG_MEDIUM, ShadowStyle.BORDER_DARK);
		}

		if (!inputBlocked && mouseOver && mouseJustPressed)
		{
			_pressed = true;
			drawBackground(ShadowStyle.BG_DARK, ShadowStyle.ACCENT);
		}

		if (_pressed && !mousePressed)
		{
			_pressed = false;
			if (mouseOver && callback != null)
			{
				callback();
			}
			drawBackground(mouseOver ? ShadowStyle.BG_LIGHT : ShadowStyle.BG_MEDIUM, mouseOver ? ShadowStyle.ACCENT : ShadowStyle.BORDER_DARK);
		}
	}

	public function setText(text:String)
	{
		label.text = text;
		label.y = (_height - label.height) / 2;
	}
}
