package cutscenes;

import openfl.utils.Assets;

typedef DialogueAnimArray =
{
	var anim:String;
	var loop_name:String;
	var loop_offsets:Array<Int>;
	var idle_name:String;
	var idle_offsets:Array<Int>;
}

typedef DialogueCharacterFile =
{
	var image:String;
	var dialogue_pos:String;
	var no_antialiasing:Bool;

	var animations:Array<DialogueAnimArray>;
	var position:Array<Float>;
	var scale:Float;
}

@:nullSafety
class DialogueCharacter extends FlxSprite
{
	private static var IDLE_SUFFIX:String = '-IDLE';
	public static var DEFAULT_CHARACTER:String = 'bf';
	public static var DEFAULT_SCALE:Float = 0.7;

	public var jsonFile:Null<DialogueCharacterFile> = null;
	public var dialogueAnimations:Map<String, DialogueAnimArray> = new Map<String, DialogueAnimArray>();

	public var startingPos:Float = 0; // For center characters, it works as the starting Y, for everything else it works as starting X
	public var isGhost:Bool = false; // For the editor
	public var curCharacter:String = 'bf';
	public var skiptimer = 0;
	public var skipping = 0;

	public function new(x:Float = 0, y:Float = 0, character:String = null)
	{
		super(x, y);

		if (character == null)
			character = DEFAULT_CHARACTER;
		this.curCharacter = character;

		reloadCharacterJson(character);
		if (jsonFile != null)
		{
			var img:String = jsonFile.image;
			var atlas = Paths.getSparrowAtlas('dialogue/' + img);
			if (atlas != null)
				frames = atlas;
		}
		reloadAnimations();

		antialiasing = ClientPrefs.data.antialiasing;
		if (jsonFile != null && jsonFile.no_antialiasing == true)
			antialiasing = false;
	}

	public function reloadCharacterJson(character:String)
	{
		var characterPath:String = 'images/dialogue/' + character + '.json';
		var defaultPath:String = 'images/dialogue/' + DEFAULT_CHARACTER + '.json';
		var path:String = Paths.getSharedPath(characterPath);
		#if FEATURE_MODS
		var modPath:String = Paths.modFolders(characterPath);
		if (FileSystem.exists(modPath))
			path = modPath;
		#end

		if (!FileSystem.exists(path))
			path = Paths.getSharedPath(defaultPath);

		var rawJson:Null<String> = File.getContent(path);
		if (rawJson != null)
			jsonFile = cast Json.parse(rawJson, path);
	}

	public function reloadAnimations()
	{
		dialogueAnimations.clear();
		if (jsonFile != null && jsonFile.animations != null && jsonFile.animations.length > 0)
		{
			for (anim in jsonFile.animations)
			{
				animation.addByPrefix(anim.anim, anim.loop_name, 24, isGhost);
				animation.addByPrefix(anim.anim + IDLE_SUFFIX, anim.idle_name, 24, true);
				dialogueAnimations.set(anim.anim, anim);
			}
		}
	}

	public function playAnim(animName:Null<String> = null, playIdle:Bool = false)
	{
		var targetAnim:Null<String> = animName;
		if (animName == null || !dialogueAnimations.exists(animName)) // Anim is null, get a random animation
		{
			var arrayAnims:Array<String> = [];
			for (anim in dialogueAnimations)
			{
				arrayAnims.push(anim.anim);
			}
			if (arrayAnims.length > 0)
			{
				targetAnim = arrayAnims[FlxG.random.int(0, arrayAnims.length - 1)];
			}
		}

		if (targetAnim != null && dialogueAnimations.exists(targetAnim))
		{
			var animData:Null<DialogueAnimArray> = dialogueAnimations.get(targetAnim);
			if (animData != null && (animData.loop_name == null || animData.loop_name.length < 1 || animData.loop_name == animData.idle_name))
			{
				playIdle = true;
			}
		}
		if (targetAnim != null)
			animation.play(playIdle ? targetAnim + IDLE_SUFFIX : targetAnim, false);

		if (targetAnim != null && dialogueAnimations.exists(targetAnim))
		{
			var anim:Null<DialogueAnimArray> = dialogueAnimations.get(targetAnim);
			if (anim != null)
			{
				if (playIdle)
				{
					offset.set(anim.idle_offsets[0], anim.idle_offsets[1]);
				}
				else
				{
					offset.set(anim.loop_offsets[0], anim.loop_offsets[1]);
				}
			}
		}
		else
		{
			offset.set(0, 0);
			trace('Offsets not found! Dialogue character is badly formatted, anim: '
				+ targetAnim
				+ ', '
				+ (playIdle ? 'idle anim' : 'loop anim'));
		}
	}

	public function animationIsLoop():Bool
	{
		if (animation.curAnim == null)
			return false;
		return !animation.curAnim.name.endsWith(IDLE_SUFFIX);
	}
}
