package objects;

import flixel.addons.effects.FlxSkewedSprite;
import shaders.ColorSwap;
import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

using backend.CoolUtil;

class StrumNote extends FlxSkewedSprite
{
	public var colorSwap:ColorSwap = null;
	public var rgbShader:RGBShaderReference;
	public var resetAnim:Float = 0;

	private var noteData:Int = 0;

	public var direction:Float = 90; // plan on doing scroll directions soon -bb
	public var downScroll:Bool = false; // plan on doing scroll directions soon -bb
	public var sustainReduce:Bool = true;

	private var player:Int;

	public var texture(default, set):String = null;

	private function set_texture(value:String):String
	{
		if (texture != value)
		{
			texture = value;
			reloadNote();
		}
		return value;
	}

	public static var _activeStrumNotes:Array<StrumNote> = [];
	
	public static var usePixelTextures(default, set):Null<Bool>;

	private static function set_usePixelTextures(value:Null<Bool>):Null<Bool>
	{
		if (usePixelTextures != value)
		{
			usePixelTextures = value;
			for (note in _activeStrumNotes)
				note.reloadNote();
		}

		return value;
	}

	public var useRGBShader:Bool = true;

	public function new(x:Float, y:Float, leData:Int, player:Int, daTexture:String)
	{
		if (ClientPrefs.data.disableRGBNotes) 
		{
			colorSwap = new ColorSwap();
			shader = colorSwap.shader;
		}
		else
		{
			rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData));
			rgbShader.enabled = false;
			if (PlayState.SONG != null && PlayState.SONG.disableNoteCustomColor)
				useRGBShader = false;

			var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[leData];
			if (PlayState.isPixelStage.priorityBool(usePixelTextures))
				arr = ClientPrefs.data.arrowRGBPixel[leData];

			if (leData <= arr.length)
			{
				@:bypassAccessor
				{
					rgbShader.r = arr[0];
					rgbShader.g = arr[1];
					rgbShader.b = arr[2];
				}
			}
		}

		noteData = leData;
		this.player = player;
		this.noteData = leData;
		super(x, y);

		_activeStrumNotes.push(this);

		var skinPostfix:String = Note.getNoteSkinPostfix();
		var skin:String = if (daTexture != null && daTexture.length > 1) daTexture else Note.defaultNoteSkin;
		var customSkin:String = skin + skinPostfix;

		if (Paths.fileExists('images/${PlayState.isPixelStage.priorityBool(usePixelTextures) ? 'pixelUI/' : ''}$customSkin.${Paths.GPU_IMAGE_EXT}', Paths.getImageAssetType(Paths.GPU_IMAGE_EXT)) || Paths.fileExists('images/${PlayState.isPixelStage.priorityBool(usePixelTextures) ? 'pixelUI/' : ''}$customSkin.${Paths.IMAGE_EXT}', Paths.getImageAssetType(Paths.IMAGE_EXT)))
			skin = customSkin;
		else
			skin = Note.defaultNoteSkin;

		texture = skin; // Load texture and anims
		scrollFactor.set();
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if (animation.curAnim != null)
			lastAnim = animation.curAnim.name;

		if (PlayState.isPixelStage.priorityBool(usePixelTextures))
		{
			loadGraphic(Paths.image('pixelUI/' + texture));
			width = width / 4;
			height = height / 5;
			loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));

			antialiasing = false;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));

			animation.add('green', [6]);
			animation.add('red', [7]);
			animation.add('blue', [5]);
			animation.add('purple', [4]);
			switch (Math.abs(noteData) % 4)
			{
				case 0:
					animation.add('static', [0]);
					animation.add('pressed', [4, 8], 12, false);
					animation.add('confirm', [12, 16], 24, false);
				case 1:
					animation.add('static', [1]);
					animation.add('pressed', [5, 9], 12, false);
					animation.add('confirm', [13, 17], 24, false);
				case 2:
					animation.add('static', [2]);
					animation.add('pressed', [6, 10], 12, false);
					animation.add('confirm', [14, 18], 12, false);
				case 3:
					animation.add('static', [3]);
					animation.add('pressed', [7, 11], 12, false);
					animation.add('confirm', [15, 19], 24, false);
			}
		}
		else
		{
			frames = Paths.getSparrowAtlas(texture);
			animation.addByPrefix('green', 'arrowUP');
			animation.addByPrefix('blue', 'arrowDOWN');
			animation.addByPrefix('purple', 'arrowLEFT');
			animation.addByPrefix('red', 'arrowRIGHT');

			antialiasing = ClientPrefs.data.antialiasing;
			setGraphicSize(Std.int(width * 0.7));

			switch (Math.abs(noteData) % 4)
			{
				case 0:
					animation.addByPrefix('static', 'arrowLEFT');
					animation.addByPrefix('pressed', 'left press', 24, false);
					animation.addByPrefix('confirm', 'left confirm', 24, false);
				case 1:
					animation.addByPrefix('static', 'arrowDOWN');
					animation.addByPrefix('pressed', 'down press', 24, false);
					animation.addByPrefix('confirm', 'down confirm', 24, false);
				case 2:
					animation.addByPrefix('static', 'arrowUP');
					animation.addByPrefix('pressed', 'up press', 24, false);
					animation.addByPrefix('confirm', 'up confirm', 24, false);
				case 3:
					animation.addByPrefix('static', 'arrowRIGHT');
					animation.addByPrefix('pressed', 'right press', 24, false);
					animation.addByPrefix('confirm', 'right confirm', 24, false);
			}
		}
		updateHitbox();

		if (lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	public function postAddedToGroup()
	{
		playAnim('static');
		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
		ID = noteData;
	}

	override function update(elapsed:Float)
	{
		if (resetAnim > 0)
		{
			resetAnim -= elapsed;
			if (resetAnim <= 0)
			{
				playAnim('static');
				resetAnim = 0;
			}
		}
		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false)
	{
		animation.play(anim, force);
		if (animation.curAnim != null)
		{
			centerOffsets();
			centerOrigin();
		}
		if (ClientPrefs.data.disableRGBNotes)
		{
			if (animation.curAnim == null || animation.curAnim.name == 'static')
			{
				colorSwap.hue = 0;
				colorSwap.saturation = 0;
				colorSwap.brightness = 0;
			}
			else
			{
				if (noteData > -1 && noteData < ClientPrefs.data.arrowHSV.length)
				{
					colorSwap.hue = ClientPrefs.data.arrowHSV[noteData][0] / 360;
					colorSwap.saturation = ClientPrefs.data.arrowHSV[noteData][1] / 100;
					colorSwap.brightness = ClientPrefs.data.arrowHSV[noteData][2] / 100;
				}

				if (animation.curAnim != null)
				{
					if (animation.curAnim.name == 'confirm' && !PlayState.isPixelStage.priorityBool(usePixelTextures))
						centerOrigin();
				}
			}
		}
		else if (useRGBShader)
			rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static');
	}

	override function destroy():Void
	{
		_activeStrumNotes.remove(this);
		super.destroy();
	}
}
