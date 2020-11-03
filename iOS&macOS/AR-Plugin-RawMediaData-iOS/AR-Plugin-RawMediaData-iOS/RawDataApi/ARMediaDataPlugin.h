//
//  ARMediaDataPlugin.h
//  AR-Plugin-RawMediaData-iOS
//
//  Created by 余生丶 on 2020/10/22.
//

#import <Foundation/Foundation.h>
#import "ARVideoRawData.h"

#if (!(TARGET_OS_IPHONE) && (TARGET_OS_MAC))
#import <Cocoa/Cocoa.h>
typedef NSImage AGImage;
#else
#import <UIKit/UIKit.h>
typedef UIImage AGImage;
#endif

typedef NS_OPTIONS(NSInteger, ObserverVideoType) {
    ObserverVideoTypeCaptureVideo                    = 1 << 0,
    ObserverVideoTypeRenderVideo                     = 1 << 1,
    ObserverVideoTypePreEncodeVideo            = 1 << 2
};

typedef NS_OPTIONS(NSInteger, ObserverAudioType) {
    ObserverAudioTypeRecordAudio                     = 1 << 0,
    ObserverAudioTypePlaybackAudio                   = 1 << 1,
    ObserverAudioTypePlaybackAudioFrameBeforeMixing  = 1 << 2,
    ObserverAudioTypeMixedAudio                      = 1 << 3
};

typedef NS_OPTIONS(NSInteger, ObserverPacketType) {
    ObserverPacketTypeSendAudio                      = 1 << 0,
    ObserverPacketTypeSendVideo                      = 1 << 1,
    ObserverPacketTypeReceiveAudio                   = 1 << 2,
    ObserverPacketTypeReceiveVideo                   = 1 << 3
};

@class ARtcEngineKit;
@class ARMediaDataPlugin;
@protocol ARVideoDataPluginDelegate <NSObject>
@optional
- (ARVideoRawData * _Nonnull)mediaDataPlugin:(ARMediaDataPlugin * _Nonnull)mediaDataPlugin didCapturedVideoRawData:(ARVideoRawData * _Nonnull)videoRawData;
- (ARVideoRawData * _Nonnull)mediaDataPlugin:(ARMediaDataPlugin * _Nonnull)mediaDataPlugin willRenderVideoRawData:(ARVideoRawData * _Nonnull)videoRawData ofUid:(NSString *_Nonnull)uid;
- (ARVideoRawData * _Nonnull)mediaDataPlugin:(ARMediaDataPlugin * _Nonnull)mediaDataPlugin willPreEncodeVideoRawData:(ARVideoRawData * _Nonnull)videoRawData;
@end

@protocol ARAudioDataPluginDelegate <NSObject>
@optional
- (ARAudioRawData * _Nonnull)mediaDataPlugin:(ARMediaDataPlugin * _Nonnull)mediaDataPlugin didRecordAudioRawData:(ARAudioRawData * _Nonnull)audioRawData;
- (ARAudioRawData * _Nonnull)mediaDataPlugin:(ARMediaDataPlugin * _Nonnull)mediaDataPlugin willPlaybackAudioRawData:(ARAudioRawData * _Nonnull)audioRawData;
- (ARAudioRawData * _Nonnull)mediaDataPlugin:(ARMediaDataPlugin * _Nonnull)mediaDataPlugin willPlaybackBeforeMixingAudioRawData:(ARAudioRawData * _Nonnull)audioRawData ofUid:(NSString *_Nonnull)uid;
- (ARAudioRawData * _Nonnull)mediaDataPlugin:(ARMediaDataPlugin * _Nonnull)mediaDataPlugin didMixedAudioRawData:(ARAudioRawData * _Nonnull)audioRawData;
@end

@protocol ARPacketDataPluginDelegate <NSObject>
@optional
- (ARPacketRawData * _Nonnull)mediaDataPlugin:(ARMediaDataPlugin * _Nonnull)mediaDataPlugin willSendAudioPacket:(ARPacketRawData * _Nonnull)audioPacket;
- (ARPacketRawData * _Nonnull)mediaDataPlugin:(ARMediaDataPlugin * _Nonnull)mediaDataPlugin willSendVideoPacket:(ARPacketRawData * _Nonnull)videoPacket;

- (ARPacketRawData * _Nonnull)mediaDataPlugin:(ARMediaDataPlugin * _Nonnull)mediaDataPlugin didReceivedAudioPacket:(ARPacketRawData * _Nonnull)audioPacket;
- (ARPacketRawData * _Nonnull)mediaDataPlugin:(ARMediaDataPlugin * _Nonnull)mediaDataPlugin didReceivedVideoPacket:(ARPacketRawData * _Nonnull)videoPacket;
@end

@interface ARMediaDataPlugin : NSObject
@property (nonatomic, weak) id<ARVideoDataPluginDelegate> _Nullable videoDelegate;
@property (nonatomic, weak) id<ARAudioDataPluginDelegate> _Nullable audioDelegate;
@property (nonatomic, weak) id<ARPacketDataPluginDelegate> _Nullable packetDelegate;

+ (instancetype _Nonnull)mediaDataPluginWithRtcKit:(ARtcEngineKit * _Nonnull)rtcKit;

- (void)registerVideoRawDataObserver:(ObserverVideoType)observerType;
- (void)deregisterVideoRawDataObserver:(ObserverVideoType)observerType;

- (void)registerAudioRawDataObserver:(ObserverAudioType)observerType;
- (void)deregisterAudioRawDataObserver:(ObserverAudioType)observerType;

- (void)registerPacketRawDataObserver:(ObserverPacketType)observerType;
- (void)deregisterPacketRawDataObserver:(ObserverPacketType)observerType;

- (void)setVideoRawDataFormatter:(ARVideoRawDataFormatter * _Nonnull)formatter;
- (ARVideoRawDataFormatter * _Nonnull)getCurrentVideoRawDataFormatter;

// you can call following methods before set videoDelegate
- (void)localSnapshot:(void (^ _Nullable)(AGImage * _Nonnull image))completion;
- (void)remoteSnapshotWithUid:(NSString *_Nonnull)uid image:(void (^ _Nullable)(UIImage * _Nonnull image))completion;
@end


