package backend;

#if FEATURE_DISCORD_RPC
import Sys.sleep;
import lime.app.Application;
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;

@:nullSafety
class DiscordClient
{
	public static var isInitialized:Bool = false;
	private static final _defaultID:String = "1482658467125661818";
	public static var clientID(default, set):String = _defaultID;
	private static var presence:DiscordRichPresence = #if (hxdiscord_rpc > "1.2.4") new DiscordRichPresence(); #else DiscordRichPresence.create(); #end

	public static function check()
	{
		if (ClientPrefs.data.discordRPC)
			initialize();
		else if (isInitialized)
			shutdown();
	}

	public static function prepare()
	{
		if (!isInitialized && ClientPrefs.data.discordRPC)
			initialize();

		Application.current.window.onClose.add(function()
		{
			if (isInitialized)
				shutdown();
		});
	}

	public dynamic static function shutdown()
	{
		Discord.Shutdown();
		isInitialized = false;
	}

	private static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void
	{
		var requestPtr:cpp.Star<DiscordUser> = cpp.ConstPointer.fromRaw(request).ptr;
		var username:String = (requestPtr != null && requestPtr.username != null) ? requestPtr.username : '';
		var discriminator:String = (requestPtr != null && requestPtr.discriminator != null) ? requestPtr.discriminator : '0';

		if (Std.parseInt(discriminator) != 0) // New Discord IDs/Discriminator system
			trace('(Discord) Connected to User ($username#$discriminator)');
		else // Old discriminators
			trace('(Discord) Connected to User ($username)');

		changePresence();
	}

	private static function onError(errorCode:Int, message:cpp.ConstCharStar):Void
	{
		trace('(Discord) Error ($errorCode: ${cast (message, String)})');
	}

	private static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void
	{
		trace('(Discord) Disconnected ($errorCode: ${cast (message, String)})');
	}

	public static function initialize()
	{
		var discordHandlers:DiscordEventHandlers = #if (hxdiscord_rpc > "1.2.4") new DiscordEventHandlers(); #else DiscordEventHandlers.create(); #end
		discordHandlers.ready = cpp.Function.fromStaticFunction(onReady);
		discordHandlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		discordHandlers.errored = cpp.Function.fromStaticFunction(onError);
		Discord.Initialize(clientID, cpp.RawPointer.addressOf(discordHandlers), #if (hxdiscord_rpc > "1.2.4") false #else 1 #end, "");

		if (!isInitialized)
			trace("(Discord) Client initialized");

		sys.thread.Thread.create(() ->
		{
			var localID:String = clientID;
			while (localID == clientID)
			{
				#if DISCORD_DISABLE_IO_THREAD
				Discord.UpdateConnection();
				#end
				Discord.RunCallbacks();

				// Wait 0.5 seconds until the next loop...
				Sys.sleep(0.5);
			}
		});
		isInitialized = true;
	}

	public static function changePresence(?details:String = 'In the Menus', ?state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool,
			?endTimestamp:Float)
	{
		var startTimestamp:Float = 0;
		var hasTimestamp:Bool = (hasStartTimestamp == true);
		var endTime:Float = (endTimestamp == null) ? 0 : endTimestamp;
		if (hasTimestamp)
			startTimestamp = Date.now().getTime();
		if (endTime > 0)
			endTime = startTimestamp + endTime;

		presence.details = (details != null) ? details : 'In the Menus';
		presence.state = (state != null) ? state : '';
		presence.largeImageKey = 'icon';
		presence.largeImageText = "Version: " + states.MainMenuState.shadowEngineVersion;
		presence.smallImageKey = (smallImageKey != null) ? smallImageKey : '';
		// Obtained times are in milliseconds so they are divided so Discord can use it
		presence.startTimestamp = Std.int(startTimestamp / 1000);
		presence.endTimestamp = Std.int(endTime / 1000);
		updatePresence();

		// trace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp');
	}

	public static function updatePresence()
		Discord.UpdatePresence(cpp.RawConstPointer.addressOf(presence));

	public static function resetClientID()
		clientID = _defaultID;

	private static function set_clientID(newID:String)
	{
		var change:Bool = (clientID != newID);
		clientID = newID;

		if (change && isInitialized)
		{
			shutdown();
			initialize();
			updatePresence();
		}
		return newID;
	}

	#if (FEATURE_MODS && FEATURE_DISCORD_RPC)
	public static function loadModRPC()
	{
		var pack:Dynamic = Mods.getPack();
		if (pack != null && pack.discordRPC != null && pack.discordRPC != clientID)
		{
			clientID = pack.discordRPC;
			trace('(Discord) Changing clientID to $clientID');
		}
	}
	#end

	#if FEATURE_LUA
	public static function addLuaCallbacks(funk:psychlua.FunkinLua)
	{
		funk.set("changeDiscordPresence", function(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float)
		{
			changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
		});

		funk.set("changeDiscordClientID", function(?newID:String = null)
		{
			if (newID == null)
				newID = _defaultID;
			clientID = newID;
			trace('(Discord) Changing clientID to $newID');
		});
	}
	#end
}
#end
