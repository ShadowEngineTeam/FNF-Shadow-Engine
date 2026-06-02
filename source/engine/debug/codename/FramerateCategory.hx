package debug.codename;

import flixel.math.FlxPoint;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

@:nullSafety(Off)
class FramerateCategory extends Sprite
{
	public var title:TextField;
	public var text:TextField;

	public var panel:Sprite;
	public var bgSprite:Bitmap;
	public var borderSprite:Bitmap;
	public var headerSprite:Bitmap;

	public var offset:FlxPoint = new FlxPoint();
	public var dragged:Bool = false;

	private var _text:String = "";

	// Appear / disappear animation.
	var visT:Float = 0; // alpha (eases both ways)
	var slideT:Float = 1; // 0 = off-edge, 1 = at rest (only animates on appear)
	var slideFromX:Float = 0;
	var slideFromY:Float = 0;
	var lastVisible:Bool = false;

	public function new(title:String, text:String = "")
	{
		super();

		this.title = new TextField();
		this.text = new TextField();

		// Same chrome as the main board: panel bg, dark header strip, left accent border, drop shadow.
		// Bitmaps are scaled, so they live in an unscaled container that carries the shadow filter.
		panel = new Sprite();
		panel.filters = [Framerate.panelShadow()];
		addChild(panel);

		bgSprite = new Bitmap(Framerate.__bitmap);
		bgSprite.alpha = 0.82;
		panel.addChild(bgSprite);

		headerSprite = new Bitmap(Framerate.__darkBitmap);
		headerSprite.alpha = 0.55;
		panel.addChild(headerSprite);

		borderSprite = new Bitmap(Framerate.__accentBitmap);
		borderSprite.alpha = 1;
		panel.addChild(borderSprite);

		for (label in [this.title, this.text])
		{
			label.autoSize = LEFT;
			label.x = 0;
			label.y = 0;
			label.selectable = false;
			addChild(label);
		}
		this.title.defaultTextFormat = new TextFormat(Framerate.fontName, 13, Framerate.COLOR_FG, true);
		this.text.defaultTextFormat = new TextFormat(Framerate.fontName, 13, Framerate.COLOR_DIM);
		this.title.text = title;
		this.title.multiline = this.title.wordWrap = false;
		this.text.multiline = true;
	}

	public function updateAnim(vis:Bool):Void
	{
		visT = CoolUtil.fpsLerp(visT, vis ? 1 : 0, 0.5);

		if (vis && !lastVisible) // just appeared: slide in from nearest edge
		{
			slideT = 0;
			var sf = Framerate.computeSlideFrom(offset.x, offset.y, width, height);
			slideFromX = sf.x;
			slideFromY = sf.y;
		}
		lastVisible = vis;
		slideT = CoolUtil.fpsLerp(slideT, 1, 0.5);

		alpha = visT;
		visible = visT > 0.05;
		x = offset.x + slideFromX * (1 - slideT);
		y = offset.y + slideFromY * (1 - slideT);
	}

	public function reload() {}

	public override function __enterFrame(t:Float)
	{
		if (alpha <= 0.05)
			return;
		super.__enterFrame(t);

		var pad = Framerate.PAD_X;
		var padY = Framerate.PAD_Y;

		var headerH = this.title.height + padY * 2;
		this.title.x = pad;
		this.title.y = padY;

		this.text.x = pad;
		this.text.y = headerH + padY;

		var width = Math.max(this.title.width, this.text.width) + (pad * 2);
		var height = this.text.y + this.text.height + padY;

		bgSprite.x = bgSprite.y = 0;
		bgSprite.scaleX = width;
		bgSprite.scaleY = height;

		headerSprite.x = headerSprite.y = 0;
		headerSprite.scaleX = width;
		headerSprite.scaleY = headerH;

		borderSprite.x = borderSprite.y = 0;
		borderSprite.scaleX = 2;
		borderSprite.scaleY = height;
	}
}
