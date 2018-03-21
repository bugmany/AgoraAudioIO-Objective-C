//
//  RoomViewController.h
//  AgoraAudioIO
//
//  Created by suleyu on 2017/12/15.
//  Copyright © 2017 Agora. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AudioOptions.h"

@class RoomViewControllerMac;
@protocol RoomVCMacDelegate
- (void)roomVCNeedClose:(RoomViewControllerMac *)roomVC;
@end

@interface RoomViewControllerMac : NSViewController
@property (copy, nonatomic) NSString *channel;
@property (assign, nonatomic) int sampleRate;
@property (assign, nonatomic) AudioCRMode audioMode;
@property (assign, nonatomic) ChannelMode channelMode;
@property (assign, nonatomic) ClientRole role;
@property (strong, nonatomic) id<RoomVCMacDelegate> delegate;
@end
