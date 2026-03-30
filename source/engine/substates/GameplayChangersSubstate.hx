package substates;

import objects.AttachedText;
import objects.CheckboxThingie;
import flixel.addons.transition.FlxTransitionableState;

@:nullSafety
class GameplayChangersSubstate extends MusicBeatSubstate
{
	private var curOption:Null<GameplayOption> = null;
	private var curSelected:Int = 0;
	private var optionsArray:Array<Dynamic> = [];

	private var grpOptions:FlxTypedGroup<Alphabet> = new FlxTypedGroup<Alphabet>();
	private var checkboxGroup:FlxTypedGroup<CheckboxThingie> = new FlxTypedGroup<CheckboxThingie>();
	private var grpTexts:FlxTypedGroup<AttachedText> = new FlxTypedGroup<AttachedText>();

	function getOptions()
	{
		var goption:GameplayOption = new GameplayOption('Scroll Type', 'scrolltype', 'string', 'multiplicative', ["multiplicative", "constant"]);
		optionsArray.push(goption);

		var option:GameplayOption = new GameplayOption('Scroll Speed', 'scrollspeed', 'float', 1);
		option.scrollSpeed = 2.0;
		option.minValue = 0.35;
		option.changeValue = 0.05;
		option.decimals = 2;
		if (goption.getValue() != "constant")
		{
			option.displayFormat = '%vX';
			option.maxValue = 3;
		}
		else
		{
			option.displayFormat = "%v";
			option.maxValue = 6;
		}
		optionsArray.push(option);

		#if FLX_PITCH
		var option:GameplayOption = new GameplayOption('Playback Rate', 'songspeed', 'float', 1);
		option.scrollSpeed = 1;
		option.minValue = 0.5;
		option.maxValue = 3.0;
		option.changeValue = 0.05;
		option.displayFormat = '%vX';
		option.decimals = 2;
		optionsArray.push(option);
		#end

		var option:GameplayOption = new GameplayOption('Health Gain Multiplier', 'healthgain', 'float', 1);
		option.scrollSpeed = 2.5;
		option.minValue = 0;
		option.maxValue = 5;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Health Loss Multiplier', 'healthloss', 'float', 1);
		option.scrollSpeed = 2.5;
		option.minValue = 0.5;
		option.maxValue = 5;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';
		optionsArray.push(option);

		optionsArray.push(new GameplayOption('Play as Opponent', 'playAsOpponent', 'bool', false));
		optionsArray.push(new GameplayOption('Instakill on Miss', 'instakill', 'bool', false));
		optionsArray.push(new GameplayOption('Practice Mode', 'practice', 'bool', false));
		optionsArray.push(new GameplayOption('Botplay', 'botplay', 'bool', false));
	}

	public function getOptionByName(name:String):Null<GameplayOption>
	{
		for (i in optionsArray)
		{
			var opt:GameplayOption = i;
			if (opt.name == name)
				return opt;
		}
		return null;
	}

	public function new()
	{
		super();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		add(grpOptions);
		add(grpTexts);
		add(checkboxGroup);

		getOptions();

		for (i in 0...optionsArray.length)
		{
			var optItem:GameplayOption = optionsArray[i];
			var optionText:Alphabet = new Alphabet(200, 360, optItem.name, true);
			optionText.isMenuItem = true;
			optionText.setScale(0.8);
			optionText.targetY = i;
			grpOptions.add(optionText);

			if (optItem.type == 'bool')
			{
				optionText.x += 90;
				optionText.startPosition.x += 90;
				optionText.snapToPosition();
				var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, optItem.getValue() == true);
				checkbox.sprTracker = optionText;
				checkbox.offsetX -= 20;
				checkbox.offsetY = -52;
				checkbox.ID = i;
				checkboxGroup.add(checkbox);
			}
			else
			{
				optionText.snapToPosition();
				var valueText:AttachedText = new AttachedText(Std.string(optItem.getValue()), optionText.width + 40, 0, true, 0.8);
				valueText.sprTracker = optionText;
				valueText.copyAlpha = true;
				valueText.ID = i;
				grpTexts.add(valueText);
				optItem.setChild(valueText);
			}
			updateTextFrom(optItem);
		}

		#if FEATURE_MOBILE_CONTROLS
		addTouchPad("LEFT_FULL", "A_B_C");
		addTouchPadCamera(false);
		#end

