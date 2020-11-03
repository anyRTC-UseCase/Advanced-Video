//
//  ARAudienceViewController.m
//  AR-Screen-Sharing-iOS
//
//  Created by 余生丶 on 2020/8/18.
//  Copyright © 2020 AR. All rights reserved.
//

#import "ARAudienceViewController.h"
#import <ARtcKit/ARtcKit.h>

@interface ARAudienceViewController ()<ARtcEngineDelegate>

@property (weak, nonatomic) IBOutlet UILabel *channelLabel;

@property (strong, nonatomic) ARtcEngineKit *rtcKit;

@end

@implementation ARAudienceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.channelLabel.text = self.channelId;
}

- (void)initializeRtcKit {
    //实例化ARtcEngineKit对象
    self.rtcKit = [ARtcEngineKit sharedEngineWithAppId:@"57f16e995cf36741e2ff2c97875a0944" delegate:self];
    //开启视频模块
    [self.rtcKit enableVideo];
    //加入频道
    [self.rtcKit joinChannelByToken:nil channelId:self.channelId uid:nil joinSuccess:^(NSString * _Nonnull channel, NSString * _Nonnull uid, NSInteger elapsed) {
        NSLog(@"joinSuccess");
    }];
}

//MARK: - ARtcEngineDelegate

- (void)rtcEngine:(ARtcEngineKit *_Nonnull)engine didJoinedOfUid:(NSString *_Nonnull)uid elapsed:(NSInteger)elapsed {
    //远端用户/主播加入回调
    ARtcVideoCanvas *canvas = [[ARtcVideoCanvas alloc] init];
    canvas.uid = uid;
    canvas.view = self.view;
    canvas.channelId = self.channelId;
    [self.rtcKit setupRemoteVideo:canvas];
}

- (void)rtcEngine:(ARtcEngineKit *_Nonnull)engine didOfflineOfUid:(NSString *_Nonnull)uid reason:(ARUserOfflineReason)reason {
    //远端用户（通信场景）/主播（直播场景）离开当前频道回调
}

@end
