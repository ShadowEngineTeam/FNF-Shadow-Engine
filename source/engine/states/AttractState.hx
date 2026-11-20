package states;

#if FEATURE_VIDEOS
import objects.VideoSprite;
#end

/**
 * After sitting on the title screen for a while, the game plays a trailer, as arcade machines do.
 * From V-Slice's AttractState.
 */
class AttractState extends MusicBeatState
{
	/**
	 * Seconds of inactivity on the title screen before it switches here.
	 */
	public static final DELAY:Float = 37.5;

	static final VIDEOS:Array<String> = ['attract/rift-collab-trailer', 'attract/mobile-release', 'attract/boyfriend-everywhere'];

	/**
	 * The videos play in order, one per visit.
	 */
	static var nextVideo:Int = 0;

	#if FEATURE_VIDEOS
	var video:VideoSprite;
	#end

	/**
	 * The paths of the attract videos that exist.
	 */
	public static function availableVideos():Array<String>
	{
		#if FEATURE_VIDEOS
		return [for (name in VIDEOS) Paths.video(name)].filter((path:String) -> FileSystem.exists(path));
		#else
		return [];
		#end
	}

	override public function create():Void
	{
		super.create();

		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.destroy();
			FlxG.sound.music = null;
		}

		#if FEATURE_VIDEOS
		final videos:Array<String> = availableVideos();
		if (videos.length > 0)
		{
			nextVideo %= videos.length;
			video = new VideoSprite(videos[nextVideo], false, true);
			nextVideo = (nextVideo + 1) % videos.length;

			video.finishCallback = video.onSkip = onAttractEnd;
			add(video);
			video.play();
			return;
		}
		#end

		onAttractEnd();
	}

	function onAttractEnd():Void
	{
		#if FEATURE_VIDEOS
		video = null;
		#end

		FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
		FlxG.sound.music.fadeIn(4, 0, 0.7);
		Funkin.switchState(TitleState);
	}
}