		changeSelection();
		reloadCheckboxes();
	}

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;

	override function update(elapsed:Float)
	{
		if (controls.UI_UP_P)
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
		}

		if (controls.BACK)
		{
			ClientPrefs.saveSettings();
			close();
			var cancelSnd = Paths.sound('cancelMenu');
			if (cancelSnd != null)
				FlxG.sound.play(cancelSnd);
		}

		if (nextAccept <= 0)
		{
			var opt = curOption;
			if (opt != null)
			{
				var optType = opt.type;
				var usesCheckbox = optType == 'bool';

				if (usesCheckbox)
				{
					if (controls.ACCEPT)
					{
						var scrollSnd = Paths.sound('scrollMenu');
						if (scrollSnd != null)
							FlxG.sound.play(scrollSnd);
						var currentVal = opt.getValue();
						opt.setValue((currentVal == true) ? false : true);
						opt.change();
						reloadCheckboxes();
					}
				}
				else
				{
					if (controls.UI_LEFT || controls.UI_RIGHT)
					{
						var pressed = (controls.UI_LEFT_P || controls.UI_RIGHT_P);
						if (holdTime > 0.5 || pressed)
						{
							if (pressed)
							{
								var add:Dynamic = null;
								if (optType != 'string')
								{
									add = controls.UI_LEFT ? -opt.changeValue : opt.changeValue;
								}

								switch (optType)
								{
									case 'int' | 'float' | 'percent':
										holdValue = opt.getValue() + add;
										if (holdValue < opt.minValue)
											holdValue = opt.minValue;
										else if (holdValue > opt.maxValue)
											holdValue = opt.maxValue;

										switch (optType)
										{
											case 'int':
												holdValue = Math.round(holdValue);
												opt.setValue(holdValue);

											case 'float' | 'percent':
												holdValue = FlxMath.roundDecimal(holdValue, opt.decimals);
												opt.setValue(holdValue);
										}

									case 'string':
										var num:Int = opt.curOption;
										if (controls.UI_LEFT_P)
											--num;
										else
											num++;

										var optOpts = opt.options;
										if (optOpts != null)
										{
											if (num < 0)
											{
												num = optOpts.length - 1;
											}
											else if (num >= optOpts.length)
											{
												num = 0;
											}
											var optVal = optOpts[num];
											opt.curOption = num;
											opt.setValue(optVal);

											if (opt.name == "Scroll Type")
											{
												var oOption = getOptionByName("Scroll Speed");
												if (oOption != null)
												{
													var curVal = opt.getValue();
													if (curVal == "constant")
													{
														oOption.displayFormat = "%v";
														oOption.maxValue = 6;
													}
													else
													{
														oOption.displayFormat = "%vX";
														oOption.maxValue = 3;
														if (oOption.getValue() > 3)
															oOption.setValue(3);
													}
													updateTextFrom(oOption);
												}
											}
										}
								}
								updateTextFrom(opt);
								opt.change();
								var scrollSnd2 = Paths.sound('scrollMenu');
								if (scrollSnd2 != null)
									FlxG.sound.play(scrollSnd2);
							}
							else if (optType != 'string')
							{
								holdValue = Math.max(opt.minValue, Math.min(opt.maxValue, holdValue + opt.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1)));

								switch (optType)
								{
									case 'int':
										opt.setValue(Math.round(holdValue));

									case 'float' | 'percent':
										var blah:Float = Math.max(opt.minValue,
											Math.min(opt.maxValue, holdValue + opt.changeValue - (holdValue % opt.changeValue)));
										opt.setValue(FlxMath.roundDecimal(blah, opt.decimals));
								}
								updateTextFrom(opt);
								opt.change();
							}
						}

						if (optType != 'string')
						{
							holdTime += elapsed;
						}
					}
					else if (controls.UI_LEFT_R || controls.UI_RIGHT_R)
					{
						clearHold();
					}
				}
			}

			if (controls.RESET #if FEATURE_MOBILE_CONTROLS || touchPad.buttonC.justPressed #end)
			{
				for (i in 0...optionsArray.length)
				{
					var leOption:GameplayOption = optionsArray[i];
					leOption.setValue(leOption.defaultValue);
					var leType = leOption.type;
					if (leType != 'bool')
					{
						if (leType == 'string')
						{
							var leOpts = leOption.options;
							if (leOpts != null)
							{
								leOption.curOption = leOpts.indexOf(leOption.getValue());
							}
						}
						updateTextFrom(leOption);
					}

					if (leOption.name == 'Scroll Speed')
					{
						leOption.displayFormat = "%vX";
						leOption.maxValue = 3;
						if (leOption.getValue() > 3)
						{
							leOption.setValue(3);
						}
						updateTextFrom(leOption);
					}
					leOption.change();
				}
				var cancelSnd2 = Paths.sound('cancelMenu');
				if (cancelSnd2 != null)
					FlxG.sound.play(cancelSnd2);
				reloadCheckboxes();
			}
		}

		if (nextAccept > 0)
		{
			nextAccept -= 1;
		}
		#if FEATURE_MOBILE_CONTROLS
		if (touchPad == null)
		{
			addTouchPad("LEFT_FULL", "A_B_C");
			addTouchPadCamera(false);
		}
		#end
		super.update(elapsed);
	}

	function updateTextFrom(option:GameplayOption)
	{
		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();
		if (option.type == 'percent')
			val *= 100;
		var def:Dynamic = option.defaultValue;
		var newText = text.replace('%v', val).replace('%d', def);
		option.text = newText;
	}

	function clearHold()
	{
		if (holdTime > 0.5)
		{
			var scrollSnd3 = Paths.sound('scrollMenu');
			if (scrollSnd3 != null)
				FlxG.sound.play(scrollSnd3);
		}
		holdTime = 0;
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		if (curSelected < 0)
			curSelected = optionsArray.length - 1;
		if (curSelected >= optionsArray.length)
			curSelected = 0;

		callOnScripts('onChangeSelection');

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}
		for (text in grpTexts)
		{
			if (text != null)
			{
				text.alpha = 0.6;
				if (text.ID == curSelected)
				{
					text.alpha = 1;
				}
			}
		}
		curOption = optionsArray[curSelected];
		var scrollSnd4 = Paths.sound('scrollMenu');
		if (scrollSnd4 != null)
			FlxG.sound.play(scrollSnd4);
	}

	function reloadCheckboxes()
	{
		for (checkbox in checkboxGroup)
		{
			if (checkbox != null)
			{
				checkbox.isChecked = (optionsArray[checkbox.ID].getValue() == true);
			}
		}
	}
}

