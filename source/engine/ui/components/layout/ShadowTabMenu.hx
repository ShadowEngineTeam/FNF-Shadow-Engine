package ui.components.layout;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import backend.Paths;
import ui.ShadowStyle;
import ui.components.controls.ShadowDropdown;

typedef TabDef =
{
	var name:String;
	var label:String;
}

class ShadowTabMenu extends FlxSpriteGroup
{
	public var selectedTab(get, set):Int;
	public var callback:Int->Void;

	var tabs:Array<TabDef>;
	var tabButtons:Array<FlxSpriteGroup>;
	var tabContents:Map<String, FlxSpriteGroup>;
	var panelBg:FlxSprite;
	var tabBar:FlxSprite;
	var accentLine:FlxSprite;

	var _width:Int;
	var _height:Int;
	var _tabWidth:Int;
	var _selectedTab:Int = 0;
	var _initialized:Bool = false;
	var _mousePos:FlxPoint = new FlxPoint();

	var _dragging:Bool = false;
	var _dragOffsetX:Float = 0;
	var _dragOffsetY:Float = 0;

	public function new(x:Float, y:Float, tabDefs:Array<TabDef>, width:Int = 400, height:Int = 300)
	{
		super(x, y);
		tabs = tabDefs;
		_width = width;
		_height = height;
		_tabWidth = tabs.length > 0 ? Std.int(_width / tabs.length) : _width;

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
					var isActive = (i == _selectedTab);
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

		if (FlxG.mouse.justPressed)
		{
			// don't steal clicks from dropdowns
			if (!ShadowDropdown.isClickCaptured() && !ShadowDropdown.isAnyOpen())
			{
				if (FlxG.mouse.overlaps(panelBg, camera) || FlxG.mouse.overlaps(tabBar, camera) || FlxG.mouse.overlaps(accentLine, camera))
				{
					_dragging = true;
					_dragOffsetX = FlxG.mouse.screenX - this.x;
					_dragOffsetY = FlxG.mouse.screenY - this.y;
					return;
				}
			}
		}

		if (_dragging)
		{
			if (FlxG.mouse.pressed)
			{
				this.x = FlxG.mouse.screenX - _dragOffsetX;
				this.y = FlxG.mouse.screenY - _dragOffsetY;
				return; // while dragging, ignore tab switching
			}
			else
				_dragging = false;
		}

		if (FlxG.mouse.justPressed)
		{
			if (ShadowDropdown.isClickCaptured() || ShadowDropdown.isAnyOpen())
				return;

			for (i in 0...tabButtons.length)
			{
				var btn = tabButtons[i];
				var bg:FlxSprite = cast btn.members[0];
				if (FlxG.mouse.overlaps(bg, camera))
				{
					if (i != _selectedTab)
					{
						selectedTab = i;
						if (callback != null)
							callback(i);
					}
					break;
				}
			}
		}
	}
}
