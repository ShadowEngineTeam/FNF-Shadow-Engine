package objects;

import haxe.Json;

/**
 * `images/icons/<name>.json` makes an icon out of other icons, drawn over each other in order.
 * Positions are from the middle of the icon, for the opponent's side; the player's side mirrors them.
 */
typedef HealthIconGroupFile =
{
	var icons:Array<{name:String, position:Array<Float>}>;
	@:optional var scale:Float;
}

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;

	private var isOldIcon:Bool = false;
	private var isPlayer:Bool = false;
	private var char:String = '';

	private var groupFile:Null<HealthIconGroupFile> = null;
	private var groupIcons:Array<HealthIcon> = [];

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

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	private var iconOffsets:Array<Float> = [0, 0];

	public function changeIcon(char:String)
	{
		if (this.char != char)
		{
			for (icon in groupIcons)
				icon.destroy();
			groupIcons = [];
			groupFile = null;

			// A group takes its faces from the icon that has the most.
			var iconName:String = char;
			final groupJson:Null<String> = Paths.getTextFromFile('images/icons/$char.json');
			if (groupJson != null)
			{
				groupFile = Json.parse(groupJson);
				var mostFrames:Int = 0;
				for (data in groupFile.icons)
				{
					final icon:HealthIcon = new HealthIcon(data.name, isPlayer);
					groupIcons.push(icon);
					if (icon.animation.curAnim.frames.length > mostFrames)
					{
						mostFrames = icon.animation.curAnim.frames.length;
						iconName = data.name;
					}
				}
			}

			var name:String = 'icons/' + iconName;
			if (!Paths.fileExists('images/' + name + '.${Paths.IMAGE_EXT}', Paths.getImageAssetType(Paths.IMAGE_EXT)))
				name = 'icons/icon-' + iconName; // Older versions of psych engine's support
			if (!Paths.fileExists('images/' + name + '.${Paths.IMAGE_EXT}', Paths.getImageAssetType(Paths.IMAGE_EXT)))
				name = 'icons/icon-face'; // Prevents crash from missing icon

			var graphic = Paths.image(name);

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

	override function draw()
	{
		if (groupFile == null)
		{
			super.draw();
			return;
		}

		final groupScale:Float = groupFile.scale ?? 1;
		final centerX:Float = x - offset.x + frameWidth / 2;
		final centerY:Float = y - offset.y + frameHeight / 2;
		final frame:Int = animation.curAnim != null ? animation.curAnim.curFrame : 0;

		for (i in 0...groupIcons.length)
		{
			final icon:HealthIcon = groupIcons[i];
			final position:Array<Float> = groupFile.icons[i].position;

			icon.cameras = cameras;
			icon.scrollFactor.copyFrom(scrollFactor);
			icon.alpha = alpha;
			icon.color = color;
			icon.angle = angle;
			icon.scale.set(scale.x * groupScale, scale.y * groupScale);
			icon.updateHitbox();
			icon.x = centerX + (isPlayer ? -position[0] : position[0]) * scale.x - icon.frameWidth / 2 + icon.offset.x;
			icon.y = centerY + position[1] * scale.y - icon.frameHeight / 2 + icon.offset.y;

			// Normal, losing and winning faces; an icon without one shows its normal face.
			icon.animation.curAnim.curFrame = frame < icon.animation.curAnim.frames.length ? frame : 0;
			icon.draw();
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
		for (icon in groupIcons)
			icon.destroy();
		groupIcons = [];
		super.destroy();
	}
}
