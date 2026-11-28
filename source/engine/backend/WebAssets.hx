package backend;

#if ON_DEMAND_ASSETS
import lime.utils.AssetLibrary;
import lime.utils.Assets as LimeAssets;

/**
 * Downloads the asset libraries and files the web build does not preload.
 *
 * Libraries are downloaded whole, like Funkin's. Song audio, videos and characters are downloaded
 * one file at a time, and freed once they are decoded.
 */
@:access(lime.utils.AssetLibrary)
@:access(lime.utils.Assets)
class WebAssets
{
	static final loadedLibraries:Array<String> = [];

	public static function exists(library:String):Bool
		return LimeAssets.getLibrary(library) != null;

	public static function isLibraryLoaded(library:String):Bool
		return loadedLibraries.contains(library) || !exists(library);

	/**
	 * Downloads `library`, then calls `callback`, also when it fails.
	 */
	public static function loadLibrary(library:String, callback:Void->Void):Void
	{
		if (isLibraryLoaded(library))
		{
			callback();
			return;
		}

		LimeAssets.loadLibrary(library).onComplete(_ ->
		{
			if (!loadedLibraries.contains(library))
				loadedLibraries.push(library);
			callback();
		}).onError(error ->
		{
			trace('ERROR! Could not download library $library: $error');
			callback();
		});
	}

	public static function unloadLibrary(library:String):Void
	{
		if (!loadedLibraries.remove(library))
			return;

		LimeAssets.getLibrary(library)?.unload();
	}

	/**
	 * Unloads every library but `shared` and the ones in `keep`.
	 */
	public static function unloadLibrariesExcept(keep:Array<String>):Void
	{
		for (library in loadedLibraries.copy())
			if (library != "shared" && !keep.contains(library))
				unloadLibrary(library);
	}

	static function libraryOf(path:String):Null<AssetLibrary>
	{
		for (name => library in LimeAssets.libraries)
			if (name != "default" && library.exists(path, null))
				return library;
		return null;
	}

	/**
	 * Whether `path` is a file that is only downloaded when it is asked for, and is not downloaded yet.
	 */
	public static function needsDownload(path:String):Bool
	{
		final library:Null<AssetLibrary> = libraryOf(path);
		return library != null && library.preload.get(path) != true && !library.cachedBytes.exists(path);
	}

	/**
	 * Downloads `path` so it can be read, then calls `callback`, also when it fails.
	 */
	public static function download(path:String, callback:Void->Void):Void
	{
		final library:Null<AssetLibrary> = libraryOf(path);
		if (library == null || library.cachedBytes.exists(path))
		{
			callback();
			return;
		}

		library.loadBytes(path).onComplete(bytes ->
		{
			if (bytes != null)
				library.cachedBytes.set(path, bytes);
			callback();
		}).onError(error ->
		{
			trace('ERROR! Could not download $path: $error');
			callback();
		});
	}

	/**
	 * Frees what `download()` got for `path`, once it is decoded.
	 */
	public static function release(path:String):Void
	{
		final library:Null<AssetLibrary> = libraryOf(path);
		if (library != null && library.preload.get(path) != true)
			library.cachedBytes.remove(path);
	}
}
#end
