package openfl.display3D.textures;

#if !flash
import haxe.io.Bytes;
import openfl.utils._internal.UInt8Array;
import openfl.utils.ByteArray;
import openfl.Lib;

/**
	The ETC2Texture class represents a 2-dimensional compressed ETC2 texture uploaded to a rendering context.

	Defines a 2D texture for use during rendering.

	ETC2Texture cannot be instantiated directly. Create instances by using Context3D
	`createETC2Texture()` method.
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(openfl.display3D.Context3D)
@:final class ETC2Texture extends TextureBase
{
	@:noCompletion private static var __lowMemoryMode:Bool = false;
	private static inline final GL_COMPRESSED_RGB8_ETC2 = 0x8D64;
	private static inline final GL_COMPRESSED_SRGB8_ETC2 = 0x8D65;
	private static inline final GL_COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2 = 0x8D66;
	private static inline final GL_COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2 = 0x8D67;
	private static inline final GL_COMPRESSED_RGBA8_ETC2_EAC = 0x9278;
	private static inline final GL_COMPRESSED_SRGB8_ALPHA8_ETC2_EAC = 0x9279;
	private static inline final GL_COMPRESSED_R11_EAC = 0x9270;
	private static inline final GL_COMPRESSED_SIGNED_R11_EAC = 0x9271;
	private static inline final GL_COMPRESSED_RG11_EAC = 0x9272;
	private static inline final GL_COMPRESSED_SIGNED_RG11_EAC = 0x9273;

	@:noCompletion private function new(context:Context3D, data:ByteArray)
	{
		super(context);

		data.position = 0x24;
		__width = data.readUnsignedInt();
		__height = data.readUnsignedInt();

		__optimizeForRenderToTexture = false;
		__streamingLevels = 0;

		var format = detectETC2Format(data);
		__format = format;
		__internalFormat = format;

		var gl = __context.gl;

		__textureTarget = gl.TEXTURE_2D;

		__uploadETC2TextureFromByteArray(data);
	}

	@:noCompletion public function __uploadETC2TextureFromByteArray(data:ByteArray):Void
	{
		var context = __context;
		var gl = context.gl;

		__context.__bindGLTexture2D(__textureID);

		data.position = 0x3C;
		var bytesOfKeyValueData = data.readUnsignedInt();
		var imageSizeOffset = 64 + bytesOfKeyValueData;
		data.position = imageSizeOffset;
		var imageSize = data.readUnsignedInt();

		var bytes:Bytes = cast data;
		var textureBytes = new UInt8Array(#if js @:privateAccess bytes.b.buffer #else bytes #end, 68, imageSize);
		gl.compressedTexImage2D(__textureTarget, 0, __internalFormat, __width, __height, 0, textureBytes);
		gl.texParameteri(__textureTarget, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
		gl.texParameteri(__textureTarget, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

		__context.__bindGLTexture2D(null);
	}

	private function detectETC2Format(data:ByteArray):Int
	{
		var format = 0;

		final header = data.readUnsignedByte();
		switch (header)
		{
			case 0x64:
				format = GL_COMPRESSED_RGB8_ETC2;
			case 0x65:
				format = GL_COMPRESSED_SRGB8_ETC2;
			case 0x66:
				format = GL_COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2;
			case 0x67:
				format = GL_COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2;
			case 0x78:
				format = GL_COMPRESSED_RGBA8_ETC2_EAC;
			case 0x79:
				format = GL_COMPRESSED_SRGB8_ALPHA8_ETC2_EAC;
			case 0x70:
				format = GL_COMPRESSED_R11_EAC;
			case 0x71:
				format = GL_COMPRESSED_SIGNED_R11_EAC;
			case 0x72:
				format = GL_COMPRESSED_RG11_EAC;
			case 0x73:
				format = GL_COMPRESSED_SIGNED_RG11_EAC;
		}

		return format;
	}
}
#end
