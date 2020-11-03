#include <jni.h>

#ifndef _Included_org_ar_raw_data_simple_VideoRawData
#define _Included_org_ar_raw_data_simple_VideoRawData
#ifdef __cplusplus
extern "C" {
#endif

JNIEXPORT void JNICALL Java_org_ar_raw_1data_1simple_VideoRawData_nativeSetEngine
        (JNIEnv *, jobject, jlong nativeId);


JNIEXPORT void JNICALL Java_org_ar_raw_1data_1simple_VideoRawData_setCallback
        (JNIEnv *, jobject, jobject);

JNIEXPORT void JNICALL
Java_org_ar_raw_1data_1simple_VideoRawData_setVideoCaptureByteBuffer(JNIEnv *env, jobject thiz,
                                                                     jobject byte_buffer);
JNIEXPORT void JNICALL
Java_org_ar_raw_1data_1simple_VideoRawData_releasePoint(JNIEnv *env, jobject thiz);
#ifdef __cplusplus
}
#endif
#endif
