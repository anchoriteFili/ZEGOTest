//
//  ZegoAVKitManager.h
//  AudioLive
//
//  Created by zetafin on 2018/4/3.
//  Copyright © 2018年 赵宏亚. All rights reserved.
//

#pragma once

#import <ZegoAudioRoom/ZegoAudioRoom.h>

typedef enum : NSUInteger {
    ZegoAppTypeUDP      = 0,    // 国内版
    ZegoAppTypeI18N     = 1,    // 国际版
    ZegoAppTypeCustom   = 2,    // 用户自定义
} ZegoAppType;

@interface ZegoAudioLive : NSObject



@end
