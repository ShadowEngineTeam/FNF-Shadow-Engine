package backend.ui.components.layout;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import backend.Paths;
import backend.ui.ShadowStyle;
import backend.ui.components.controls.ShadowDropdown;

typedef TabDef =
{
	var name:String;
	var label:String;
}

class ShadowTabMenu extends FlxSpriteGroup
{
	public var selectedTab(get, set):Int;
	public var callback:Int->Void;
	public var collapsed(default, set):Bool = false;
	public var showMinimizeButton(default, set):Bool = true;

	var tabs:Array<TabDef>;
	var tabButtons:Array<FlxSpriteGroup>;
	var tabContents:Map<String, FlxSpriteGroup>;
	var panelBg:FlxSprite;
	var tabBar:FlxSprite;
	var accentLine:FlxSprite;
	var minimizeBtn:FlxSprite;

	var _width:Int;
	var _height:Int;

	var _tabWidth:Int;
	var _tabAreaWidth:Int;
	var _tabStartX:Int = 0;

	var _headerRightPad:Int = 3;

	var _selectedTab:Int = 0;
	var _initialized:Bool = false;

	var _dragging:Bool = false;
	var _dragOffsetX:Float = 0;
	var _dragOffsetY:Float = 0;

	var _pressing:Bool = false;
	var _pressStartX:Float = 0;
	var _pressStartY:Float = 0;
	var _pressTabIndex:Int = -1;

	var _minimizeBtnHover:Bool = false;
	var _wantsMinimizeToggle:Bool = false;

	public function new(x:Float, y:Float, tabDefs:Array<TabDef>, width:Int = 400, height:Int = 300)
	{
		super(x, y);
		tabs = tabDefs;
		_width = width;
		_height = height;

		tabContents = new Map();
		tabButtons = [];

		panelBg = new FlxSprite(0, ShadowStyle.HEIGHT_TAB);
		drawPanel();
		add(panelBg);

		tabBar = new FlxSprite();
		drawTabBar();
		add(tabBar);

		accentLine = new FlxSprite(0, ShadowStyle.HEIGHT_TAB - 2);
		accentLine.makeGraphic(_width, 2, ShadowStyle.ACCENT);
		add(accentLine);

		minimizeBtn = new FlxSprite();
		minimizeBtn.y = ((ShadowStyle.HEIGHT_TAB - ShadowStyle.SIZE_HEADER_BTN) / 2) - 1;
		drawMinimizeButton(false);

		updateButtonPositions();
		calculateTabWidth();

		if (tabs.length > 0)
		{
			for (i in 0...tabs.length)
			{
				var tabBtn = createTabButton(i);
				tabButtons.push(tabBtn);
				add(tabBtn);

				var content = new FlxSpriteGroup(0, ShadowStyle.HEIGHT_TAB);
				content.visible = (i == 0);
				content.active = (i == 0);
				tabContents.set(tabs[i].name, content);
				add(content);
			}
		}

		add(minimizeBtn);

		selectedTab = _selectedTab;
		_initialized = true;
	}

	override public function destroy():Void
	{
		if (ShadowStyle.hasFocus(this))
			ShadowStyle.clearFocus();
		super.destroy();
	}

	inline function headerButtonsWidth():Int
	{
		return ShadowStyle.SIZE_HEADER_BTN + _headerRightPad + 2;
	}

	function calculateTabWidth()
	{
		_tabStartX = 0;

		var reservedRight = headerButtonsWidth();

		_tabAreaWidth = _width - reservedRight;
		if (_tabAreaWidth < 0)
			_tabAreaWidth = 0;

		if (tabs.length <= 1)
		{
			_tabWidth = _tabAreaWidth;
			if (_tabWidth < 1)
				_tabWidth = 1;
			return;
		}

		_tabWidth = Std.int(_tabAreaWidth / tabs.length);
		if (_tabWidth < 1)
			_tabWidth = 1;
	}

	inline function tabButtonWidth(index:Int):Int
	{
		if (tabs.length <= 0)
			return _tabAreaWidth;

		if (index == tabs.length - 1)
		{
			var used = index * _tabWidth;
			var rem = _tabAreaWidth - used;
			return (rem > 0) ? rem : _tabWidth;
		}

		return _tabWidth;
	}

	function updateButtonPositions()
	{
		var rightX = _width - _headerRightPad;

		rightX -= ShadowStyle.SIZE_HEADER_BTN;
		minimizeBtn.x += rightX;
		minimizeBtn.visible = showMinimizeButton;

		if (!showMinimizeButton)
			minimizeBtn.x = 0;
	}

