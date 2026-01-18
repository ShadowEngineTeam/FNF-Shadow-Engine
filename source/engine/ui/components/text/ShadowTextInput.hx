package ui.components.text;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import backend.Paths;
import ui.ShadowStyle;
import ui.components.text.ShadowInputText;
import ui.components.controls.ShadowDropdown;

class ShadowTextInput extends FlxSpriteGroup {
	public var input:ShadowInputText;
	public var callback:String->Void;
	public var text(get, set):String;

	var bg:FlxSprite;
	var _width:Int;
	var _height:Int;
	var _hovered:Bool = false;

	public function new(x:Float, y:Float, width:Int, ?defaultText:String, ?onChange:String->Void) {
		super(x, y);
		_width = width;
		_height = ShadowStyle.HEIGHT_INPUT;
		callback = onChange;

		bg = new FlxSprite();
		bg.makeGraphic(_width, _height, ShadowStyle.BG_INPUT, true);
		drawBorder(ShadowStyle.BORDER_DARK);
		add(bg);

		var startText = defaultText != null ? defaultText : "";
		input = new ShadowInputText(2, 0, _width - 4, "", ShadowStyle.FONT_SIZE_MD, ShadowStyle.TEXT_PRIMARY, FlxColor.TRANSPARENT, true);
		input.setFormat(Paths.font(ShadowStyle.FONT_DEFAULT), ShadowStyle.FONT_SIZE_MD, ShadowStyle.TEXT_PRIMARY);
		input.antialiasing = ShadowStyle.antialiasing;
		input.background = false;
		input.fieldBorderThickness = 0;
		input.caretColor = ShadowStyle.TEXT_PRIMARY;
		input.selectionColor = FlxColor.fromRGB(196, 30, 58, 96);
		input.y = Std.int((_height - ShadowStyle.FONT_SIZE_MD) / 2) - 2;
		input.text = startText;
		input.callback = function(text:String, action:String) {
			if (callback != null)
				callback(text);
		};
		add(input);
	}

	function drawBorder(borderColor:FlxColor):Void {
		bg.makeGraphic(_width, _height, ShadowStyle.BG_INPUT, true);
		for (i in 0..._width) {
			bg.pixels.setPixel32(i, 0, borderColor);
			bg.pixels.setPixel32(i, _height - 1, borderColor);
		}
		for (i in 0..._height) {
			bg.pixels.setPixel32(0, i, borderColor);
			bg.pixels.setPixel32(_width - 1, i, borderColor);
		}
	}

	override public function update(elapsed:Float):Void {
		if (!visible || !active || !exists)
			return;

		super.update(elapsed);

		var inputBlocked = ShadowDropdown.isClickCaptured() || ShadowDropdown.isAnyOpen();
		var mouseOver = !inputBlocked && FlxG.mouse.overlaps(bg, camera);
		var highlight = mouseOver || (input != null && input.hasFocus);

		if (highlight && !_hovered) {
			_hovered = true;
			drawBorder(ShadowStyle.ACCENT);
		} else if (!highlight && _hovered) {
			_hovered = false;
			drawBorder(ShadowStyle.BORDER_DARK);
		}
	}

	public function hasFocus():Bool {
		return input != null && input.hasFocus;
	}

	public function setFocus(value:Bool):Void {
		if (input != null)
			input.hasFocus = value;
	}

	function get_text():String {
		return input != null ? input.text : "";
	}

	function set_text(value:String):String {
		if (input != null)
			input.text = value;
		return value;
	}
}
