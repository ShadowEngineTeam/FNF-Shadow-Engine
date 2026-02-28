package flixel.input.touch;

#if FLX_TOUCH
import openfl.geom.Point;
import flixel.FlxG;
import flixel.input.FlxInput;
import flixel.input.FlxSwipe;
import flixel.input.IFlxInput;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;

/**
 * Helper class, contains and tracks touch points in your game.
 * Automatically accounts for parallax scrolling, etc.
 */
@:allow(flixel.input.touch.FlxTouchManager)
class FlxTouch extends FlxPointer implements IFlxDestroyable implements IFlxInput
{
	/**
	 * The _unique_ ID of this touch. You should not make not any further assumptions
	 * about this value - IDs are not guaranteed to start from 0 or ascend in order.
	 * The behavior may vary from device to device.
	 */
	public var touchPointID(get, never):Int;

	/**
	 * A value between 0.0 and 1.0 indicating force of the contact with the device. If the device does not support detecting the pressure, the value is 1.0.
	 */
	public var pressure(default, null):Float;

	/**
	 * Check to see if this touch has just been moved upwards.
	 */
	public var justMovedUp(get, never):Bool;

	/**
	 * Check to see if this touch has just been moved downwards.
	 */
	public var justMovedDown(get, never):Bool;

	/**
	 * Check to see if this touch has just been moved leftwards.
	 */
	public var justMovedLeft(get, never):Bool;

	/**
	 * Check to see if this touch has just been moved rightwards.
	 */
	public var justMovedRight(get, never):Bool;

	/**
	 * Check to see if this touch has just been moved.
	 */
	public var justMoved(get, never):Bool;

	/**
	 * Check to see if this touch is currently pressed.
	 */
	public var pressed(get, never):Bool;

	/**
	 * Check to see if this touch has just been pressed.
	 */
	public var justPressed(get, never):Bool;

	/**
	 * Check to see if this touch is currently not pressed.
	 */
	public var released(get, never):Bool;

	/**
	 * Check to see if this touch has just been released.
	 */
	public var justReleased(get, never):Bool;

	/**
	 * Time in ticks of last press.
	 */
	public var justPressedTimeInTicks(default, null):Float = -1;

	/**
	 * Distance in pixels this touch has moved since the last frame in the X direction.
	 */
	public var deltaX(get, default):Float;

	/**
	 * Distance in pixels this touch has moved since the last frame in the Y direction.
	 */
	public var deltaY(get, default):Float;

	/**
	 * Distance in pixels this touch has moved in view space since the last frame in the X direction.
	 */
	public var deltaViewX(get, default):Float;

	/**
	 * Distance in pixels this touch has moved in view space since the last frame in the Y direction.
	 */
	public var deltaViewY(get, default):Float;

	/**
	 * The position of the touch when it was just pressed in FlxPoint.
	 */
	public var justPressedPosition(default, null) = FlxPoint.get();

	/**
	 * Time in ticks that had passed since of last press
	 */
	public var ticksDeltaSincePress(get, default):Float;

	/**
	 * The speed of this touch, always updates.
	 */
	public var velocity(default, null):FlxPoint = FlxPoint.get();

	/**
	 * Helper variables
	 */
	var input:FlxInput<Int>;

	var flashPoint = new Point();

	var _prevX:Float = 0;
	var _prevY:Float = 0;

	var _prevViewX:Float = 0;
	var _prevViewY:Float = 0;

	var _startX:Float = 0;
	var _startY:Float = 0;

	var _swipeDeltaX(get, never):Float;
	var _swipeDeltaY(get, never):Float;

	public function destroy():Void
	{
		input = null;
		justPressedPosition = FlxDestroyUtil.put(justPressedPosition);
		velocity = FlxDestroyUtil.put(velocity);
		flashPoint = null;
	}

	/**
	 * Resets the justPressed/justReleased flags, sets touch to not pressed and sets touch pressure to 0.
	 */
	public function recycle(x:Int, y:Int, pointID:Int, pressure:Float):Void
	{
		setXY(x, y, true);
		input.ID = pointID;
		input.reset();
		this.pressure = pressure;
	}