@:nullSafety
class GameplayOption
{
	private var child:Null<Alphabet> = null;
	private var _text:Null<String> = null;

	public var onChange:Null<Void->Void> = null;

	public var type(get, default):String = 'bool';

	public var showBoyfriend:Bool = false;
	public var scrollSpeed:Float = 50;

	private var variable:Null<String> = null;

	public var defaultValue:Dynamic = null;

	public var curOption:Int = 0;
	public var options:Null<Array<String>> = null;
	public var changeValue:Dynamic = 1;
	public var minValue:Dynamic = null;
	public var maxValue:Dynamic = null;
	public var decimals:Int = 1;

	public var displayFormat:String = '%v';
	public var name:String = 'Unknown';

	public function new(name:String, variable:String, type:String = 'bool', defaultValue:Dynamic = 'null variable value', ?options:Array<String> = null)
	{
		this.name = name;
		this.variable = variable;
		this.type = type;
		this.defaultValue = defaultValue;
		this.options = options;

		if (defaultValue == 'null variable value')
		{
			switch (type)
			{
				case 'bool':
					defaultValue = false;
				case 'int' | 'float':
					defaultValue = 0;
				case 'percent':
					defaultValue = 1;
				case 'string':
					defaultValue = '';
					if (options != null && options.length > 0)
					{
						defaultValue = options[0];
					}
			}
		}

		if (getValue() == null)
		{
			setValue(defaultValue);
		}

		switch (type)
		{
			case 'string':
				var opts = options;
				if (opts != null)
				{
					var num:Int = opts.indexOf(getValue());
					if (num > -1)
					{
						curOption = num;
					}
				}

			case 'percent':
				displayFormat = '%v%';
				changeValue = 0.01;
				minValue = 0;
				maxValue = 1;
				scrollSpeed = 0.5;
				decimals = 2;
		}
	}

	public function change()
	{
		var cb = onChange;
		if (cb != null)
		{
			cb();
		}
	}

	public function getValue():Dynamic
	{
		var v = variable;
		if (v != null)
		{
			return ClientPrefs.data.gameplaySettings.get(v);
		}
		return null;
	}

	public function setValue(value:Dynamic)
	{
		var v = variable;
		if (v != null)
		{
			ClientPrefs.data.gameplaySettings.set(v, value);
		}
	}

	public function setChild(child:Alphabet)
	{
		this.child = child;
	}

	public var text(get, set):String;

	private function get_text():String
	{
		var t = _text;
		if (t != null)
			return t;
		var c = child;
		if (c != null)
			return c.text;
		return '';
	}

	private function set_text(newValue:String):String
	{
		_text = newValue;
		var c = child;
		if (c != null)
		{
			c.text = newValue;
		}
		return newValue;
	}

	private function get_type():String
	{
		var newValue:String = 'bool';
		switch (type.toLowerCase().trim())
		{
			case 'int' | 'float' | 'percent' | 'string':
				newValue = type;
			case 'integer':
				newValue = 'int';
			case 'str':
				newValue = 'string';
			case 'fl':
				newValue = 'float';
		}
		type = newValue;
		return type;
	}
}