	function set_showMinimizeButton(value:Bool):Bool
	{
		if (showMinimizeButton == value)
			return value;
		showMinimizeButton = value;

		updateButtonPositions();
		calculateTabWidth();
		updateTabButtonSizes();

		return value;
	}

	function updateTabButtonSizes()
	{
		for (i in 0...tabButtons.length)
		{
			var btn = tabButtons[i];
			var w = tabButtonWidth(i);

			btn.x = _tabStartX + i * _tabWidth;

			var bg:FlxSprite = cast btn.members[0];
			var txt:FlxText = cast btn.members[1];

			if (i == _selectedTab)
				bg.makeGraphic(w, ShadowStyle.HEIGHT_TAB - 2, ShadowStyle.BG_DARK);
			else
				bg.makeGraphic(w, ShadowStyle.HEIGHT_TAB - 2, ShadowStyle.BG_MEDIUM);

			txt.fieldWidth = w;
		}
	}

	function drawMinimizeButton(hover:Bool)
	{
		var size = ShadowStyle.SIZE_HEADER_BTN;
		var bgColor = hover ? ShadowStyle.brighten(ShadowStyle.BG_LIGHT, 0.1) : ShadowStyle.BG_LIGHT;
		minimizeBtn.makeGraphic(size, size, bgColor, true);

		var lineColor = ShadowStyle.TEXT_PRIMARY;
		var padding = 4;

		if (collapsed)
		{
			for (i in padding...(size - padding))
			{
				minimizeBtn.pixels.setPixel32(i, padding, lineColor);
				minimizeBtn.pixels.setPixel32(i, size - padding - 1, lineColor);
				minimizeBtn.pixels.setPixel32(padding, i, lineColor);
				minimizeBtn.pixels.setPixel32(size - padding - 1, i, lineColor);
			}
		}
		else
		{
			var lineY = size - padding - 2;
			for (i in padding...(size - padding))
			{
				minimizeBtn.pixels.setPixel32(i, lineY, lineColor);
				minimizeBtn.pixels.setPixel32(i, lineY + 1, lineColor);
			}
		}
	}

	function drawPanel()
	{
		var panelHeight = _height - ShadowStyle.HEIGHT_TAB;
		panelBg.makeGraphic(_width, panelHeight, ShadowStyle.BG_DARK, true);
		for (i in 0..._width)
			panelBg.pixels.setPixel32(i, panelHeight - 1, ShadowStyle.BORDER_DARK);

		for (i in 0...panelHeight)
		{
			panelBg.pixels.setPixel32(0, i, ShadowStyle.BORDER_DARK);
			panelBg.pixels.setPixel32(_width - 1, i, ShadowStyle.BORDER_DARK);
		}
	}

	function drawTabBar()
	{
		tabBar.makeGraphic(_width, ShadowStyle.HEIGHT_TAB, ShadowStyle.BG_MEDIUM, true);
		for (i in 0..._width)
			tabBar.pixels.setPixel32(i, 0, ShadowStyle.BORDER_DARK);

		for (i in 0...ShadowStyle.HEIGHT_TAB)
		{
			tabBar.pixels.setPixel32(0, i, ShadowStyle.BORDER_DARK);
			tabBar.pixels.setPixel32(_width - 1, i, ShadowStyle.BORDER_DARK);
		}
	}

	function createTabButton(index:Int):FlxSpriteGroup
	{
		var btnX = _tabStartX + index * _tabWidth;
		var btn = new FlxSpriteGroup(btnX, 0);

		var w = tabButtonWidth(index);

		var bg = new FlxSprite();
		bg.makeGraphic(w, ShadowStyle.HEIGHT_TAB - 2, ShadowStyle.BG_MEDIUM);
		bg.ID = index;
		btn.add(bg);

		var txt = new FlxText(0, 0, w, tabs[index].label);
		txt.setFormat(Paths.font(ShadowStyle.FONT_DEFAULT), ShadowStyle.FONT_SIZE_MD, ShadowStyle.TEXT_PRIMARY, CENTER);
		txt.antialiasing = ShadowStyle.antialiasing;
		txt.y = (ShadowStyle.HEIGHT_TAB - txt.height) / 2 - 1;
		btn.add(txt);

		return btn;
	}

	function updateTabVisuals()
	{
		for (i in 0...tabButtons.length)
		{
			var btn = tabButtons[i];
			var w = tabButtonWidth(i);

			var bg:FlxSprite = cast btn.members[0];
			var txt:FlxText = cast btn.members[1];

			if (i == _selectedTab)
			{
				bg.makeGraphic(w, ShadowStyle.HEIGHT_TAB - 2, ShadowStyle.BG_DARK);
				txt.color = ShadowStyle.TEXT_PRIMARY;
			}
			else
			{
				bg.makeGraphic(w, ShadowStyle.HEIGHT_TAB - 2, ShadowStyle.BG_MEDIUM);
				txt.color = ShadowStyle.TEXT_SECONDARY;
			}
			txt.fieldWidth = w;
		}
	}

