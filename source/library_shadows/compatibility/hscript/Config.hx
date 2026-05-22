package hscript;

class Config {
	public static final ALLOWED_CUSTOM_CLASSES = [
		"flixel",
		"flixel.addons",
		"flixel.animation",
		"flixel.effects",
		"flixel.graphics",
		"flixel.group",
		"flixel.input",
		"flixel.math",
		"flixel.sound",
		"flixel.text",
		"flixel.tile",
		"flixel.tweens",
		"flixel.ui",
		"flixel.util",
		"animate",
		"engine",
		"backend",
		"states",
		"substates",
		"objects",
		"mobile",
		"psychlua",
		"cutscenes",
		"debug",
		"options",
		"shaders",
		"macros",
	];

	public static final ALLOWED_ABSTRACT_AND_ENUM = [
		"flixel",
		"flixel.util",
		"flixel.math",
		"flixel.ui",
		"flixel.input",
		"flixel.system",
		"animate",
		"engine",
		"backend",
		"states",
		"substates",
		"objects",
		"mobile",
		"psychlua",
		"cutscenes",
		"debug",
		"options",
		"shaders",
		"macros",
	];

	public static final DISALLOW_CUSTOM_CLASSES = [
		"backend.Main",
		"flixel.graphics.tile.FlxGraphicsShader",
	];

	public static final DISALLOW_ABSTRACT_AND_ENUM = [

	];
}