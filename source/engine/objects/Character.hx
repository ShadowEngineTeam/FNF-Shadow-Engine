package objects;

import flixel.animation.FlxAnimationController;
import backend.animation.PsychAnimateController;
import flixel.util.FlxSort;
import flixel.util.FlxDestroyUtil;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import backend.Song;
import backend.Section;
import animate.FlxAnimate;

typedef CharacterFile =
{
	var animations:Array<AnimArray>;
	var image:flixel.util.typeLimit.OneOfTwo<String, Array<String>>;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
	var vocals_file:String;
	@:optional var _editor_isPlayer:Null<Bool>;
}

enum CharacterSpriteType
{
	SPRITE;
	MULTI_ATLAS;
	TEXTURE_ATLAS;
}

typedef AnimArray =
{
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

class Character extends FlxAnimate
{
	/**
	 * In case a character is missing, it will use this on its place
	**/
	public static final DEFAULT_CHARACTER:String = 'bf';

	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;
	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; // Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; // Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public var hasMissAnimations:Bool = false;
	public var vocalsFile:String = '';

	// Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var editorIsPlayer:Null<Bool> = null;
	public var isAnimateAtlas:Bool = false;

	public var spriteType:CharacterSpriteType = SPRITE;

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y);
		
		animOffsets = new Map<String, Array<Dynamic>>();
		curCharacter = character;
		this.isPlayer = isPlayer;
		switch (curCharacter)
		{
			// case 'your character name in case you want to hardcode them instead':

			default:
				var characterPath:String = 'characters/$curCharacter.json';

				var path:String = Paths.getPath(characterPath, TEXT, null, true);
				#if MODS_ALLOWED
				if (!FileSystem.exists(path))
				#else
				if (!Assets.exists(path))
				#end
				{
					path = Paths.getSharedPath('characters/' + DEFAULT_CHARACTER +
						'.json'); // If a character couldn't be found, change him to BF just to prevent a crash
					color = FlxColor.BLACK;
					alpha = 0.6;
				}

				try
				{
					#if MODS_ALLOWED
					loadCharacterFile(Json.parse(File.getContent(path), path));
					#else
					loadCharacterFile(Json.parse(Assets.getText(path), path));
					#end
				}
				catch (e:Dynamic)
				{
					trace('Error loading character file of "$character": $e');
				}
		}

		if (animOffsets.exists('singLEFTmiss') || animOffsets.exists('singDOWNmiss') || animOffsets.exists('singUPmiss') || animOffsets.exists('singRIGHTmiss'))
			hasMissAnimations = true;
		recalculateDanceIdle();
		dance();
	}
	override function initVars()
	{
		super.initVars();
		anim = new PsychAnimateController(this);
		skew = new FlxPoint();
		animation = anim;
	}

	override public function isOnScreen(?camera:FlxCamera):Bool
	{
		if (spriteType == MULTI_ATLAS)
			return true; // flixel is stoobid

		if (camera == null)
			camera = FlxG.camera;

		return camera.containsRect(getScreenBounds(_rect, camera));
	}

	public function loadCharacterFile(json:Dynamic)
	{
		scale.set(1, 1);
		updateHitbox();

		if (!(json.image is String))
		{
			spriteType = MULTI_ATLAS;
			frames = Paths.getAtlas(json.image[0]);
			final split:Array<String> = json.image;
			if (frames != null)
				for (imgFile in split)
				{
					final daAtlas = Paths.getAtlas(imgFile);
					if (daAtlas != null)
						cast(frames, flixel.graphics.frames.FlxAtlasFrames).addAtlas(daAtlas);
				}
			imageFile = json.image[0];
		}
		else
		{
			if (!Paths.fileExists('images/${haxe.io.Path.withExtension(json.image, 'png')}', IMAGE))
			{
				spriteType = TEXTURE_ATLAS;
				frames = Paths.getTextureAtlas(json.image);
			}
			else
			{
				spriteType = SPRITE;
				frames = Paths.getAtlas(json.image);
			}
			imageFile = json.image;
		}

		jsonScale = json.scale;
		if (json.scale != 1)
		{
			scale.set(jsonScale, jsonScale);
			updateHitbox();
		}

		// positioning
		positionArray = json.position;
		cameraPosition = json.camera_position;

		// data
		healthIcon = json.healthicon;
		singDuration = json.sing_duration;
		flipX = (json.flip_x != isPlayer);
		healthColorArray = (json.healthbar_colors != null && json.healthbar_colors.length > 2) ? json.healthbar_colors : [161, 161, 161];
		vocalsFile = json.vocals_file != null ? json.vocals_file : '';
		originalFlipX = (json.flip_x == true);
		editorIsPlayer = json._editor_isPlayer;

		// antialiasing
		noAntialiasing = (json.no_antialiasing == true);
		antialiasing = ClientPrefs.data.antialiasing ? !noAntialiasing : false;

		// animations
		animationsArray = json.animations;
		if (animationsArray != null && animationsArray.length > 0)
		{
			for (anim in animationsArray)
			{
				var animAnim:String = '' + anim.anim;
				var animName:String = '' + anim.name;
				var animFps:Int = anim.fps;
				var animLoop:Bool = !!anim.loop; // Bruh
				var animIndices:Array<Int> = anim.indices;

				switch (spriteType)
				{
					case TEXTURE_ATLAS:
						if (animIndices != null && animIndices.length > 0)
							this.anim.addBySymbolIndices(animAnim, animName, animIndices, animFps, animLoop);
						else
							this.anim.addBySymbol(animAnim, animName, animFps, animLoop);
					default:
						if (animIndices != null && animIndices.length > 0)
							animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
						else
							animation.addByPrefix(animAnim, animName, animFps, animLoop);
				}

				if (anim.offsets != null && anim.offsets.length > 1)
					addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
				else
					addOffset(anim.anim, 0, 0);
			}
		}
		// trace('Loaded file to character ' + curCharacter);
	}

	override function update(elapsed:Float)
	{
		if (debugMode || isAnimationNull())
		{
			trace('animation null');
			super.update(elapsed);
			return;
		}

		if (heyTimer > 0)
		{
			var rate:Float = (PlayState.instance != null ? PlayState.instance.playbackRate : 1.0);
			heyTimer -= elapsed * rate;
			if (heyTimer <= 0)
			{
				var anim:String = getAnimationName();
				if (specialAnim && (anim == 'hey' || anim == 'cheer'))
				{
					specialAnim = false;
					dance();
				}
				heyTimer = 0;
			}
		}
		else if (specialAnim && isAnimationFinished())
		{
			specialAnim = false;
			dance();
		}
		else if (getAnimationName().endsWith('miss') && isAnimationFinished())
		{
			dance();
			finishAnimation();
		}

		if (getAnimationName().startsWith('sing'))
			holdTimer += elapsed;
		else if (isPlayer)
			holdTimer = 0;

		if (!isPlayer
			&& holdTimer >= Conductor.stepCrochet * (0.0011 #if FLX_PITCH / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1) #end) * singDuration)
		{
			dance();
			holdTimer = 0;
		}

		var name:String = getAnimationName();
		if (isAnimationFinished() && animOffsets.exists('$name-loop'))
			playAnim('$name-loop');

		super.update(elapsed);
	}

	inline public function isAnimationNull():Bool
		return getAnimaionController().curAnim == null;

	inline public function getAnimationName():String
	{
		var name:String = '';
		@:privateAccess
		if (!isAnimationNull())
			name = getAnimaionController().curAnim.name;
		return (name != null) ? name : '';
	}

	public function isAnimationFinished():Bool
	{
		if (isAnimationNull())
			return false;
		return getAnimaionController().curAnim.finished;
	}

	public function finishAnimation():Void
	{
		if (isAnimationNull())
			return;

		getAnimaionController().curAnim.finish();
	}

	inline public function getAnimaionController():FlxAnimationController
	{
		if (spriteType == TEXTURE_ATLAS)
			return cast this.anim;
		else
			return animation;
	}

	public var animPaused(get, set):Bool;

	private function get_animPaused():Bool
	{
		if (isAnimationNull())
			return false;
		return getAnimaionController().curAnim.paused;
	}

	private function set_animPaused(value:Bool):Bool
	{
		if (isAnimationNull())
			return value;

		getAnimaionController().curAnim.paused = value;

		return value;
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance()
	{
		if (!debugMode && !skipDance && !specialAnim)
		{
			if (danceIdle)
			{
				danced = !danced;

				if (danced)
					playAnim('danceRight' + idleSuffix);
				else
					playAnim('danceLeft' + idleSuffix);
			}
			else if (animOffsets.exists('idle' + idleSuffix))
			{
				playAnim('idle' + idleSuffix);
			}
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;
		getAnimaionController().play(AnimName, Force, Reversed, Frame);
		
		if (animOffsets.exists(AnimName))
		{
			var daOffset = animOffsets.get(AnimName);
			offset.set(daOffset[0], daOffset[1]);
		}
		// else offset.set(0, 0);

		if (curCharacter.startsWith('gf-') || curCharacter == 'gf')
		{
			if (AnimName == 'singLEFT')
				danced = true;
			else if (AnimName == 'singRIGHT')
				danced = false;

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
				danced = !danced;
		}
	}

	function loadMappedAnims():Void
	{
		try
		{
			var noteData:Array<SwagSection> = Song.loadFromJson('picospeaker', Paths.formatToSongPath(PlayState.SONG.song)).notes;
			for (section in noteData)
			{
				for (songNotes in section.sectionNotes)
				{
					animationNotes.push(songNotes);
				}
			}
			animationNotes.sort(sortAnims);
		}
		catch (e:Dynamic)
		{
		}
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	public var danceEveryNumBeats:Int = 2;

	private var settingCharacterUp:Bool = true;

	public function recalculateDanceIdle()
	{
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animOffsets.exists('danceLeft' + idleSuffix) && animOffsets.exists('danceRight' + idleSuffix));

		if (settingCharacterUp)
		{
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if (lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if (danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		if (spriteType == TEXTURE_ATLAS)
			this.anim.addBySymbol(name, name, 24, false);
		else
			animation.addByPrefix(name, anim, 24, false);
	}
}
