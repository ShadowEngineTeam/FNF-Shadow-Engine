package objects;

import flixel.graphics.FlxGraphic;

@:nullSafety
class HealthIcon extends FlxSprite
{
	public var sprTracker:Null<FlxSprite> = null;

	private var isOldIcon:Bool = false;
	private var isPlayer:Bool = false;
	private var char:String = '';

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		isOldIcon = (char == 'bf-old');
		this.isPlayer = isPlayer;
		changeIcon(char);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var tracker = sprTracker;
		if (tracker != null)
			setPosition(tracker.x + tracker.width + 12, tracker.y - 30);
	}

	private var iconOffsets:Array<Float> = [0, 0];

	public function changeIcon(char:String)
	{
		if (this.char != char)
		{
			var name:String = 'icons/' + char;
			if (!Paths.fileExists('images/' + name + '.${Paths.IMAGE_EXT}', Paths.getImageAssetType(Paths.IMAGE_EXT)))
				name = 'icons/icon-' + char;
			if (!Paths.fileExists('images/' + name + '.${Paths.IMAGE_EXT}', Paths.getImageAssetType(Paths.IMAGE_EXT)))
				name = 'icons/icon-face';

			var graphic:Null<FlxGraphic> = Paths.image(name);
			if (graphic != null)
			{
				var frames = Math.floor(graphic.width / 150);
				loadGraphic(graphic, true, Math.floor(graphic.width / frames), Math.floor(graphic.height));

				iconOffsets[0] = (width - 150) / 2;
				iconOffsets[1] = (height - 150) / 2;
				updateHitbox();

				var frameIndices:Array<Int> = [];
				for (i in 0...frames)
					frameIndices.push(i);

				animation.add(char, frameIndices, 0, false, isPlayer);
				animation.play(char);
				this.char = char;

				if (char.endsWith('-pixel'))
					antialiasing = false;
				else
					antialiasing = ClientPrefs.data.antialiasing;
			}
		}
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}

	public function getCharacter():String
	{
		return char;
	}

	override function destroy()
	{
		sprTracker = FlxDestroyUtil.destroy(sprTracker);
		super.destroy();
	}
}
