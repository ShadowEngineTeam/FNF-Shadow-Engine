package hscript;

class Config {
	// Runs support for custom classes in these
	// THIS IS UNUSED
	public static final ALLOWED_CUSTOM_CLASSES = [
		"flixel",
		"states",
		"substates",
		"objects",
		"mobile",
		"backend"
	];

	// Runs support for abstract support in these
	public static final ALLOWED_ABSTRACT_AND_ENUM = [
		"flixel",
		"openfl",
		"haxe.xml",
		"haxe.CallStack",
		"mobile"
	];

	// Incase any of your files fail
	// These are the module names
	// THIS IS UNUSED
	public static final DISALLOW_CUSTOM_CLASSES = [

	];

	// Incase any of your files fail
	// These are the module names
	public static final DISALLOW_ABSTRACT_AND_ENUM = [
		
	];
}