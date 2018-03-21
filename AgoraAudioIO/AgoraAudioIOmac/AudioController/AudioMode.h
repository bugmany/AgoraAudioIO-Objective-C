//
//  AudioMode.h
//  AgoraAudioIO
//
//  Created by suleyu on 2017/12/15.
//  Copyright © 2017 Agora. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_OPTIONS(NSUInteger, AudioMode) {
    AudioMode_Normal = 0,
    AudioMode_SelfCapture = 1 << 0,
    AudioMode_SelfRender = 1 << 1
};

