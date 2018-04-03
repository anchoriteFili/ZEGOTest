//
//  ZegoAudioLiveViewController.m
//  ZEGOTest
//
//  Created by zetafin on 2018/4/3.
//  Copyright © 2018年 赵宏亚. All rights reserved.
//

#import "ZegoAudioLiveViewController.h"
#import "ZegoAVKitManager.h"
#import <AVFoundation/AVFoundation.h>

@interface ZegoAudioLiveViewController ()<ZegoAudioLivePublisherDelegate, ZegoAudioLivePlayerDelegate, ZegoAudioRoomDelegate, ZegoAudioIMDelegate>

@end

@implementation ZegoAudioLiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
