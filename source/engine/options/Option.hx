package options;

typedef Keybind =
{
	keyboard:String,
	gamepad:String
}

@:nullSafety
class Option
{
	public var child:Null<Alphabet> = null;
	public var text(get, set):String;
	private var _text:String = '';
	public var onChange:Null<Void->Void> = null;

	public var type(get, default):String = 'bool';

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
	public var description:String = '';
	public var name:String = 'Unknown';

	public var defaultKeys:Null<Keybind> = null;
	public var keys:Null<Keybind> = null;

	public function new(name:String, description:String = '', variable:String, type:String = 'bool', ?options:Array<String> = null)
	{
		this.name = name;
		this.description = description;
		this.variable = variable;
		this.type = type;
		this.options = options;

		if (this.type != 'keybind')
			this.defaultValue = Reflect.getProperty(ClientPrefs.defaultData, variable);
		switch (type)
		{
			case 'bool':
				if (defaultValue == null)
					defaultValue = false;
			case 'int' | 'float':
				if (defaultValue == null)
					defaultValue = 0;
			case 'percent':
				if (defaultValue == null)
					defaultValue = 1;
				displayFormat = '%v%';
				changeValue = 0.01;
				minValue = 0;
				maxValue = 1;
				scrollSpeed = 0.5;
				decimals = 2;
			case 'string':
				if (defaultValue == null)
					defaultValue = '';
				if (options != null && options.length > 0)
				{
					defaultValue = options[0];
				}

			case 'keybind':
				defaultValue = '';
				defaultKeys = {gamepad: 'NONE', keyboard: 'NONE'};
				keys = {gamepad: 'NONE', keyboard: 'NONE'};
		}

		try
		{
			if (getValue() == null)
			{
				setValue(defaultValue);
			}

			switch (type)
			{
				case 'string':
					if (options != null)
					{
						var num:Int = options.indexOf(getValue());
						if (num > -1)
						{
							curOption = num;
						}
					}
			}
		}
		catch (e)
		{
		}
	}

	public function change()
	{
		// nothin'
		if (onChange != null)
			onChange();
	}

	dynamic public function getValue():Dynamic
	{
		var varName:String = (variable != null) ? variable : '';
		var value = Reflect.getProperty(ClientPrefs.data, varName);
		if (type == 'keybind')
		{
			var isControllerMode:Bool = (Controls.instance != null && Controls.instance.controllerMode);
			return !isControllerMode ? value.keyboard : value.gamepad;
		}
		return value;
	}

	dynamic public function setValue(value:Dynamic)
	{
		if (type == 'keybind')
		{
			var varName:String = (variable != null) ? variable : '';
			var keys = Reflect.getProperty(ClientPrefs.data, varName);
			var isControllerMode:Bool = (Controls.instance != null && Controls.instance.controllerMode);
			if (!isControllerMode)
				keys.keyboard = value;
			else
				keys.gamepad = value;
			return value;
		}
		var varName:String = (variable != null) ? variable : '';
		return Reflect.setProperty(ClientPrefs.data, varName, value);
	}

	private function get_text():String
	{
		if (child != null)
		{
			return child.text;
		}
		return _text;
	}

	private function set_text(newValue:String):String
	{
		if (child != null)
		{
			child.text = newValue;
		}
		_text = newValue;
		return newValue;
	}

	private function get_type()
	{
		var newValue:String = 'bool';
		switch (type.toLowerCase().trim())
		{
			case 'key', 'keybind':
				newValue = 'keybind';
			case 'int', 'float', 'percent', 'string':
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
