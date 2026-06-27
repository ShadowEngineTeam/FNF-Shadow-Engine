package effects;

import flixel.util.FlxTimer;
import flixel.FlxCamera;
import openfl.filters.BitmapFilter;
import openfl.filters.ColorMatrixFilter;

class RetroCameraFade
{
	// im lazy, but we only use this for week 6
	// and also sorta yoinked for djflixel, lol !

	static function applyFade(camera:FlxCamera, ?fade:ColorMatrixFilter):Void
	{
		var arr:Array<BitmapFilter> = [];
		if (camera.filters != null)
			for (f in camera.filters)
				if (!Std.isOfType(f, ColorMatrixFilter)) // keep everything except a previous fade matrix
					arr.push(f);
		if (fade != null)
			arr.push(fade);
		camera.filters = arr;
	}

	static inline function whiteMatrix(V:Float):ColorMatrixFilter
	{
		return new ColorMatrixFilter([
			1, 0, 0, 0, V * 255,
			0, 1, 0, 0, V * 255,
			0, 0, 1, 0, V * 255,
			0, 0, 0, 1,       0
		]);
	}

	static inline function blackMatrix(V:Float):ColorMatrixFilter
	{
		return new ColorMatrixFilter([
			1, 0, 0, 0, -V * 255,
			0, 1, 0, 0, -V * 255,
			0, 0, 1, 0, -V * 255,
			0, 0, 0, 1,        0
		]);
	}

	public static function fadeWhite(camera:FlxCamera, camSteps:Int = 5, time:Float = 1):Void
	{
		var steps:Int = 0;
		var stepsTotal:Int = camSteps;

		new FlxTimer().start(time / (stepsTotal + 1), (_) ->
		{
			var V:Float = (1 / stepsTotal) * steps;
			if (steps == stepsTotal)
				V = 1;

			applyFade(camera, V <= 0 ? null : whiteMatrix(V));
			steps++;
		}, stepsTotal + 1);
	}

	public static function fadeFromWhite(camera:FlxCamera, camSteps:Int = 5, time:Float = 1):Void
	{
		var steps:Int = camSteps;
		var stepsTotal:Int = camSteps;

		applyFade(camera, whiteMatrix(1.0));

		new FlxTimer().start(time / stepsTotal, (_) ->
		{
			var V:Float = (1 / stepsTotal) * steps;
			if (steps == stepsTotal)
				V = 1;

			applyFade(camera, V <= 0 ? null : whiteMatrix(V));
			steps--;
		}, camSteps);
	}

	public static function fadeToBlack(camera:FlxCamera, camSteps:Int = 5, time:Float = 1):Void
	{
		var steps:Int = 0;
		var stepsTotal:Int = camSteps;

		new FlxTimer().start(time / (stepsTotal + 1), (_) ->
		{
			var V:Float = (1 / stepsTotal) * steps;
			if (steps == stepsTotal)
				V = 1;

			applyFade(camera, V <= 0 ? null : blackMatrix(V));
			steps++;
		}, stepsTotal + 1);
	}

	public static function fadeBlack(camera:FlxCamera, camSteps:Int = 5, time:Float = 1):Void
	{
		var steps:Int = camSteps;
		var stepsTotal:Int = camSteps;

		applyFade(camera, blackMatrix(1.0));

		new FlxTimer().start(time / (stepsTotal + 1), (_) ->
		{
			var V:Float = (1 / stepsTotal) * steps;
			if (steps == stepsTotal)
				V = 1;

			applyFade(camera, V <= 0 ? null : blackMatrix(V));
			steps--;
		}, camSteps + 1);
	}
}
