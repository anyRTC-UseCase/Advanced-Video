#include <jni.h>
#include <android/log.h>
#include <cstring>
#include "ar/IArMediaEngine.h"

#include "ar/IArRtcEngine.h"
#include <string.h>
#include "videorawdata.h"
#include "ar/VMUtil.h"

#include <map>

using namespace std;

jobject gCallBack = nullptr;
jclass gCallbackClass = nullptr;
jmethodID captureVideoMethodId = nullptr;
jmethodID renderVideoMethodId = nullptr;
void *_javaDirectPlayBufferCapture = nullptr;
//map<int, void *> decodeBufferMap;

static JavaVM *gJVM = nullptr;

/**Listener to get video frame*/
class ARVideoFrameObserver : public ar::media::IVideoFrameObserver {

public:
    ARVideoFrameObserver() {

    }

    ~ARVideoFrameObserver() {

    }

    void getVideoFrame(VideoFrame &videoFrame, _jmethodID *jmethodID, void *_byteBufferObject,
                       const char* uid) {
        if (_byteBufferObject == nullptr) {
            return;
        }

        int width = videoFrame.width;
        int height = videoFrame.height;
        size_t widthAndHeight = (size_t) videoFrame.yStride * height;
        size_t length = widthAndHeight * 3 / 2;

        AttachThreadScoped ats(gJVM);
        JNIEnv *env = ats.env();

        memcpy(_byteBufferObject, videoFrame.yBuffer, widthAndHeight);
        memcpy((uint8_t *) _byteBufferObject + widthAndHeight, videoFrame.uBuffer,
               widthAndHeight / 4);
        memcpy((uint8_t *) _byteBufferObject + widthAndHeight * 5 / 4, videoFrame.vBuffer,
               widthAndHeight / 4);

        if (uid == "0") {
            env->CallVoidMethod(gCallBack, jmethodID, videoFrame.type, width, height, length,
                                videoFrame.yStride, videoFrame.uStride,
                                videoFrame.vStride, videoFrame.rotation,
                                videoFrame.renderTimeMs);
        } else {
            env->CallVoidMethod(gCallBack, jmethodID, uid, videoFrame.type, width, height,
                                length,
                                videoFrame.yStride, videoFrame.uStride,
                                videoFrame.vStride, videoFrame.rotation,
                                videoFrame.renderTimeMs);
        }
    }

    void writebackVideoFrame(VideoFrame &videoFrame, void *byteBuffer) {
        if (byteBuffer == nullptr) {
            return;
        }

        int width = videoFrame.width;
        int height = videoFrame.height;
        size_t widthAndHeight = (size_t) videoFrame.yStride * height;

        memcpy(videoFrame.yBuffer, byteBuffer, widthAndHeight);
        memcpy(videoFrame.uBuffer, (uint8_t *) byteBuffer + widthAndHeight, widthAndHeight / 4);
        memcpy(videoFrame.vBuffer, (uint8_t *) byteBuffer + widthAndHeight * 5 / 4,
               widthAndHeight / 4);
    }

public:
    virtual bool onCaptureVideoFrame(VideoFrame &videoFrame) override {
        getVideoFrame(videoFrame, captureVideoMethodId, _javaDirectPlayBufferCapture, "0");
        writebackVideoFrame(videoFrame, _javaDirectPlayBufferCapture);
        return true;
    }

    virtual bool onRenderVideoFrame(const char* uid, VideoFrame &videoFrame) override {
//        __android_log_print(ANDROID_LOG_DEBUG, "ARVideoFrameObserver", "onRenderVideoFrame");
//        map<char*, void *>::iterator it_find;
//        it_find = decodeBufferMap.find(uid);
//
//        if (it_find != decodeBufferMap.end()) {
//            if (it_find->second != nullptr) {
//                getVideoFrame(videoFrame, renderVideoMethodId, it_find->second, uid);
//                writebackVideoFrame(videoFrame, it_find->second);
//            }
//        }
        return true;
    }

};

static ARVideoFrameObserver s_videoFrameObserver;
static ar::rtc::IRtcEngine *rtcEngine = nullptr;

#ifdef __cplusplus
extern "C" {
#endif

int __attribute__((visibility("default")))
loadARRtcEnginePlugin(ar::rtc::IRtcEngine *engine) {
    __android_log_print(ANDROID_LOG_DEBUG, "apm-video-raw-data", "plugin loadAgoraRtcEnginePlugin");
    rtcEngine = engine;
    return 0;
}

void __attribute__((visibility("default")))
unloadARRtcEnginePlugin(ar::rtc::IRtcEngine *engine) {
    __android_log_print(ANDROID_LOG_DEBUG, "apm-video-raw-data", "unloadAgoraRtcEnginePlugin");
    rtcEngine = nullptr;
}

JNIEXPORT void JNICALL Java_org_ar_raw_1data_1simple_VideoRawData_setCallback
        (JNIEnv *env, jobject, jobject callback) {
    if (!rtcEngine) {
        __android_log_print(ANDROID_LOG_INFO, "ldh", "register null");
        return;
    }

    env->GetJavaVM(&gJVM);

    ar::util::AutoPtr<ar::media::IMediaEngine> mediaEngine;
    mediaEngine.queryInterface(rtcEngine, ar::INTERFACE_ID_TYPE::AR_IID_MEDIA_ENGINE);
    if (mediaEngine) {
        int code = mediaEngine->registerVideoFrameObserver(&s_videoFrameObserver);
    }

    if (gCallBack == nullptr) {
        gCallBack = env->NewGlobalRef(callback);
        gCallbackClass = env->GetObjectClass(gCallBack);

/**Get the MethodId of each callback function through the callback object.
 * Pass the data back to the java layer through these methods*/
        captureVideoMethodId = env->GetMethodID(gCallbackClass, "onCaptureVideoFrame",
                                                "(IIIIIIIIJ)V");
        __android_log_print(ANDROID_LOG_DEBUG, "setCallback", "setCallback done successfully");
    }
}

JNIEXPORT void JNICALL
Java_org_ar_raw_1data_1simple_VideoRawData_setVideoCaptureByteBuffer
        (JNIEnv *env, jobject, jobject bytebuffer) {
    _javaDirectPlayBufferCapture = env->GetDirectBufferAddress(bytebuffer);
}
JNIEXPORT void JNICALL
Java_org_ar_raw_1data_1simple_VideoRawData_nativeSetEngine
        (JNIEnv *env, jobject, jlong nativeId) {

    rtcEngine = (AR::IRtcEngine*)nativeId;
}


JNIEXPORT void JNICALL Java_org_ar_raw_1data_1simple_VideoRawData_releasePoint
        (JNIEnv *env, jobject thiz) {
    ar::util::AutoPtr<ar::media::IMediaEngine> mediaEngine;
    mediaEngine.queryInterface(rtcEngine, ar::INTERFACE_ID_TYPE::AR_IID_MEDIA_ENGINE);

    if (mediaEngine) {
/**Release video and audio observers*/
        mediaEngine->registerVideoFrameObserver(NULL);
    }

    if (gCallBack != nullptr) {
        env->DeleteGlobalRef(gCallBack);
        gCallBack = nullptr;
    }
    gCallbackClass = nullptr;

    captureVideoMethodId = nullptr;
    renderVideoMethodId = nullptr;

    _javaDirectPlayBufferCapture = nullptr;

//    decodeBufferMap.clear();
}

#ifdef __cplusplus
}
#endif
