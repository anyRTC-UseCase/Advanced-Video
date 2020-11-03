//
//  SampleHandler.m
//  AR-Screen-Sharing-iOS-Broadcast
//
//  Created by 余生丶 on 2020/8/17.
//  Copyright © 2020 AR. All rights reserved.
//


#import "SampleHandler.h"
#import <ARtcKit/ARtcEngineKit.h>

static ARtcEngineKit *rtcKit;
//MARK: - 配置开发者信息
/* AppID
* anyRTC 为 App 开发者签发的 App ID。每个项目都应该有一个独一无二的 App ID。如果你的开发包里没有 App ID，请从anyRTC官网(https://www.anyrtc.io)申请一个新的 App ID
*/
static NSString *appId = <#T##String#>;

@interface SampleHandler()<ARtcEngineDelegate>

@end

@implementation SampleHandler

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
    [self initializationRtcEnginKit];
}

- (void)broadcastPaused {
    // User has requested to pause the broadcast. Samples will stop being delivered.
}

- (void)broadcastResumed {
    // User has requested to resume the broadcast. Samples delivery will resume.
}

- (void)broadcastFinished {
    // User has requested to finish the broadcast.
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    switch (sampleBufferType) {
        case RPSampleBufferTypeVideo:
            // 处理视频数据
        {
            CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            if (pixelBuffer) {
                CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                ARVideoFrame *videoFrame = [[ARVideoFrame alloc] init];
                videoFrame.format = 12;
                videoFrame.time = timestamp;
                videoFrame.textureBuf = pixelBuffer;
                videoFrame.rotation = [self getRotateByBuffer:sampleBuffer];
                [rtcKit pushExternalVideoFrame:videoFrame];
            }
        }
            break;
        case RPSampleBufferTypeAudioApp:
            // 处理音频数据，音频由App产生
            [rtcKit pushExternalAudioFrameSampleBuffer:sampleBuffer type:ARAudioTypeApp];
            break;
        case RPSampleBufferTypeAudioMic:
            // 处理音频数据，音频由麦克风产生
            [rtcKit pushExternalAudioFrameSampleBuffer:sampleBuffer type:ARAudioTypeMic];
            break;
        default:
            break;
    }
}

//MARK : - RTMeetEngine

- (void)initializationRtcEnginKit{
    //实例化一个ARtcEngineKit对象
    rtcKit = [ARtcEngineKit sharedEngineWithAppId:appId delegate:self];
    [rtcKit setChannelProfile:ARChannelProfileiveBroadcasting];
    [rtcKit setClientRole:ARClientRoleBroadcaster];
    //开启视频模块
    [rtcKit enableVideo];
    [rtcKit enableLocalAudio:NO];
    //配置外部视频源
    [rtcKit setExternalVideoSource:YES useTexture:YES pushMode:YES];
    //视频编码配置
    ARVideoEncoderConfiguration *config = [[ARVideoEncoderConfiguration alloc] init];
    config.dimensions = CGSizeMake(540, 960);
    config.bitrate = 1000;
    config.frameRate = 24;
    config.orientationMode = ARVideoOutputOrientationModeAdaptative;
    [rtcKit setVideoEncoderConfiguration:config];
    //设置音频编码配置
    [rtcKit setAudioProfile:ARAudioProfileMusicStandard scenario:ARAudioScenarioDefault];
    //音频自采集
    [rtcKit enableExternalAudioSourceWithSampleRate:48000 channelsPerFrame:2];
    //禁止接收所有音视频流
    [rtcKit muteAllRemoteVideoStreams:YES];
    [rtcKit muteAllRemoteAudioStreams:YES];
    
    [rtcKit joinChannelByToken:nil channelId:@"808080" uid:nil joinSuccess:^(NSString * _Nonnull channel, NSString * _Nonnull uid, NSInteger elapsed) {
        NSLog(@"joinSuccess");
    }];
}

//MARK: - ARtcEngineDelegate

- (void)rtcEngine:(ARtcEngineKit *_Nonnull)engine didJoinedOfUid:(NSString *_Nonnull)uid elapsed:(NSInteger)elapsed {
    
}

- (void)rtcEngine:(ARtcEngineKit *_Nonnull)engine didOfflineOfUid:(NSString *_Nonnull)uid reason:(ARUserOfflineReason)reason {
    
}

//MARK: - other


/**获取影像的方向 计算需旋转角度   1  ——  */
- (CGFloat)getRotateByBuffer:(CMSampleBufferRef)sampleBuffer{
   CGFloat rotate = 270;
    if (@available(iOS 11.1, *)) {
        /*
         1.1以上支持自动旋转
         IOS 11.0系统 编译RPVideoSampleOrientationKey会bad_address
         Replaykit bug：api说ios 11 支持RPVideoSampleOrientationKey 但是 却存在bad_address的情况 代码编译执行会报错bad_address 即使上面@available(iOS 11.1, *)也无效
         解决方案：Link Binary With Libraries  -->Replaykit  Request-->Option
        */
        CFStringRef RPVideoSampleOrientationKeyRef = (__bridge CFStringRef)RPVideoSampleOrientationKey;
        NSNumber *orientation = (NSNumber *)CMGetAttachment(sampleBuffer, RPVideoSampleOrientationKeyRef,NULL);
        switch ([orientation integerValue]) {
                //竖屏时候
                //SDK内部会做图像大小自适配(不会变形) 所以上层只要控制横屏时候的影像旋转的问题
            case kCGImagePropertyOrientationUp:{
                rotate = 0;
            }
                break;
            case kCGImagePropertyOrientationDown:{
                rotate = 180;
                break;
            }
            case kCGImagePropertyOrientationLeft: {
                //静音键那边向上 所需转90度
                rotate = 90;
            }
                break;
            case kCGImagePropertyOrientationRight:{
                //关机键那边向上 所需转270
                rotate = 270;
            }
                break;
            default:
                break;
        }
    }
    return rotate;
}


@end
