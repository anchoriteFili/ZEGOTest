//
//  ZegoAudioLiveViewController.m
//  AudioLive
//
//  Created by zetafin on 2018/4/10.
//  Copyright © 2018年 赵宏亚. All rights reserved.
//

#import "ZegoAudioLiveViewController.h"
#import "ZegoAVKitManager.h"
#import "ZegoSettings.h"
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

#pragma mark 开始直播点击
- (IBAction)onPublishButton:(UIButton *)sender {
    
    if (self.isPublished) { // 如果是直播状态
        
        // 停止直播
        [[ZegoAudioLive api] stopPublish];
        [self.publishButton setTitle:NSLocalizedString(@"开始直播", nil) forState:UIControlStateNormal];
        self.isPublished = NO;
        
        // 删除流
        for (ZegoAudioStream *audioStream in self.streamList) {
            
            if ([audioStream.userID isEqualToString:[ZegoSettings sharedInstance].userID]) {
                [self.streamList removeObject:audioStream];
                break;
            }
            [self.tableView reloadData];
        }
    } else { // 如果是停播状态
        BOOL result = [[ZegoAudioLive api] startPublish];
        
        if (result == NO) {
            self.tipsLabel.text = NSLocalizedString(@"开播失败，直播流超过上线", nil);
        } else {
            [self.publishButton setTitle:NSLocalizedString(@"停止直播", nil) forState:UIControlStateNormal];
            self.publishButton.enabled = NO;
        }
    }
}

#pragma mark 关闭按钮点击，关闭房间
- (IBAction)closeView:(UIButton *)sender {
    
    [[ZegoAudioLive api] logoutRoom];
    [self.streamList removeAllObjects];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark 静音按钮
- (IBAction)onMutedButton:(UIButton *)sender {
    
    if (self.enableSpeaker) {
        self.enableSpeaker = NO;
        [self.mutedButton setTitleColor:self.defaultButtonColor forState:UIControlStateNormal];
    } else {
        self.enableSpeaker = YES;
        [self.mutedButton setTitleColor:self.defaultButtonColor forState:UIControlStateNormal];
    }
    //
    [[ZegoAudioLive api] enableSpeaker:self.enableSpeaker];
}

#pragma mark 广播测试按钮点击事件
- (IBAction)onMessageButton:(UIButton *)sender {
    
    NSString *content = [NSString stringWithFormat:@"%@ hand shake", [self getCurrentTime]];
    
    
    [[ZegoAudioLive api] sendRoomMessage:content type:ZEGO_TEXT category:ZEGO_CHAT priority:ZEGO_DEFAULT completion:^(int errorCode, NSString *roomId, unsigned long long messageId) {
        if (errorCode == 0) {
            [self addLogString:@"message send success"];
        }
    }];
}

#pragma mark 关闭麦克风按钮点击事件
- (IBAction)onMicButton:(UIButton *)sender {
    
    if (self.enableMic) {
        self.enableMic = NO;
        [self.micButton setTitle:NSLocalizedString(@"打开麦克风", nil) forState:UIControlStateNormal];
        
        [self.micButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    } else {
        self.enableMic = YES;
        [self.micButton setTitle:NSLocalizedString(@"关闭麦克风", nil) forState:UIControlStateNormal];
        [self.micButton setTitleColor:self.defaultButtonColor forState:UIControlStateNormal];
    }
    
    // 打开关闭麦克风方法
    [[ZegoAudioLive api] enableMic:self.enableMic];
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

#pragma mark 通知方法
- (void)audioSessionWasInterrupted:(NSNotification *)notification {
    
    if (AVAudioSessionInterruptionTypeBegan == [notification.userInfo[AVAudioSessionInterruptionTypeKey] intValue]) {
        NSLog(@"开始录音");
        
    } else if (AVAudioSessionInterruptionTypeEnded == [notification.userInfo[AVAudioSessionInterruptionTypeKey] intValue]) {
        NSLog(@"结束录音");
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
}

#pragma mark ********** 相关代理方法 **********

#pragma mark 推流状态更新
- (void)onPublishStateUpdate:(int)stateCode streamID:(NSString *)streamID streamInfo:(NSDictionary *)info {
    
    if (stateCode == 0) {
        [self addLogString:[NSString stringWithFormat:NSLocalizedString(@"推流成功: %@", nil), streamID]];
        
        self.tipsLabel.text = NSLocalizedString(@"推流成功", nil);
        if ([ZegoAudioLive manualPublish]) {
            self.publishButton.enabled = YES;
            self.isPublished = YES;
        }
        
        ZegoAudioStream *audioStream = [ZegoAudioStream new];
        audioStream.streamID = streamID;
        audioStream.userName = [ZegoSettings sharedInstance].userName;
        
        [self.streamList addObject:audioStream];
        [self.tableView reloadData];
    } else {
        
        if ([ZegoAudioLive manualPublish]) {
            self.publishButton.enabled = YES;
            self.isPublished = NO;
            
            [self.publishButton setTitle:NSLocalizedString(@"开始直播", nil) forState:UIControlStateNormal];
        }
        
        [self addLogString:[NSString stringWithFormat:NSLocalizedString(@"推流失败: %@, error:%d", nil), streamID, stateCode]];
        self.tipsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"推流失败:%d", nil), stateCode];
    }
}

#pragma mark 播放流事件
- (void)onPlayStateUpdate:(int)stateCode stream:(ZegoAudioStream *)stream {
    if (stateCode == 0)
    {
        [self addLogString:[NSString stringWithFormat:NSLocalizedString(@"拉流成功: %@", nil), stream.streamID]];
        self.tipsLabel.text = NSLocalizedString(@"拉流成功", nil);
    }
    else
    {
        [self addLogString:[NSString stringWithFormat:NSLocalizedString(@"拉流失败: %@, error: %d", nil), stream.streamID, stateCode]];
        self.tipsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"拉流失败: %d", nil), stateCode];
    }
}

