//
//  ARMediaDataPlugin.m
//  AR-Plugin-RawMediaData-iOS
//
//  Created by 余生丶 on 2020/10/22.
//

#import "ARMediaDataPlugin.h"

#import <ARtcKit/ARtcEngineKit.h>
#import <ARtcKit/IArMediaEngine.h>
#import <ARtcKit/IArRtcEngine.h>
#include <vector>

typedef void (^imageBlock)(AGImage *image);

@interface ARMediaDataPlugin ()
@property (nonatomic, assign) NSUInteger screenShotUid;
@property (nonatomic, assign) ObserverVideoType observerVideoType;
@property (nonatomic, assign) ObserverAudioType observerAudioType;
@property (nonatomic, assign) ObserverPacketType observerPacketType;
@property (nonatomic, strong) ARVideoRawDataFormatter *videoFormatter;
@property (nonatomic, weak) ARtcEngineKit *rtcKit;
@property (nonatomic, copy) imageBlock imageBlock;
- (void)yuvToUIImageWithVideoRawData:(ARVideoRawData *)data;
@end


class ARMediaDataPluginVideoFrameObserver : public ar::media::IVideoFrameObserver
{
public:
    ARMediaDataPlugin *mediaDataPlugin;
    BOOL getOneDidCaptureVideoFrame = false;
    BOOL getOneWillRenderVideoFrame = false;
    NSString *videoFrameUid = @"-1";
    
    ARVideoRawData* getVideoRawDataWithVideoFrame(VideoFrame& videoFrame)
    {
        ARVideoRawData *data = [[ARVideoRawData alloc] init];
        data.type = videoFrame.type;
        data.width = videoFrame.width;
        data.height = videoFrame.height;
        data.yStride = videoFrame.yStride;
        data.uStride = videoFrame.uStride;
        data.vStride = videoFrame.vStride;
        data.rotation = videoFrame.rotation;
        data.renderTimeMs = videoFrame.renderTimeMs;
        data.yBuffer = (char *)videoFrame.yBuffer;
        data.uBuffer = (char *)videoFrame.uBuffer;
        data.vBuffer = (char *)videoFrame.vBuffer;
        return data;
    }
    
    void modifiedVideoFrameWithNewVideoRawData(VideoFrame& videoFrame, ARVideoRawData *videoRawData)
    {
        videoFrame.width = videoRawData.width;
        videoFrame.height = videoRawData.height;
        videoFrame.yStride = videoRawData.yStride;
        videoFrame.uStride = videoRawData.uStride;
        videoFrame.vStride = videoRawData.vStride;
        videoFrame.rotation = videoRawData.rotation;
        videoFrame.renderTimeMs = videoRawData.renderTimeMs;
    }
    
    virtual bool onCaptureVideoFrame(VideoFrame& videoFrame) override
    {
        if (!mediaDataPlugin && ((mediaDataPlugin.observerVideoType >> 0) == 0)) return true;
        @autoreleasepool {
            ARVideoRawData *newData = nil;
            if ([mediaDataPlugin.videoDelegate respondsToSelector:@selector(mediaDataPlugin:didCapturedVideoRawData:)]) {
                ARVideoRawData *data = getVideoRawDataWithVideoFrame(videoFrame);
                newData = [mediaDataPlugin.videoDelegate mediaDataPlugin:mediaDataPlugin didCapturedVideoRawData:data];
                modifiedVideoFrameWithNewVideoRawData(videoFrame, newData);
                
                // ScreenShot
                if (getOneDidCaptureVideoFrame) {
                    getOneDidCaptureVideoFrame = false;
                    [mediaDataPlugin yuvToUIImageWithVideoRawData:newData];
                }
            }
        }
        return true;
    }
    
