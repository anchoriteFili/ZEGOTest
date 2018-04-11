//
//  ZegoAudioLiveViewController.m
//  AudioLive
//
//  Created by zetafin on 2018/4/10.
//  Copyright © 2018年 赵宏亚. All rights reserved.
//

#import "ZegoAudioLiveViewController.h"
#import "ZegoAVKitManager.h"
#import <AVFoundation/AVFoundation.h>

@interface ZegoAudioLiveViewController () <ZegoAudioLivePublisherDelegate, ZegoAudioLivePlayerDelegate, ZegoAudioRoomDelegate, ZegoAudioIMDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *mutedButton; // 静音按钮
@property (weak, nonatomic) IBOutlet UILabel *tipsLabel; // 开始登陆房间label
@property (weak, nonatomic) IBOutlet UIButton *publishButton; // 开始播放
@property (weak, nonatomic) IBOutlet UIButton *messageButton; // 广播测试
@property (weak, nonatomic) IBOutlet UIButton *micButton; // 关闭麦克风


@property (nonatomic,strong) NSMutableArray *logArray; // 日志记录
@property (nonatomic,strong) NSMutableArray *streamList; // 播放流数

@property (nonatomic,strong) UIColor *defaultButtonColor; // 默认按钮的颜色
@property (nonatomic,assign) BOOL enableSpeaker; // 能否说话
@property (nonatomic,assign) BOOL isPublished; // 是否开始直播
@property (nonatomic,assign) BOOL enableMic; // 是否麦克风

@end

@implementation ZegoAudioLiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 获取 SDK 支持的最大同时播放流数
    int maxCount = [ZegoAudioRoomApi getMaxPlayChannelCount];
    self.logArray = [NSMutableArray array];
    self.streamList = [NSMutableArray arrayWithCapacity:maxCount];
    
    // 检查麦克风权限
    BOOL audioAuthorization = [self checkAudioAuthorization];
    if (audioAuthorization == NO) {
        [self showAuthorizationAlert:NSLocalizedString(@"直播视频,访问麦克风", nil) title:NSLocalizedString(@"需要访问麦克风", nil)];
    }
    
    // 手动直播是否打开
    if ([ZegoAudioLive manualPublish]) {
        self.publishButton.hidden = NO;
    } else {
        self.publishButton.hidden = YES;
    }
    
    self.publishButton.enabled = NO; // 开始播放按钮不可点击
    self.messageButton.enabled = NO; // 广播测试按钮不可点击
    self.mutedButton.enabled = NO; // 静音按钮不可点击
    [[ZegoAudioLive api] setUserStateUpdate:YES]; // 设置用户进入/退出房间是否通知其他用户
    
    [self setupLiveKit]; // 设置api中所有的代理方法
    self.enableMic = YES; // 设置麦克风可以点击

    self.tableView.tableFooterView = [[UIView alloc] init]; // tableview的底部高度
    
    [self addLogString:[NSString stringWithFormat:NSLocalizedString(@"开始加入session: %@", nil),self.sessionID]];
    
    self.tipsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"开始登录房间: %@", nil),self.sessionID];
    
    // 监听电话事件
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionWasInterrupted:) name:AVAudioSessionInterruptionNotification object:nil];
    
    // 进入房间
    [[ZegoAudioLive api] loginRoom:self.sessionID completionBlock:^(int errorCode) {
        
        if (errorCode != 0) { // 如果进入房间失败
            [self addLogString:[NSString stringWithFormat:NSLocalizedString(@"加入session失败: %d", nil), errorCode]];
            self.tipsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"登录房间失败: %d", nil),errorCode];
        } else { // 如果进入房间成功
            self.mutedButton.enabled = YES;
            self.publishButton.enabled = YES;
            self.messageButton.enabled = YES;
            self.micButton.enabled = YES;
            
            [self addLogString:[NSString stringWithFormat:NSLocalizedString(@"加入session成功", nil)]];
            self.tipsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"登录房间成功", nil)];
        }
    }];
}

#pragma mark 检查麦克风权限
- (BOOL)checkAudioAuthorization {
    
    AVAuthorizationStatus audioAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    
    // 如果权限是拒绝的，或者受限制的
    if (audioAuthStatus == AVAuthorizationStatusDenied || audioAuthStatus == AVAuthorizationStatusRestricted) {
        return NO;
    }
    // 如果有权限
    if (audioAuthStatus == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
        }];
    }
    
    return YES;
}

#pragma mark 显示提示窗
- (void)showAuthorizationAlert:(NSString *)message title:(NSString *)title {
    
    UIAlertController *alerController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"取消", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    UIAlertAction *settingAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"设置权限", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 进入设置页面
        [self openSetting];
    }];
    
    [alerController addAction:settingAction];
    [alerController addAction:cancelAction];
    
    alerController.preferredAction = settingAction;
    [self presentViewController:alerController animated:YES completion:nil];
}

#pragma mark 进入设置页面
- (void)openSetting {
    NSURL *settingURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication] canOpenURL:settingURL]) {
        [[UIApplication sharedApplication] openURL:settingURL];
    }
}

#pragma mark 各个代理的赋值
- (void)setupLiveKit {
    [[ZegoAudioLive api] setAudioRoomDelegate:self];
    [[ZegoAudioLive api] setAudioRoomDelegate:self];
    [[ZegoAudioLive api] setAudioPublisherDelegate:self];
    [[ZegoAudioLive api] setAudioIMDelegate:self];
}

#pragma mark 添加日志
- (void)addLogString:(NSString *)logString {
    
    if (logString.length != 0) {
        NSString *totalString = [NSString stringWithFormat:@"%@ %@", [self getCurrentTime], logString];
        [self.logArray insertObject:totalString atIndex:0];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"logUpdateNotification" object:self userInfo:nil];
    }
}

#pragma mark 获取当前时间
- (NSString *)getCurrentTime {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"HH-mm-ss:SSS";
    return [formatter stringFromDate:[NSDate date]];
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
