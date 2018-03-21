//
//  AudioController.h
//  AgoraAudioIO
//
//  Created by suleyu on 2017/12/15.
//  Copyright © 2017 Agora. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AudioMode.h"
#import "../../../../../media_sdk3/interface/objc/AgoraRtcEngineKit.h"

@interface AudioControllerMac : NSObject
- (void)registerToRtcEngine:(AgoraRtcEngineKit *)rtcEngine audioMode:(AudioMode)audioMode sampleRate:(int)sampleRate;
- (void)deregister;
- (void)pushExternalData:(void *)data length:(int)length;
- (int)readAudioData:(void *)data length:(int)length;
@end