    virtual bool onRenderVideoFrame(const char* uid, VideoFrame& videoFrame) override
    {
        if (!mediaDataPlugin && ((mediaDataPlugin.observerVideoType >> 1) == 0)) return true;
        @autoreleasepool {
            ARVideoRawData *newData = nil;
            if ([mediaDataPlugin.videoDelegate respondsToSelector:@selector(mediaDataPlugin:willRenderVideoRawData:ofUid:)]) {
                ARVideoRawData *data = getVideoRawDataWithVideoFrame(videoFrame);
                newData = [mediaDataPlugin.videoDelegate mediaDataPlugin:mediaDataPlugin willRenderVideoRawData:data ofUid:[NSString stringWithUTF8String:uid]];
                modifiedVideoFrameWithNewVideoRawData(videoFrame, newData);
                
                // ScreenShot
                if (getOneWillRenderVideoFrame && [videoFrameUid isEqualToString:[NSString stringWithUTF8String:uid]]) {
                    getOneWillRenderVideoFrame = false;
                    videoFrameUid = @"-1";
                    [mediaDataPlugin yuvToUIImageWithVideoRawData:newData];
                }
            }
        }
        return true;
    }
    
    virtual bool onPreEncodeVideoFrame(VideoFrame& videoFrame) override
    {
        if (!mediaDataPlugin && ((mediaDataPlugin.observerVideoType >> 2) == 0)) return true;
        @autoreleasepool {
            ARVideoRawData *newData = nil;
            if ([mediaDataPlugin.videoDelegate respondsToSelector:@selector(mediaDataPlugin:willPreEncodeVideoRawData:)]) {
                ARVideoRawData *data = getVideoRawDataWithVideoFrame(videoFrame);
                newData = [mediaDataPlugin.videoDelegate mediaDataPlugin:mediaDataPlugin willPreEncodeVideoRawData:data];
                modifiedVideoFrameWithNewVideoRawData(videoFrame, newData);
            }
        }
        return true;
    }
    
    virtual VIDEO_FRAME_TYPE getVideoFormatPreference() override
    {
        return VIDEO_FRAME_TYPE(mediaDataPlugin.videoFormatter.type);
    }

    virtual bool getRotationApplied() override
    {
        return mediaDataPlugin.videoFormatter.rotationApplied;
    }

    virtual bool getMirrorApplied() override
    {
        return mediaDataPlugin.videoFormatter.mirrorApplied;
    }
};

class ARMediaDataPluginAudioFrameObserver : public ar::media::IAudioFrameObserver
{
public:
    ARMediaDataPlugin *mediaDataPlugin;

    ARAudioRawData* getAudioRawDataWithAudioFrame(AudioFrame& audioFrame)
    {
        ARAudioRawData *data = [[ARAudioRawData alloc] init];
        data.samples = audioFrame.samples;
        data.bytesPerSample = audioFrame.bytesPerSample;
        data.channels = audioFrame.channels;
        data.samplesPerSec = audioFrame.samplesPerSec;
        data.renderTimeMs = audioFrame.renderTimeMs;
        data.buffer = (char *)audioFrame.buffer;
        data.bufferSize = audioFrame.samples * audioFrame.bytesPerSample;
        return data;
    }
    
    void modifiedAudioFrameWithNewAudioRawData(AudioFrame& audioFrame, ARAudioRawData *audioRawData)
    {
        audioFrame.samples = audioRawData.samples;
        audioFrame.bytesPerSample = audioRawData.bytesPerSample;
        audioFrame.channels = audioRawData.channels;
        audioFrame.samplesPerSec = audioRawData.samplesPerSec;
        audioFrame.renderTimeMs = audioRawData.renderTimeMs;
    }
    
    virtual bool onRecordAudioFrame(AudioFrame& audioFrame) override
    {
        if (!mediaDataPlugin && ((mediaDataPlugin.observerAudioType >> 0) == 0)) return true;
        @autoreleasepool {
            if ([mediaDataPlugin.audioDelegate respondsToSelector:@selector(mediaDataPlugin:didRecordAudioRawData:)]) {
                ARAudioRawData *data = getAudioRawDataWithAudioFrame(audioFrame);
                ARAudioRawData *newData = [mediaDataPlugin.audioDelegate mediaDataPlugin:mediaDataPlugin didRecordAudioRawData:data];
                modifiedAudioFrameWithNewAudioRawData(audioFrame, newData);
            }
        }
        return true;
    }
    
