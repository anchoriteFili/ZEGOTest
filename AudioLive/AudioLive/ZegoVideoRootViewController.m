//
//  ZegoVideoRootViewController.m
//  AudioLive
//
//  Created by zetafin on 2018/4/3.
//  Copyright © 2018年 赵宏亚. All rights reserved.
//

#import "ZegoVideoRootViewController.h"
#import "ZegoSettings.h"
#import "ZegoAVKitManager.h"

@interface ZegoVideoRootViewController ()

@property (weak, nonatomic) IBOutlet UITextField *sessionIdText;
@property (weak, nonatomic) IBOutlet UIButton *videoTalkButton;
@property (nonatomic,strong) UITapGestureRecognizer *tapGesture;

@end

@implementation ZegoVideoRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.videoTalkButton.enabled = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldTextDidChange) name:UITextFieldTextDidChangeNotification object:self.sessionIdText];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSString *title = [NSString stringWithFormat:@"AudioLive(%@)", [ZegoSettings sharedInstance].appTypeList[[ZegoAudioLive appType]]];
    self.navigationItem.title = NSLocalizedString(title, nil);
}

- (void)textFieldTextDidChange
{
    if(self.sessionIdText.text.length > 0 )
        self.videoTalkButton.enabled = YES;
    else
        self.videoTalkButton.enabled = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onTapTableView:(UIGestureRecognizer *)gesture
{
    [self.view endEditing:YES];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (self.tapGesture == nil)
        self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapTableView:)];
    
    [self.view addGestureRecognizer:self.tapGesture];
}


- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (text.length == 0)
        self.videoTalkButton.enabled = NO;
    else
        self.videoTalkButton.enabled = YES;
    
    if ([text isEqualToString:@"\n"])
    {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"presentVideoTalk"])
    {
//        ZegoAudioLiveViewController *viewController = (ZegoAudioLiveViewController *)segue.destinationViewController;
//        viewController.sessionID = self.sessionIdText.text;
    }
}


@end
