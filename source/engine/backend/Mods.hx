package backend;

typedef ModsList =
{
	enabled:Array<String>,
	disabled:Array<String>,
	all:Array<String>
};

class Mods
{
	static public var currentModDirectory:String = '';
	public static var ignoreModFolders:Array<String> = [
		'achievements',
		'characters',
		'custom_events',
		'custom_notetypes',
		'data',
		'songs',
		'music',
		'sounds',
		'shaders',
		'videos',
		'images',
		'stages',
		'weeks',
		'fonts',
		'scripts',
		'statescripts',
		'substatescripts'
	];

	private static var globalMods:Array<String> = [];

	inline public static function getGlobalMods()
		return globalMods;

	inline public static function pushGlobalMods() // prob a better way to do this but idc
	{
		// Remembered image paths assume the current set of global mods.
		Paths.clearPathCaches();

		globalMods = [];
		for (mod in parseList().enabled)
		{
			var pack:Dynamic = getPack(mod);
			if (pack != null && pack.runsGlobally)
				globalMods.push(mod);
		}
		return globalMods;
	}

	inline public static function getModDirectories():Array<String>
	{
		var list:Array<String> = [];
		#if FEATURE_MODS
		var modsFolder:String = Paths.mods();
		if (FileSystem.exists(modsFolder))
		{
			for (folder in FileSystem.readDirectory(modsFolder))
			{
				var path = haxe.io.Path.join([modsFolder, folder]);
				if (FileSystem.isDirectory(path) && !ignoreModFolders.contains(folder.toLowerCase()) && !list.contains(folder))
					list.push(folder);
			}
		}
		#end
		return list;
	}

	inline public static function mergeAllTextsNamed(path:String, ?defaultDirectory:String = null, allowDuplicates:Bool = false)
	{
		if (defaultDirectory == null)
			defaultDirectory = Paths.getPreloadPath();
		defaultDirectory = defaultDirectory.trim();
		if (!defaultDirectory.endsWith('/'))
			defaultDirectory += '/';
		if (!defaultDirectory.startsWith('assets/'))
			defaultDirectory = 'assets/$defaultDirectory';

		if (path.indexOf(defaultDirectory) == 0)
			path = path.substr(defaultDirectory.length);

		var mergedList:Array<String> = [];
		var paths:Array<String> = directoriesWithFile(defaultDirectory, path);

		var defaultPath:String = defaultDirectory + path;
		if (paths.contains(defaultPath))
		{
			paths.remove(defaultPath);
			paths.insert(0, defaultPath);
		}

		for (file in paths)
		{
			var list:Array<String> = CoolUtil.coolTextFile(file);
			for (value in list)
				if ((allowDuplicates || !mergedList.contains(value)) && value.length > 0)
					mergedList.push(value);
		}
		return mergedList;
	}

	inline public static function directoriesWithFile(path:String, fileToFind:String, mods:Bool = true)
	{
		var foldersToCheck:Array<String> = [];

		if (FileSystem.exists(path + fileToFind))
			foldersToCheck.push(path + fileToFind);

		#if FEATURE_MODS
		if (mods)
		{
			// Global mods first
			for (mod in Mods.getGlobalMods())
			{
				var folder:String = Paths.mods(mod + '/' + fileToFind);
				if (FileSystem.exists(folder) && !foldersToCheck.contains(folder))
					foldersToCheck.push(folder);
			}

			// Then "ShadowEngine/mods/" main folder
			var folder:String = Paths.mods(fileToFind);
			if (FileSystem.exists(folder) && !foldersToCheck.contains(folder))
				foldersToCheck.push(Paths.mods(fileToFind));

			// And lastly, the loaded mod's folder
			if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			{
				var folder:String = Paths.mods(Mods.currentModDirectory + '/' + fileToFind);
				if (FileSystem.exists(folder) && !foldersToCheck.contains(folder))
					foldersToCheck.push(folder);
			}
		}
		#end
		return foldersToCheck;
	}

	public static function getPack(?folder:String = null):Dynamic
	{
		#if FEATURE_MODS
		if (folder == null)
			folder = Mods.currentModDirectory;

		var path = Paths.mods(folder + '/pack.json');
		if (FileSystem.exists(path))
		{
			try
			{
				var rawJson:String = File.getContent(path);
				if (rawJson != null && rawJson.length > 0)
					return Json.parse(rawJson, path);
			}
			catch (e:Dynamic)
			{
				trace(e);
			}
		}
		#end
		return null;
	}

	public static var updatedOnState:Bool = false;

