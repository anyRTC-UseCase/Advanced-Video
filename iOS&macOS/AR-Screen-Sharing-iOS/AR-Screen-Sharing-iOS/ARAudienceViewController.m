//
//  ARAudienceViewController.m
//  AR-Screen-Sharing-iOS
//
//  Created by 余生丶 on 2020/8/18.
//  Copyright © 2020 AR. All rights reserved.
//

#import "ARAudienceViewController.h"
#import <ARtcKit/ARtcKit.h>

/* AppID
* anyRTC 为 App 开发者签发的 App ID。每个项目都应该有一个独一无二的 App ID。如果你的开发包里没有 App ID，请从anyRTC官网(https://www.anyrtc.io)申请一个新的 App ID
*/
static NSString *appID = <#T##NSString#>;

@interface ARAudienceViewController ()<ARtcEngineDelegate>

@property (weak, nonatomic) IBOutlet UILabel *channelLabel;

@property (strong, nonatomic) ARtcEngineKit *rtcKit;

@end

@implementation ARAudienceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.channelLabel.text = @"808080";
    [self initializeRtcKit];
}

- (void)initializeRtcKit {
    //实例化ARtcEngineKit对象
    self.rtcKit = [ARtcEngineKit sharedEngineWithAppId:appID delegate:self];
    //开启视频模块
    [self.rtcKit enableVideo];
    //加入频道
    [self.rtcKit joinChannelByToken:nil channelId:@"808080" uid:nil joinSuccess:^(NSString * _Nonnull channel, NSString * _Nonnull uid, NSInteger elapsed) {
        NSLog(@"joinSuccess");
    }];
}

- (IBAction)didClickCloseButton:(id)sender {
    [self.rtcKit leaveChannel:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

//MARK: - ARtcEngineDelegate

- (void)rtcEngine:(ARtcEngineKit *_Nonnull)engine didJoinedOfUid:(NSString *_Nonnull)uid elapsed:(NSInteger)elapsed {
    //远端用户/主播加入回调
    ARtcVideoCanvas *canvas = [[ARtcVideoCanvas alloc] init];
    canvas.uid = uid;
    canvas.view = self.view;
    canvas.channelId = self.channelId;
    canvas.renderMode = ARVideoRenderModeFit;
    [self.rtcKit setupRemoteVideo:canvas];
}

- (void)rtcEngine:(ARtcEngineKit *_Nonnull)engine didOfflineOfUid:(NSString *_Nonnull)uid reason:(ARUserOfflineReason)reason {
    //远端用户（通信场景）/主播（直播场景）离开当前频道回调
}

@end
