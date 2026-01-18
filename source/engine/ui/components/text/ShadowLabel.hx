package ui.components.text;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import backend.Paths;
import ui.ShadowStyle;

class ShadowLabel extends FlxText {
	public function new(x:Float, y:Float, text:String, ?size:Int, ?color:FlxColor, fieldWidth:Int = 0) {
		super(x, y, fieldWidth, text);
		var fontSize = size != null ? size : ShadowStyle.FONT_SIZE_MD;
		var textColor = color != null ? color : ShadowStyle.TEXT_PRIMARY;
		setFormat(Paths.font(ShadowStyle.FONT_DEFAULT), fontSize, textColor);
		antialiasing = ShadowStyle.antialiasing;
	}

	public function setSecondary() {
		color = ShadowStyle.TEXT_SECONDARY;
	}

	public function setAccent() {
		color = ShadowStyle.ACCENT;
	}
}
