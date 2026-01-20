package lime.media;

import lime.system.CFFIPointer;
import lime._internal.utils.MainLoop;
#if (windows || mac || linux || android || ios)
import haxe.io.Path;
import lime.system.System;
import sys.FileSystem;
import sys.io.File;
#end
import haxe.Timer;
import lime._internal.backend.native.NativeCFFI;
import lime.media.openal.AL;
import lime.media.openal.ALC;
import lime.media.openal.ALContext;
import lime.media.openal.ALDevice;
import lime.app.Application;
#if (js && html5)
import js.Browser;
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
@:access(lime.media.openal.ALDevice)
class AudioManager
{
	public static var context:AudioContext;

	public static function init(context:AudioContext = null)
	{
		if (AudioManager.context == null)
		{
			if (context == null)
			{
				AudioManager.context = new AudioContext();

				context = AudioManager.context;

				#if !lime_doc_gen
				if (context.type == OPENAL)
				{
					#if (windows || mac || linux || android || ios)
					setupConfig();
					#end

					var alc = context.openal;
					var device = alc.openDevice();
					var ctx = alc.createContext(device);

					alc.makeContextCurrent(ctx);
					alc.processContext(ctx);

					#if !(neko || mobile)
					if (alc.isExtensionPresent('ALC_SOFT_system_events', device) && alc.isExtensionPresent('ALC_SOFT_reopen_device', device))
					{
						alc.disable(AL.STOP_SOURCES_ON_DISCONNECT_SOFT);

						alc.eventControlSOFT([ALC.EVENT_TYPE_DEFAULT_DEVICE_CHANGED_SOFT, ALC.EVENT_TYPE_DEVICE_ADDED_SOFT, ALC.EVENT_TYPE_DEVICE_REMOVED_SOFT], true);

						alc.eventCallbackSOFT(deviceEventCallback);
					}
					#end
				}
				#end
			}

			AudioManager.context = context;

			#if (lime_cffi && !macro && lime_openal && (ios || tvos || mac))
			var timer = new Timer(100);
			timer.run = function()
			{
				NativeCFFI.lime_al_cleanup();
			};
			#end
		}
	}

	public static function resume():Void
	{
		#if !lime_doc_gen
		if (context != null && context.type == OPENAL)
		{
			var alc = context.openal;
			var currentContext = alc.getCurrentContext();

			if (currentContext != null)
			{
				var device = alc.getContextsDevice(currentContext);
				alc.resumeDevice(device);
				alc.processContext(currentContext);
			}
		}
		#end
	}

	public static function shutdown():Void
	{
		#if !lime_doc_gen
		if (context != null && context.type == OPENAL)
		{
			var alc = context.openal;
			var currentContext = alc.getCurrentContext();
			var device = alc.getContextsDevice(currentContext);

			if (currentContext != null)
			{
				alc.makeContextCurrent(null);
				alc.destroyContext(currentContext);

				if (device != null)
				{
					alc.closeDevice(device);
				}
			}
		}
		#end

		context = null;
	}

	public static function suspend():Void
	{
		#if !lime_doc_gen
		if (context != null && context.type == OPENAL)
		{
			var alc = context.openal;
			var currentContext = alc.getCurrentContext();
			var device = alc.getContextsDevice(currentContext);

			if (currentContext != null)
			{
				alc.suspendContext(currentContext);

				if (device != null)
				{
					alc.pauseDevice(device);
				}
			}
		}
		#end
	}

	@:noCompletion
	#if hl
	private static function deviceEventCallback(eventType:Int, deviceType:Int, handle:CFFIPointer, message:hl.Bytes):Void
	#else
	private static function deviceEventCallback(eventType:Int, deviceType:Int, handle:CFFIPointer, message:String):Void
	#end
	{
		#if !lime_doc_gen
		if (eventType == ALC.EVENT_TYPE_DEFAULT_DEVICE_CHANGED_SOFT && deviceType == ALC.PLAYBACK_DEVICE_SOFT)
		{
			var device = new ALDevice(handle);

			MainLoop.runInMainThread(function():Void
			{
				var alc = context.openal;

				if (device == null)
				{
					var currentContext = alc.getCurrentContext();

					var device = alc.getContextsDevice(currentContext);

					if (device != null)
						alc.reopenDeviceSOFT(device, null, null);
				}
				else
				{
					alc.reopenDeviceSOFT(device, null, null);
				}

			});
		}
		#end
	}

	@:noCompletion
	private static function setupConfig():Void
	{
		#if (windows || mac || linux || android || ios)
		final alConfig:Array<String> = [];

		alConfig.push('[General]');
		alConfig.push('sample-type=float32');
		alConfig.push('stereo-mode=speakers');
		alConfig.push('hrtf=false');
		alConfig.push('cf_level=0');
		alConfig.push('output-limiter=false');
		alConfig.push('front-stablizer=false');
		alConfig.push('volume-adjust=0');
		alConfig.push('period_size=441');
		alConfig.push('sources=512');
		alConfig.push('sends=64');
		alConfig.push('dither=false');

		alConfig.push('[decoder]');
		alConfig.push('hq-mode=true');
		alConfig.push('distance-comp=true');
		alConfig.push('nfc=false');

		try
		{
			final directory:String = Path.directory(Path.withoutExtension(System.applicationStorageDirectory));
			final path:String = Path.join([directory, #if windows 'alsoft.ini' #else 'alsoft.conf' #end]);
			final content:String = alConfig.join('\n');

			if (!FileSystem.exists(directory)) FileSystem.createDirectory(directory);

			if (!FileSystem.exists(path)) File.saveContent(path, content);

			Sys.putEnv('ALSOFT_CONF', path);
		}
		catch (e:Dynamic) {}
		#end
	}
}