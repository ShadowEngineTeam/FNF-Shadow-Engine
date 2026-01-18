package ui.components.text;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUI.NamedString;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxTimer;
import lime.system.Clipboard;
import openfl.display.BitmapData;
import openfl.errors.Error;
import openfl.events.KeyboardEvent;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import ui.components.controls.ShadowDropdown;

class ShadowInputText extends FlxText
{
	public static inline var NO_FILTER:Int = 0;
	public static inline var ONLY_ALPHA:Int = 1;
	public static inline var ONLY_NUMERIC:Int = 2;
	public static inline var ONLY_ALPHANUMERIC:Int = 3;
	public static inline var CUSTOM_FILTER:Int = 4;

	public static inline var ALL_CASES:Int = 0;
	public static inline var UPPER_CASE:Int = 1;
	public static inline var LOWER_CASE:Int = 2;

	public static inline var BACKSPACE_ACTION:String = "backspace";
	public static inline var DELETE_ACTION:String = "delete";
	public static inline var ENTER_ACTION:String = "enter";
	public static inline var INPUT_ACTION:String = "input";

	public var customFilterPattern(default, set):EReg;

	function set_customFilterPattern(cfp:EReg)
	{
		customFilterPattern = cfp;
		filterMode = CUSTOM_FILTER;
		return customFilterPattern;
	}

	public var callback:String->String->Void;

	public var background:Bool = false;

	public var caretColor(default, set):Int;

	function set_caretColor(i:Int):Int
	{
		caretColor = i;
		dirty = true;
		return caretColor;
	}

	public var caretWidth(default, set):Int = 1;

	function set_caretWidth(i:Int):Int
	{
		caretWidth = i;
		dirty = true;
		return caretWidth;
	}

	public var selectionColor(default, set):FlxColor = FlxColor.fromRGB(0, 0, 0, 96);

	public var params(default, set):Array<Dynamic>;

	public var passwordMode(get, set):Bool;

	public var hasFocus(default, set):Bool = false;

	public var caretIndex(default, set):Int = 0;

	public var focusGained:Void->Void;

	public var focusLost:Void->Void;

	public var forceCase(default, set):Int = ALL_CASES;

	public var maxLength(default, set):Int = 0;

	public var lines(default, set):Int;

	public var filterMode(default, set):Int = NO_FILTER;

	public var fieldBorderColor(default, set):Int = FlxColor.BLACK;

	public var fieldBorderThickness(default, set):Int = 1;

	public var backgroundColor(default, set):Int = FlxColor.WHITE;

	private var backgroundSprite:FlxSprite;

	private var _caretTimer:FlxTimer;

	private var caret:FlxSprite;

	private var selectionSprite:FlxSprite;

	private var fieldBorderSprite:FlxSprite;

	private var _scrollBoundIndeces:{left:Int, right:Int} = {left: 0, right: 0};

	private var _charBoundaries:Array<FlxRect>;

	private var lastScroll:Int;

	private var _selectionAnchor:Int = 0;
	private var _selecting:Bool = false;
	private var _suppressCaretScroll:Bool = false;

	public function new(X:Float = 0, Y:Float = 0, Width:Int = 150, ?Text:String, size:Int = 8, TextColor:Int = FlxColor.BLACK,
			BackgroundColor:Int = FlxColor.WHITE, EmbeddedFont:Bool = true)
	{
		super(X, Y, Width, Text, size, EmbeddedFont);
		backgroundColor = BackgroundColor;

		if (BackgroundColor != FlxColor.TRANSPARENT)
			background = true;

		color = TextColor;
		caretColor = TextColor;

		caret = new FlxSprite();
		caret.makeGraphic(caretWidth, Std.int(size + 2));
		_caretTimer = new FlxTimer();

		selectionSprite = new FlxSprite(X, Y);
		selectionSprite.visible = false;

		caretIndex = 0;
		_selectionAnchor = caretIndex;
		hasFocus = false;

		if (background)
		{
			fieldBorderSprite = new FlxSprite(X, Y);
			backgroundSprite = new FlxSprite(X, Y);
		}

		lines = 1;
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, false, 1);

		if (Text == null)
			Text = "";

		#if (js && html5)
		FlxG.stage.window.onTextInput.add(handleClipboardText);
		#end

		text = Text;

