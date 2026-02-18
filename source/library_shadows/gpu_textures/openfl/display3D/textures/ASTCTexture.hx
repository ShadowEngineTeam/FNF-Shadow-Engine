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

	private var __isSRGB:Bool = false;
	private var __isHDR:Bool = false;

	@:noCompletion private function new(context:Context3D, data:ByteArray)
	{
		super(context);
		var gl = __context.gl;

		var astcLdrExtension = gl.getExtension("KHR_texture_compression_astc_ldr");
		var astcHdrExtension = gl.getExtension("KHR_texture_compression_astc_hdr");

		if (astcLdrExtension == null && astcHdrExtension == null)
		{
			if (!__warned)
			{
				Lib.current.stage.window.alert("ASTC compression (LDR and HDR) is not available on this device.", "Rendering Error!");
				__warned = true;
			}
			supported = false;
		}

		if (supported)
		{
			__parseASTCHeader(data);
			__getImageSize(data);
			__getImageDimensions(data);

			var formatName:String;
			if (__isHDR)
			{
				// HDR: RGBA
				formatName = 'COMPRESSED_RGBA_ASTC_${blockDimX}x${blockDimY}_KHR';
				if (!Reflect.fields(astcHdrExtension).contains(formatName))
				{
					trace('[ERROR] HDR format: $formatName is invalid!');
					supported = false;
					return;
				}
				__format = Reflect.getProperty(astcHdrExtension, formatName);
			}
			else
			{
				// LDR: SRGB or RGBA
				if (__isSRGB)
					formatName = 'COMPRESSED_SRGB8_ALPHA8_ASTC_${blockDimX}x${blockDimY}_KHR';
				else
					formatName = 'COMPRESSED_RGBA_ASTC_${blockDimX}x${blockDimY}_KHR';

				if (!Reflect.fields(astcLdrExtension).contains(formatName))
				{
					trace('[ERROR] LDR format: $formatName is invalid!');
					supported = false;
					return;
				}
				__format = Reflect.getProperty(astcLdrExtension, formatName);
			}

			__internalFormat = __format;
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

	@:noCompletion private function __parseASTCHeader(bytes:ByteArray):Void
	{
		bytes.position = 0;

		var magic = bytes.readUnsignedInt();
		if (magic != 0x5CA1AB13)
		{
			trace('[ERROR] Invalid ASTC file: magic number mismatch!');
			supported = false;
			return;
		}

		bytes.position = 4;
		blockDimX = bytes.readUnsignedByte();
		blockDimY = bytes.readUnsignedByte();
		blockDimZ = bytes.readUnsignedByte();

		bytes.position = 7;
		bytes.position += 9;

		bytes.position = 7;
		var flags = bytes.readUnsignedByte() >> 4;

		__isSRGB = (flags & 0x1) != 0;
		// SHADOW TODO: better HDR implement
		// __isHDR = (flags & 0x2) != 0;
	}
}
#end
