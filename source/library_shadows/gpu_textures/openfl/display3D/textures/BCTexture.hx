package openfl.display3D.textures;

#if !flash
import haxe.io.Bytes;
import openfl.utils._internal.UInt8Array;
import openfl.utils.ByteArray;
import openfl.Lib;

/**
	The BCTexture class represents a 2-dimensional compressed BCn texture uploaded to a rendering context.

	Defines a 2D texture for use during rendering.

	BCTexture cannot be instantiated directly. Create instances by using Context3D
	`createBCTexture()` method.
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(openfl.display3D.Context3D)
@:final class BCTexture extends TextureBase
{
	@:noCompletion private static var __warned:Bool = false;
	public static inline final BC_MAGIC_NUMBER:Int = 0x20534444;
	public static inline final IMAGE_DATA_OFFSET = 148;

	public var supported:Bool = true;
	public var imageSize(default, null):Int = 0;

	private var __isSRGB:Bool = false;
	private var __bcFormat:String = "BC7";

	private function new(context:Context3D, data:ByteArray)
	{
		super(context);

		var gl = __context.gl;

		__detectBCFormat(data);

		var dxt1Extension = gl.getExtension("EXT_texture_compression_dxt1");
		var s3tcExtension = gl.getExtension("EXT_texture_compression_s3tc");
		var s3tcSRGBExtension = gl.getExtension("EXT_texture_compression_s3tc_srgb");
		var rgtcExtension = gl.getExtension("EXT_texture_compression_rgtc");
		var bptcExtension = gl.getExtension("EXT_texture_compression_bptc");

		var extensionSupported = switch (__bcFormat)
		{
			case "BC1", "BC2", "BC3":
				dxt1Extension != null && s3tcExtension != null && s3tcSRGBExtension != null;
			case "BC4", "BC5":
				rgtcExtension != null;
			case "BC6H", "BC7":
				bptcExtension != null;
			default:
				false;
		}

		if (!extensionSupported)
		{
			if (!__warned)
			{
				Lib.current.stage.window.alert('BC compression for $__bcFormat is not available on this device.', "Rendering Error!");
				__warned = true;
			}
			supported = false;
			return;
		}

		__getImageDimensions(data);
		__computeImageSize();

		__format = switch (__bcFormat)
		{
			case "BC1":
				__isSRGB ? s3tcSRGBExtension.COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT : dxt1Extension.COMPRESSED_RGBA_S3TC_DXT1_EXT;
			case "BC2":
				__isSRGB ? s3tcSRGBExtension.COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT : s3tcExtension.COMPRESSED_RGBA_S3TC_DXT3_EXT;
			case "BC3":
				__isSRGB ? s3tcSRGBExtension.COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT : s3tcExtension.COMPRESSED_RGBA_S3TC_DXT5_EXT;
			case "BC4":
				__isSRGB ? rgtcExtension.COMPRESSED_RED_RGTC1_EXT : rgtcExtension.COMPRESSED_SIGNED_RED_RGTC1_EXT;
			case "BC5":
				__isSRGB ? rgtcExtension.COMPRESSED_RED_GREEN_RGTC2_EXT : rgtcExtension.COMPRESSED_SIGNED_RED_GREEN_RGTC2_EXT;
			case "BC6H":
				__isSRGB ? bptcExtension.COMPRESSED_RGB_BPTC_SIGNED_FLOAT_EXT : bptcExtension.COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT_EXT;
			case "BC7":
				__isSRGB ? bptcExtension.COMPRESSED_SRGB_ALPHA_BPTC_UNORM_EXT : bptcExtension.COMPRESSED_RGBA_BPTC_UNORM_EXT;
			default:
				bptcExtension.COMPRESSED_RGBA_BPTC_UNORM_EXT; // fallback
		}

		__internalFormat = __format;
		__optimizeForRenderToTexture = false;
		__streamingLevels = 0;

		__uploadBCTextureFromByteArray(data);
	}

	private function __uploadBCTextureFromByteArray(data:ByteArray):Void
	{
		var gl = __context.gl;

		__textureTarget = gl.TEXTURE_2D;
		__context.__bindGLTexture2D(__textureID);

		var bytes:Bytes = cast data;
		var textureBytes = new UInt8Array(#if js @:privateAccess bytes.b.buffer #else bytes #end, IMAGE_DATA_OFFSET, imageSize);
		gl.compressedTexImage2D(__textureTarget, 0, __internalFormat, __width, __height, 0, textureBytes);
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
		var blockSize = switch (__bcFormat)
		{
			case "BC1": 8;
			case "BC2", "BC3", "BC6H", "BC7": 16;
			case "BC4": 8;
			case "BC5": 16;
			default: 16;
		}

		imageSize = blockWidth * blockHeight * blockSize;
	}

	private function __detectBCFormat(bytes:ByteArray):Void
	{
		bytes.position = 84;
		var fourCC = bytes.readUTFBytes(4);

		if (fourCC == "DX10")
		{
			// DXGI format stored at offset 128 (after DDS header).
			bytes.position = 128;
			var dxgiFormat = bytes.readUnsignedInt();

			switch (dxgiFormat)
			{
				case 71:
					__bcFormat = "BC1";
					__isSRGB = false;
				case 72:
					__bcFormat = "BC1";
					__isSRGB = true;
				case 74:
					__bcFormat = "BC2";
					__isSRGB = false;
				case 75:
					__bcFormat = "BC2";
					__isSRGB = true;
				case 77:
					__bcFormat = "BC3";
					__isSRGB = false;
				case 78:
					__bcFormat = "BC3";
					__isSRGB = true;
				case 80:
					__bcFormat = "BC4";
					__isSRGB = false; // UNORM
				case 81:
					__bcFormat = "BC4";
					__isSRGB = true; // SNORM (signed)
				case 83:
					__bcFormat = "BC5";
					__isSRGB = false; // UNORM
				case 84:
					__bcFormat = "BC5";
					__isSRGB = true; // SNORM
				case 95:
					__bcFormat = "BC6H";
					__isSRGB = false; // UF16
				case 96:
					__bcFormat = "BC6H";
					__isSRGB = true; // SF16
				case 98:
					__bcFormat = "BC7";
					__isSRGB = false;
				case 99:
					__bcFormat = "BC7";
					__isSRGB = true;
				default:
					__bcFormat = "BC7";
			}
		}
		else
		{
			// legacy DDS fourCC
			switch (fourCC)
			{
				case "DXT1":
					__bcFormat = "BC1";
					__isSRGB = false;
				case "DXT3":
					__bcFormat = "BC2";
					__isSRGB = false;
				case "DXT5":
					__bcFormat = "BC3";
					__isSRGB = false;
				case "BC4U":
					__bcFormat = "BC4";
					__isSRGB = false;
				case "BC4S":
					__bcFormat = "BC4";
					__isSRGB = true;
				case "BC5U":
					__bcFormat = "BC5";
					__isSRGB = false;
				case "BC5S":
					__bcFormat = "BC5";
					__isSRGB = true;
				default:
					__bcFormat = "BC7"; // assuming DX10 if not legacy
			}
		}
	}

	public static function isBytesBC(bytes:ByteArray)
	{
		bytes.position = 0;
		var magic = bytes.readUnsignedInt();

		return magic == BC_MAGIC_NUMBER;
	}
}
#end
