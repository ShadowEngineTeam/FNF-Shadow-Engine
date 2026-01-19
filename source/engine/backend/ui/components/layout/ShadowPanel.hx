package backend.ui.components.layout;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import backend.ui.ShadowStyle;

class ShadowPanel extends FlxSpriteGroup
{
	public var bg:FlxSprite;

	var _width:Int;
	var _height:Int;

	var _dragging:Bool = false;
	var _dragOffsetX:Float = 0;
	var _dragOffsetY:Float = 0;

	public function new(x:Float, y:Float, width:Int = 300, height:Int = 200, ?bgColor:FlxColor, ?borderColor:FlxColor)
	{
		super(x, y);
		_width = width;
		_height = height;

		var fill = bgColor != null ? bgColor : ShadowStyle.BG_DARK;
		var border = borderColor != null ? borderColor : ShadowStyle.BORDER_DARK;

		bg = new FlxSprite();
		drawBackground(fill, border);
		add(bg);
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

	public function resize(width:Int, height:Int, ?bgColor:FlxColor, ?borderColor:FlxColor)
	{
		_width = width;
		_height = height;
		var fill = bgColor != null ? bgColor : ShadowStyle.BG_DARK;
		var border = borderColor != null ? borderColor : ShadowStyle.BORDER_DARK;
		drawBackground(fill, border);
	}

	override function update(elapsed:Float)
	{
		if (!visible || !active || !exists)
			return;

		super.update(elapsed);

		if (FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.overlaps(bg, camera))
			{
				_dragging = true;
				_dragOffsetX = FlxG.mouse.screenX - this.x;
				_dragOffsetY = FlxG.mouse.screenY - this.y;
			}
		}

		if (_dragging)
		{
			if (FlxG.mouse.pressed)
			{
				this.x = FlxG.mouse.screenX - _dragOffsetX;
				this.y = FlxG.mouse.screenY - _dragOffsetY;
			}
			else
			{
				_dragging = false;
			}
		}
	}
}
