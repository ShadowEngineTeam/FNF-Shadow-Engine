package mobile.options;

import flixel.input.keyboard.FlxKey;
import options.BaseOptionsMenu;
import options.Option;

class MobileOptionsSubState extends BaseOptionsMenu
{
	final exControlTypes:Array<String> = ["NONE", "SINGLE", "DOUBLE"];
	final hintOptions:Array<String> = ["No Gradient", "No Gradient (Old)", "Gradient", "Hidden"];
	var option:Option;

	public function new()
	{
		title = 'Mobile Options';
		rpcTitle = 'Mobile Options Menu'; // for Discord Rich Presence, fuck it

		option = new Option('Extra Controls', 'Select how many extra buttons you prefer to have?\nThey can be used for mechanics with LUA or HScript.',
			'extraButtons', 'string', exControlTypes);
		addOption(option);

		option = new Option('Mobile Controls Opacity',
			'Selects the opacity for the mobile buttons (careful not to put it at 0 and lose track of your buttons).', 'controlsAlpha', 'percent');
		option.scrollSpeed = 1;
		option.minValue = 0.001;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.onChange = () ->
		{
			touchPad.alpha = curOption.getValue();
			ClientPrefs.toggleVolumeKeys();
		};
		addOption(option);

		#if mobile
		option = new Option('Allow Phone Screensaver',
			'If checked, the phone will sleep after going inactive for few seconds.\n(The time depends on your phone\'s options)', 'screensaver', 'bool');
		option.onChange = () -> lime.system.System.allowScreenTimeout = curOption.getValue();
		addOption(option);
		#end

		#if android
		option = new Option('Use EXTERNAL Folder',
			'If checked, the game will use the .ShadowEngine folder for the mods folder.', 'useExternalStorage', 'bool');
		option.onChange = onChangeStorageDir;
		addOption(option);
		#end

		if (MobileData.mode == 3)
		{
			option = new Option('Hitbox Design', 'Choose how your hitbox should look like.', 'hitboxType', 'string', hintOptions);
			addOption(option);

			option = new Option('Hitbox Position', 'If checked, the hitbox will be put at the bottom of the screen, otherwise will stay at the top.',
				'hitboxPos', 'bool');
			addOption(option);
		}

		option = new Option('Dynamic Controls Color',
			'If checked, the mobile controls color will be set to the notes color in your settings.\n(have effect during gameplay only)', 'dynamicColors',
			'bool');
		addOption(option);

		super();
	}

	#if android
	private function onChangeStorageDir():Void
	{
		File.saveContent(haxe.io.Path.addTrailingSlash(lime.system.System.applicationStorageDirectory) + "useExternal.txt", '${ClientPrefs.data.useExternalStorage}');
		Sys.setCwd(StorageUtil.getStorageDirectory());
	}
	#end
}