package ui;

import flixel.util.FlxColor;
import backend.ClientPrefs;

class ShadowStyle
{
	public static var antialiasing(get, never):Bool;

	static function get_antialiasing():Bool
		return ClientPrefs.data.antialiasing;

	public static inline var ShadowTHEME_DARK:String = "dark";
	public static inline var ShadowTHEME_LIGHT:String = "light";

	public static var DARK_ShadowTHEME:ShadowTheme = {
		bgDark: 0xFF1A1A1E,
		bgMedium: 0xFF252528,
		bgLight: 0xFF2E2E32,
		bgInput: 0xFF1E1E22,
		borderDark: 0xFF3A3A42,
		borderLight: 0xFF4A4A52,
		accent: 0xFFC41E3A,
		accentHover: 0xFFD42E4A,
		accentDark: 0xFF8B1528,
		textPrimary: 0xFFE8E8EC,
		textSecondary: 0xFF888890,
		textDisabled: 0xFF555558,
		spacingXs: 4,
		spacingSm: 8,
		spacingMd: 12,
		spacingLg: 16,
		spacingXl: 24,
		heightInput: 28,
		heightButton: 28,
		heightTab: 32,
		heightCheckbox: 16,
		fontSizeSm: 10,
		fontSizeMd: 12,
		fontSizeLg: 14,
		fontDefault: "Inconsolata-Bold.ttf"
	};

	public static var LIGHT_ShadowTHEME:ShadowTheme = {
		bgDark: 0xFFF2F2F4,
		bgMedium: 0xFFE6E6EA,
		bgLight: 0xFFDADAE0,
		bgInput: 0xFFFBFBFD,
		borderDark: 0xFFB6B6C0,
		borderLight: 0xFFCCCCD4,
		accent: 0xFFC41E3A,
		accentHover: 0xFFD42E4A,
		accentDark: 0xFF8B1528,
		textPrimary: 0xFF1B1B20,
		textSecondary: 0xFF4D4D58,
		textDisabled: 0xFF8A8A96,
		spacingXs: 4,
		spacingSm: 8,
		spacingMd: 12,
		spacingLg: 16,
		spacingXl: 24,
		heightInput: 28,
		heightButton: 28,
		heightTab: 32,
		heightCheckbox: 16,
		fontSizeSm: 10,
		fontSizeMd: 12,
		fontSizeLg: 14,
		fontDefault: "Inconsolata-Bold.ttf"
	};

	// Backgrounds
	public static var BG_DARK:FlxColor = DARK_ShadowTHEME.bgDark;
	public static var BG_MEDIUM:FlxColor = DARK_ShadowTHEME.bgMedium;
	public static var BG_LIGHT:FlxColor = DARK_ShadowTHEME.bgLight;
	public static var BG_INPUT:FlxColor = DARK_ShadowTHEME.bgInput;

	// Borders
	public static var BORDER_DARK:FlxColor = DARK_ShadowTHEME.borderDark;
	public static var BORDER_LIGHT:FlxColor = DARK_ShadowTHEME.borderLight;

	// Accent
	public static var ACCENT:FlxColor = DARK_ShadowTHEME.accent;
	public static var ACCENT_HOVER:FlxColor = DARK_ShadowTHEME.accentHover;
	public static var ACCENT_DARK:FlxColor = DARK_ShadowTHEME.accentDark;

	// Text
	public static var TEXT_PRIMARY:FlxColor = DARK_ShadowTHEME.textPrimary;
	public static var TEXT_SECONDARY:FlxColor = DARK_ShadowTHEME.textSecondary;
	public static var TEXT_DISABLED:FlxColor = DARK_ShadowTHEME.textDisabled;

	// Spacing
	public static var SPACING_XS:Int = DARK_ShadowTHEME.spacingXs;
	public static var SPACING_SM:Int = DARK_ShadowTHEME.spacingSm;
	public static var SPACING_MD:Int = DARK_ShadowTHEME.spacingMd;
	public static var SPACING_LG:Int = DARK_ShadowTHEME.spacingLg;
	public static var SPACING_XL:Int = DARK_ShadowTHEME.spacingXl;

	// Heights
	public static var HEIGHT_INPUT:Int = DARK_ShadowTHEME.heightInput;
	public static var HEIGHT_BUTTON:Int = DARK_ShadowTHEME.heightButton;
	public static var HEIGHT_TAB:Int = DARK_ShadowTHEME.heightTab;
	public static var HEIGHT_CHECKBOX:Int = DARK_ShadowTHEME.heightCheckbox;

