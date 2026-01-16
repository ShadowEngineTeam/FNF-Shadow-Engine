package mobile.backend.io.android;

/**
 * The code for this class is mostly taken from SDL2.
 * This class implements IO methods from the Android NDK's AAssetManager to read bundled app assets.
 */

#if android
import haxe.io.Bytes;
import lime.system.JNI;

@:cppNamespaceCode('
	#include <jni.h>
	#include <android/log.h>
	#include <android/asset_manager_jni.h>

	static jmethodID midGetContext;
	static jclass mActivityClass;
	static AAssetManager *asset_manager = NULL;
	static jobject javaAssetManagerRef = 0;

	struct LocalReferenceHolder
	{
		JNIEnv *m_env;
		const char *m_func;
	};

	static struct LocalReferenceHolder LocalReferenceHolder_Setup(const char *func)
	{
		struct LocalReferenceHolder refholder;
		refholder.m_env = NULL;
		refholder.m_func = func;
		__android_log_print (ANDROID_LOG_DEBUG, "Shadow Engine", "Entering function %s", func);
		return refholder;
	}

	static bool LocalReferenceHolder_Init(struct LocalReferenceHolder *refholder, JNIEnv *env)
	{
		const int capacity = 16;
		if ((*env).PushLocalFrame(capacity) < 0)
		{
			__android_log_print (ANDROID_LOG_ERROR, "Shadow Engine", "Failed to allocate enough JVM local references");
			return false;
		}
		refholder->m_env = env;
		return true;
	}

	static void LocalReferenceHolder_Cleanup(struct LocalReferenceHolder *refholder)
	{
		__android_log_print (ANDROID_LOG_DEBUG, "Shadow Engine", "Leaving function %s", refholder->m_func);
		if (refholder->m_env)
		{
			JNIEnv *env = refholder->m_env;
			(*env).PopLocalFrame(NULL);
		}
	}

	void Assets_obj::native_init(::Dynamic jni_env)
	{
		JNIEnv* env = (JNIEnv*)(uintptr_t)jni_env;
		jclass cls = env->FindClass("org/libsdl/app/SDLActivity");
		mActivityClass = (jclass)((*env).NewGlobalRef(cls));
	
		struct LocalReferenceHolder refs = LocalReferenceHolder_Setup(__FUNCTION__);
		jmethodID mid;
		jobject context;
		jobject javaAssetManager;

		if (!LocalReferenceHolder_Init(&refs, env))
		{
			LocalReferenceHolder_Cleanup(&refs);
			return;
		}

		// context = SDLActivity.getContext();
		midGetContext = (*env).GetStaticMethodID(mActivityClass, "getContext","()Landroid/content/Context;");
		context = (*env).CallStaticObjectMethod(mActivityClass, midGetContext);

		// javaAssetManager = context.getAssets();
		mid = (*env).GetMethodID((*env).GetObjectClass(context),
				"getAssets", "()Landroid/content/res/AssetManager;");
		javaAssetManager = (*env).CallObjectMethod(context, mid);

		/**
		 * Given a Dalvik AssetManager object, obtain the corresponding native AAssetManager
		 * object.  Note that the caller is responsible for obtaining and holding a VM reference
		 * to the jobject to prevent its being garbage collected while the native object is
		 * in use.
		 */
		javaAssetManagerRef = (*env).NewGlobalRef(javaAssetManager);
		asset_manager = AAssetManager_fromJava(env, javaAssetManagerRef);

		if (asset_manager == NULL)
		{
			(*env).DeleteGlobalRef(javaAssetManagerRef);
			__android_log_print (ANDROID_LOG_DEBUG, "Shadow Engine", "Failed to create Android Assets Manager");
		}
		
		LocalReferenceHolder_Cleanup(&refs);
	}

	void Assets_obj::native_destroy(::Dynamic jni_env)
	{
		JNIEnv* env = (JNIEnv*)(uintptr_t)jni_env;

		if (asset_manager)
		{
			(*env).DeleteGlobalRef(javaAssetManagerRef);
			asset_manager = NULL;
		}
	}

	bool Assets_obj::native_exists(::String file)
	{
		AAsset* asset = AAssetManager_open(asset_manager, file.__s, AASSET_MODE_UNKNOWN);
		bool ret = asset != NULL;

		if (ret)
			AAsset_close(asset);

		return ret;
	}

	::String Assets_obj::native_getContent(::String file) {
		std::vector<char> buffer;
		
		hx::EnterGCFreeZone();
		AAsset* asset = AAssetManager_open(asset_manager, file.__s, AASSET_MODE_BUFFER);
		
		if (!asset)
		{
			hx::ExitGCFreeZone();
			return ::String(null());
		}

		int len = AAsset_getLength(asset);
		if (len <= 0)
		{
			AAsset_close(asset);
			hx::ExitGCFreeZone();
			return ::String::emptyString;
		}

		const char* src = (const char*)AAsset_getBuffer(asset);
		
		buffer.resize(len);
		memcpy(&buffer[0], src, len);

		AAsset_close(asset);
		hx::ExitGCFreeZone();

		return ::String::create(&buffer[0], buffer.size());
	}

	Array<unsigned char> Assets_obj::native_getBytes(::String file) {
		hx::EnterGCFreeZone();
		AAsset* asset = AAssetManager_open(asset_manager, file.__s, AASSET_MODE_BUFFER);
		
		if (!asset)
		{
			hx::ExitGCFreeZone();
			return null(); 
		}

		int len = AAsset_getLength(asset);
		const unsigned char* src = (const unsigned char*)AAsset_getBuffer(asset);
		hx::ExitGCFreeZone();

		Array<unsigned char> buffer = Array_obj<unsigned char>::__new(len, len);
		if (len > 0)
		{
			hx::EnterGCFreeZone();
			memcpy(buffer->getBase(), src, len);
			AAsset_close(asset);
			hx::ExitGCFreeZone();
		}
		else 
		{
			hx::EnterGCFreeZone();
			AAsset_close(asset);
			hx::ExitGCFreeZone();
		}

		return buffer;
	}
')
@:headerClassCode('
	static void native_init(::Dynamic jni_env);
	static void native_destroy(::Dynamic jni_env);
	static bool native_exists(::String file);
	static ::String native_getContent(::String file);
	static Array<unsigned char> native_getBytes(::String file);
')
class Assets
{
	public static function init():Void
	{
		__init(JNI.getEnv());
	}

	public static function destroy():Void
	{
		__destroy(JNI.getEnv());
	}

	public static function getContent(file:String):String
	{
		final content:String = __getContent(file);

		if (content == null)
			throw 'file_contents, $file';

		return content;
	}

	public static function getBytes(file:String):Bytes
	{
		final data:Array<cpp.UInt8> = __getBytes(file);

		if (data == null || data.length <= 0)
			throw 'file_contents, $file';

		return Bytes.ofData(data);
	}

	@:native('mobile::backend::android::Assets_obj::native_exists')
	public static function exists(file:String):Bool
		return false;

	@:noCompletion
	@:native('mobile::backend::android::Assets_obj::native_init')
	private static function __init(jni_env:Dynamic):Void
		return;

	@:noCompletion
	@:native('mobile::backend::android::Assets_obj::native_destroy')
	private static function __destroy(jni_env:Dynamic):Void
		return;

	@:noCompletion
	@:native('mobile::backend::android::Assets_obj::native_getContent')
	public static function __getContent(file:String):String
		return null;

	@:noCompletion
	@:native('mobile::backend::android::Assets_obj::native_getBytes')
	private static function __getBytes(file:String):Array<cpp.UInt8>
		return null;
}
#end
