//
//  ARBroadcastViewController.m
//  AR-Screen-Sharing-iOS
//
//  Created by 余生丶 on 2020/8/17.
//  Copyright © 2020 AR. All rights reserved.
//

#import "ARBroadcastViewController.h"
#import <ReplayKit/ReplayKit.h>

@interface ARBroadcastViewController ()<RPBroadcastActivityViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *rotatingView;

@property (nonatomic, strong) RPSystemBroadcastPickerView * broadPickerView;
//iOS 10.0
@property (nonatomic, strong) RPBroadcastActivityViewController *broadcastAVC;
@property (nonatomic, strong) RPBroadcastController *broadcastVc;
@end

@implementation ARBroadcastViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.duration = 1.5;
    animation.toValue = [NSNumber numberWithFloat:M_PI * 2];
    animation.repeatCount = MAXFLOAT;
    animation.removedOnCompletion = NO;
    [self.rotatingView.layer addAnimation:animation forKey:@""];
}

- (IBAction)didClickRecordButton:(id)sender {
    if (@available(iOS 12, *)) {
        if (!self.broadPickerView) {
            self.broadPickerView = [[RPSystemBroadcastPickerView alloc] initWithFrame:CGRectZero];
            self.broadPickerView.preferredExtension = @"com.AR-Screen-Sharing-iOS.BroadcastUpload";
            self.broadPickerView.showsMicrophoneButton = YES;
            [self.view addSubview:self.broadPickerView];
        }
        
        for (UIView *subView in self.broadPickerView.subviews) {
            if ([subView isKindOfClass:[UIButton class]]) {
                [(UIButton *)subView sendActionsForControlEvents:UIControlEventAllTouchEvents];
                break;
            }
        }
    } else {
#if 1
        //10.0以上 应用内 - 无导航
        [RPBroadcastActivityViewController loadBroadcastActivityViewControllerWithHandler:^(RPBroadcastActivityViewController * _Nullable broadcastActivityViewController, NSError * _Nullable error) {
            
            self.broadcastAVC = broadcastActivityViewController;
            self.broadcastAVC.delegate = self;
            [self presentViewController:self.broadcastAVC animated:YES completion:nil];
        }];
#else
        //iOS 11.0 10.0基础上添加新的接口、系统级，(控制面板 -> 上滑 -> 长按录制 -> 选择app)
        [RPBroadcastActivityViewController loadBroadcastActivityViewControllerWithPreferredExtension:@"com.AR-Screen-Sharing-iOS.BroadcastUpload" handler:^(RPBroadcastActivityViewController * _Nullable broadcastActivityViewController, NSError * _Nullable error) {
            
        }];
#endif
    }
}

- (IBAction)didClickCloseButton:(id)sender {
    if (self.broadcastVc) {
        [self.broadcastVc finishBroadcastWithHandler:^(NSError * _Nullable error) {
            NSLog(@"finish");
        }];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

//MARK: - RPBroadcastActivityViewControllerDelegate 10.0

- (void)broadcastActivityViewController:(RPBroadcastActivityViewController *)broadcastActivityViewController didFinishWithBroadcastController:(nullable RPBroadcastController *)broadcastController error:(nullable NSError *)error API_AVAILABLE(ios(10.0), tvos(10.0)) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [broadcastActivityViewController dismissViewControllerAnimated:YES completion:nil];
    });
      
    [broadcastController startBroadcastWithHandler:^(NSError * _Nullable error) {

    }];
    self.broadcastVc = broadcastController;
}

@end
