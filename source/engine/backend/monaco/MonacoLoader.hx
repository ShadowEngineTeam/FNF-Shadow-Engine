package backend.monaco;

#if FEATURE_WEBVIEW
import sys.thread.Thread;
import lime.app.Application;
import webview.WebView;
import haxe.atomic.AtomicBool;

@:nullSafety
class MonacoLoader
{
	public static var webview:Null<WebView> = null;

	public static function load():Void
	{
		MonacoServer.startServer('monaco');

		Thread.createWithEventLoop(() -> {
			webview	= new WebView(#if debug true #else false #end, Application.current.window.nativeHandle);
			webview.setTitle('Monaco Editor');
			webview.setSize(FlxG.width, FlxG.height, NONE);
			webview.navigate(MonacoServer.resolveAsset('index.html'));
			Application.current.onExit.add((_) -> {
				close();
			});
			webview.run();
			webview.destroy();
			webview = null;
			MonacoServer.closeServer();
		});
	}

	public static function close():Void
	{
		if (webview != null)
			webview.terminate();
	}
}
#end