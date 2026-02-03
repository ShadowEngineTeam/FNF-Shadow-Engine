package substates;

class Prompt extends MusicBeatSubstate
{
	public var okc:Void->Void;
	public var cancelc:Void->Void;

	var overlay:FlxSprite;
	var panel:ShadowPanel;
	var buttonAccept:FlxSprite;
	var buttonCancel:FlxSprite;
	var labelAccept:FlxText;
	var labelCancel:FlxText;
	var questionText:FlxText;

	var theText:String = '';
	var goAnyway:Bool = false;
	var acceptLabel:String;
	var cancelLabel:String;

	var selected:Int = 0;
	var buttonWidth:Int = 120;
	var buttonHeight:Int = 36;

	public function new(promptText:String = '', defaultSelected:Int = 0, okCallback:Void->Void, cancelCallback:Void->Void, acceptOnDefault:Bool = false,
			option1:String = null, option2:String = null)
	{
		selected = defaultSelected;
		okc = okCallback;
		cancelc = cancelCallback;
		theText = promptText;
		goAnyway = acceptOnDefault;

		acceptLabel = option1 != null ? option1 : 'OK';
		cancelLabel = option2 != null ? option2 : 'Cancel';
		super();
	}

	override public function create():Void
	{
		super.create();

		if (goAnyway)
		{
			if (okc != null)
				okc();
			close();
			return;
		}

		overlay = new FlxSprite();
		overlay.makeGraphic(FlxG.width, FlxG.height, 0xAA000000);
		overlay.scrollFactor.set();
		add(overlay);

		var panelWidth:Int = 450;
		var panelHeight:Int = 180;
		var panelX:Int = Std.int((FlxG.width - panelWidth) / 2);
		var panelY:Int = Std.int((FlxG.height - panelHeight) / 2);

		panel = new ShadowPanel(panelX, panelY, panelWidth, panelHeight);
		panel.scrollFactor.set();
		add(panel);

		questionText = new FlxText(ShadowStyle.SPACING_LG, ShadowStyle.SPACING_LG, panelWidth - ShadowStyle.SPACING_LG * 2, theText);
		questionText.setFormat(Paths.font(ShadowStyle.FONT_DEFAULT), ShadowStyle.FONT_SIZE_LG + 2, ShadowStyle.TEXT_PRIMARY, CENTER);
		questionText.scrollFactor.set();
		panel.add(questionText);

		var buttonSpacing:Int = ShadowStyle.SPACING_LG;
		var totalButtonWidth:Float = buttonWidth * 2 + buttonSpacing;
		var buttonY:Int = panelHeight - buttonHeight - ShadowStyle.SPACING_LG;
		var buttonStartX:Int = Std.int((panelWidth - totalButtonWidth) / 2);

		buttonAccept = new FlxSprite(buttonStartX, buttonY);
		buttonAccept.scrollFactor.set();
		panel.add(buttonAccept);

		labelAccept = new FlxText(buttonStartX, buttonY, buttonWidth, acceptLabel);
		labelAccept.setFormat(Paths.font(ShadowStyle.FONT_DEFAULT), ShadowStyle.FONT_SIZE_MD + 2, ShadowStyle.TEXT_PRIMARY, CENTER);
		labelAccept.y = buttonY + (buttonHeight - labelAccept.height) / 2;
		labelAccept.scrollFactor.set();
		panel.add(labelAccept);

		buttonCancel = new FlxSprite(buttonStartX + buttonWidth + buttonSpacing, buttonY);
		buttonCancel.scrollFactor.set();
		panel.add(buttonCancel);

		labelCancel = new FlxText(buttonStartX + buttonWidth + buttonSpacing, buttonY, buttonWidth, cancelLabel);
		labelCancel.setFormat(Paths.font(ShadowStyle.FONT_DEFAULT), ShadowStyle.FONT_SIZE_MD + 2, ShadowStyle.TEXT_PRIMARY, CENTER);
		labelCancel.y = buttonY + (buttonHeight - labelCancel.height) / 2;
		labelCancel.scrollFactor.set();
		panel.add(labelCancel);

		updateSelection();
	}

	function drawButton(button:FlxSprite, isSelected:Bool, isHovered:Bool = false)
	{
		var fillColor:FlxColor = isSelected ? ShadowStyle.ACCENT : ShadowStyle.BG_MEDIUM;
		var borderColor:FlxColor = isSelected ? ShadowStyle.ACCENT_HOVER : ShadowStyle.BORDER_DARK;

		if (isHovered && !isSelected)
		{
			fillColor = ShadowStyle.BG_LIGHT;
			borderColor = ShadowStyle.BORDER_LIGHT;
		}

		button.makeGraphic(buttonWidth, buttonHeight, fillColor, true);

		for (i in 0...buttonWidth)
		{
			button.pixels.setPixel32(i, 0, borderColor);
			button.pixels.setPixel32(i, buttonHeight - 1, borderColor);
		}
		for (i in 0...buttonHeight)
		{
			button.pixels.setPixel32(0, i, borderColor);
			button.pixels.setPixel32(buttonWidth - 1, i, borderColor);
		}
	}

	function updateSelection()
	{
		var hoverAccept:Bool = FlxG.mouse.overlaps(buttonAccept, camera);
		var hoverCancel:Bool = FlxG.mouse.overlaps(buttonCancel, camera);

		drawButton(buttonAccept, selected == 0, hoverAccept);
		drawButton(buttonCancel, selected == 1, hoverCancel);

		labelAccept.color = selected == 0 ? FlxColor.WHITE : ShadowStyle.TEXT_PRIMARY;
		labelCancel.color = selected == 1 ? FlxColor.WHITE : ShadowStyle.TEXT_PRIMARY;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (buttonAccept == null || buttonCancel == null)
			return;

		var hoverAccept:Bool = FlxG.mouse.overlaps(buttonAccept, camera);
		var hoverCancel:Bool = FlxG.mouse.overlaps(buttonCancel, camera);

		if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A)
		{
			selected = 0;
			//FlxG.sound.play(Paths.sound('scrollMenu'));
			updateSelection();
		}
		else if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D)
		{
			selected = 1;
			//FlxG.sound.play(Paths.sound('scrollMenu'));
			updateSelection();
		}

		if (hoverAccept || hoverCancel)
			updateSelection();

		if (FlxG.mouse.justPressed)
		{
			if (hoverAccept)
			{
				selected = 0;
				confirm();
			}
			else if (hoverCancel)
			{
				selected = 1;
				confirm();
			}
		}

		if (FlxG.keys.justPressed.ENTER)
		{
			confirm();
		}
		else if (FlxG.keys.justPressed.ESCAPE)
		{
			selected = 1;
			confirm();
		}
	}

	function confirm()
	{
		//FlxG.sound.play(Paths.sound('confirmMenu'));

		if (selected == 0)
		{
			if (okc != null)
				okc();
			callOnScripts('onOK');
		}
		else
		{
			if (cancelc != null)
				cancelc();
			callOnScripts('onNO');
		}
		close();
	}
}