	// Font
	public static var FONT_SIZE_SM:Int = DARK_ShadowTHEME.fontSizeSm;
	public static var FONT_SIZE_MD:Int = DARK_ShadowTHEME.fontSizeMd;
	public static var FONT_SIZE_LG:Int = DARK_ShadowTHEME.fontSizeLg;
	public static var FONT_DEFAULT:String = DARK_ShadowTHEME.fontDefault;

	public static function applyShadowTheme(Shadowtheme:ShadowTheme):Void
	{
		BG_DARK = Shadowtheme.bgDark;
		BG_MEDIUM = Shadowtheme.bgMedium;
		BG_LIGHT = Shadowtheme.bgLight;
		BG_INPUT = Shadowtheme.bgInput;
		BORDER_DARK = Shadowtheme.borderDark;
		BORDER_LIGHT = Shadowtheme.borderLight;
		ACCENT = Shadowtheme.accent;
		ACCENT_HOVER = Shadowtheme.accentHover;
		ACCENT_DARK = Shadowtheme.accentDark;
		TEXT_PRIMARY = Shadowtheme.textPrimary;
		TEXT_SECONDARY = Shadowtheme.textSecondary;
		TEXT_DISABLED = Shadowtheme.textDisabled;
		SPACING_XS = Shadowtheme.spacingXs;
		SPACING_SM = Shadowtheme.spacingSm;
		SPACING_MD = Shadowtheme.spacingMd;
		SPACING_LG = Shadowtheme.spacingLg;
		SPACING_XL = Shadowtheme.spacingXl;
		HEIGHT_INPUT = Shadowtheme.heightInput;
		HEIGHT_BUTTON = Shadowtheme.heightButton;
		HEIGHT_TAB = Shadowtheme.heightTab;
		HEIGHT_CHECKBOX = Shadowtheme.heightCheckbox;
		FONT_SIZE_SM = Shadowtheme.fontSizeSm;
		FONT_SIZE_MD = Shadowtheme.fontSizeMd;
		FONT_SIZE_LG = Shadowtheme.fontSizeLg;
		FONT_DEFAULT = Shadowtheme.fontDefault;
	}

	public static function setShadowThemeByName(name:String):Void
	{
		switch (name)
		{
			case ShadowTHEME_LIGHT:
				applyShadowTheme(LIGHT_ShadowTHEME);
			case ShadowTHEME_DARK:
				applyShadowTheme(DARK_ShadowTHEME);
			default:
				applyShadowTheme(DARK_ShadowTHEME);
		}
	}

	public static function applySavedTheme():Void
	{
		var theme:String = ClientPrefs.data.uiTheme != null ? ClientPrefs.data.uiTheme : ShadowTHEME_DARK;
		setShadowThemeByName(theme);
	}

	public static function lerpColor(from:FlxColor, to:FlxColor, t:Float):FlxColor
	{
		t = Math.max(0, Math.min(1, t));
		return FlxColor.fromRGBFloat(from.redFloat
			+ (to.redFloat - from.redFloat) * t, from.greenFloat
			+ (to.greenFloat - from.greenFloat) * t,
			from.blueFloat
			+ (to.blueFloat - from.blueFloat) * t, from.alphaFloat
			+ (to.alphaFloat - from.alphaFloat) * t);
	}

	public static function brighten(color:FlxColor, amount:Float):FlxColor
		return FlxColor.fromRGBFloat(Math.min(1, color.redFloat + amount), Math.min(1, color.greenFloat + amount), Math.min(1, color.blueFloat + amount), color.alphaFloat);
}

typedef ShadowTheme =
{
	var bgDark:FlxColor;
	var bgMedium:FlxColor;
	var bgLight:FlxColor;
	var bgInput:FlxColor;
	var borderDark:FlxColor;
	var borderLight:FlxColor;
	var accent:FlxColor;
	var accentHover:FlxColor;
	var accentDark:FlxColor;
	var textPrimary:FlxColor;
	var textSecondary:FlxColor;
	var textDisabled:FlxColor;
	var spacingXs:Int;
	var spacingSm:Int;
	var spacingMd:Int;
	var spacingLg:Int;
	var spacingXl:Int;
	var heightInput:Int;
	var heightButton:Int;
	var heightTab:Int;
	var heightCheckbox:Int;
	var fontSizeSm:Int;
	var fontSizeMd:Int;
	var fontSizeLg:Int;
	var fontDefault:String;
};
