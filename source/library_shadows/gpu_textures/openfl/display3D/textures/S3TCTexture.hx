package openfl.display3D.textures;

#if !flash
import haxe.io.Bytes;
import openfl.utils._internal.UInt8Array;
import openfl.display.BlendMode;
import openfl.utils.ByteArray;
import openfl.Lib;

/**
	The S3TCTexture class represents a 2-dimensional compressed S3TC/DXTn texture uploaded to a rendering context.

	Defines a 2D texture for use during rendering.

	S3TCTexture cannot be instantiated directly. Create instances by using Context3D
	`createS3TCTexture()` method.
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(openfl.display3D.Context3D)
@:final class S3TCTexture extends TextureBase
{
	@:noCompletion private static var __lowMemoryMode:Bool = false;
	@:noCompletion private static var __warned:Bool = false;
	public static inline final IMAGE_DATA_OFFSET = 128;

	public var supported:Bool = true;
	public var usingANGLEExtension:Bool = false;
	public var imageSize(default, null):Int = 0;

	@:noCompletion private function new(context:Context3D, data:ByteArray)
	{
		super(context);
		var gl = __context.gl;
		var dxtExtension = gl.getExtension("EXT_texture_compression_s3tc");

		if (dxtExtension == null)
		{
			// fallback to ANGLE extension
			dxtExtension = gl.getExtension("ANGLE_texture_compression_dxt5");
			usingANGLEExtension = true;
		}

		if (dxtExtension == null)
		{
			if (!__warned)
			{
				Lib.current.stage.window.alert("S3TC compression is not available on this device.", "Rendering Error!");
				__warned = true;
			}

			usingANGLEExtension = supported = false;
		}

		if (supported)
		{
			__getImageSize(data);
			__getImageDimensions(data);
			var textureFromat = __getTextureFormat(data);

			var formatName = 'COMPRESSED_RGBA_S3TC_${textureFromat}_${usingANGLEExtension ? "ANGLE" : "EXT"}';
			if (!Reflect.fields(dxtExtension).contains(formatName))
			{
				trace('[ERROR] format: $formatName is invalid!');
			}

			__format = Reflect.getProperty(dxtExtension, formatName);
			__internalFormat = __format;
			__optimizeForRenderToTexture = false;
			__streamingLevels = 0;

			__uploadS3TCTextureFromByteArray(data);
		}
	}

	@:noCompletion public function __uploadS3TCTextureFromByteArray(data:ByteArray):Void
	{
		var context = __context;
		var gl = context.gl;

		__textureTarget = gl.TEXTURE_2D;
		__context.__bindGLTexture2D(__textureID);

		var bytes:Bytes = cast data;
		var textureBytes = new UInt8Array(#if js @:privateAccess bytes.b.buffer #else bytes #end, IMAGE_DATA_OFFSET, imageSize);
		gl.compressedTexImage2D(__textureTarget, 0, __internalFormat, __width, __height, 0, textureBytes);
		gl.texParameteri(__textureTarget, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
		gl.texParameteri(__textureTarget, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

		__context.__bindGLTexture2D(null);
	}

	@:noCompletion private function __getImageDimensions(bytes:ByteArray):Void
	{
		bytes.position = 12;
		__height = bytes.readUnsignedInt();

		bytes.position = 16;
		__width = bytes.readUnsignedInt();
	}

	@:noCompletion private function __getImageSize(bytes:ByteArray):Void
	{
		bytes.position = 20;
		imageSize = bytes.readUnsignedInt();
	}

	@:noCompletion private function __getTextureFormat(bytes:ByteArray):String
	{
		bytes.position = 84;
		var formatName = bytes.readUTFBytes(4);

		return formatName;
	}
}
#end