	/**
	 * @param	X			stageX touch coordinate
	 * @param	Y			stageX touch coordinate
	 * @param	PointID		touchPointID of the touch
	 * @param	pressure	A value between 0.0 and 1.0 indicating force of the contact with the device. If the device does not support detecting the pressure, the value is 1.0.
	 */
	function new(x:Int = 0, y:Int = 0, pointID:Int = 0, pressure:Float = 0)
	{
		super();

		input = new FlxInput(pointID);
		setXY(x, y, true);
		this.pressure = pressure;
	}

	/**
	 * Called by the internal game loop to update the just pressed/just released flags.
	 */
	function update():Void
	{
		input.update();

		if (justPressed)
		{
			justPressedPosition.set(viewX, viewY);
			justPressedTimeInTicks = FlxG.game.ticks;
			_startX = viewX;
			_startY = viewY;
		}
		#if FLX_POINTER_INPUT
		if (justReleased)
		{
			FlxG.touches.flickManager.initFlick(touchPointID, velocity);
			FlxG.swipes.push(new FlxSwipe(touchPointID, justPressedPosition.copyTo(), getViewPosition(), justPressedTimeInTicks));
		}
		if (pressed)
		{
			FlxG.touches.flickManager.destroy();
		}
		#end

	}

	/**
	 * Function for updating touch coordinates. Called by the TouchManager.
	 *
	 * @param	X	stageX touch coordinate
	 * @param	Y	stageY touch coordinate
	 * @param updatePrev Wether the previous touch position values should be updated with the current touch postion or new one
	 */
	function setXY(X:Int, Y:Int, updatePrev:Bool = false):Void
	{
		calculateVelocity();

		if (!updatePrev)
		{
			_prevX = x;
			_prevY = y;
			_prevViewX = viewX;
			_prevViewY = viewY;
		}

		flashPoint.setTo(X, Y);
		flashPoint = FlxG.game.globalToLocal(flashPoint);

		setRawPositionUnsafe(flashPoint.x, flashPoint.y);

		if (updatePrev)
		{
			_prevX = x;
			_prevY = y;
			_prevViewX = viewX;
			_prevViewY = viewY;
		}
	}

	/**
	 * Calculates this touch's velocity.
	 */
	function calculateVelocity():Void
	{
		if (!pressed)
			return;


		velocity.x = deltaViewX;
		velocity.y = deltaViewY;
	}

	@:noCompletion
	inline function get_touchPointID():Int
		return input.ID;

	@:noCompletion
	inline function get_justReleased():Bool
		return input.justReleased;

	@:noCompletion
	inline function get_released():Bool
		return input.released;

	@:noCompletion
	inline function get_pressed():Bool
		return input.pressed;

	@:noCompletion
	inline function get_justPressed():Bool
		return input.justPressed;

	@:noCompletion
	inline function get_justMoved():Bool
		return x != _prevX || y != _prevY;

	@:noCompletion
	inline function get_justMovedUp():Bool
	{
		var swiped:Bool = _swipeDeltaY > FlxG.touches.swipeThreshold.y;
		if (swiped)
			_startY = viewY;
		return swiped;
	}

	@:noCompletion
	inline function get_justMovedDown():Bool
	{
		var swiped:Bool = _swipeDeltaY < -FlxG.touches.swipeThreshold.y;
		if (swiped)
			_startY = viewY;
		return swiped;
	}

	@:noCompletion
	inline function get_justMovedLeft():Bool
	{
		var swiped:Bool = _swipeDeltaX > FlxG.touches.swipeThreshold.x;
		if (swiped)
			_startX = viewX;
		return swiped;
	}

	@:noCompletion
	inline function get_justMovedRight():Bool
	{
		var swiped:Bool = _swipeDeltaX < -FlxG.touches.swipeThreshold.x;
		if (swiped)
			_startX = viewX;
		return swiped;
	}

	@:noCompletion
	inline function get_deltaX():Float
		return x - _prevX;

	@:noCompletion
	inline function get_deltaY():Float
		return y - _prevY;

	@:noCompletion
	inline function get_deltaViewX():Float
		return viewX - _prevViewX;

	@:noCompletion
	inline function get_deltaViewY():Float
		return viewY - _prevViewY;

	@:noCompletion
	inline function get__swipeDeltaX():Float
		return viewX - _startX;

	@:noCompletion
	inline function get__swipeDeltaY():Float
		return viewY - _startY;

	@:noCompletion
	inline function get_ticksDeltaSincePress():Float
		return FlxG.game.ticks - justPressedTimeInTicks;
}
#else
class FlxTouch {}
#end