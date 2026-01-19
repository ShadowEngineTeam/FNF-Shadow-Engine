package backend.ui.components.layout;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
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
	public var showCloseButton:Bool = true;
	public var showMinimizeButton:Bool = true;
	public var onClose:Void->Void;

	var tabs:Array<TabDef>;
	var tabButtons:Array<FlxSpriteGroup>;
	var tabContents:Map<String, FlxSpriteGroup>;
	var panelBg:FlxSprite;
	var tabBar:FlxSprite;
	var accentLine:FlxSprite;
	var closeBtn:FlxSprite;
	var minimizeBtn:FlxSprite;

	var _width:Int;
	var _height:Int;
	var _tabWidth:Int;
	var _tabAreaWidth:Int;
	var _selectedTab:Int = 0;
	var _initialized:Bool = false;
	var _mousePos:FlxPoint = new FlxPoint();

	var _dragging:Bool = false;
	var _dragOffsetX:Float = 0;
	var _dragOffsetY:Float = 0;

	var _pressing:Bool = false;
	var _pressStartX:Float = 0;
	var _pressStartY:Float = 0;
	var _pressTabIndex:Int = -1;

	var _closeBtnHover:Bool = false;
	var _minimizeBtnHover:Bool = false;

	public function new(x:Float, y:Float, tabDefs:Array<TabDef>, width:Int = 400, height:Int = 300)
	{
		super(x, y);
		tabs = tabDefs;
		_width = width;
		_height = height;

		// Calculate tab area width (leave space for buttons)
		var buttonSpace = (ShadowStyle.SIZE_HEADER_BTN + 3) * 2 + 4;
		_tabAreaWidth = _width - buttonSpace;
		_tabWidth = tabs.length > 0 ? Std.int(_tabAreaWidth / tabs.length) : _tabAreaWidth;

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

		// Create close button
		closeBtn = new FlxSprite();
		drawCloseButton(false);
		closeBtn.x = _width - ShadowStyle.SIZE_HEADER_BTN - 3;
		closeBtn.y = (ShadowStyle.HEIGHT_TAB - ShadowStyle.SIZE_HEADER_BTN) / 2;
		add(closeBtn);

		// Create minimize button
		minimizeBtn = new FlxSprite();
		drawMinimizeButton(false);
		minimizeBtn.x = _width - (ShadowStyle.SIZE_HEADER_BTN + 3) * 2;
		minimizeBtn.y = (ShadowStyle.HEIGHT_TAB - ShadowStyle.SIZE_HEADER_BTN) / 2;
		add(minimizeBtn);

		if (tabs.length > 0)
		{
			for (i in 0...tabs.length)
			{
				var tabBtn = createTabButton(i);
				tabButtons.push(tabBtn);
				add(tabBtn);

				var content = new FlxSpriteGroup(0, ShadowStyle.HEIGHT_TAB);
				content.visible = (i == 0);
				content.active = (i == 0); // Only first tab is active initially
				tabContents.set(tabs[i].name, content);
				add(content);
			}
		}

		selectedTab = _selectedTab;
		_initialized = true;
	}

	function drawCloseButton(hover:Bool)
	{
		var size = ShadowStyle.SIZE_HEADER_BTN;
		var bgColor = hover ? ShadowStyle.ACCENT : ShadowStyle.BG_LIGHT;
		closeBtn.makeGraphic(size, size, bgColor, true);

		// Draw X symbol
		var lineColor = ShadowStyle.TEXT_PRIMARY;
		var padding = 4;
		for (i in 0...(size - padding * 2))
		{
			// Top-left to bottom-right diagonal
			closeBtn.pixels.setPixel32(padding + i, padding + i, lineColor);
			// Top-right to bottom-left diagonal
			closeBtn.pixels.setPixel32(size - padding - 1 - i, padding + i, lineColor);
			// Make lines thicker
			if (i > 0)
			{
				closeBtn.pixels.setPixel32(padding + i - 1, padding + i, lineColor);
				closeBtn.pixels.setPixel32(size - padding - i, padding + i, lineColor);
			}
		}
	}

	function drawMinimizeButton(hover:Bool)
	{
		var size = ShadowStyle.SIZE_HEADER_BTN;
		var bgColor = hover ? ShadowStyle.BG_LIGHT : ShadowStyle.BG_LIGHT;
		if (hover)
			bgColor = ShadowStyle.brighten(ShadowStyle.BG_LIGHT, 0.1);
		minimizeBtn.makeGraphic(size, size, bgColor, true);

		var lineColor = ShadowStyle.TEXT_PRIMARY;
		var padding = 4;

		if (collapsed)
		{
			// Draw restore symbol (square)
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
			// Draw minimize symbol (underscore)
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
		{
			panelBg.pixels.setPixel32(i, panelHeight - 1, ShadowStyle.BORDER_DARK);
		}
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
		{
			tabBar.pixels.setPixel32(i, 0, ShadowStyle.BORDER_DARK);
		}
		for (i in 0...ShadowStyle.HEIGHT_TAB)
		{
			tabBar.pixels.setPixel32(0, i, ShadowStyle.BORDER_DARK);
			tabBar.pixels.setPixel32(_width - 1, i, ShadowStyle.BORDER_DARK);
		}
	}

	function createTabButton(index:Int):FlxSpriteGroup
	{
		var btn = new FlxSpriteGroup(index * _tabWidth, 0);

		var bg = new FlxSprite();
		bg.makeGraphic(_tabWidth, ShadowStyle.HEIGHT_TAB - 2, ShadowStyle.BG_MEDIUM);
		bg.ID = index;
		btn.add(bg);

		var txt = new FlxText(0, 0, _tabWidth, tabs[index].label);
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
			var bg:FlxSprite = cast btn.members[0];
			var txt:FlxText = cast btn.members[1];

			if (i == _selectedTab)
			{
				bg.makeGraphic(_tabWidth, ShadowStyle.HEIGHT_TAB - 2, ShadowStyle.BG_DARK);
				txt.color = ShadowStyle.TEXT_PRIMARY;
			}
			else
			{
				bg.makeGraphic(_tabWidth, ShadowStyle.HEIGHT_TAB - 2, ShadowStyle.BG_MEDIUM);
				txt.color = ShadowStyle.TEXT_SECONDARY;
			}
		}
	}

	function set_collapsed(value:Bool):Bool
	{
		if (collapsed == value)
			return value;
		collapsed = value;

		panelBg.visible = !collapsed;
		accentLine.visible = !collapsed;

		// Hide/show tab contents
		for (i in 0...tabs.length)
		{
			var content = tabContents.get(tabs[i].name);
			if (content != null)
			{
				content.visible = !collapsed && (i == _selectedTab);
				content.active = !collapsed && (i == _selectedTab);
			}
		}

		// Redraw minimize button to show correct icon
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

		var mx = FlxG.mouse.screenX;
		var my = FlxG.mouse.screenY;

		// Check button hovers using overlaps for accurate detection
		var overCloseBtn = showCloseButton && FlxG.mouse.overlaps(closeBtn, camera);
		var overMinimizeBtn = showMinimizeButton && FlxG.mouse.overlaps(minimizeBtn, camera);

		// Update hover states
		if (overCloseBtn != _closeBtnHover)
		{
			_closeBtnHover = overCloseBtn;
			drawCloseButton(_closeBtnHover);
		}
		if (overMinimizeBtn != _minimizeBtnHover)
		{
			_minimizeBtnHover = overMinimizeBtn;
			drawMinimizeButton(_minimizeBtnHover);
		}

		// Update button visibility
		closeBtn.visible = showCloseButton;
		minimizeBtn.visible = showMinimizeButton;

		var left = this.x;
		var top = this.y;
		var right = this.x + _width;
		var tabBottom = this.y + ShadowStyle.HEIGHT_TAB;

		var inTabBar = (mx >= left && mx <= right && my >= top && my <= tabBottom);

		if (_dragging)
		{
			if (FlxG.mouse.pressed)
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

		if (FlxG.mouse.justPressed)
		{
			// Check button clicks first
			if (overCloseBtn)
			{
				if (onClose != null)
					onClose();
				this.visible = false;
				return;
			}

			if (overMinimizeBtn)
			{
				collapsed = !collapsed;
				return;
			}

			if (ShadowDropdown.isClickCaptured() || ShadowDropdown.isAnyOpen())
				return;

			_pressing = inTabBar;
			_pressStartX = mx;
			_pressStartY = my;
			_pressTabIndex = -1;

			if (inTabBar)
			{
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

		if (_pressing && !_dragging && FlxG.mouse.pressed)
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
			if (!_dragging && _pressTabIndex != -1)
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
