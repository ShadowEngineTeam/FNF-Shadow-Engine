package psychlua;

#if FEATURE_VIDEOS
import hxvlc.flixel.FlxVideoSprite;
#end

class VideoFunctions
{
	public static function implement(funk:FunkinLua)
	{
		#if FEATURE_VIDEOS
		funk.set("playLuaVideoSprite", function(tag:String, path:String, ?x:Float = 0, ?y:Float = 0, ?front:Bool = false)
		{
			if (tag == null || tag.trim() == '')
			{
				FunkinLua.luaTrace('playLuaVideoSprite: tag cannot be empty!', false, false, FlxColor.RED);
				return;
			}
			if (path == null || path.trim() == '')
			{
				FunkinLua.luaTrace('playLuaVideoSprite: path cannot be empty!', false, false, FlxColor.RED);
				return;
			}

			var state:Dynamic = FunkinLua.getCurrentMusicState();
			var existingVideo = state.variables.get(tag);
			if (existingVideo != null) removeLuaVideo(tag, state);

			var videoSprite:FlxVideoSprite = new FlxVideoSprite();
			videoSprite.antialiasing = ClientPrefs.data.antialiasing;
			videoSprite.bitmap.onFormatSetup.add(function()
			{
				videoSprite.updateHitbox();
				videoSprite.x = x;
				videoSprite.y = y;
			});
			videoSprite.bitmap.onEndReached.add(function()
			{
				funk.call('onVideoFinished', [tag]);
				removeLuaVideo(tag, state);
			});
			videoSprite.load(Paths.video(path), null);
			videoSprite.play();
			state.variables.set(tag, videoSprite);

			if (front)
				state.add(videoSprite);
			else
			{
				var position:Int = state.members.indexOf(cast state.gfGroup);
				if (state.members.indexOf(cast state.boyfriendGroup) < position) position = state.members.indexOf(cast state.boyfriendGroup);
				if (state.members.indexOf(cast state.dadGroup) < position) position = state.members.indexOf(cast state.dadGroup);
				state.insert(position, videoSprite);
			}
		});

		funk.set("pauseLuaVideo", function(tag:String)
		{
			var video = getLuaVideo(tag);
			if (video != null) video.pause();
		});

		funk.set("resumeLuaVideo", function(tag:String)
		{
			var video = getLuaVideo(tag);
			if (video != null) video.resume();
		});

		funk.set("removeLuaVideo", function(tag:String) { removeLuaVideo(tag, FunkinLua.getCurrentMusicState()); });

		funk.set("forceRemoveLuaVideo", function(tag:String) { removeLuaVideo(tag, FunkinLua.getCurrentMusicState()); });

		funk.set("luaVideoExists", function(tag:String):Bool { return getLuaVideo(tag) != null; });

		funk.set("isLuaVideoPlaying", function(tag:String):Bool
		{
			var video = getLuaVideo(tag);
			return (video != null) ? video.bitmap.isPlaying : false;
		});

		funk.set("setLuaVideoVolume", function(tag:String, volume:Float)
		{
			var video = getLuaVideo(tag);
			if (video != null) video.bitmap.volume = Std.int(volume * 100);
		});

		funk.set("getLuaVideoDuration", function(tag:String):Float
		{
			var video = getLuaVideo(tag);
			return (video != null) ? haxe.Int64.toInt(video.bitmap.duration) / 1000.0 : 0.0;
		});

		funk.set("getLuaVideoTime", function(tag:String):Float
		{
			var video = getLuaVideo(tag);
			return (video != null) ? haxe.Int64.toInt(video.bitmap.time) / 1000.0 : 0.0;
		});

		funk.set("setLuaVideoRate", function(tag:String, rate:Float)
		{
			var video = getLuaVideo(tag);
			if (video != null) video.bitmap.rate = rate;
		});

		funk.set("getLuaVideoRate", function(tag:String):Float
		{
			var video = getLuaVideo(tag);
			return (video != null) ? video.bitmap.rate : 1.0;
		});
		#else
		funk.set("playLuaVideoSprite", function(tag:String, path:String, ?x:Float = 0, ?y:Float = 0, ?front:Bool = false)
		{
			FunkinLua.luaTrace('playLuaVideoSprite: Video support is not enabled!', false, false, FlxColor.RED);
		});

		funk.set("pauseLuaVideo", function(tag:String)
		{
			FunkinLua.luaTrace('pauseLuaVideo: Video support is not enabled!', false, false, FlxColor.RED);
		});

		funk.set("resumeLuaVideo", function(tag:String)
		{
			FunkinLua.luaTrace('resumeLuaVideo: Video support is not enabled!', false, false, FlxColor.RED);
		});

		funk.set("removeLuaVideo", function(tag:String)
		{
			FunkinLua.luaTrace('removeLuaVideo: Video support is not enabled!', false, false, FlxColor.RED);
		});

		funk.set("forceRemoveLuaVideo", function(tag:String)
		{
			FunkinLua.luaTrace('forceRemoveLuaVideo: Video support is not enabled!', false, false, FlxColor.RED);
		});

		funk.set("luaVideoExists", function(tag:String):Bool { return false; });

		funk.set("isLuaVideoPlaying", function(tag:String):Bool { return false; });

		funk.set("setLuaVideoVolume", function(tag:String, volume:Float) {});

		funk.set("getLuaVideoDuration", function(tag:String):Float { return 0.0; });

		funk.set("getLuaVideoTime", function(tag:String):Float { return 0.0; });

		funk.set("setLuaVideoRate", function(tag:String, rate:Float) {});

		funk.set("getLuaVideoRate", function(tag:String):Float { return 1.0; });
		#end
	}

	#if FEATURE_VIDEOS
	static function getLuaVideo(tag:String):FlxVideoSprite
	{
		var sprite = FunkinLua.getCurrentMusicState().variables.get(tag);
		if (sprite != null && Std.isOfType(sprite, FlxVideoSprite)) return cast sprite;

		FunkinLua.luaTrace('getLuaVideo: Video "$tag" does ${(sprite == null) ? "not exist" : "is not a video"}!', false, false, FlxColor.RED);
		return null;
	}

	static function removeLuaVideo(tag:String, state:Dynamic)
	{
		var video = state.variables.get(tag);
		if (video == null || !Std.isOfType(video, FlxVideoSprite)) return;

		var videoSprite:FlxVideoSprite = cast video;
		state.variables.remove(tag);

		if (videoSprite.bitmap != null)
		{
			videoSprite.bitmap.onEndReached.removeAll();
			videoSprite.bitmap.onFormatSetup.removeAll();
		}

		if (state.members != null && state.members.contains(videoSprite)) state.remove(videoSprite);
		videoSprite.destroy();
	}
	#end
}
