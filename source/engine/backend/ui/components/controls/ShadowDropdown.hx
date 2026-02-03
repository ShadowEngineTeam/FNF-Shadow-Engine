package backend.ui.components.controls;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxCamera;
import backend.Paths;
import backend.ui.ShadowStyle;

class ShadowDropdown extends FlxSpriteGroup
{
	public var selectedIndex(get, set):Int;
	public var selectedLabel(get, null):String;
	public var callback:Int->Void;
	public var hasFocus:Bool = false;

	private static var _instances:Array<ShadowDropdown> = [];
	private static var _clickConsumedFrame:Int = -1;
	private static var _clickConsumer:ShadowDropdown = null;

	var options:Array<String>;
	var header:FlxSprite;
	var headerText:FlxText;
	var arrow:FlxSprite;
	var dropList:ShadowDropdownList;
	var listBg:FlxSprite;
	var isOpen:Bool = false;

	var _rowHighlight:FlxSprite;
	var _rowItems:Array<FlxText> = [];

	var _width:Int;
	var _height:Int;
	var _maxVisible:Int;
	var _scrollIndex:Int = 0;
	var _headerHovered:Bool = false;
	var _selectedIndex:Int = 0;

	var _hoverIndex:Int = -1;

	var _ignoreUntilMouseRelease:Bool = false;
	var _ignoreClickUntilTick:Int = -1;
	var _wasActive:Bool = true;

	var _tmpMouse:FlxPoint = new FlxPoint();
	var _tmpBg:FlxPoint = new FlxPoint();

	public function new(x:Float, y:Float, items:Array<String>, ?onChange:Int->Void, width:Int = 150, maxVisibleItems:Int = 6)
	{
		super(x, y);

		_instances.push(this);
		options = items;
		callback = onChange;
		_width = width;
		_height = ShadowStyle.HEIGHT_INPUT;
		_maxVisible = maxVisibleItems;

		header = new FlxSprite(0, 0);
		drawHeader(ShadowStyle.BORDER_DARK);
		add(header);

		headerText = new FlxText(ShadowStyle.SPACING_SM, 0, _width - 24, options.length > 0 ? options[0] : "");
		headerText.setFormat(Paths.font(ShadowStyle.FONT_DEFAULT), ShadowStyle.FONT_SIZE_MD, ShadowStyle.TEXT_PRIMARY);
		headerText.antialiasing = ShadowStyle.antialiasing;
		headerText.y = (_height - headerText.height) / 2;
		add(headerText);

		arrow = new FlxSprite(_width - 16, 0);
		drawArrow();
		add(arrow);

		dropList = new ShadowDropdownList(0, _height);
		dropList.dropdown = this;
		dropList.visible = false;
		dropList.exists = false;
		dropList.active = false;
		add(dropList);

		_ignoreClickUntilTick = Std.int(FlxG.game.ticks);
		_ignoreUntilMouseRelease = (FlxG.mouse.pressed || FlxG.mouse.pressedRight || FlxG.mouse.pressedMiddle);

		applyCamerasToChildren();
	}

	override public function destroy():Void
	{
		if (isOpen)
			closeList();
		if (_clickConsumer == this)
			_clickConsumer = null;
		_instances.remove(this);
		super.destroy();
	}

	override function set_cameras(value:Array<FlxCamera>):Array<FlxCamera>
	{
		var out:Array<FlxCamera> = super.set_cameras(value);
		applyCamerasToChildren();
		return out;
	}

	inline function getCam():FlxCamera
	{
		return (cameras != null && cameras.length > 0 && cameras[0] != null) ? cameras[0] : FlxG.camera;
	}

	function applyCamerasToChildren():Void
	{
		if (header != null)
			header.cameras = cameras;
		if (headerText != null)
			headerText.cameras = cameras;
		if (arrow != null)
			arrow.cameras = cameras;
		if (dropList != null)
			dropList.cameras = cameras;

		if (listBg != null)
			listBg.cameras = cameras;
		if (_rowHighlight != null)
			_rowHighlight.cameras = cameras;
		for (t in _rowItems)
			if (t != null)
				t.cameras = cameras;
	}

	public static function closeAllOpen():Void
		for (dropdown in _instances)
			if (dropdown != null && dropdown.isOpen)
				dropdown.closeList();

	public static function isAnyOpen():Bool
	{
		for (d in _instances)
			if (d != null && d.exists && d.active && d.visible && d.isOpen)
				return true;

		return false;
	}

