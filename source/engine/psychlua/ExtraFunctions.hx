package psychlua;

import haxe.extern.EitherType;
import flixel.util.FlxSave;
import openfl.utils.Assets;

//
// Things to trivialize some dumb stuff like splitting strings on older Lua
//
class ExtraFunctions
{
	public static function implement(funk:FunkinLua)
	{
		// Keyboard & Gamepads
		funk.set("keyboardJustPressed", function(name:String)
		{
			return Reflect.getProperty(FlxG.keys.justPressed, name.toUpperCase());
		});
		funk.set("keyboardPressed", function(name:String)
		{
			return Reflect.getProperty(FlxG.keys.pressed, name.toUpperCase());
		});
		funk.set("keyboardReleased", function(name:String)
		{
			return Reflect.getProperty(FlxG.keys.justReleased, name.toUpperCase());
		});

		funk.set("anyGamepadJustPressed", function(name:String) return FlxG.gamepads.anyJustPressed(name.toUpperCase()));
		funk.set("anyGamepadPressed", function(name:String) return FlxG.gamepads.anyPressed(name.toUpperCase()));
		funk.set("anyGamepadReleased", function(name:String) return FlxG.gamepads.anyJustReleased(name.toUpperCase()));

		funk.set("gamepadAnalogX", function(id:Int, ?leftStick:Bool = true)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
				return 0.0;

			return controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		funk.set("gamepadAnalogY", function(id:Int, ?leftStick:Bool = true)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
				return 0.0;

			return controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		funk.set("gamepadJustPressed", function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
				return false;

			return Reflect.getProperty(controller.justPressed, name) == true;
		});
		funk.set("gamepadPressed", function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
				return false;

			return Reflect.getProperty(controller.pressed, name) == true;
		});
		funk.set("gamepadReleased", function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null)
				return false;

			return Reflect.getProperty(controller.justReleased, name) == true;
		});

		funk.set("keyJustPressed", function(name:String = '')
		{
			name = name.toLowerCase();
			switch (name)
			{
				case 'left':
					return FunkinLua.getCurrentMusicState().controls.NOTE_LEFT_P;
				case 'down':
					return FunkinLua.getCurrentMusicState().controls.NOTE_DOWN_P;
				case 'up':
					return FunkinLua.getCurrentMusicState().controls.NOTE_UP_P;
				case 'right':
					return FunkinLua.getCurrentMusicState().controls.NOTE_RIGHT_P;
				default:
					return FunkinLua.getCurrentMusicState().controls.justPressed(name);
			}
			return false;
		});
		funk.set("keyPressed", function(name:String = '')
		{
			name = name.toLowerCase();
			switch (name)
			{
				case 'left':
					return FunkinLua.getCurrentMusicState().controls.NOTE_LEFT;
				case 'down':
					return FunkinLua.getCurrentMusicState().controls.NOTE_DOWN;
				case 'up':
					return FunkinLua.getCurrentMusicState().controls.NOTE_UP;
				case 'right':
					return FunkinLua.getCurrentMusicState().controls.NOTE_RIGHT;
				default:
					return FunkinLua.getCurrentMusicState().controls.pressed(name);
			}
			return false;
		});
		funk.set("keyReleased", function(name:String = '')
		{
			name = name.toLowerCase();
			switch (name)
			{
				case 'left':
					return FunkinLua.getCurrentMusicState().controls.NOTE_LEFT_R;
				case 'down':
					return FunkinLua.getCurrentMusicState().controls.NOTE_DOWN_R;
				case 'up':
					return FunkinLua.getCurrentMusicState().controls.NOTE_UP_R;
				case 'right':
					return FunkinLua.getCurrentMusicState().controls.NOTE_RIGHT_R;
				default:
					return FunkinLua.getCurrentMusicState().controls.justReleased(name);
			}
			return false;
		});

		// Save data management
		funk.set("initSaveData", function(name:String, ?folder:String = 'psychenginemods')
		{
			if (!FunkinLua.getCurrentMusicState().modchartSaves.exists(name))
			{
				var save:FlxSave = new FlxSave();
				// folder goes unused for flixel 5 users. @BeastlyGhost
				save.bind(name, CoolUtil.getSavePath() + '/' + folder);
				FunkinLua.getCurrentMusicState().modchartSaves.set(name, save);
				return;
			}
			FunkinLua.luaTrace('initSaveData: Save file already initialized: ' + name);
		});
		funk.set("flushSaveData", function(name:String)
		{
			if (FunkinLua.getCurrentMusicState().modchartSaves.exists(name))
			{
				FunkinLua.getCurrentMusicState().modchartSaves.get(name).flush();
				return;
			}
			FunkinLua.luaTrace('flushSaveData: Save file not initialized: ' + name, false, false, FlxColor.RED);
		});
		funk.set("getDataFromSave", function(name:String, field:String, ?defaultValue:Dynamic = null)
		{
			if (FunkinLua.getCurrentMusicState().modchartSaves.exists(name))
			{
				var saveData = FunkinLua.getCurrentMusicState().modchartSaves.get(name).data;
				if (Reflect.hasField(saveData, field))
					return Reflect.field(saveData, field);
				else
					return defaultValue;
			}
			FunkinLua.luaTrace('getDataFromSave: Save file not initialized: ' + name, false, false, FlxColor.RED);
			return defaultValue;
		});
		funk.set("setDataFromSave", function(name:String, field:String, value:Dynamic)
		{
			if (FunkinLua.getCurrentMusicState().modchartSaves.exists(name))
			{
				Reflect.setField(FunkinLua.getCurrentMusicState().modchartSaves.get(name).data, field, value);
				return;
			}
			FunkinLua.luaTrace('setDataFromSave: Save file not initialized: ' + name, false, false, FlxColor.RED);
		});
		funk.set("eraseSaveData", function(name:String)
		{
			if (FunkinLua.getCurrentMusicState().modchartSaves.exists(name))
			{
				FunkinLua.getCurrentMusicState().modchartSaves.get(name).erase();
				return;
			}
			FunkinLua.luaTrace('eraseSaveData: Save file not initialized: ' + name, false, false, FlxColor.RED);
		});

		// File management
		funk.set("checkFileExists", function(filename:String, ?absolute:Bool = false)
		{
			#if MODS_ALLOWED
			if (absolute)
			{
				return FileSystem.exists(filename);
			}

			var path:String = Paths.modFolders(filename);
			if (FileSystem.exists(path))
			{
				return true;
			}
			return FileSystem.exists(Paths.getPath('assets/$filename', TEXT));
			#else
			if (absolute)
			{
				return Assets.exists(filename);
			}
			return Assets.exists(Paths.getPath('assets/$filename', TEXT));
			#end
		});
		funk.set("saveFile", function(path:String, content:String, ?absolute:Bool = false)
		{
			try
			{
				#if MODS_ALLOWED
				if (!absolute)
					File.saveContent(Paths.mods(path), content);
				else
				#end
				#if sys
				File.saveContent(path, content);
				#end

				return true;
			}
			catch (e:Dynamic)
			{
				FunkinLua.luaTrace("saveFile: Error trying to save " + path + ": " + e, false, false, FlxColor.RED);
			}
			return false;
		});
		funk.set("deleteFile", function(path:String, ?ignoreModFolders:Bool = false)
		{
			try
			{
				#if MODS_ALLOWED
				if (!ignoreModFolders)
				{
					var lePath:String = Paths.modFolders(path);
					if (FileSystem.exists(lePath))
					{
						FileSystem.deleteFile(lePath);
						return true;
					}
				}
				#end

				var lePath:String = Paths.getPath(path, TEXT);
				if (Assets.exists(lePath))
				{
					#if sys
					FileSystem.deleteFile(lePath);
					#end
					return true;
				}
			}
			catch (e:Dynamic)
			{
				FunkinLua.luaTrace("deleteFile: Error trying to delete " + path + ": " + e, false, false, FlxColor.RED);
			}
			return false;
		});
		funk.set("getTextFromFile", Paths.getTextFromFile);
		funk.set("directoryFileList", function(folder:String)
		{
			var list:Array<String> = [];
			if (FileSystem.exists(folder))
			{
				for (folder in Paths.readDirectory(folder))
				{
					if (!list.contains(folder))
					{
						list.push(folder);
					}
				}
			}
			return list;
		});

		// String tools
		funk.set("stringStartsWith", StringTools.startsWith);
		funk.set("stringEndsWith", StringTools.endsWith);
		funk.set("stringSplit", function(str:String, split:String)
		{
			return str.split(split);
		});
		funk.set("stringTrim", StringTools.trim);

		// Randomization
		funk.set("getRandomInt", function(min:Int, max:Int = FlxMath.MAX_VALUE_INT, exclude:String = '')
		{
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Int> = [];
			for (i in 0...excludeArray.length)
			{
				if (exclude == '')
					break;
				toExclude.push(Std.parseInt(excludeArray[i].trim()));
			}
			return FlxG.random.int(min, max, toExclude);
		});
		funk.set("getRandomFloat", function(min:Float, max:Float = 1, exclude:String = '')
		{
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Float> = [];
			for (i in 0...excludeArray.length)
			{
				if (exclude == '')
					break;
				toExclude.push(Std.parseFloat(excludeArray[i].trim()));
			}
			return FlxG.random.float(min, max, toExclude);
		});
		funk.set("getRandomBool", FlxG.random.bool);
	}
}