    virtual bool onPlaybackAudioFrame(AudioFrame& audioFrame) override
    {
        if (!mediaDataPlugin && ((mediaDataPlugin.observerAudioType >> 1) == 0)) return true;
        @autoreleasepool {
            if ([mediaDataPlugin.audioDelegate respondsToSelector:@selector(mediaDataPlugin:willPlaybackAudioRawData:)]) {
                ARAudioRawData *data = getAudioRawDataWithAudioFrame(audioFrame);
                ARAudioRawData *newData = [mediaDataPlugin.audioDelegate mediaDataPlugin:mediaDataPlugin willPlaybackAudioRawData:data];
                modifiedAudioFrameWithNewAudioRawData(audioFrame, newData);
            }
        }
        return true;
    }
    
    virtual bool onPlaybackAudioFrameBeforeMixing(const char* uid, AudioFrame& audioFrame) override
    {
        if (!mediaDataPlugin && ((mediaDataPlugin.observerAudioType >> 2) == 0)) return true;
        @autoreleasepool {
            if ([mediaDataPlugin.audioDelegate respondsToSelector:@selector(mediaDataPlugin:willPlaybackBeforeMixingAudioRawData:ofUid:)]) {
                ARAudioRawData *data = getAudioRawDataWithAudioFrame(audioFrame);
                ARAudioRawData *newData = [mediaDataPlugin.audioDelegate mediaDataPlugin:mediaDataPlugin willPlaybackBeforeMixingAudioRawData:data ofUid:[NSString stringWithUTF8String:uid]];
                modifiedAudioFrameWithNewAudioRawData(audioFrame, newData);
            }
        }
        return true;
    }
    
    virtual bool onMixedAudioFrame(AudioFrame& audioFrame) override
    {
        if (!mediaDataPlugin && ((mediaDataPlugin.observerAudioType >> 3) == 0)) return true;
        @autoreleasepool {
            if ([mediaDataPlugin.audioDelegate respondsToSelector:@selector(mediaDataPlugin:didMixedAudioRawData:)]) {
                ARAudioRawData *data = getAudioRawDataWithAudioFrame(audioFrame);
                ARAudioRawData *newData = [mediaDataPlugin.audioDelegate mediaDataPlugin:mediaDataPlugin didMixedAudioRawData:data];
                modifiedAudioFrameWithNewAudioRawData(audioFrame, newData);
            }
        }
        return true;
    }
};

class ARMediaDataPluginPacketObserver : public ar::rtc::IPacketObserver
{
public:
    ARMediaDataPlugin *mediaDataPlugin;
    
    ARMediaDataPluginPacketObserver()
    {
    }
    
    ARPacketRawData* getPacketRawDataWithPacket(Packet& packet)
    {
        ARPacketRawData *data = [[ARPacketRawData alloc] init];
        data.buffer = packet.buffer;
        data.bufferSize = packet.size;
        return data;
    }
    
    void modifiedPacketWithNewPacketRawData(Packet& packet, ARPacketRawData *rawData)
    {
        packet.size = rawData.bufferSize;
    }
    
    virtual bool onSendAudioPacket(Packet& packet)
    {
        if (!mediaDataPlugin && ((mediaDataPlugin.observerPacketType >> 0) == 0)) return true;
        @autoreleasepool {
            if ([mediaDataPlugin.packetDelegate respondsToSelector:@selector(mediaDataPlugin:willSendAudioPacket:)]) {
                ARPacketRawData *data = getPacketRawDataWithPacket(packet);
                ARPacketRawData *newData = [mediaDataPlugin.packetDelegate mediaDataPlugin:mediaDataPlugin willSendAudioPacket:data];
                modifiedPacketWithNewPacketRawData(packet, newData);
            }
        }
        return true;
    }
    
