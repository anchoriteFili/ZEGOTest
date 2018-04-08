//
//  ZegoSettings.h
//  AudioLive
//
//  Created by zetafin on 2018/4/3.
//  Copyright © 2018年 赵宏亚. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZegoAVKitManager.h"

@interface ZegoSettings : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, copy) NSString *userID;
@property (nonatomic, copy) NSString *userName;

@property (nonatomic, readonly) NSArray *appTypeList;

- (void)cleanLocalUser;

- (BOOL)isDeviceiOS7;


@end
