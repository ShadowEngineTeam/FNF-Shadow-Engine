package mobile.backend;

#if android
typedef Assets = mobile.backend.android.Assets;
// #elseif ios
// typedef Assets = mobile.backend.ios.Assets;
#else
typedef Assets = Dynamic;
#end