    virtual bool onSendVideoPacket(Packet& packet)
    {
        if (!mediaDataPlugin && ((mediaDataPlugin.observerPacketType >> 1) == 0)) return true;
        @autoreleasepool {
            if ([mediaDataPlugin.packetDelegate respondsToSelector:@selector(mediaDataPlugin:willSendVideoPacket:)]) {
                ARPacketRawData *data = getPacketRawDataWithPacket(packet);
                ARPacketRawData *newData = [mediaDataPlugin.packetDelegate mediaDataPlugin:mediaDataPlugin willSendVideoPacket:data];
                modifiedPacketWithNewPacketRawData(packet, newData);
            }
        }
        return true;
    }
    
    virtual bool onReceiveAudioPacket(Packet& packet)
    {
        if (!mediaDataPlugin && ((mediaDataPlugin.observerPacketType >> 2) == 0)) return true;
        @autoreleasepool {
            if ([mediaDataPlugin.packetDelegate respondsToSelector:@selector(mediaDataPlugin:didReceivedAudioPacket:)]) {
                ARPacketRawData *data = getPacketRawDataWithPacket(packet);
                ARPacketRawData *newData = [mediaDataPlugin.packetDelegate mediaDataPlugin:mediaDataPlugin didReceivedAudioPacket:data];
                modifiedPacketWithNewPacketRawData(packet, newData);
            }
        }
        return true;
    }
    
    virtual bool onReceiveVideoPacket(Packet& packet)
    {
        if (!mediaDataPlugin && ((mediaDataPlugin.observerPacketType >> 3) == 0)) return true;
        @autoreleasepool {
            if ([mediaDataPlugin.packetDelegate respondsToSelector:@selector(mediaDataPlugin:didReceivedVideoPacket:)]) {
                ARPacketRawData *data = getPacketRawDataWithPacket(packet);
                ARPacketRawData *newData = [mediaDataPlugin.packetDelegate mediaDataPlugin:mediaDataPlugin didReceivedVideoPacket:data];
                modifiedPacketWithNewPacketRawData(packet, newData);
            }
        }
        return true;
    }
};

static ARMediaDataPluginVideoFrameObserver s_videoFrameObserver;
static ARMediaDataPluginAudioFrameObserver s_audioFrameObserver;
static ARMediaDataPluginPacketObserver s_packetObserver;

@implementation ARMediaDataPlugin
    
+ (instancetype _Nonnull)mediaDataPluginWithRtcKit:(ARtcEngineKit * _Nonnull)rtcKit {
    ARMediaDataPlugin *source = [[ARMediaDataPlugin alloc] init];
    source.videoFormatter = [[ARVideoRawDataFormatter alloc] init];
    source.rtcKit = rtcKit;
    
    if (!rtcKit) {
        return nil;
    }
    return source;
}

- (void)registerVideoRawDataObserver:(ObserverVideoType)observerType {
    ar::rtc::IRtcEngine* rtc_engine = (ar::rtc::IRtcEngine*)self.rtcKit.getNativeHandle;
    ar::util::AutoPtr<ar::media::IMediaEngine> mediaEngine;
    mediaEngine.queryInterface(rtc_engine, ar::AR_IID_MEDIA_ENGINE);
    
    NSInteger oldValue = self.observerVideoType;
    self.observerVideoType |= observerType;
    
    if (mediaEngine && oldValue == 0)
    {
        mediaEngine->registerVideoFrameObserver(&s_videoFrameObserver);
        s_videoFrameObserver.mediaDataPlugin = self;
    }
}

- (void)deregisterVideoRawDataObserver:(ObserverVideoType)observerType {
    
    ar::rtc::IRtcEngine* rtc_engine = (ar::rtc::IRtcEngine*)self.rtcKit.getNativeHandle;
    ar::util::AutoPtr<ar::media::IMediaEngine> mediaEngine;
    mediaEngine.queryInterface(rtc_engine, ar::AR_IID_MEDIA_ENGINE);
    
    self.observerVideoType ^= observerType;
    
    if (mediaEngine && self.observerVideoType == 0)
    {
        mediaEngine->registerVideoFrameObserver(NULL);
        s_videoFrameObserver.mediaDataPlugin = nil;
    }
}

