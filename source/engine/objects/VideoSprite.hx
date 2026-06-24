package objects;

#if FEATURE_VIDEOS
import hxvlc.flixel.FlxVideoSprite;
import flixel.addons.display.FlxRadialGauge;
#end

class VideoSprite extends FlxSpriteGroup
{
	#if FEATURE_VIDEOS
	public var finishCallback:Void->Void = null;
	public var onSkip:Void->Void = null;
	public var holdingTime:Float = 0;
	public var videoSprite:FlxVideoSprite;
	public var skipSprite:FlxRadialGauge;
	public var cover:FlxSprite;
	public var canSkip(default, set):Bool = false;
	public var waiting:Bool = false;

	final _timeToSkip:Float = 1;
	var videoName:String;
	var alreadyDestroyed:Bool = false;

	public function new(videoName:String, isWaiting:Bool, canSkip:Bool = false, shouldLoop:Bool = false):Void
	{
		super();

		this.videoName = videoName;
		scrollFactor.set();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		waiting = isWaiting;
		if (!waiting)
		{
			add(cover = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK));
			cover.scale.set(FlxG.width + 100, FlxG.height + 100);
			cover.screenCenter();
			cover.scrollFactor.set();
		}

		// initialize sprites
		add(videoSprite = new FlxVideoSprite());
		videoSprite.antialiasing = ClientPrefs.data.antialiasing;

		if (canSkip)
			this.canSkip = true;

		// callbacks
		if (!shouldLoop)
			videoSprite.bitmap.onEndReached.add(finishVideo);

		videoSprite.bitmap.onFormatSetup.add(() ->
		{
			/*
				#if FEATURE_VIDEOS
				var wd:Int = videoSprite.bitmap.formatWidth;
				var hg:Int = videoSprite.bitmap.formatHeight;
				trace('Video Resolution: ${wd}x${hg}');
				videoSprite.scale.set(FlxG.width / wd, FlxG.height / hg);
				#end
			 */
			videoSprite.setGraphicSize(FlxG.width);
			videoSprite.updateHitbox();
			videoSprite.screenCenter();
		});

		// start video and adjust resolution to screen size
		videoSprite.load(videoName, shouldLoop ? ['input-repeat=65545'] : null);
	}

	override function destroy():Void
	{
		if (alreadyDestroyed)
			return;

		// trace('Video destroyed');
		if (cover != null)
		{
			remove(cover);
			cover.destroy();
		}

		finishCallback = null;
		onSkip = null;

		if (FlxG.state != null)
		{
			if (FlxG.state.members.contains(this))
				FlxG.state.remove(this);

			if (FlxG.state.subState != null && FlxG.state.subState.members.contains(this))
				FlxG.state.subState.remove(this);
		}

		super.destroy();
		alreadyDestroyed = true;
	}

	function finishVideo():Void
	{
		if (alreadyDestroyed) return;

		if (finishCallback != null)
			finishCallback();

		destroy();
	}

	override function update(elapsed:Float):Void
	{
		if (canSkip)
		{
			if (Controls.instance.pressed('accept') || mobile.backend.TouchUtil.pressed)
				holdingTime = Math.max(0, Math.min(_timeToSkip, holdingTime + elapsed));
			else if (holdingTime > 0)
				holdingTime = Math.max(0, FlxMath.lerp(holdingTime, -0.1, FlxMath.bound(elapsed * 3, 0, 1)));

			if (skipSprite != null)
				skipSprite.alpha = skipSprite.amount = FlxMath.bound(holdingTime / _timeToSkip * 1.025, 0, 1);

			if (holdingTime >= _timeToSkip)
			{
				if (onSkip != null) onSkip();
				finishCallback = null;
				videoSprite.bitmap.onEndReached.dispatch();
				// trace('Skipped video');
				return;
			}
		}
		super.update(elapsed);
	}

	function set_canSkip(val:Bool):Bool
	{
		if (val)
		{
			if (skipSprite == null)
			{
				add(skipSprite = new FlxRadialGauge(0, 0, backend.Paths.image('pie')));
				skipSprite.setPosition(FlxG.width - (skipSprite.width + 80), FlxG.height - (skipSprite.height + 72));
				skipSprite.alpha = skipSprite.amount = 0;
				skipSprite.blend = INVERT;
			}
		}
		else if (skipSprite != null)
		{
			remove(skipSprite);
			skipSprite = flixel.util.FlxDestroyUtil.destroy(skipSprite);
		}

		return canSkip = val;
	}

	public function play():Void
		videoSprite?.play();

	public function resume():Void
		videoSprite?.resume();

	public function pause():Void
		videoSprite?.pause();
	#end
}