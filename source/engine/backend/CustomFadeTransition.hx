package backend;

import flixel.util.FlxGradient;

@:nullSafety
class CustomFadeTransition extends MusicBeatSubstate
{
	public static var finishCallback:Null<Void->Void>;

	var isTransIn:Bool = false;
	var transBlack:Null<FlxSprite>;
	var transGradient:Null<FlxSprite>;

	var duration:Float;

	public function new(duration:Float, isTransIn:Bool)
	{
		this.duration = duration;
		this.isTransIn = isTransIn;
		super();
	}

	override function create()
	{
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		var width:Int = Std.int(FlxG.width / Math.max(camera.zoom, 0.001));
		var height:Int = Std.int(FlxG.height / Math.max(camera.zoom, 0.001));
		final gradient:FlxSprite = FlxGradient.createGradientFlxSprite(1, height, (isTransIn ? [0x0, FlxColor.BLACK] : [FlxColor.BLACK, 0x0]));
		gradient.scale.x = width;
		gradient.updateHitbox();
		gradient.scrollFactor.set();
		gradient.screenCenter(X);
		add(gradient);
		transGradient = gradient;

		final black:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		black.scale.set(width, height + 400);
		black.updateHitbox();
		black.scrollFactor.set();
		black.screenCenter(X);
		add(black);
		transBlack = black;

		if (isTransIn)
			gradient.y = black.y - black.height;
		else
			gradient.y = -gradient.height;

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		final gradient:Null<FlxSprite> = transGradient;
		final black:Null<FlxSprite> = transBlack;
		if (gradient == null || black == null)
			return;

		final height:Float = FlxG.height * Math.max(camera.zoom, 0.001);
		final targetPos:Float = gradient.height + 50 * Math.max(camera.zoom, 0.001);
		if (duration > 0)
			gradient.y += (height + targetPos) * elapsed / duration;
		else
			gradient.y = (targetPos) * elapsed;

		if (isTransIn)
			black.y = gradient.y + gradient.height;
		else
			black.y = gradient.y - black.height;

		if (gradient.y >= targetPos)
		{
			close();
			if (finishCallback != null)
				finishCallback();
			finishCallback = null;
		}
	}
}
