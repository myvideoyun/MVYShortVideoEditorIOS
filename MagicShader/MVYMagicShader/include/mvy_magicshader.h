#pragma once

#if defined(ANDROID)
#define EXPORT __attribute ((visibility("default")))
#else
#define EXPORT
#endif
#if defined(ANDROID)
#include <jni.h>
#elif defined(IOS)
#include "Observer.h"
#endif

/* define error code */

/* define beauty types */

/* define interface */
/* return NULL if fail, else return the handler */
EXPORT void *MVY_MagicShader_CreateShader(int type);
EXPORT int MVY_MagicShader_SetParam(void *handle, const char *name, void *value);
EXPORT int MVY_MagicShader_ReleaseShader(void *handle);
EXPORT int MVY_MagicShader_Draw(void *handle, int texId, int width,
                            int height); /* texId: backgroud texture */
EXPORT int MVY_MagicShader_InitGL(void *handle);
EXPORT int MVY_MagicShader_DeinitGL(void *handle);
#if defined(ANDROID)
EXPORT void MVY_MagicShader_Auth(JNIEnv *env, jobject obj, const char* appKey, Observer * observer, int length);
#elif defined(IOS)
EXPORT void MVY_MagicShader_Auth(const char* appId, const char* appKey, const char* imei, Observer * observer, int length);
#endif
