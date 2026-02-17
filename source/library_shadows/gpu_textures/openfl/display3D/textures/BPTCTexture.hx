package openfl.display3D.textures;

#if !flash
import haxe.io.Bytes;
import openfl.utils._internal.UInt8Array;
import openfl.utils.ByteArray;
import openfl.Lib;

/**
	The BPTCTexture class represents a 2-dimensional compressed BPTC/BCn texture uploaded to a rendering context.

	Defines a 2D texture for use during rendering.

	BPTCTexture cannot be instantiated directly. Create instances by using Context3D
	`createBPTCTexture()` method.
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(openfl.display3D.Context3D)
@:final class BPTCTexture extends TextureBase
{
	public static inline final IMAGE_DATA_OFFSET = 148;

	public var supported:Bool = true;
	public var imageSize(default, null):Int = 0;

	private var __isSRGB:Bool = false;

	private function new(context:Context3D, data:ByteArray)
	{
		super(context);

		var gl = __context.gl;
		var bptcExtension = gl.getExtension("EXT_texture_compression_bptc");

		if (bptcExtension == null)
		{
			Lib.current.stage.window.alert("BPTC compression is not available on this device.", "Rendering Error!");
			supported = false;
			return;
		}

		__getImageDimensions(data);
		__computeImageSize();
		__detectBC7Format(data);

		if (__isSRGB)
		{
			__format = bptcExtension.COMPRESSED_SRGB_ALPHA_BPTC_UNORM_EXT;
		}
		else
		{
			__format = bptcExtension.COMPRESSED_RGBA_BPTC_UNORM_EXT;
		}

		__internalFormat = __format;
		__optimizeForRenderToTexture = false;
		__streamingLevels = 0;

		__uploadBPTCTextureFromByteArray(data);
	}

	private function __uploadBPTCTextureFromByteArray(data:ByteArray):Void
	{
		var gl = __context.gl;

		__textureTarget = gl.TEXTURE_2D;
		__context.__bindGLTexture2D(__textureID);

		var bytes:Bytes = cast data;
		var textureBytes = new UInt8Array(
			#if js @:privateAccess bytes.b.buffer #else bytes #end,
			IMAGE_DATA_OFFSET,
			imageSize
		);

		gl.compressedTexImage2D(
			__textureTarget,
			0,
			__internalFormat,
			__width,
			__height,
			0,
			textureBytes
		);

		gl.texParameteri(__textureTarget, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
		gl.texParameteri(__textureTarget, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

		__context.__bindGLTexture2D(null);
	}

	private function __getImageDimensions(bytes:ByteArray):Void
	{
		bytes.position = 12;
		__height = bytes.readUnsignedInt();

		bytes.position = 16;
		__width = bytes.readUnsignedInt();
	}

	private function __computeImageSize():Void
	{
		var blockWidth = Math.ceil(__width / 4);
		var blockHeight = Math.ceil(__height / 4);
		imageSize = blockWidth * blockHeight * 16;
	}

	private function __detectBC7Format(bytes:ByteArray):Void
	{
		bytes.position = 84;
		var fourCC = bytes.readUTFBytes(4);

		if (fourCC == "DX10")
		{
			// DXGI format stored at offset 128 (after DDS header).
			bytes.position = 128;
			var dxgiFormat = bytes.readUnsignedInt();

			// DXGI_FORMAT_BC7_UNORM is 98
			// DXGI_FORMAT_BC7_UNORM_SRGB is 99
			__isSRGB = (dxgiFormat == 99);
		}
		else
		{
			trace("[ERROR] Not a valid BC7/DX10 DDS file.");
		}
	}
}
#end
