package mobile.backend.android;

/**
 * The code for this class is mostly taken from SDL2.
 * This class implements IO methods from the Android NDK's AAssetManager to read bundled app assets.
 */

#if android
@:cppNamespaceCode('
#include <jni.h>
#include <android/log.h>
#include <android/configuration.h>
#include <android/asset_manager_jni.h>
#include <sys/system_properties.h>
#include <pthread.h>
#include <sys/types.h>
#include <unistd.h>
#include <dlfcn.h>

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
    if ((*env).PushLocalFrame(capacity) < 0) {
		__android_log_print (ANDROID_LOG_ERROR, "Shadow Engine", "Failed to allocate enough JVM local references");
        return false;
    }
    refholder->m_env = env;
    return true;
}

static void LocalReferenceHolder_Cleanup(struct LocalReferenceHolder *refholder)
{
	__android_log_print (ANDROID_LOG_DEBUG, "Shadow Engine", "Leaving function %s", refholder->m_func);
    if (refholder->m_env) {
        JNIEnv *env = refholder->m_env;
        (*env).PopLocalFrame(NULL);
    }
}

static jmethodID midGetContext;
static jclass mActivityClass;
static AAssetManager *asset_manager = NULL;
static jobject javaAssetManagerRef = 0;
')
class Assets
{
	@:functionCode('
		JNIEnv* env = (JNIEnv*)(uintptr_t)a;

        jclass cls = env->FindClass("org/libsdl/app/SDLActivity");
		mActivityClass = (jclass)((*env).NewGlobalRef(cls));
    
		struct LocalReferenceHolder refs = LocalReferenceHolder_Setup(__FUNCTION__);
    	jmethodID mid;
    	jobject context;
    	jobject javaAssetManager;

    	if (!LocalReferenceHolder_Init(&refs, env)) {
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

    	if (asset_manager == NULL) {
    	    (*env).DeleteGlobalRef(javaAssetManagerRef);
			__android_log_print (ANDROID_LOG_DEBUG, "Shadow Engine", "Failed to create Android Assets Manager");
    	}

    	LocalReferenceHolder_Cleanup(&refs);
	')
	public static function init(a:Dynamic):Void
	{
		return;
	}

	@:functionCode('
		JNIEnv* env = (JNIEnv*)(uintptr_t)a;

    	if (asset_manager) {
        	(*env).DeleteGlobalRef(javaAssetManagerRef);
        	asset_manager = NULL;
    	}
	')
	public static function destroy(a:Dynamic):Void
	{
		return;
	}

	@:functionCode('
		AAsset* asset = AAssetManager_open(asset_manager, file, AASSET_MODE_UNKNOWN);

		bool ret = asset != NULL;

		if (ret)
			AAsset_close(asset);

		return ret;
	')
	public static function exists(file:cpp.ConstCharStar):Bool
	{
		return false;
	}

}
#end