- (void)registerAudioRawDataObserver:(ObserverAudioType)observerType {
    ar::rtc::IRtcEngine* rtc_engine = (ar::rtc::IRtcEngine*)self.rtcKit.getNativeHandle;
    ar::util::AutoPtr<ar::media::IMediaEngine> mediaEngine;
    mediaEngine.queryInterface(rtc_engine, ar::AR_IID_MEDIA_ENGINE);
    
    NSInteger oldValue = self.observerAudioType;
    self.observerAudioType |= observerType;
    
    if (mediaEngine && oldValue == 0)
    {
        mediaEngine->registerAudioFrameObserver(&s_audioFrameObserver);
        s_audioFrameObserver.mediaDataPlugin = self;
    }
}

- (void)deregisterAudioRawDataObserver:(ObserverAudioType)observerType {
    ar::rtc::IRtcEngine* rtc_engine = (ar::rtc::IRtcEngine*)self.rtcKit.getNativeHandle;
    ar::util::AutoPtr<ar::media::IMediaEngine> mediaEngine;
    mediaEngine.queryInterface(rtc_engine, ar::AR_IID_MEDIA_ENGINE);
    
    self.observerAudioType ^= observerType;
    
    if (mediaEngine && self.observerAudioType == 0)
    {
        mediaEngine->registerAudioFrameObserver(NULL);
        s_audioFrameObserver.mediaDataPlugin = nil;
    }
}

- (void)registerPacketRawDataObserver:(ObserverPacketType)observerType {
    ar::rtc::IRtcEngine* rtc_engine = (ar::rtc::IRtcEngine*)self.rtcKit.getNativeHandle;
    
    NSInteger oldValue = self.observerPacketType;
    self.observerPacketType |= observerType;
    
    if (rtc_engine && oldValue == 0)
    {
        rtc_engine->registerPacketObserver(&s_packetObserver);
        s_packetObserver.mediaDataPlugin = self;
    }
}

- (void)deregisterPacketRawDataObserver:(ObserverPacketType)observerType {
    AR::IRtcEngine* rtc_engine = (AR::IRtcEngine*)self.rtcKit.getNativeHandle;
    
    self.observerPacketType ^= observerType;
    
    if (rtc_engine && self.observerPacketType == 0)
    {
        rtc_engine->registerPacketObserver(NULL);
        s_packetObserver.mediaDataPlugin = nil;
    }
}

- (void)setVideoRawDataFormatter:(ARVideoRawDataFormatter * _Nonnull)formatter {
    if (self.videoFormatter.type != formatter.type) {
        self.videoFormatter.type = formatter.type;
    }
    
    if (self.videoFormatter.rotationApplied != formatter.rotationApplied) {
        self.videoFormatter.rotationApplied = formatter.rotationApplied;
    }
    
    if (self.videoFormatter.mirrorApplied != formatter.mirrorApplied) {
        self.videoFormatter.mirrorApplied = formatter.mirrorApplied;
    }
}

- (ARVideoRawDataFormatter * _Nonnull)getCurrentVideoRawDataFormatter {
    return self.videoFormatter;
}

#pragma mark - Screen Capture
- (void)localSnapshot:(void (^ _Nullable)(AGImage * _Nonnull image))completion {
    self.imageBlock = completion;
    s_videoFrameObserver.getOneDidCaptureVideoFrame = true;
}

- (void)remoteSnapshotWithUid:(NSString *_Nonnull)uid image:(void (^ _Nullable)(AGImage * _Nonnull image))completion {
    self.imageBlock = completion;
    s_videoFrameObserver.getOneWillRenderVideoFrame = true;
    s_videoFrameObserver.videoFrameUid = uid;
}

