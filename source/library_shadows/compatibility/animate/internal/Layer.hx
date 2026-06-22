package animate.internal;

import animate.FlxAnimateJson.LayerJson;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.util.FlxDestroyUtil;

class Layer implements IFlxDestroyable
{
	public var timeline:Null<Timeline>;
	public var frames:Null<Array<Frame>>;
	public var frameCount(get, never):Int;
	public var visible:Bool;
	public var name:String;
	public var layerType:LayerType;
	public var parentLayer:Null<Layer>;

	var frameIndices:Null<Array<Int>>;

	public function new(?timeline:Timeline)
	{
		this.frames = [];
		this.frameIndices = [];
		this.visible = true;
		this.timeline = timeline;
		this.name = "";
		this.layerType = NORMAL;
	}

	public function forEachFrame(callback:Frame->Void)
	{
		if (frames != null)
		{
			for (frame in frames)
				callback(frame);
		}
	}

	public function getFrameAtIndex(index:Int):Null<Frame>
	{
		index = FlxMath.maxInt(index, 0);

		if (frames.length == 0)
			return null;

		if (index >= frameCount)
			return frames[frames.length - 1];

		var frameIndex = frameIndices[index];
		return frames[frameIndex];
	}

	public function setKeyframe(index:Int)
	{
		var lastFrame = getFrameAtIndex(index);
		if (lastFrame == null || lastFrame.index == index)
			return;

		setBlankKeyframe(index);
		var keyframe = getFrameAtIndex(index);

		keyframe.elements = lastFrame.elements.copy();
		keyframe.name = lastFrame.name;
	}

	public function setBlankKeyframe(index:Int)
	{
		var lastFrame = getFrameAtIndex(index);

		var startIndex = lastFrame.index;
		var startDuration = lastFrame.duration;

		var keyframe = new Frame(this);
		keyframe.index = index;
		keyframe.duration = startDuration - (index - startIndex);

		frames.insert(frames.indexOf(lastFrame) + 1, keyframe);
		for (i in 0...keyframe.duration)
			frameIndices[index + i] = frames.length - 1;
	}

	public function getBounds(frameIndex:Int, ?rect:FlxRect, ?matrix:FlxMatrix, ?includeFilters:Bool = true, ?useCachedBounds:Bool = false):FlxRect
	{
		rect ??= FlxRect.get();

		var frame = getFrameAtIndex(frameIndex);
		if (frame != null)
			return frame.getBounds((frameIndex - frame.index), rect, matrix, includeFilters, useCachedBounds);

		Timeline.applyMatrixToRect(rect, matrix);

		return rect;
	}

	public inline function iterator()
	{
		return frames.iterator();
	}

	public inline function keyValueIterator()
	{
		return frames.keyValueIterator();
	}

	@:allow(animate.internal.Timeline)
	function _loadJson(layer:LayerJson, parent:FlxAnimateFrames, ?layerIndex:Int, ?layers:Array<Layer>):Void
	{
		this.name = layer.LN;

		var clippedBy:Null<String> = layer.Clpb;
		var isMasked:Bool = clippedBy != null;

		if (isMasked && layerIndex != null && layers != null)
		{
			var i = layerIndex - 1;
			var foundLayer:Bool = false;
			this.layerType = CLIPPED;

			while (i >= 0)
			{
				var aboveLayer = layers[i--];
				if (aboveLayer != null && aboveLayer.name == clippedBy && aboveLayer.layerType == CLIPPER)
				{
					parentLayer = aboveLayer;
					foundLayer = true;
					break;
				}
			}

			if (!foundLayer)
			{
				parentLayer = null;
				isMasked = false;
				visible = false;
			}
		}
		else
		{
			final type:Null<String> = layer.LT;
			this.layerType = type != null ? switch (type)
			{
				case "Clp" | "Clipper": CLIPPER;
				case "Fld" | "Folder": FOLDER;
				default: NORMAL;
			} : NORMAL;
		}

		if (this.layerType == CLIPPER)
			visible = false;

		if (this.layerType != FOLDER)
		{
			for (i => frameJson in layer.FR)
			{
				var frame = new Frame(this);
				frame._loadJson(frameJson, parent);
				frames.push(frame);

				for (_ in 0...frame.duration)
					frameIndices.push(i);
			}
		}

		if (!isMasked)
			return;

		var _cacheOnLoad:Bool = false;
		@:privateAccess {
			if (parent != null && parent._settings != null)
				_cacheOnLoad = parent._settings.cacheOnLoad ?? false;
		}

		for (frame in frames)
		{
			if (frame.elements.length <= 0)
				continue;

			frame._dirty = true;
			frame._requireBake = true;

			if (_cacheOnLoad)
			{
				for (i in 0...frame.duration)
					frame._bakeFrame(i);
			}
		}
	}

	public function destroy():Void
	{
		parentLayer = null;

		if (frames != null)
		{
			for (frame in frames)
				frame.destroy();
		}

		frames = null;
		frameIndices = null;
	}

	inline function get_frameCount():Int
	{
		return frameIndices.length;
	}

	public function toString():String
	{
		return '{name: "$name", frameCount: $frameCount, layerType: $layerType}';
	}
}

enum abstract LayerType(Int) to Int
{
	var NORMAL;
	var CLIPPER;
	var CLIPPED;
	var FOLDER;

	public function toString():String
	{
		return switch (cast this : LayerType)
		{
			case CLIPPER: "clipper";
			case CLIPPED: "clipped";
			case FOLDER: "folder";
			case NORMAL: "normal";
		}
	}
}