	function set_collapsed(value:Bool):Bool
	{
		if (collapsed == value)
			return value;
		collapsed = value;

		panelBg.visible = !collapsed;
		accentLine.visible = !collapsed;

		for (i in 0...tabs.length)
		{
			var content = tabContents.get(tabs[i].name);
			if (content != null)
			{
				content.visible = !collapsed && (i == _selectedTab);
				content.active = !collapsed && (i == _selectedTab);
			}
		}

		drawMinimizeButton(_minimizeBtnHover);
		return value;
	}

	function get_selectedTab():Int
		return _selectedTab;

	function set_selectedTab(value:Int):Int
	{
		if (_initialized && value == _selectedTab)
			return value;

		_selectedTab = value;
		ShadowDropdown.closeAllOpen();
		updateTabVisuals();

		if (tabs.length > 0)
		{
			for (i in 0...tabs.length)
			{
				var content = tabContents.get(tabs[i].name);
				if (content != null)
				{
					var isActive = (i == _selectedTab) && !collapsed;
					content.visible = isActive;
					content.active = isActive;
					content.forEach(function(member:flixel.FlxBasic)
					{
						content.visible = isActive;
						member.active = isActive;
					}, true);
				}
			}
		}
		return value;
	}

	public function getTabGroup(name:String):FlxSpriteGroup
		return tabContents.get(name);

	public function addToTab(name:String, sprite:FlxSprite)
	{
		var group = tabContents.get(name);
		if (group != null)
			group.add(sprite);
	}

	override function update(elapsed:Float)
	{
		if (!visible || !active || !exists)
			return;

		super.update(elapsed);

		var mx = FlxG.mouse.screenX;
		var my = FlxG.mouse.screenY;

		var overMinimizeBtn = showMinimizeButton && minimizeBtn.visible && FlxG.mouse.overlaps(minimizeBtn, camera);

		if (overMinimizeBtn != _minimizeBtnHover)
		{
			_minimizeBtnHover = overMinimizeBtn;
			drawMinimizeButton(_minimizeBtnHover);
		}

		var inTabBar = FlxG.mouse.overlaps(tabBar, camera) && !overMinimizeBtn;

		if (_wantsMinimizeToggle)
		{
			if (ShadowStyle.hasFocus(this))
				collapsed = !collapsed;
			_wantsMinimizeToggle = false;
		}

		if (_dragging)
		{
			if (FlxG.mouse.pressed && ShadowStyle.hasFocus(this))
			{
				this.x = mx - _dragOffsetX;
				this.y = my - _dragOffsetY;
				return;
			}
			else
			{
				_dragging = false;
				_pressing = false;
				_pressTabIndex = -1;
			}
		}

		if (FlxG.mouse.justReleased)
		{
			if (overMinimizeBtn)
			{
				_wantsMinimizeToggle = true;
				ShadowStyle.setFocus(this);
				return;
			}
		}

		if (FlxG.mouse.justPressed)
		{
			if (ShadowDropdown.isClickCaptured() || ShadowDropdown.isAnyOpen())
				return;

			_pressing = inTabBar;
			_pressStartX = mx;
			_pressStartY = my;
			_pressTabIndex = -1;

			if (inTabBar)
			{
				ShadowStyle.setFocus(this);
				for (i in 0...tabButtons.length)
				{
					var btn = tabButtons[i];
					var bg:FlxSprite = cast btn.members[0];
					if (FlxG.mouse.overlaps(bg, camera))
					{
						_pressTabIndex = i;
						break;
					}
				}
			}
		}

		if (_pressing && !_dragging && FlxG.mouse.pressed && ShadowStyle.hasFocus(this))
		{
			var dx = mx - _pressStartX;
			var dy = my - _pressStartY;
			if ((dx * dx + dy * dy) >= 16)
			{
				_dragging = true;
				_dragOffsetX = _pressStartX - this.x;
				_dragOffsetY = _pressStartY - this.y;
				return;
			}
		}

		if (_pressing && FlxG.mouse.justReleased)
		{
			if (!_dragging && _pressTabIndex != -1 && ShadowStyle.hasFocus(this))
			{
				if (_pressTabIndex != _selectedTab)
				{
					selectedTab = _pressTabIndex;
					if (callback != null)
						callback(_pressTabIndex);
				}
			}
			_pressing = false;
			_pressTabIndex = -1;
		}
	}
}