	public static function isClickCaptured():Bool
	{
		if (_clickConsumer == null)
			return false;
		if (_clickConsumedFrame != Std.int(FlxG.game.ticks))
			return false;
		return _clickConsumer.exists && _clickConsumer.active && _clickConsumer.visible && _clickConsumer.isOpen;
	}

	public static function consumeClick(?consumer:ShadowDropdown):Void
	{
		_clickConsumedFrame = Std.int(FlxG.game.ticks);
		_clickConsumer = consumer;
	}

	private static inline function clearClickConsumer(dropdown:ShadowDropdown):Void
		if (_clickConsumer == dropdown)
			_clickConsumer = null;

	private static inline function isAnyMouseJustPressed():Bool
		return FlxG.mouse.justPressed || FlxG.mouse.justPressedRight || FlxG.mouse.justPressedMiddle;

	private static inline function isDropdownActive(dropdown:ShadowDropdown):Bool
		return dropdown != null && dropdown.exists && dropdown.active && dropdown.visible && dropdown.isOpen;

	function drawHeader(borderColor:FlxColor)
	{
		header.makeGraphic(_width, _height, ShadowStyle.BG_INPUT, true);
		for (i in 0..._width)
		{
			header.pixels.setPixel32(i, 0, borderColor);
			header.pixels.setPixel32(i, _height - 1, borderColor);
		}
		for (i in 0..._height)
		{
			header.pixels.setPixel32(0, i, borderColor);
			header.pixels.setPixel32(_width - 1, i, borderColor);
		}
	}

	function drawArrow()
	{
		arrow.makeGraphic(12, _height, FlxColor.TRANSPARENT, true);
		var cx:Int = 6;
		var cy:Int = Std.int(_height / 2);
		for (row in 0...4)
		{
			for (col in 0...(row * 2 + 1))
			{
				var px:Int = cx - row + col;
				var py:Int = cy - 2 + row;
				if (px >= 0 && px < 12 && py >= 0 && py < _height)
					arrow.pixels.setPixel32(px, py, ShadowStyle.TEXT_SECONDARY);
			}
		}
	}

	inline function mouseOverSpriteScreenRect(s:FlxSprite, cam:FlxCamera):Bool
	{
		if (s == null || !s.visible)
			return false;

		FlxG.mouse.getScreenPosition(cam, _tmpMouse);
		s.getScreenPosition(_tmpBg, cam);

		return _tmpMouse.x >= _tmpBg.x
			&& _tmpMouse.x < _tmpBg.x + s.width
			&& _tmpMouse.y >= _tmpBg.y
			&& _tmpMouse.y < _tmpBg.y + s.height;
	}

	inline function isMouseOverHeader(cam:FlxCamera):Bool
		return header != null && header.visible && header.active && mouseOverSpriteScreenRect(header, cam);

	inline function isMouseOverList(cam:FlxCamera):Bool
		return listBg != null && listBg.visible && mouseOverSpriteScreenRect(listBg, cam);

	inline function getHoveredIndexOnList(cam:FlxCamera):Int
	{
		if (!isMouseOverList(cam))
			return -1;

		FlxG.mouse.getScreenPosition(cam, _tmpMouse);
		listBg.getScreenPosition(_tmpBg, cam);

		var localY:Float = _tmpMouse.y - _tmpBg.y;
		if (localY < 0)
			return -1;

		var idx:Int = _scrollIndex + Std.int(localY / _height);
		return (idx >= 0 && idx < options.length) ? idx : -1;
	}

	function ensureListAssets():Void
	{
		if (dropList == null)
			return;

		if (listBg == null)
		{
			listBg = new FlxSprite(0, 0);
			listBg.cameras = cameras;
			dropList.add(listBg);
		}

		if (_rowHighlight == null)
		{
			_rowHighlight = new FlxSprite(1, 0);
			_rowHighlight.makeGraphic(_width - 2, _height, ShadowStyle.BG_MEDIUM);
			_rowHighlight.visible = false;
			_rowHighlight.cameras = cameras;
			dropList.add(_rowHighlight);
		}

		while (_rowItems.length < _maxVisible)
		{
			var t:FlxText = new FlxText(ShadowStyle.SPACING_SM, 0, _width - ShadowStyle.SPACING_SM * 2, "");
			t.setFormat(Paths.font(ShadowStyle.FONT_DEFAULT), ShadowStyle.FONT_SIZE_MD, ShadowStyle.TEXT_PRIMARY);
			t.antialiasing = ShadowStyle.antialiasing;
			t.visible = false;
			t.cameras = cameras;
			_rowItems.push(t);
			dropList.add(t);
		}
	}

