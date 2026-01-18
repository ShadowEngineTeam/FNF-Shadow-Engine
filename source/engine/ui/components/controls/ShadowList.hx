package ui.components.controls;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import backend.Paths;
import ui.ShadowStyle;
import ui.components.text.ShadowLabel;

class ShadowList extends FlxSpriteGroup {
	public var selectedIndex(get, set):Int;
	public var callback:Int->Void;
	public var items:Array<String> = [];

	var bg:FlxSprite;
	var itemLabels:Array<ShadowLabel> = [];
	var _width:Int;
	var _height:Int;
	var _selectedIndex:Int = 0;
	var itemHeight:Int = 20;
	var scrollOffset:Int = 0;
	var maxVisibleItems:Int = 10;

	public function new(x:Float, y:Float, width:Int = 250, height:Int = 300, ?initialItems:Array<String>) {
		super(x, y);
		_width = width;
		_height = height;

		bg = new FlxSprite();
		drawBackground();
		add(bg);

		if (initialItems != null) {
			setItems(initialItems);
		}
	}

	function drawBackground() {
		bg.makeGraphic(_width, _height, ShadowStyle.BG_INPUT, true);
		for (i in 0..._width) {
			bg.pixels.setPixel32(i, 0, ShadowStyle.BORDER_DARK);
			bg.pixels.setPixel32(i, _height - 1, ShadowStyle.BORDER_DARK);
		}
		for (i in 0..._height) {
			bg.pixels.setPixel32(0, i, ShadowStyle.BORDER_DARK);
			bg.pixels.setPixel32(_width - 1, i, ShadowStyle.BORDER_DARK);
		}
	}

	public function setItems(newItems:Array<String>) {
		items = newItems;

		for (label in itemLabels) {
			remove(label, true);
			label.destroy();
		}
		itemLabels = [];

		maxVisibleItems = Std.int((_height - 4) / itemHeight);

		refreshDisplay();
	}

	function refreshDisplay() {
		// Clear existing labels
		for (label in itemLabels) {
			remove(label, true);
			label.destroy();
		}
		itemLabels = [];

		var startIndex = scrollOffset;
		var endIndex = Std.int(Math.min(items.length, scrollOffset + maxVisibleItems));

		for (i in startIndex...endIndex) {
			var displayIndex = i - scrollOffset;
			var yPos = 2 + (displayIndex * itemHeight);

			var color = (i == _selectedIndex) ? FlxColor.LIME : ShadowStyle.TEXT_PRIMARY;
			var label = new ShadowLabel(4, yPos, items[i], ShadowStyle.FONT_SIZE_MD, color, _width - 8);
			itemLabels.push(label);
			add(label);
		}
	}

	override function update(elapsed:Float) {
		if (!visible || !active || !exists)
			return;

		super.update(elapsed);

		#if FLX_MOUSE
		if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(bg, camera)) {
			var mouseY = FlxG.mouse.y - y;
			var clickedIndex = Std.int((mouseY - 2) / itemHeight) + scrollOffset;

			if (clickedIndex >= 0 && clickedIndex < items.length) {
				selectedIndex = clickedIndex;
				if (callback != null)
					callback(clickedIndex);
			}
		}
		#end

		#if FLX_MOUSE
		if (FlxG.mouse.overlaps(bg, camera) && FlxG.mouse.wheel != 0) {
			scrollOffset -= FlxG.mouse.wheel;
			if (scrollOffset < 0)
				scrollOffset = 0;

			var maxScroll = Std.int(Math.max(0, items.length - maxVisibleItems));
			if (scrollOffset > maxScroll)
				scrollOffset = maxScroll;

			refreshDisplay();
		}
		#end
	}

	function get_selectedIndex():Int {
		return _selectedIndex;
	}

	function set_selectedIndex(value:Int):Int {
		if (value < 0) value = 0;
		if (value >= items.length) value = items.length - 1;

		_selectedIndex = value;

		if (_selectedIndex < scrollOffset) {
			scrollOffset = _selectedIndex;
			refreshDisplay();
		} else if (_selectedIndex >= scrollOffset + maxVisibleItems) {
			scrollOffset = _selectedIndex - maxVisibleItems + 1;
			refreshDisplay();
		} else {
			// just color update
			for (i in 0...itemLabels.length) {
				var actualIndex = i + scrollOffset;
				itemLabels[i].color = (actualIndex == _selectedIndex) ? FlxColor.LIME : ShadowStyle.TEXT_PRIMARY;
			}
		}

		return _selectedIndex;
	}

	public function refresh() {
		refreshDisplay();
	}

	public function updateItem(index:Int, newText:String) {
		if (index < 0 || index >= items.length)
			return;

		items[index] = newText;
		
		var visibleIndex = index - scrollOffset;
		if (visibleIndex >= 0 && visibleIndex < itemLabels.length) {
			itemLabels[visibleIndex].text = newText;
		}
	}

	public function updateAllItems(newItems:Array<String>) {
		if (newItems.length != items.length) {
			setItems(newItems);
			return;
		}

		items = newItems;
		for (i in 0...itemLabels.length) {
			var actualIndex = i + scrollOffset;
			if (actualIndex < items.length) {
				itemLabels[i].text = items[actualIndex];
			}
		}
	}
}
