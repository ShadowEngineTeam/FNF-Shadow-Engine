package debug.codename;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import cpp.SizeT;
import cpp.vm.Gc;

//@:cppNamespaceCode("#include <hx/GC.h>")
class GCMemoryCounter extends Sprite
{
	public var gcMemoryText:TextField;
	public var gcMemoryPeakText:TextField;

	public var gcMemory:Float = 0;
	public var gcMemoryPeak:Float = 0;

	public function new()
	{
		super();

		gcMemoryText = new TextField();
		gcMemoryPeakText = new TextField();

		for (label in [gcMemoryText, gcMemoryPeakText])
		{
			label.autoSize = LEFT;
			label.x = 0;
			label.y = 0;
			label.text = "GC";
			label.multiline = label.wordWrap = false;
			label.defaultTextFormat = new TextFormat(Framerate.fontName, 12, -1);
			label.selectable = false;
			addChild(label);
		}

		gcMemoryPeakText.alpha = 0.5;
	}

	public function reload() {}

	public override function __enterFrame(t:Float)
	{
		if (alpha <= 0.05)
			return;

		super.__enterFrame(t);

		final usedGc = /*cpp.NativeGc.gcGarbageEstimate()*/ Gc.memInfo64(Gc.MEM_INFO_USAGE);

		if (usedGc == gcMemory)
		{
			updateLabelPosition();
			return;
		}

		gcMemory = usedGc;
		if (gcMemoryPeak < gcMemory)
			gcMemoryPeak = gcMemory;

		refreshText(gcMemory, gcMemoryPeak);

		updateLabelPosition();
	}

	private inline function updateLabelPosition():Void
		gcMemoryPeakText.x = gcMemoryText.x + gcMemoryText.width;

	private inline function refreshText(mem:Float, peak:Float):Void
	{
		gcMemoryText.text = (Framerate.debugMode == 2 ? "GC: " : "") + CoolUtil.getSizeString(mem);
		gcMemoryPeakText.text = ' / ${CoolUtil.getSizeString(peak)}';
	}
}
