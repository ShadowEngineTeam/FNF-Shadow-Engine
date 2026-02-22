package backend.monaco;

import haxe.Exception;
import cpp.vm.Gc;
import haxe.io.Bytes;
#if FEATURE_WEBVIEW
import sys.net.Socket;
import sys.net.Host;
import sys.thread.Thread;
import haxe.io.Path;
import haxe.io.Mime;
import haxe.atomic.AtomicBool;

using StringTools;

@:nullSafety
class MonacoServer
{
	public static var DEFAULT_IP:String = '127.0.0.1';
	public static var DEFAULT_PORT:Int = 8080;
	public static var server:Null<Socket>;
	public static var running(default, null):AtomicBool = new AtomicBool(false);

	public static function startServer(root:String):Void
	{
		server = new Socket();
		// server.setBlocking(false);
		server.bind(new Host(DEFAULT_IP), DEFAULT_PORT);
		server.listen(5);

		running.store(true);
		Thread.create(() ->
		{
			while (running.load())
			{
				try
				{
					var client = server.accept();
					update(client, root);
					Sys.sleep(0.01);
				}
				catch (e:Exception)
				{
					trace('Failed to update the server: ${e.stack}');
				}
			}
		});

		trace('Monaco server running at http://$DEFAULT_IP:$DEFAULT_PORT');
	}

	public static function resolveAsset(path:String):String
	{
		return 'http://$DEFAULT_IP:$DEFAULT_PORT/$path';
	}

	public static function update(client:Socket, root:String):Void
	{
		try
		{
			var requestLine:String = client.input.readLine();

			while (true)
			{
				var line:String = client.input.readLine();
				if (line == null || line.length <= 0)
					break;
			}

			var path:String = requestLine.split(" ")[1];
			if (!path.startsWith('/')) path = '/' + path;
			var absolutePath:String = root + path;

			if (!FileSystem.exists(absolutePath))
			{
				sendError(client);
				return;
			}

			var data:Null<Bytes> = File.getBytes(absolutePath);
			var contentType:String = getMime(absolutePath);
			
			if (data == null)
			{
				sendError(client);
				return;
			}

			var header = "HTTP/1.1 200 OK\r\n" + "Content-Type: " + contentType + "\r\n" + "Content-Length: " + data.length + "\r\n"
				+ "Connection: close\r\n\r\n";

			client.output.writeString(header);
			client.output.write(data);

			client.output.flush();
		}
		catch (e:Exception)
		{
			trace('Update Error: ${e.stack}');
		}

		client.close();
	}

	public static function closeServer():Void
	{
		if (running.load())
		{
			running.store(false);
			if (server != null)
			{
				server.close();
				server = null;
			}
		}
	}

	private static function sendError(client:Socket):Void
	{
		var response = "HTTP/1.1 404 Not Found\r\n\r\n404";
		client.output.writeString(response);
	}

	private static function getMime(path:String):String
	{
		return switch (Path.extension(path))
		{
			case "html": Mime.TextHtml;
			case "js": Mime.ApplicationJavascript;
			case "css": Mime.TextCss;
			case "json": Mime.ApplicationJson;
			case "ttf": "font/ttf";
			case "woff": "font/woff";
			case "woff2": "font/woff2";
			default: Mime.ApplicationOctetStream;
		}
	}
}
#end