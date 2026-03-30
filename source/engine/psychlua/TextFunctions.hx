package psychlua;

@:nullSafety
class TextFunctions
{
	private static var game(get, never):Dynamic;

	inline private static function get_game()
		return FunkinLua.getCurrentMusicState();

	public static function implement(funk:FunkinLua)
	{
		funk.set("makeLuaText", function(tag:String, text:String, width:Int, x:Float, y:Float)
		{
			tag = tag.replace('.', '');
			LuaUtils.resetTextTag(tag);
			var textObj:FlxText = new FlxText(x, y, width, text, 16);
			textObj.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			textObj.cameras = [cast(game, PlayState).camHUD ?? FlxG.camera];
			textObj.scrollFactor.set();
			textObj.borderSize = 2;
			game.modchartTexts.set(tag, textObj);
		});

		funk.set("setTextString", function(tag:String, text:String)
		{
			var obj:Null<FlxText> = LuaUtils.getTextObject(tag);
			if (obj != null)
			{
				obj.text = text;
				return true;
			}
			FunkinLua.luaTrace("setTextString: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		funk.set("setTextSize", function(tag:String, size:Int)
		{
			var obj:Null<FlxText> = LuaUtils.getTextObject(tag);
			if (obj != null)
			{
				obj.size = size;
				return true;
			}
			FunkinLua.luaTrace("setTextSize: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		funk.set("setTextWidth", function(tag:String, width:Float)
		{
			var obj:Null<FlxText> = LuaUtils.getTextObject(tag);
			if (obj != null)
			{
				obj.fieldWidth = width;
				return true;
			}
			FunkinLua.luaTrace("setTextWidth: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		funk.set("setTextHeight", function(tag:String, height:Float)
		{
			var obj:Null<FlxText> = LuaUtils.getTextObject(tag);
			if (obj != null)
			{
				obj.fieldHeight = height;
				return true;
			}
			FunkinLua.luaTrace("setTextHeight: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		funk.set("setTextAutoSize", function(tag:String, value:Bool)
		{
			var obj:Null<FlxText> = LuaUtils.getTextObject(tag);
			if (obj != null)
			{
				obj.autoSize = value;
				return true;
			}
			FunkinLua.luaTrace("setTextAutoSize: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		funk.set("setTextBorder", function(tag:String, size:Float, color:String, ?style:String = 'outline')
		{
			var obj:Null<FlxText> = LuaUtils.getTextObject(tag);
			if (obj != null)
			{
				var borderStyle:String = if (style == null) 'outline' else style;
				CoolUtil.setTextBorderFromString(obj, (size > 0 ? borderStyle : 'none'));
				if (size > 0)
					obj.borderSize = size;

				obj.borderColor = CoolUtil.colorFromString(color);
				return true;
			}
			FunkinLua.luaTrace("setTextBorder: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		funk.set("setTextColor", function(tag:String, color:String)
		{
			var obj:Null<FlxText> = LuaUtils.getTextObject(tag);
			if (obj != null)
			{
				obj.color = CoolUtil.colorFromString(color);
				return true;
			}
			FunkinLua.luaTrace("setTextColor: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		funk.set("setTextFont", function(tag:String, newFont:String)
		{
			var obj:Null<FlxText> = LuaUtils.getTextObject(tag);
			if (obj != null)
			{
				obj.font = Paths.font(newFont);
				return true;
			}
			FunkinLua.luaTrace("setTextFont: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		funk.set("setTextItalic", function(tag:String, italic:Bool)
		{
			var obj:Null<FlxText> = LuaUtils.getTextObject(tag);
			if (obj != null)
			{
				obj.italic = italic;
				return true;
			}
			FunkinLua.luaTrace("setTextItalic: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		funk.set("setTextAlignment", function(tag:String, alignment:String = 'left')
		{
			var obj:Null<FlxText> = LuaUtils.getTextObject(tag);
			if (obj != null)
			{
				obj.alignment = LEFT;
				switch (alignment.trim().toLowerCase())
				{
					case 'right':
						obj.alignment = RIGHT;
					case 'center':
						obj.alignment = CENTER;
				}
				return true;
			}
			FunkinLua.luaTrace("setTextAlignment: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});

		funk.set("getTextString", function(tag:String):Null<String>
		{
			var obj:Null<FlxText> = LuaUtils.getTextObject(tag);
			if (obj != null && obj.text != null)
			{
				return obj.text;
			}
			FunkinLua.luaTrace("getTextString: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});
		funk.set("getTextSize", function(tag:String)
		{
			var obj:Null<FlxText> = LuaUtils.getTextObject(tag);
			if (obj != null)
			{
				var text:FlxText = obj;
				var sizeValue:Dynamic = Reflect.getProperty(text, 'size');
				return Std.int(sizeValue);
			}
			FunkinLua.luaTrace("getTextSize: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return -1;
		});
		funk.set("getTextFont", function(tag:String):Null<String>
		{
			var obj:Null<FlxText> = LuaUtils.getTextObject(tag);
			if (obj != null)
			{
				return obj.font;
			}
			FunkinLua.luaTrace("getTextFont: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});
		funk.set("getTextWidth", function(tag:String)
		{
			var obj:Null<FlxText> = LuaUtils.getTextObject(tag);
			if (obj != null)
			{
				return obj.fieldWidth;
			}
			FunkinLua.luaTrace("getTextWidth: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return 0;
		});

		funk.set("addLuaText", function(tag:String)
		{
			if (game.modchartTexts.exists(tag))
			{
				var textElement:FlxText = game.modchartTexts.get(tag);
				var target = LuaUtils.getTargetInstance();
				if (target != null)
					target.add(textElement);
			}
		});
		funk.set("removeLuaText", function(tag:String, destroy:Bool = true)
		{
			if (!game.modchartTexts.exists(tag))
			{
				return;
			}

			var textElement:FlxText = game.modchartTexts.get(tag);
			var target = LuaUtils.getTargetInstance();
			if (target != null)
				target.remove(textElement, true);
			if (destroy)
			{
				textElement.kill();
				textElement.destroy();
				game.modchartTexts.remove(tag);
			}
		});
	}
}
