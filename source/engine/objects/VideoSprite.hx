package objects;

#if FEATURE_VIDEOS
import hxvlc.flixel.FlxVideoSprite;
import flixel.addons.display.FlxRadialGauge;
#end

@:nullSafety
class VideoSprite extends FlxSpriteGroup
{
	#if FEATURE_VIDEOS
	public var finishCallback:Null<Void->Void> = null;
	public var onSkip:Null<Void->Void> = null;
	public var holdingTime:Float = 0;

	@:nullSafety(Off)
	public var videoSprite:FlxVideoSprite;

	public var skipSprite:Null<FlxRadialGauge>;

	public var cover:Null<FlxSprite>;
	public var canSkip(default, set):Bool = false;
	public var waiting:Bool = false;
	final _timeToSkip:Float = 1;
	var videoName:String;
	var alreadyDestroyed:Bool = false;

	public function new(videoName:String, isWaiting:Bool, canSkip:Bool = false, shouldLoop:Bool = false):Void {
		super();

		this.videoName = videoName;
		scrollFactor.set();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		waiting = isWaiting;
		if (!waiting) {
			final bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
			add(bg);
			bg.scale.set(FlxG.width + 100, FlxG.height + 100);
			bg.screenCenter();
			bg.scrollFactor.set();
			cover = bg;
		}

		// initialize sprites
		add(videoSprite = new FlxVideoSprite());
		videoSprite.antialiasing = ClientPrefs.data.antialiasing;

		if (canSkip)
			this.canSkip = true;

		// callbacks
		if (!shouldLoop && videoSprite.bitmap != null)
			videoSprite.bitmap.onEndReached.add(finishVideo);

		if (videoSprite.bitmap != null)
			videoSprite.bitmap.onFormatSetup.add(() -> {
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

	override function destroy():Void {
		if (alreadyDestroyed) return;

		//trace('Video destroyed');
		final c:Null<FlxSprite> = cover;
		if (c != null) {
			remove(c);
			c.destroy();
		}

		finishCallback = null;
		onSkip = null;

		if (FlxG.state != null) {
			if (FlxG.state.members.contains(this))
				FlxG.state.remove(this);

			if (FlxG.state.subState != null && FlxG.state.subState.members.contains(this))
				FlxG.state.subState.remove(this);
		}

		super.destroy();
		alreadyDestroyed = true;
	}

	function finishVideo():Void {
		if (alreadyDestroyed) return;

		if (finishCallback != null)
			finishCallback();

		destroy();
	}

	override function update(elapsed:Float):Void {
		if (canSkip) {
			if (Controls.instance.pressed('accept') || mobile.backend.TouchUtil.pressed)
				holdingTime = Math.max(0, Math.min(_timeToSkip, holdingTime + elapsed));
			else if (holdingTime > 0)
				holdingTime = Math.max(0, FlxMath.lerp(holdingTime, -0.1, FlxMath.bound(elapsed * 3, 0, 1)));

			updateSkipAlpha();

			if (holdingTime >= _timeToSkip) {
				if (onSkip != null) onSkip();
				finishCallback = null;
				if (videoSprite.bitmap != null)
					videoSprite.bitmap.onEndReached.dispatch();
				//trace('Skipped video');
				return;
			}
		}
		super.update(elapsed);
	}

	function set_canSkip(val:Bool):Bool {
		if (val) {
			if (skipSprite == null) {
				final gauge:FlxRadialGauge = new FlxRadialGauge(0, 0, backend.Paths.image('pie'));
				add(gauge);
				gauge.setPosition(FlxG.width - (gauge.width + 80), FlxG.height - (gauge.height + 72));
				gauge.amount = 0;
				skipSprite = gauge;
			}
		}
		else {
			final gauge:Null<FlxRadialGauge> = skipSprite;
			if (gauge != null) {
				remove(gauge);
				skipSprite = flixel.util.FlxDestroyUtil.destroy(gauge);
			}
		}

		return canSkip = val;
	}

	function updateSkipAlpha():Void {
		final gauge:Null<FlxRadialGauge> = skipSprite;
		if (gauge == null) return;
		gauge.amount = FlxMath.bound(holdingTime / _timeToSkip * 1.025, 0, 1);
		gauge.alpha = FlxMath.remapToRange(gauge.amount, 0.025, 1, 0, 1);
	}

	public function play():Void
		videoSprite?.play();

	public function resume():Void
		videoSprite?.resume();

	public function pause():Void
		videoSprite?.pause();
	#end
}