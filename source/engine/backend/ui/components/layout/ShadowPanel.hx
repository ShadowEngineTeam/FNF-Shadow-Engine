package backend.ui.components.layout;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import backend.Paths;
import backend.ui.ShadowStyle;

class ShadowPanel extends FlxSpriteGroup
{
	public var bg:FlxSprite;
	public var title(default, set):String;
	public var collapsed(default, set):Bool = false;
	public var showCloseButton:Bool = true;
	public var showMinimizeButton:Bool = true;
	public var onClose:Void->Void;

	var headerBar:FlxSprite;
	var titleText:FlxText;
	var closeBtn:FlxSprite;
	var minimizeBtn:FlxSprite;

	var _width:Int;
	var _height:Int;
	var _contentHeight:Int;

	var _dragging:Bool = false;
	var _dragOffsetX:Float = 0;
	var _dragOffsetY:Float = 0;

	var _pressing:Bool = false;
	var _pressStartX:Float = 0;
	var _pressStartY:Float = 0;

	var _closeBtnHover:Bool = false;
	var _minimizeBtnHover:Bool = false;

	public function new(x:Float, y:Float, width:Int = 300, height:Int = 200, ?title:String, ?bgColor:FlxColor, ?borderColor:FlxColor)
	{
		super(x, y);
		_width = width;
		_height = height;
		_contentHeight = height - ShadowStyle.HEIGHT_HEADER;
		this.title = title;

		var fill = bgColor != null ? bgColor : ShadowStyle.BG_DARK;
		var border = borderColor != null ? borderColor : ShadowStyle.BORDER_DARK;

		// Create header bar
		headerBar = new FlxSprite();
		drawHeaderBar();
		add(headerBar);

		// Create title text
		titleText = new FlxText(ShadowStyle.SPACING_SM, 0, _width - ShadowStyle.SPACING_SM * 2 - (ShadowStyle.SIZE_HEADER_BTN + 2) * 2, title != null ? title : "");
		titleText.setFormat(Paths.font(ShadowStyle.FONT_DEFAULT), ShadowStyle.FONT_SIZE_MD, ShadowStyle.TEXT_PRIMARY, LEFT);
		titleText.antialiasing = ShadowStyle.antialiasing;
		titleText.y = (ShadowStyle.HEIGHT_HEADER - titleText.height) / 2;
		add(titleText);

		// Create close button
		closeBtn = new FlxSprite();
		drawCloseButton(false);
		closeBtn.x = _width - ShadowStyle.SIZE_HEADER_BTN - 3;
		closeBtn.y = (ShadowStyle.HEIGHT_HEADER - ShadowStyle.SIZE_HEADER_BTN) / 2;
		add(closeBtn);

		// Create minimize button
		minimizeBtn = new FlxSprite();
		drawMinimizeButton(false);
		minimizeBtn.x = _width - (ShadowStyle.SIZE_HEADER_BTN + 3) * 2;
		minimizeBtn.y = (ShadowStyle.HEIGHT_HEADER - ShadowStyle.SIZE_HEADER_BTN) / 2;
		add(minimizeBtn);

		// Create background panel (below header)
		bg = new FlxSprite(0, ShadowStyle.HEIGHT_HEADER);
		drawBackground(fill, border);
		add(bg);
	}

	function drawHeaderBar()
	{
		headerBar.makeGraphic(_width, ShadowStyle.HEIGHT_HEADER, ShadowStyle.BG_MEDIUM, true);
		// Top border
		for (i in 0..._width)
			headerBar.pixels.setPixel32(i, 0, ShadowStyle.BORDER_DARK);
		// Side borders
		for (i in 0...ShadowStyle.HEIGHT_HEADER)
		{
			headerBar.pixels.setPixel32(0, i, ShadowStyle.BORDER_DARK);
			headerBar.pixels.setPixel32(_width - 1, i, ShadowStyle.BORDER_DARK);
		}
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

	function drawBackground(fillColor:FlxColor, borderColor:FlxColor)
	{
		bg.makeGraphic(_width, _contentHeight, fillColor, true);
		// Bottom border
		for (i in 0..._width)
			bg.pixels.setPixel32(i, _contentHeight - 1, borderColor);
		// Side borders
		for (i in 0..._contentHeight)
		{
			bg.pixels.setPixel32(0, i, borderColor);
			bg.pixels.setPixel32(_width - 1, i, borderColor);
		}
	}

	function set_title(value:String):String
	{
		title = value;
		if (titleText != null)
			titleText.text = value != null ? value : "";
		return value;
	}

	function set_collapsed(value:Bool):Bool
	{
		if (collapsed == value)
			return value;
		collapsed = value;

		bg.visible = !collapsed;
		// Hide/show content added after bg
		for (i in 0...members.length)
		{
			var member = members[i];
			if (member != headerBar && member != titleText && member != closeBtn && member != minimizeBtn && member != bg)
			{
				member.visible = !collapsed;
			}
		}

		// Redraw minimize button to show correct icon
		drawMinimizeButton(_minimizeBtnHover);

		return value;
	}

	public function resize(width:Int, height:Int, ?bgColor:FlxColor, ?borderColor:FlxColor)
	{
		_width = width;
		_height = height;
		_contentHeight = height - ShadowStyle.HEIGHT_HEADER;

		var fill = bgColor != null ? bgColor : ShadowStyle.BG_DARK;
		var border = borderColor != null ? borderColor : ShadowStyle.BORDER_DARK;

		drawHeaderBar();
		drawBackground(fill, border);

		// Update title text width
		titleText.fieldWidth = _width - ShadowStyle.SPACING_SM * 2 - (ShadowStyle.SIZE_HEADER_BTN + 2) * 2;

		// Reposition buttons
		closeBtn.x = _width - ShadowStyle.SIZE_HEADER_BTN - 3;
		minimizeBtn.x = _width - (ShadowStyle.SIZE_HEADER_BTN + 3) * 2;
	}

	override function update(elapsed:Float)
	{
		if (!visible || !active || !exists)
			return;

		super.update(elapsed);

		var mx = FlxG.mouse.screenX;
		var my = FlxG.mouse.screenY;

		var overCloseBtn = showCloseButton && FlxG.mouse.overlaps(closeBtn, camera);
		var overMinimizeBtn = showMinimizeButton && FlxG.mouse.overlaps(minimizeBtn, camera);
		
		if (overCloseBtn != _closeBtnHover)
		{
			_closeBtnHover = overCloseBtn;
			drawCloseButton(_closeBtnHover);
		}

		closeBtn.visible = showCloseButton;
		minimizeBtn.visible = showMinimizeButton;

		var headerLeft = this.x;
		var headerTop = this.y;
		var headerRight = this.x + _width;
		var headerBottom = this.y + ShadowStyle.HEIGHT_HEADER;
		var inHeader = mx >= headerLeft && mx <= headerRight && my >= headerTop && my <= headerBottom;

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

			// Start potential drag
			if (inHeader)
			{
				_pressing = true;
				_pressStartX = mx;
				_pressStartY = my;
			}
		}

		// Check for drag threshold
		if (_pressing && !_dragging && FlxG.mouse.pressed)
		{
			var dx = mx - _pressStartX;
			var dy = my - _pressStartY;
			if ((dx * dx + dy * dy) >= 16)
			{
				_dragging = true;
				_dragOffsetX = _pressStartX - this.x;
				_dragOffsetY = _pressStartY - this.y;
			}
		}

		if (_pressing && FlxG.mouse.justReleased)
		{
			_pressing = false;
		}
	}
}