#pragma mark 观看质量更新
- (void)onPlayQualityUpate:(NSString *)streamID quality:(ZegoApiPlayQuality)quality {
    
    NSLog(@"onPlayQualityUpate, streamID: %@, quality: %d, audiobiterate: %fkb",streamID, quality.quality, quality.akbps);
}


#pragma mark - ZegoAudioRoomDelegate

#pragma mark 与server断开通知
- (void)onDisconnect:(int)errorCode roomID:(NSString *)roomID {
    
    [self addLogString:[NSString stringWithFormat:NSLocalizedString(@"连接房间失败 %d", nil), errorCode]];
}

#pragma mark  流更新消息，此时sdk会开始拉流/停止拉流
- (void)onStreamUpdated:(ZegoAudioStreamType)type stream:(ZegoAudioStream *)stream {
    
    if (type == ZEGO_AUDIO_STREAM_ADD) { /** 音频流新增 */
        
        BOOL alreadyHave = NO;
        
        for (ZegoAudioStream *playSteam in self.streamList) {
            
            if ([playSteam.streamID isEqualToString:stream.streamID]) {
                alreadyHave = YES;
                break;
            }
        }
        
        [self addLogString:[NSString stringWithFormat:NSLocalizedString(@"新增流:%@", nil), stream.streamID]];
        self.tipsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"用户%@进入，开始拉流", nil), stream.userID];
        if (alreadyHave == NO) {
            [self.streamList addObject:stream];
        }
    } else { // 删除流
        
        for (ZegoAudioStream *playStream in self.streamList) {
            
            if ([playStream.streamID isEqualToString:stream.streamID]) {
                
                [self addLogString:[NSString stringWithFormat:NSLocalizedString(@"删除流:%@", nil), stream.streamID]];
                
                self.tipsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"用户%@退出，停止拉流", nil), stream.userID];
                
                [self.streamList removeObject:playStream];
                break;
            }
        }
    }
    [self.tableView reloadData];
}

#pragma mark 房间成员更新回调
- (void)onUserUpdate:(NSArray<ZegoUserState *> *)userList updateType:(ZegoUserUpdateType)type {
    
    if (type == ZEGO_UPDATE_TOTAL) { // 全部更新
        [self addLogString:NSLocalizedString(@"用户列表已全量更新", nil)];
    } else if (type == ZEGO_UPDATE_INCREASE) {
        [self addLogString:NSLocalizedString(@"用户列表增量更新", nil)];
    }
    
    for (ZegoUserState *user in userList) {
        
        if (user.updateFlag == ZEGO_USER_ADD) { // 新增
            [self addLogString:[NSString stringWithFormat:NSLocalizedString(@"%@ 用户进入房间", nil), user.userID]];
        } else if (user.updateFlag == ZEGO_USER_DELETE) { // 删除
            [self addLogString:[NSString stringWithFormat:NSLocalizedString(@"用户离开房间", user.userID)]];
        }
    }
}

#pragma mark 收到房间的广播消息
- (void)onRecvAudioRoomMessage:(NSString *)roomId messageList:(NSArray<ZegoRoomMessage *> *)messageList {
    
    for (ZegoRoomMessage *message in messageList) {
        [self addLogString:[NSString stringWithFormat:@"%@ said: %@", message.fromUserId, message.content]];
    }
}

@end
