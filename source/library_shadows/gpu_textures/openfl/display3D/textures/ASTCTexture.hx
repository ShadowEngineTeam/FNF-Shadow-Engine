package openfl.display3D.textures;

#if !flash
import haxe.io.Bytes;
import openfl.utils._internal.UInt8Array;
import openfl.display.BlendMode;
import openfl.utils.ByteArray;
import openfl.Lib;

/**
	The ASTCTexture class represents a 2-dimensional compressed ASTC texture uploaded to a rendering context.

	Defines a 2D texture for use during rendering.

	ASTCTexture cannot be instantiated directly. Create instances by using Context3D
	`createASTCTexture()` method.
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(openfl.display3D.Context3D)
@:final class ASTCTexture extends TextureBase
{
	@:noCompletion private static var __lowMemoryMode:Bool = false;
	@:noCompletion private static var __warned:Bool = false;
	public static inline final IMAGE_DATA_OFFSET = 16;

	public var supported:Bool = true;
	public var imageSize(default, null):Int = 0;
	public var depth(default, null):Int = 0;
	public var blockDimX:Int = -1;
	public var blockDimY:Int = -1;
	public var blockDimZ:Int = -1;

	@:noCompletion private function new(context:Context3D, data:ByteArray)
	{
		super(context);
		var gl = __context.gl;
		var astcExtension = gl.getExtension("KHR_texture_compression_astc_ldr");

		if (astcExtension == null)
		{
			if (!__warned)
			{
				Lib.current.stage.window.alert("ASTC compression is not available on this device.", "Rendering Error!");
				__warned = true;
			}

			supported = false;
		}

		if (supported)
		{
			__getImageSize(data);
			__getImageDimensions(data);

			var formatName = 'COMPRESSED_RGBA_ASTC_${blockDimX}x${blockDimY}_KHR';
			if (!Reflect.fields(astcExtension).contains(formatName))
			{
				trace('[ERROR] format: $formatName is invalid!');
			}

			var format = Reflect.getProperty(astcExtension, formatName);
			__format = format;
			__internalFormat = format;
			__optimizeForRenderToTexture = false;
			__streamingLevels = 0;

			__uploadASTCTextureFromByteArray(data);
		}
	}

	@:noCompletion public function __uploadASTCTextureFromByteArray(data:ByteArray):Void
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
		bytes.position = 7;

		__width = bytes.readUnsignedByte() | (bytes.readUnsignedByte() << 8) | (bytes.readUnsignedByte() << 16);
		__height = bytes.readUnsignedByte() | (bytes.readUnsignedByte() << 8) | (bytes.readUnsignedByte() << 16);
		depth = bytes.readUnsignedByte() | (bytes.readUnsignedByte() << 8) | (bytes.readUnsignedByte() << 16);
	}

	@:noCompletion private function __getImageSize(bytes:ByteArray):Void
	{
		bytes.position = 4;

		blockDimX = bytes.readUnsignedByte();
		blockDimY = bytes.readUnsignedByte();
		blockDimZ = bytes.readUnsignedByte();

		bytes.position = 7;

		var dimX = bytes.readUnsignedByte() | (bytes.readUnsignedByte() << 8) | (bytes.readUnsignedByte() << 16);
		var dimY = bytes.readUnsignedByte() | (bytes.readUnsignedByte() << 8) | (bytes.readUnsignedByte() << 16);
		var dimZ = bytes.readUnsignedByte() | (bytes.readUnsignedByte() << 8) | (bytes.readUnsignedByte() << 16);

		var blocksX = Math.ceil(dimX / blockDimX);
		var blocksY = Math.ceil(dimY / blockDimY);
		var blocksZ = Math.ceil(dimZ / blockDimZ);

		var totalBlocks = blocksX * blocksY * blocksZ;
		imageSize = totalBlocks * 16;
	}
}
#end