	function ensureSelectedVisible():Void
	{
		if (options == null || options.length == 0)
		{
			_scrollIndex = 0;
			return;
		}

		var visibleCount:Int = Std.int(Math.min(options.length, _maxVisible));
		if (visibleCount <= 0)
		{
			_scrollIndex = 0;
			return;
		}

		var maxScroll:Int = Std.int(Math.max(0, options.length - visibleCount));
		if (_selectedIndex < _scrollIndex)
			_scrollIndex = _selectedIndex;
		else if (_selectedIndex >= _scrollIndex + visibleCount)
			_scrollIndex = _selectedIndex - visibleCount + 1;

		if (_scrollIndex < 0)
			_scrollIndex = 0;
		if (_scrollIndex > maxScroll)
			_scrollIndex = maxScroll;
	}

	function buildDropList():Void
	{
		var visibleCount:Int = Std.int(Math.min(options.length, _maxVisible));
		if (visibleCount <= 0)
		{
			if (dropList != null)
			{
				dropList.visible = false;
				dropList.exists = false;
				dropList.active = false;
			}
			if (listBg != null)
				listBg.visible = false;
			if (_rowHighlight != null)
				_rowHighlight.visible = false;
			for (row in _rowItems)
				if (row != null)
					row.visible = false;
			return;
		}

		ensureListAssets();
		_rowHighlight.x = this.x;

		var listHeight:Int = visibleCount * _height;

		listBg.makeGraphic(_width, listHeight, ShadowStyle.BG_DARK, true);
		for (i in 0..._width)
			listBg.pixels.setPixel32(i, listHeight - 1, ShadowStyle.BORDER_DARK);
		for (i in 0...listHeight)
		{
			listBg.pixels.setPixel32(0, i, ShadowStyle.BORDER_DARK);
			listBg.pixels.setPixel32(_width - 1, i, ShadowStyle.BORDER_DARK);
		}
		listBg.visible = true;

		dropList.visible = true;
		dropList.exists = true;
		dropList.active = true;

		var highlightIndex:Int = -1;

		if (_hoverIndex >= _scrollIndex && _hoverIndex < _scrollIndex + visibleCount)
			highlightIndex = _hoverIndex - _scrollIndex;

		for (i in 0..._maxVisible)
		{
			var row = _rowItems[i];
			if (row == null)
				continue;

			if (i < visibleCount)
			{
				var optionIndex:Int = _scrollIndex + i;
				if (optionIndex >= options.length)
				{
					row.visible = false;
					continue;
				}

				row.visible = true;
				row.x = this.x + ShadowStyle.SPACING_SM; // ensure X is always correct
				row.y = (this.y + _height) + i * _height + Std.int((_height - 14) / 2);
				row.text = options[optionIndex];

				row.color = (optionIndex == _selectedIndex) ? ShadowStyle.ACCENT : ShadowStyle.TEXT_PRIMARY;
				row.ID = optionIndex;

				if (highlightIndex < 0 && optionIndex == _selectedIndex)
					highlightIndex = i;
			}
			else
			{
				row.visible = false;
			}
		}

		if (_rowHighlight != null)
		{
			if (highlightIndex >= 0)
			{
				_rowHighlight.visible = true;
				_rowHighlight.y = (this.y + _height) + highlightIndex * _height;
			}
			else
			{
				_rowHighlight.visible = false;
			}
		}
	}

	inline function openList():Void
	{
		if (options == null || options.length == 0)
			return;

		closeAllOpen(); // fixes focus / multiple open lists

		isOpen = true;
		hasFocus = true;

		ensureSelectedVisible();
		buildDropList();
		consumeClick(this);
	}

	inline function closeList():Void
	{
		isOpen = false;
		hasFocus = false;
		_hoverIndex = -1;

		if (dropList != null)
		{
			dropList.visible = false;
			dropList.exists = false;
			dropList.active = false;
		}

		if (listBg != null)
			listBg.visible = false;
		if (_rowHighlight != null)
			_rowHighlight.visible = false;
		for (row in _rowItems)
			if (row != null)
				row.visible = false;

		clearClickConsumer(this);
		if (!_headerHovered)
			drawHeader(ShadowStyle.BORDER_DARK);
	}

	function get_selectedIndex():Int
		return _selectedIndex;

