package mobile.backend.io;

#if android
typedef Assets = mobile.backend.io.android.Assets;
// #elseif ios
// typedef Assets = mobile.backend.io.ios.Assets;
#else
typedef Assets = Dynamic;
#end