	inline public static function parseList():ModsList
	{
		if (!updatedOnState)
			updateModList();
		var list:ModsList = {enabled: [], disabled: [], all: []};

		#if FEATURE_MODS
		try
		{
			for (mod in CoolUtil.coolTextFile(#if mobile Sys.getCwd() + #end 'modsList.txt'))
			{
				// trace('Mod: $mod');
				if (mod.trim().length < 1)
					continue;

				var dat = mod.split("|");
				list.all.push(dat[0]);
				if (dat[1] == "1")
					list.enabled.push(dat[0]);
				else
					list.disabled.push(dat[0]);
			}
		}
		catch (e)
		{
			trace(e);
		}
		#end
		return list;
	}

	private static function updateModList()
	{
		#if FEATURE_MODS
		// Find all that are already ordered
		var list:Array<Array<Dynamic>> = [];
		var added:Array<String> = [];
		try
		{
			for (mod in CoolUtil.coolTextFile(#if mobile Sys.getCwd() + #end 'modsList.txt'))
			{
				var dat:Array<String> = mod.split("|");
				var folder:String = dat[0];
				if (folder.trim().length > 0
					&& FileSystem.exists(Paths.mods(folder))
					&& FileSystem.isDirectory(Paths.mods(folder))
					&& !added.contains(folder))
				{
					added.push(folder);
					list.push([folder, (dat[1] == "1")]);
				}
			}
		}
		catch (e)
		{
			trace(e);
		}

		// Scan for folders that aren't on modsList.txt yet
		for (folder in getModDirectories())
		{
			if (folder.trim().length > 0
				&& FileSystem.exists(Paths.mods(folder))
				&& FileSystem.isDirectory(Paths.mods(folder))
				&& !ignoreModFolders.contains(folder.toLowerCase())
				&& !added.contains(folder))
			{
				added.push(folder);
				list.push([folder, true]); // i like it false by default. -bb //Well, i like it True! -Shadow Mario (2022)
				// Shadow Mario (2023): What the fuck was bb thinking
			}
		}

		// Now save file
		var fileStr:String = '';
		for (values in list)
		{
			if (fileStr.length > 0)
				fileStr += '\n';
			fileStr += values[0] + '|' + (values[1] ? '1' : '0');
		}

		File.saveContent(#if mobile Sys.getCwd() + #end 'modsList.txt', fileStr);
		updatedOnState = true;
		// trace('Saved modsList.txt');
		#end
	}

	#if FEATURE_MODS
	/**
	 * Installs a mod zip into the mods folder. The mod can sit at the root of the zip
	 * (installed under the zip's name) or inside a single folder (installed under that folder's name).
	 * @return The installed folder, or throws with the reason the zip was refused.
	 */
	public static function installZip(path:String):String
	{
		var bytes:Null<haxe.io.Bytes> = lime.utils.Bytes.fromFile(path);
		if (bytes == null || bytes.length == 0)
			throw 'Could not read the file.';

		var entries:List<haxe.zip.Entry>;
		try
		{
			entries = haxe.zip.Reader.readZip(new haxe.io.BytesInput(bytes));
		}
		catch (e:Dynamic)
		{
			throw 'This is not a valid zip file.';
		}

		var files:Array<{name:String, entry:haxe.zip.Entry}> = [];
		for (entry in entries)
		{
			var name:String = entry.fileName.replace('\\', '/');
			while (name.startsWith('./'))
				name = name.substr(2);
			if (name.length == 0 || name.endsWith('/') || name.startsWith('__MACOSX/') || haxe.io.Path.withoutDirectory(name) == '.DS_Store')
				continue;
			if (name.startsWith('/') || name.indexOf(':') != -1 || name.split('/').contains('..'))
				throw 'The zip has an unsafe path: $name';
			files.push({name: name, entry: entry});
		}

		if (files.length == 0)
			throw 'The zip is empty.';

		var isModRoot:String->Bool = function(prefix:String):Bool
		{
			for (file in files)
			{
				if (!file.name.startsWith(prefix))
					continue;
				var parts:Array<String> = file.name.substr(prefix.length).split('/');
				if ((parts.length == 1 && parts[0] == 'pack.json') || (parts.length > 1 && ignoreModFolders.contains(parts[0].toLowerCase())))
					return true;
			}
			return false;
		}

		var folder:String;
		var prefix:String = '';
		if (isModRoot(''))
			folder = haxe.io.Path.withoutExtension(haxe.io.Path.withoutDirectory(path.replace('\\', '/')));
		else
		{
			var top:String = files[0].name.split('/')[0];
			for (file in files)
				if (!file.name.startsWith(top + '/'))
					throw 'The zip has no mod in it.';
			prefix = top + '/';
			if (!isModRoot(prefix))
				throw 'The zip has no mod in it.';
			folder = top;
		}

		folder = folder.trim();
		if (folder.length == 0 || folder == '.' || ignoreModFolders.contains(folder.toLowerCase()))
			throw 'The mod folder name "$folder" can not be used.';

		for (file in files)
		{
			var target:String = Paths.mods(folder + '/' + file.name.substr(prefix.length));
			FileSystem.createDirectory(haxe.io.Path.directory(target));
			File.saveBytes(target, file.entry.compressed ? haxe.zip.Reader.unzip(file.entry) : file.entry.data);
		}

		return folder;
	}
	#end

	public static function loadTopMod()
	{
		Mods.currentModDirectory = '';

		#if FEATURE_MODS
		if (!FileSystem.exists(Paths.mods('')))
			FileSystem.createDirectory(Paths.mods(''));
		var list:Array<String> = Mods.parseList().enabled;
		if (list != null && list[0] != null)
			Mods.currentModDirectory = list[0];
		#end

		backend.scripting.ModsStateRedirect.loadRedirects();
	}
}