	function set_selectedIndex(value:Int):Int
	{
		if (options == null || options.length == 0)
		{
			_selectedIndex = 0;
			if (headerText != null)
				headerText.text = "";
			return _selectedIndex;
		}

		_selectedIndex = Std.int(Math.max(0, Math.min(options.length - 1, value)));
		if (headerText != null)
			headerText.text = options[_selectedIndex];

		ensureSelectedVisible();
		if (isOpen)
			buildDropList();

		return _selectedIndex;
	}

	function get_selectedLabel():String
	{
		if (options != null && options.length > _selectedIndex && _selectedIndex >= 0)
			return options[_selectedIndex];
		return "";
	}

	public function setOptions(items:Array<String>)
	{
		options = items;
		_scrollIndex = 0;
		if (_selectedIndex >= options.length)
			_selectedIndex = 0;
		set_selectedIndex(_selectedIndex);
		if (isOpen)
			buildDropList();
	}

	override function set_visible(Value:Bool):Bool
	{
		if (!Value && isOpen)
			closeList();
		return super.set_visible(Value);
	}

	override function set_active(Value:Bool):Bool
	{
		if (!Value && isOpen)
			closeList();
		return super.set_active(Value);
	}

	override function set_exists(Value:Bool):Bool
	{
		if (!Value && isOpen)
			closeList();
		return super.set_exists(Value);
	}

	override function update(elapsed:Float)
	{
		if (!visible || !active || !exists)
		{
			if (isOpen)
				closeList();
			_wasActive = false;
			return;
		}

		if (!_wasActive)
		{
			_wasActive = true;
			_ignoreClickUntilTick = Std.int(FlxG.game.ticks);
			_ignoreUntilMouseRelease = (FlxG.mouse.pressed || FlxG.mouse.pressedRight || FlxG.mouse.pressedMiddle);
		}

		super.update(elapsed);

		var cam = getCam();
		var nowTick:Int = Std.int(FlxG.game.ticks);

		if (_ignoreUntilMouseRelease)
		{
			if (!FlxG.mouse.pressed && !FlxG.mouse.pressedRight && !FlxG.mouse.pressedMiddle)
				_ignoreUntilMouseRelease = false;
		}

		var overHeader:Bool = isMouseOverHeader(cam);
		if (overHeader && !_headerHovered)
		{
			_headerHovered = true;
			drawHeader(ShadowStyle.ACCENT);
		}
		else if (!overHeader && _headerHovered)
		{
			_headerHovered = false;
			if (!isOpen)
				drawHeader(ShadowStyle.BORDER_DARK);
		}

		if (isOpen)
		{
			var idx:Int = getHoveredIndexOnList(cam);
			if (idx != _hoverIndex)
			{
				_hoverIndex = idx;
				buildDropList();
			}
		}

		var anyClick:Bool = isAnyMouseJustPressed();
		var leftClick:Bool = FlxG.mouse.justPressed;

		if (!_ignoreUntilMouseRelease && anyClick && nowTick > _ignoreClickUntilTick)
		{
			if (leftClick && overHeader)
			{
				if (!isOpen)
					openList();
				else
					closeList();
				return;
			}

			if (isOpen && leftClick)
			{
				var idx:Int = getHoveredIndexOnList(cam);
				if (idx != -1)
				{
					selectedIndex = idx;
					if (callback != null)
						callback(_selectedIndex);
					closeList();
					consumeClick(this);
					return;
				}

				if (!overHeader && !isMouseOverList(cam))
				{
					closeList();
					consumeClick(this);
					return;
				}
			}
		}

		if (isOpen && isMouseOverList(cam))
		{
			var wheel:Int = FlxG.mouse.wheel;
			var maxScroll:Int = Std.int(Math.max(0, options.length - Math.min(options.length, _maxVisible)));
			if (wheel != 0 && maxScroll > 0)
			{
				_scrollIndex = Std.int(Math.max(0, Math.min(maxScroll, _scrollIndex - wheel)));
				buildDropList();
			}
		}
	}
}

class ShadowDropdownList extends FlxSpriteGroup
{
	public var dropdown:ShadowDropdown;

	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);
	}

	override function set_visible(Value:Bool):Bool
	{
		if (Value && !canToggle())
			return visible;
		return super.set_visible(Value);
	}

	override function set_exists(Value:Bool):Bool
	{
		if (Value && !canToggle())
			return exists;
		return super.set_exists(Value);
	}

	override function set_active(Value:Bool):Bool
	{
		if (Value && !canToggle())
			return active;
		return super.set_active(Value);
	}

	inline function canToggle():Bool
	{
		return dropdown != null && @:privateAccess dropdown.isOpen;
	}
}