- (void)yuvToUIImageWithVideoRawData:(ARVideoRawData *)data {
    
    int height = data.height;
    int yStride = data.yStride;
    
    char* yBuffer = data.yBuffer;
    char* uBuffer = data.uBuffer;
    char* vBuffer = data.vBuffer;
    
    int Len = yStride * data.height * 3/2;
    int yLength = yStride * data.height;
    int uLength = yLength / 4;
    
    unsigned char * buf = (unsigned char *)malloc(Len);
    memcpy(buf, yBuffer, yLength);
    memcpy(buf + yLength, uBuffer, uLength);
    memcpy(buf + yLength + uLength, vBuffer, uLength);
    
    unsigned char * NV12buf = (unsigned char *)malloc(Len);
    [self yuv420p_to_nv12:buf nv12:NV12buf width:yStride height:height];
    @autoreleasepool {
        [self UIImageToJpg:NV12buf width:yStride height:height rotation:data.rotation];
    }
    if(buf != NULL) {
        free(buf);
        buf = NULL;
    }
    
    if(NV12buf != NULL) {
        free(NV12buf);
        NV12buf = NULL;
    }
    
}

// AR SDK Raw Data format is YUV420P
- (void)yuv420p_to_nv12:(unsigned char*)yuv420p nv12:(unsigned char*)nv12 width:(int)width height:(int)height {
    int i, j;
    int y_size = width * height;
    
    unsigned char* y = yuv420p;
    unsigned char* u = yuv420p + y_size;
    unsigned char* v = yuv420p + y_size * 5 / 4;
    
    unsigned char* y_tmp = nv12;
    unsigned char* uv_tmp = nv12 + y_size;
    
    // y
    memcpy(y_tmp, y, y_size);
    
    // u
    for (j = 0, i = 0; j < y_size * 0.5; j += 2, i++) {
        // swtich the location of U、V，to NV12 or NV21
#if 1
        uv_tmp[j] = u[i];
        uv_tmp[j+1] = v[i];
#else
        uv_tmp[j] = v[i];
        uv_tmp[j+1] = u[i];
#endif
    }
}

- (void)UIImageToJpg:(unsigned char *)buffer width:(int)width height:(int)height rotation:(int)rotation {
    AGImage *image = [self YUVtoUIImage:width h:height buffer:buffer rotation: rotation];
    if (self.imageBlock) {
        self.imageBlock(image);
    }
}

//This is API work well for NV12 data format only.
- (AGImage *)YUVtoUIImage:(int)w h:(int)h buffer:(unsigned char *)buffer rotation:(int)rotation {
    //YUV(NV12)-->CIImage--->UIImage Conversion
    NSDictionary *pixelAttributes = @{(NSString*)kCVPixelBufferIOSurfacePropertiesKey:@{}};
    CVPixelBufferRef pixelBuffer = NULL;
    CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault,
                                          w,
                                          h,
                                          kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                                          (__bridge CFDictionaryRef)(pixelAttributes),
                                          &pixelBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer,0);
    void *yDestPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    
    // Here y_ch0 is Y-Plane of YUV(NV12) data.
    unsigned char *y_ch0 = buffer;
    unsigned char *y_ch1 = buffer + w * h;
    memcpy(yDestPlane, y_ch0, w * h);
    void *uvDestPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);

    // Here y_ch1 is UV-Plane of YUV(NV12) data.
    memcpy(uvDestPlane, y_ch1, w * h * 0.5);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    if (result != kCVReturnSuccess) {
        NSLog(@"Unable to create cvpixelbuffer %d", result);
    }
    
    // CIImage Conversion
    CIImage *coreImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext createCGImage:coreImage
                                                       fromRect:CGRectMake(0, 0, w, h)];

#if (!(TARGET_OS_IPHONE) && (TARGET_OS_MAC))
    AGImage *finalImage =  [[NSImage alloc] initWithCGImage:videoImage size:NSMakeSize(w, h)];
#else

    UIImageOrientation imageOrientation;
    switch (rotation) {
        case 0:   imageOrientation = UIImageOrientationUp; break;
        case 90:  imageOrientation = UIImageOrientationRight; break;
        case 180: imageOrientation = UIImageOrientationDown; break;
        case 270: imageOrientation = UIImageOrientationLeft; break;
        default:  imageOrientation = UIImageOrientationUp; break;
    }

    AGImage *finalImage = [[AGImage alloc] initWithCGImage:videoImage
                                                     scale:1.0
                                               orientation:imageOrientation];
#endif
    CVPixelBufferRelease(pixelBuffer);
    CGImageRelease(videoImage);
    return finalImage;
}
@end