		calcFrame();
	}

	override public function destroy():Void
	{
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);

		if (_caretTimer != null)
		{
			_caretTimer.cancel();
			_caretTimer = null;
		}

		backgroundSprite = FlxDestroyUtil.destroy(backgroundSprite);
		fieldBorderSprite = FlxDestroyUtil.destroy(fieldBorderSprite);
		selectionSprite = FlxDestroyUtil.destroy(selectionSprite);
		caret = FlxDestroyUtil.destroy(caret);

		callback = null;

		#if sys
		if (_charBoundaries != null)
		{
			while (_charBoundaries.length > 0)
				_charBoundaries.pop();
			_charBoundaries = null;
		}
		#end

		#if (js && html5)
		FlxG.stage.window.onTextInput.remove(handleClipboardText);
		#end

		super.destroy();
	}

	override public function draw():Void
	{
		regenGraphic();
		checkEmptyFrame();

		if (alpha == 0 || _frame.type == EMPTY)
			return;

		if (dirty)
			calcFrame(useFramePixels);

		drawSprite(fieldBorderSprite);
		drawSprite(backgroundSprite);
		drawSprite(selectionSprite);

		final defaultCameras = #if (flixel < version("5.7.0")) cameras #else getCamerasLegacy() #end;
		for (camera in defaultCameras)
		{
			if (!camera.visible || !camera.exists || !isOnScreen(camera))
				continue;

			if (isSimpleRender(camera))
				drawSimple(camera);
			else
				drawComplex(camera);

			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}

		if (caretColor != caret.color || caret.height != size + 2)
			caret.color = caretColor;

		drawSprite(caret);

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug)
			drawDebug();
		#end
	}

	private function drawSprite(Sprite:FlxSprite):Void
	{
		if (Sprite != null && Sprite.visible)
		{
			Sprite.scrollFactor = scrollFactor;
			Sprite._cameras = _cameras;
			Sprite.draw();
		}
	}

	override public function update(elapsed:Float):Void
	{
		if (!visible || !active || !exists)
			return;

		super.update(elapsed);

		#if FLX_MOUSE
		// Only block input if a dropdown consumed the click (dropdown captured it this frame)
		if (FlxG.mouse.justPressed && (ShadowDropdown.isClickCaptured() || ShadowDropdown.isAnyOpen()))
			return;

		var cam = (_cameras != null && _cameras.length > 0) ? _cameras[0] : FlxG.camera;

		if (FlxG.mouse.justPressed)
		{
			var hadFocus:Bool = hasFocus;
			if (FlxG.mouse.overlaps(this, cam))
			{
				var textLen:Int = (text != null) ? text.length : 0;
				var oldCaret:Int = caretIndex;

				var mouseWorldPos = FlxPoint.get();
				FlxG.mouse.getWorldPosition(cam, mouseWorldPos);
				var localX:Float = mouseWorldPos.x - x;
				var localY:Float = mouseWorldPos.y - y;
				mouseWorldPos.put();

				var newIndex:Int = getCharIndexAtPoint(localX, localY);
				if (newIndex < 0)
					newIndex = 0;
				if (newIndex > textLen)
					newIndex = textLen;

				if (FlxG.keys.pressed.SHIFT && hadFocus)
					_selectionAnchor = oldCaret;
				else
					_selectionAnchor = newIndex;

				setCaretIndexSilent(newIndex);
				hasFocus = true;
				_selecting = textLen > 0;
				scrollToCaret();

				if (!hadFocus && focusGained != null)
					focusGained();
			}
			else
			{
				hasFocus = false;
				_selecting = false;
				clearSelection();

				if (hadFocus && focusLost != null)
					focusLost();
			}
		}

		if (_selecting && FlxG.mouse.pressed)
		{
			var textLen = (text != null) ? text.length : 0;
			if (textLen > 0)
			{
				var newIndex = getCaretIndex();
				if (newIndex > textLen)
					newIndex = textLen;
				if (newIndex != caretIndex)
				{
					setCaretIndexSilent(newIndex);
					scrollToCaret();
				}
			}
		}

		if (_selecting && FlxG.mouse.justReleased)
			_selecting = false;
		#end
	}

	private function onKeyDown(e:KeyboardEvent):Void
	{
		final key:FlxKey = e.keyCode;
		var shiftPressed = e.shiftKey;
		var commandPressed = #if mac e.commandKey #else e.ctrlKey #end;

		// Don't process input if not focused or if component is hidden/inactive
		if (!hasFocus || !visible || !active)
			return;

		var textLen = (text != null) ? text.length : 0;

		switch (key)
		{
			case SHIFT | CONTROL | BACKSLASH | ESCAPE:
				return;

			case LEFT:
				var movedCaret:Bool = false;
				if (!shiftPressed && collapseSelection(true))
				{
					scrollToCaret();
					traceScrollState("LEFT", textLen);
					return;
				}
				if (caretIndex > 0)
				{
					var oldCaret = caretIndex;
					var newIndex = caretIndex - 1;

					if (shiftPressed && textLen > 0)
					{
						if (_selectionAnchor == oldCaret)
							_selectionAnchor = oldCaret;
					}
					else
					{
						_selectionAnchor = newIndex;
					}

					setCaretIndexSilent(newIndex);
					movedCaret = true;
					scrollToCaret();
				}
				if (!movedCaret)
				{
					// Already at start; don't scroll the view.
					traceScrollState("LEFT", textLen);
					return;
				}
				traceScrollState("LEFT", textLen);

			case RIGHT:
				var movedCaretR:Bool = false;
				if (!shiftPressed && collapseSelection(false))
				{
					scrollToCaret();
					traceScrollState("RIGHT", textLen);
					return;
				}
				if (caretIndex < textLen)
				{
					var oldCaret = caretIndex;
					var newIndex = caretIndex + 1;

					if (shiftPressed && textLen > 0)
					{
						if (_selectionAnchor == oldCaret)
							_selectionAnchor = oldCaret;
					}
					else
					{
						_selectionAnchor = newIndex;
					}

					setCaretIndexSilent(newIndex);
					movedCaretR = true;
					scrollToCaret();
				}
				if (!movedCaretR)
				{
					// Already at end; don't scroll the view.
					traceScrollState("RIGHT", textLen);
					return;
				}
				traceScrollState("RIGHT", textLen);

			case END:
				if (!shiftPressed)
				{
					_selectionAnchor = textLen;
				}
				else if (_selectionAnchor == caretIndex && textLen > 0)
				{
					_selectionAnchor = caretIndex;
				}
				setCaretIndexSilent(textLen);
				scrollToCaret();

			case HOME:
				if (!shiftPressed)
				{
					_selectionAnchor = 0;
				}
				else if (_selectionAnchor == caretIndex && textLen > 0)
				{
					_selectionAnchor = caretIndex;
				}
				setCaretIndexSilent(0);
				scrollToCaret();

			case BACKSPACE:
				if (deleteSelection())
				{
					onChange(BACKSPACE_ACTION);
					return;
				}
				if (caretIndex > 0)
				{
					caretIndex--;
					_selectionAnchor = caretIndex;
					text = text.substring(0, caretIndex) + text.substring(caretIndex + 1);
					onChange(BACKSPACE_ACTION);
				}

			case DELETE:
				if (deleteSelection())
				{
					onChange(DELETE_ACTION);
					return;
				}
				if (text.length > 0 && caretIndex < text.length)
				{
					_selectionAnchor = caretIndex;
					text = text.substring(0, caretIndex) + text.substring(caretIndex + 1);
					onChange(DELETE_ACTION);
				}

			case ENTER:
				onChange(ENTER_ACTION);

			case A if (commandPressed):
				selectAll();

			case X if (commandPressed):
				#if (js && html5)
				FlxG.stage.window.textInputEnabled = true;
				#end
				if (hasSelection())
				{
					Clipboard.text = getSelectedText();
					deleteSelection();
					onChange(DELETE_ACTION);
				}
				else
				{
					Clipboard.text = text;
					caretIndex = 0;
					text = '';
				}

			case C if (commandPressed):
				#if (js && html5)
				FlxG.stage.window.textInputEnabled = true;
				#end
				if (hasSelection())
					Clipboard.text = getSelectedText();
				else
					Clipboard.text = text;

			case V if (commandPressed):
				#if (js && html5)
				FlxG.stage.window.textInputEnabled = true;
				#end
				var clipboardText:String = Clipboard.text;
				if (clipboardText != null)
					pasteClipboardText(clipboardText);

			default:
				if (e.charCode == 0)
					return;

				final newText = filter(String.fromCharCode(e.charCode));

				if (newText.length > 0)
				{
					var selectionLength = hasSelection() ? (getSelectionEnd() - getSelectionBegin()) : 0;
					if (maxLength == 0 || (text.length - selectionLength + newText.length) <= maxLength)
					{
						if (hasSelection())
						{
							replaceSelection(newText);
						}
						else
						{
							text = insertSubstring(text, newText, caretIndex);
							caretIndex++;
							_selectionAnchor = caretIndex;
						}
						onChange(INPUT_ACTION);
					}
				}
		}
	}

	private function onChange(action:String):Void
	{
		if (callback != null)
			callback(text, action);
	}

	#if (html5 && js)
	function handleClipboardText(clipboardText:String)
	{
		@:privateAccess if (Clipboard._text == clipboardText)
			pasteClipboardText(clipboardText);
	}
	#end

	function pasteClipboardText(clipboardText:String)
	{
		var selectionLength = hasSelection() ? (getSelectionEnd() - getSelectionBegin()) : 0;
		var maxPaste = maxLength > 0 ? (maxLength - (text.length - selectionLength)) : clipboardText.length;
		if (maxPaste < 0)
			maxPaste = 0;

		final newText = filter(clipboardText).substring(0, maxPaste);

		if (newText.length == 0)
			return;

		if (hasSelection())
		{
			replaceSelection(newText);
		}
		else
		{
			text = insertSubstring(text, newText, caretIndex);
			caretIndex += newText.length;
			_selectionAnchor = caretIndex;
		}

		onChange(INPUT_ACTION);
	}

	private function insertSubstring(Original:String, Insert:String, Index:Int):String
	{
		if (Index != Original.length)
			Original = Original.substring(0, Index) + Insert + Original.substring(Index);
		else
			Original = Original + Insert;
		return Original;
	}

	private inline function hasSelection():Bool
	{
		if (text == null || text.length == 0)
			return false;
		return _selectionAnchor >= 0 && caretIndex >= 0 && _selectionAnchor != caretIndex;
	}

	private inline function getSelectionBegin():Int
	{
		var textLen = (text != null) ? text.length : 0;
		var begin = caretIndex < _selectionAnchor ? caretIndex : _selectionAnchor;
		if (begin < 0)
			return 0;
		if (begin > textLen)
			return textLen;
		return begin;
	}

	private inline function getSelectionEnd():Int
	{
		var textLen = (text != null) ? text.length : 0;
		var end = caretIndex > _selectionAnchor ? caretIndex : _selectionAnchor;
		if (end < 0)
			return 0;
		if (end > textLen)
			return textLen;
		return end;
	}

	private function getSelectedText():String
	{
		if (!hasSelection() || text == null || text.length == 0)
			return "";
		var start = getSelectionBegin();
		var end = getSelectionEnd();
		if (start >= text.length || end <= 0 || start >= end)
			return "";
		return text.substring(start, end);
	}

	private function clearSelection():Void
	{
		var textLen = (text != null) ? text.length : 0;
		if (caretIndex > textLen)
			caretIndex = textLen;
		if (caretIndex < 0)
			caretIndex = 0;
		_selectionAnchor = caretIndex;
		updateSelectionSprite();
	}

	private function selectAll():Void
	{
		if (text == null || text.length == 0)
		{
			_selectionAnchor = 0;
			caretIndex = 0;
			updateSelectionSprite();
			return;
		}
		_selectionAnchor = 0;
		caretIndex = text.length;
		updateSelectionSprite();
		text = text;
	}

	private function collapseSelection(toStart:Bool):Bool
	{
		if (!hasSelection())
			return false;

		var textLen = (text != null) ? text.length : 0;
		var target = toStart ? getSelectionBegin() : getSelectionEnd();
		if (target > textLen)
			target = textLen;
		if (target < 0)
			target = 0;

		_selectionAnchor = target;
		setCaretIndexSilent(target);
		return true;
	}

	private function deleteSelection():Bool
	{
		if (!hasSelection() || text == null || text.length == 0)
			return false;

		var start = getSelectionBegin();
		var end = getSelectionEnd();
		if (start >= end || start >= text.length)
			return false;

		text = text.substring(0, start) + text.substring(end);
		caretIndex = start;
		_selectionAnchor = caretIndex;
		updateSelectionSprite();
		return true;
	}

	private function replaceSelection(newText:String):Void
	{
		var start = getSelectionBegin();
		var end = getSelectionEnd();
		var currentText = (text != null) ? text : "";

		if (start > currentText.length)
			start = currentText.length;
		if (end > currentText.length)
			end = currentText.length;

		text = currentText.substring(0, start) + newText + currentText.substring(end);
		caretIndex = start + newText.length;
		_selectionAnchor = caretIndex;
		updateSelectionSprite();
	}

	private function getCaretIndex():Int
	{
		#if FLX_MOUSE
		var mousePos = FlxPoint.get();
		var cam = (_cameras != null && _cameras.length > 0) ? _cameras[0] : FlxG.camera;
		FlxG.mouse.getWorldPosition(cam, mousePos);
		var hit = FlxPoint.get(mousePos.x - x, mousePos.y - y);
		mousePos.put();
		var result = getCharIndexAtPoint(hit.x, hit.y);
		hit.put();
		return result;
		#else
		return 0;
		#end
	}

	private function getCharBoundaries(charIndex:Int):Rectangle
	{
		if (_charBoundaries == null || _charBoundaries.length == 0 || charIndex < 0)
			return null;

		if (text == null || text.length == 0)
			return null;

		if (charIndex >= _charBoundaries.length)
		{
			if (_charBoundaries.length == 0)
				return null;
			var r:Rectangle = new Rectangle();
			_charBoundaries[_charBoundaries.length - 1].copyToFlash(r);
			return r;
		}

		var r:Rectangle = new Rectangle();
		_charBoundaries[charIndex].copyToFlash(r);
		return r;
	}

	private function getClickableRightEdge():Float
	{
		if (text != null && text.length > 0 && _charBoundaries != null && _charBoundaries.length > 0)
		{
			var boundary:Rectangle = getCharBoundaries(text.length - 1);
			if (boundary != null)
				return x + boundary.right + 4;
		}
		return x + width;
	}

	private function getSelectionOffsetX():Float
	{
		var offx:Float = 0;
		var alignStr:FlxTextAlign = getAlignStr();

		switch (alignStr)
		{
			case RIGHT:
				offx = textField.width - 2 - textField.textWidth - 2;
				if (offx < 0)
					offx = 0;
			case CENTER:
				#if !js
				offx = (textField.width - 2 - textField.textWidth) / 2 + lastScroll / 2;
				#end
				if (offx <= 1)
					offx = 0;
			default:
				offx = 0;
		}
		return offx;
	}

	private inline function traceScrollState(action:String, textLen:Int):Void
	{
		var viewW = textField != null ? Std.int(textField.width - 4) : -1;
		var textW = textField != null ? Std.int(textField.textWidth) : -1;
		var caretScreenX = caret != null ? Std.int(caret.x - x) : -1;
		var caretTextX = caretScreenX >= 0 ? caretScreenX + lastScroll : -1;
		//trace('[ShadowInputText] ' + action + ' caretIndex=' + caretIndex + '/' + textLen + ' caretScreenX=' + caretScreenX
		//	+ ' caretTextX=' + caretTextX + ' scrollX=' + lastScroll + ' viewW=' + viewW + ' textW=' + textW);
	}

	private inline function setCaretIndexSilent(newIndex:Int):Void
	{
		var oldSuppress = _suppressCaretScroll;
		_suppressCaretScroll = true;
		caretIndex = newIndex;
		_suppressCaretScroll = oldSuppress;
	}

	private function updateSelectionSprite():Void
	{
		if (selectionSprite == null || textField == null)
			return;

		if (text == null || text.length == 0 || !hasSelection() || _charBoundaries == null || _charBoundaries.length == 0)
		{
			selectionSprite.visible = false;
			return;
		}

		var begin = getSelectionBegin();
		var end = getSelectionEnd();

		if (begin >= text.length)
			begin = text.length;
		if (end > text.length)
			end = text.length;

		if (begin == end || begin < 0 || end <= 0)
		{
			selectionSprite.visible = false;
			return;
		}

		var targetWidth = Std.int(width);
		var targetHeight = Std.int(height);
		if (targetWidth <= 0 || targetHeight <= 0)
		{
			selectionSprite.visible = false;
			return;
		}

		if (selectionSprite.pixels == null || selectionSprite.frameWidth != targetWidth || selectionSprite.frameHeight != targetHeight)
		{
			selectionSprite.makeGraphic(targetWidth, targetHeight, FlxColor.TRANSPARENT, true);
		}
		else
		{
			selectionSprite.pixels.fillRect(selectionSprite.pixels.rect, FlxColor.TRANSPARENT);
		}

		var startRect = getCharBoundaries(begin);
		var endRect = getCharBoundaries(end - 1);
		if (startRect == null || endRect == null)
		{
			selectionSprite.visible = false;
			return;
		}

		var offx = getSelectionOffsetX();
		var left = offx + startRect.left;
		var right = offx + endRect.right;

		#if !js
		left -= lastScroll;
		right -= lastScroll;
		#end

		if (right <= 0 || left >= width)
		{
			selectionSprite.visible = false;
			return;
		}

		left = Math.max(0, left);
		right = Math.min(width, right);
		var rectW = right - left;
		if (rectW <= 0)
		{
			selectionSprite.visible = false;
			return;
		}

		var top = startRect.top;
		var rectH = startRect.height;
		if (top < 0)
		{
			rectH += top;
			top = 0;
		}
		if (top + rectH > height)
			rectH = height - top;
		if (rectH <= 0)
		{
			selectionSprite.visible = false;
			return;
		}

		selectionSprite.pixels.fillRect(new Rectangle(left, top, rectW, rectH), selectionColor);
		selectionSprite.dirty = true;
		selectionSprite.visible = true;
	}

	private override function set_text(Text:String):String
	{
		#if !js
		if (textField != null)
			textField.scrollH = lastScroll;
		#end

		var return_text:String = super.set_text(Text);

		if (textField == null)
			return return_text;

		var numChars:Int = Text.length;
		prepareCharBoundaries(numChars);

		textField.text = "";
		var textH:Float = 0;
		var textW:Float = 0;
		var lastW:Float = 0;

		var magicX:Float = 2;
		var magicY:Float = 2;

		for (i in 0...numChars)
		{
			textField.appendText(Text.substr(i, 1));
			textW = textField.textWidth;
			if (i == 0)
				textH = textField.textHeight;

			_charBoundaries[i].x = magicX + lastW;
			_charBoundaries[i].y = magicY;
			_charBoundaries[i].width = (textW - lastW);
			_charBoundaries[i].height = textH;
			lastW = textW;
		}

		textField.text = Text;

		var textLen = Text.length;
		if (_selectionAnchor > textLen)
			_selectionAnchor = textLen;
		if (_selectionAnchor < 0)
			_selectionAnchor = 0;
		if (caretIndex > textLen)
			caretIndex = textLen;
		if (caretIndex < 0)
			caretIndex = 0;

		onSetTextCheck();
		updateSelectionSprite();
		return return_text;
	}

	private function getCharIndexAtPoint(X:Float, Y:Float):Int
	{
		if (text == null || text.length == 0)
			return 0;

		var i:Int = 0;

		#if !js
		X += lastScroll + 2;
		#end

		if (_charBoundaries != null && _charBoundaries.length > 0)
		{
			if (textField.textWidth <= textField.width)
			{
				switch (getAlignStr())
				{
					case RIGHT:
						X = X - textField.width + textField.textWidth;
					case CENTER:
						X = X - textField.width / 2 + textField.textWidth / 2;
					default:
				}
			}
		}

		if (_charBoundaries != null)
		{
			for (r in _charBoundaries)
			{
				if (X >= r.left && X <= r.right)
					return i;
				i++;
			}
		}

		if (_charBoundaries != null && _charBoundaries.length > 0)
		{
			if (X > textField.textWidth)
				return text.length;
		}

		return 0;
	}

	private function prepareCharBoundaries(numChars:Int):Void
	{
		if (_charBoundaries == null)
			_charBoundaries = [];

		if (_charBoundaries.length > numChars)
		{
			var diff:Int = _charBoundaries.length - numChars;
			for (i in 0...diff)
				_charBoundaries.pop();
		}

		for (i in 0...numChars)
		{
			if (_charBoundaries.length - 1 < i)
				_charBoundaries.push(FlxRect.get(0, 0, 0, 0));
		}
	}

	private function scrollToCaret():Void
	{
		#if !js
		if (textField == null)
			return;

		var textLen:Int = (text != null) ? text.length : 0;
		if (textLen == 0)
		{
			textField.scrollH = 0;
			lastScroll = 0;
			return;
		}

		var targetIndex = caretIndex;
		if (targetIndex < 0)
			targetIndex = 0;
		if (targetIndex > textLen)
			targetIndex = textLen;

		var boundary:Rectangle = null;

		// caret at very end uses last char boundary
		if (targetIndex == textLen && textLen > 0)
			boundary = getCharBoundaries(textLen - 1);
		else if (targetIndex >= 0 && targetIndex < textLen)
			boundary = getCharBoundaries(targetIndex);

		if (boundary == null)
			return;

		var visibleWidth:Float = textField.width - 4;
		var maxScroll:Int = Std.int(textField.textWidth - visibleWidth);
		if (maxScroll < 0)
			maxScroll = 0;

		var newScroll:Int = lastScroll;
		var rightEdge:Float = lastScroll + visibleWidth;

		if (boundary.right > rightEdge)
			newScroll = Std.int(boundary.right - visibleWidth);
		else if (boundary.left < lastScroll)
			newScroll = Std.int(boundary.left);

		if (newScroll < 0)
			newScroll = 0;
		if (newScroll > maxScroll)
			newScroll = maxScroll;

		if (newScroll != lastScroll)
		{
			textField.scrollH = newScroll;
			lastScroll = newScroll;

			redrawTextForScroll();

			var oldSuppress = _suppressCaretScroll;
			_suppressCaretScroll = true;
			set_caretIndex(caretIndex);
			_suppressCaretScroll = oldSuppress;

			updateSelectionSprite();
		}
		#end
	}

	private function scrollViewInDirection(direction:Int):Void
	{
		#if !js
		if (textField == null)
			return;

		var visibleWidth = textField.width - 4;
		var maxScroll = Std.int(textField.textWidth - visibleWidth);
		if (maxScroll < 0)
			maxScroll = 0;

		// Scroll amount is 10% of visible width or 15 pixels, whichever is larger
		var scrollAmount:Int = Std.int(Math.max(15, visibleWidth * 0.1));

		var newScroll:Int = lastScroll;
		if (direction < 0 && lastScroll > 0)
		{
			// Scroll left
			newScroll = lastScroll - scrollAmount;
			if (newScroll < 0)
				newScroll = 0;
		}
		else if (direction > 0 && lastScroll < maxScroll)
		{
			// Scroll right
			newScroll = lastScroll + scrollAmount;
			if (newScroll > maxScroll)
				newScroll = maxScroll;
		}

		if (newScroll != lastScroll)
		{
			textField.scrollH = newScroll;
			lastScroll = newScroll;
			redrawTextForScroll();
		}
		#end
	}

	private function onSetTextCheck():Void
	{
		#if !js
		var textLen = (text != null) ? text.length : 0;
		if (textLen == 0)
		{
			textField.scrollH = 0;
			lastScroll = 0;
			calcFrame();
			return;
		}

		var boundary:Rectangle = null;
		var targetIndex = caretIndex;
		if (targetIndex < 0)
			targetIndex = 0;
		if (targetIndex > textLen)
			targetIndex = textLen;

		if (targetIndex == textLen && textLen > 0)
			boundary = getCharBoundaries(textLen - 1);
		else if (targetIndex >= 0 && targetIndex < textLen)
			boundary = getCharBoundaries(targetIndex);

		if (boundary != null)
		{
			var visibleWidth = textField.width - 4;
			var maxScroll = Std.int(textField.textWidth - visibleWidth);
			if (maxScroll < 0)
				maxScroll = 0;

			var newScroll:Int = lastScroll;
			var rightEdge:Float = lastScroll + visibleWidth;

			if (boundary.right > rightEdge)
				newScroll = Std.int(boundary.right - visibleWidth);
			else if (boundary.left < lastScroll)
				newScroll = Std.int(boundary.left);

			if (newScroll < 0)
				newScroll = 0;
			if (newScroll > maxScroll)
				newScroll = maxScroll;

			if (newScroll != lastScroll)
			{
				textField.scrollH = newScroll;
				lastScroll = newScroll;
				redrawTextForScroll();
				_suppressCaretScroll = true;
				set_caretIndex(caretIndex);
				_suppressCaretScroll = false;
				updateSelectionSprite();
			}
		}
		#end
	}

	private inline function redrawTextForScroll():Void
	{
		_regen = true;
		calcFrame(true);
	}

	private override function calcFrame(RunOnCpp:Bool = false):Void
	{
		#if !js
		var savedWidth:Float = 0;
		var needsScrollRender:Bool = false;

		if (textField != null)
		{
			textField.autoSize = NONE;
			savedWidth = width;

			// If we need to scroll, temporarily expand textField to fit all text
			if (lastScroll > 0 && textField.textWidth > width)
			{
				textField.width = textField.textWidth + 10;
				needsScrollRender = true;
			}
			else
			{
				textField.width = width;
			}
			textField.scrollH = 0; // Reset scrollH, we'll handle it manually
		}
		#end

		super.calcFrame(RunOnCpp);

		#if !js
		if (textField != null && needsScrollRender && pixels != null)
		{
			// Re-render with scroll offset: draw the expanded text shifted left
			var scrolledPixels = new BitmapData(Std.int(width), Std.int(height), true, 0x00000000);
			var scrollMatrix = new Matrix();
			scrollMatrix.translate(-lastScroll, 0);
			scrolledPixels.draw(textField, scrollMatrix);

			// Replace pixels with scrolled version
			pixels.fillRect(pixels.rect, 0x00000000);
			pixels.draw(scrolledPixels);
			scrolledPixels.dispose();
			// Restore textField width after drawing (so draw sees expanded width)
			textField.width = savedWidth;
		}
		else if (textField != null)
		{
			textField.width = width;
		}
		#end

		if (fieldBorderSprite != null)
		{
			if (fieldBorderThickness > 0)
			{
				fieldBorderSprite.makeGraphic(Std.int(width + fieldBorderThickness * 2), Std.int(height + fieldBorderThickness * 2), fieldBorderColor);
				fieldBorderSprite.x = x - fieldBorderThickness;
				fieldBorderSprite.y = y - fieldBorderThickness;
				fieldBorderSprite.visible = true;
			}
			else
			{
				fieldBorderSprite.visible = false;
			}
		}

		if (backgroundSprite != null)
		{
			if (background)
			{
				backgroundSprite.makeGraphic(Std.int(width), Std.int(height), backgroundColor);
				backgroundSprite.x = x;
				backgroundSprite.y = y;
				backgroundSprite.visible = true;
			}
			else
			{
				backgroundSprite.visible = false;
			}
		}

		if (caret != null)
		{
			final caretHeight = Std.int(size + 2);
			var cw:Int = caretWidth;
			var ch:Int = caretHeight;

			var borderC:Int = (0xff000000 | (borderColor & 0x00ffffff));
			var caretC:Int = (0xff000000 | (caretColor & 0x00ffffff));

			var caretKey:String = "caret" + cw + "x" + ch + "c:" + caretC + "b:" + borderStyle + "," + borderSize + "," + borderC;

			switch (borderStyle)
			{
				case NONE:
					caret.makeGraphic(cw, ch, caretC, false, caretKey);
					caret.offset.x = caret.offset.y = 0;

				case SHADOW:
					final absSize = Math.abs(borderSize);
					cw += Std.int(absSize);
					ch += Std.int(absSize);
					caret.makeGraphic(cw, ch, FlxColor.TRANSPARENT, false, caretKey);
					final r:Rectangle = new Rectangle(absSize, absSize, caretWidth, caretHeight);
					caret.pixels.fillRect(r, borderC);
					r.x = r.y = 0;
					caret.pixels.fillRect(r, caretC);
					caret.offset.x = caret.offset.y = 0;

				#if (flixel > "5.8.0")
				case SHADOW_XY(shadowX, shadowY):
					cw += Std.int(Math.abs(shadowX));
					ch += Std.int(Math.abs(shadowY));
					caret.makeGraphic(cw, ch, FlxColor.TRANSPARENT, false, caretKey);
					final r:Rectangle = new Rectangle(Math.max(0, shadowX), Math.max(0, shadowY), caretWidth, caretHeight);
					caret.pixels.fillRect(r, borderC);
					r.x -= shadowX;
					r.y -= shadowY;
					caret.pixels.fillRect(r, caretC);
					caret.offset.x = shadowX < 0 ? -shadowX : 0;
					caret.offset.y = shadowY < 0 ? -shadowY : 0;
				#end

				case OUTLINE_FAST, OUTLINE:
					final absSize = Math.abs(borderSize);
					cw += Std.int(absSize * 2);
					ch += Std.int(absSize * 2);
					caret.makeGraphic(cw, ch, borderC, false, caretKey);
					final r = new Rectangle(absSize, absSize, caretWidth, caretHeight);
					caret.pixels.fillRect(r, caretC);
					caret.offset.x = caret.offset.y = absSize;
			}

			caret.width = cw;
			caret.height = ch;

			_suppressCaretScroll = true;
			caretIndex = caretIndex;
			_suppressCaretScroll = false;
		}

		updateSelectionSprite();
	}

	private function toggleCaret(timer:FlxTimer):Void
	{
		if (hasFocus)
			caret.visible = !caret.visible;
		else
			caret.visible = false;
	}

	private function filter(text:String):String
	{
		if (forceCase == UPPER_CASE)
			text = text.toUpperCase();
		else if (forceCase == LOWER_CASE)
			text = text.toLowerCase();

		if (filterMode != NO_FILTER)
		{
			var pattern:EReg;
			switch (filterMode)
			{
				case ONLY_ALPHA:
					pattern = ~/[^a-zA-Z]*/g;
				case ONLY_NUMERIC:
					pattern = ~/[^0-9]*/g;
				case ONLY_ALPHANUMERIC:
					pattern = ~/[^a-zA-Z0-9]*/g;
				case CUSTOM_FILTER:
					pattern = customFilterPattern;
					if (pattern == null)
						return text;
				default:
					throw new Error("ShadowInputText: Unknown filterMode (" + filterMode + ")");
			}
			text = pattern.replace(text, "");
		}
		return text;
	}

	private function set_params(p:Array<Dynamic>):Array<Dynamic>
	{
		params = p;
		if (params == null)
			params = [];
		var namedValue:NamedString = {name: "value", value: text};
		params.push(namedValue);
		return params;
	}

	private override function set_x(X:Float):Float
	{
		if ((fieldBorderSprite != null) && fieldBorderThickness > 0)
			fieldBorderSprite.x = X - fieldBorderThickness;

		if ((backgroundSprite != null) && background)
			backgroundSprite.x = X;

		if (selectionSprite != null)
			selectionSprite.x = X;

		return super.set_x(X);
	}

	private override function set_y(Y:Float):Float
	{
		if ((fieldBorderSprite != null) && fieldBorderThickness > 0)
			fieldBorderSprite.y = Y - fieldBorderThickness;

		if ((backgroundSprite != null) && background)
			backgroundSprite.y = Y;

		if (selectionSprite != null)
			selectionSprite.y = Y;

		return super.set_y(Y);
	}

	private function set_hasFocus(newFocus:Bool):Bool
	{
		if (newFocus)
		{
			if (hasFocus != newFocus)
			{
				if (_caretTimer == null)
					_caretTimer = new FlxTimer();
				else
					_caretTimer.cancel();

				_caretTimer.start(0.5, toggleCaret, 0);
				caret.visible = true;

				var textLen = (text != null) ? text.length : 0;
				var moveCaretToEnd = true;

				#if FLX_MOUSE
				var cam = (_cameras != null && _cameras.length > 0) ? _cameras[0] : FlxG.camera;
				if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(this, cam))
					moveCaretToEnd = false;
				#end

				if (moveCaretToEnd)
				{
					caretIndex = textLen;
					_selectionAnchor = caretIndex;
					updateSelectionSprite();
				}

				#if mobile
				FlxG.stage.window.textInputEnabled = true;
				#end
			}
		}
		else
		{
			caret.visible = false;

			if (_caretTimer != null)
				_caretTimer.cancel();

			_selecting = false;
			clearSelection();

			#if mobile
			FlxG.stage.window.textInputEnabled = false;
			#end
		}

		if (newFocus != hasFocus)
		{
			hasFocus = newFocus;
			calcFrame();

			#if (js && html5)
			var window = FlxG.stage.window;
			@:privateAccess window.__backend.setTextInputEnabled(newFocus);
			#end
		}

		return hasFocus;
	}

	private function getAlignStr():FlxTextAlign
	{
		var alignStr:FlxTextAlign = LEFT;
		if (_defaultFormat != null && _defaultFormat.align != null)
			alignStr = alignment;
		return alignStr;
	}

	private function set_caretIndex(newCaretIndex:Int):Int
	{
		var offx:Float = 0;
		var alignStr:FlxTextAlign = getAlignStr();

		switch (alignStr)
		{
			case RIGHT:
				offx = textField.width - 2 - textField.textWidth - 2;
				if (offx < 0)
					offx = 0;

			case CENTER:
				#if !js
				offx = (textField.width - 2 - textField.textWidth) / 2 + lastScroll / 2;
				#end
				if (offx <= 1)
					offx = 0;

			default:
				offx = 0;
		}

		var textLen = (text != null) ? text.length : 0;

		if (newCaretIndex < 0)
			newCaretIndex = 0;
		if (newCaretIndex > textLen)
			newCaretIndex = textLen;

		caretIndex = newCaretIndex;

		if (textLen == 0)
		{
			caret.x = x + offx + 2;
			caret.y = y + 2;
			updateSelectionSprite();
			return caretIndex;
		}

		var boundaries:Rectangle = null;

		if (caretIndex < textLen)
		{
			boundaries = getCharBoundaries(caretIndex);
			if (boundaries != null)
			{
				caret.x = offx + boundaries.left + x;
				caret.y = boundaries.top + y;
			}
			else
			{
				caret.x = x + offx + 2;
				caret.y = y + 2;
			}
		}
		else
		{
			boundaries = getCharBoundaries(caretIndex - 1);
			if (boundaries != null)
			{
				caret.x = offx + boundaries.right + x;
				caret.y = boundaries.top + y;
			}
			else
			{
				caret.x = x + offx + 2;
				caret.y = y + 2;
			}
		}

		#if !js
		caret.x -= lastScroll;
		#end

		if ((lines == 1) && (caret.x + caret.width) > (x + width))
			caret.x = x + width - caret.width - 2;

		if (!_suppressCaretScroll)
			scrollToCaret();

		updateSelectionSprite();
		return caretIndex;
	}

	private function set_forceCase(Value:Int):Int
	{
		forceCase = Value;
		text = filter(text);
		return forceCase;
	}

	override private function set_size(Value:Int):Int
	{
		super.size = Value;
		dirty = true;
		calcFrame(true);
		return Value;
	}

	private function set_maxLength(Value:Int):Int
	{
		maxLength = Value;
		if (maxLength <= 0)
			return maxLength = 0;

		if (text.length > maxLength)
			text = text.substring(0, maxLength);

		return maxLength;
	}

	private function set_lines(Value:Int):Int
	{
		if (Value == 0)
			return 0;

		if (Value > 1)
		{
			textField.wordWrap = true;
			textField.multiline = true;
		}
		else
		{
			textField.wordWrap = false;
			textField.multiline = false;
		}

		lines = Value;
		calcFrame();
		return lines;
	}

	private function get_passwordMode():Bool
	{
		return textField.displayAsPassword;
	}

	private function set_passwordMode(value:Bool):Bool
	{
		textField.displayAsPassword = value;
		calcFrame();
		return value;
	}

	private function set_filterMode(Value:Int):Int
	{
		filterMode = Value;
		text = filter(text);
		return filterMode;
	}

	private function set_fieldBorderColor(Value:Int):Int
	{
		fieldBorderColor = Value;
		calcFrame();
		return fieldBorderColor;
	}

	private function set_fieldBorderThickness(Value:Int):Int
	{
		fieldBorderThickness = Value;
		calcFrame();
		return fieldBorderThickness;
	}

	private function set_backgroundColor(Value:Int):Int
	{
		backgroundColor = Value;
		calcFrame();
		return backgroundColor;
	}

	private function set_selectionColor(value:FlxColor):FlxColor
	{
		selectionColor = value;
		updateSelectionSprite();
		return selectionColor;
	}
}
