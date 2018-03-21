//
//  AudioRender.h
//  Audio-Source
//
//  Created by CavanSu on 12/11/2017.
//  Copyright © 2017 Agora. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AudioRenderMac;

@protocol AudioRenderMacDelegate <NSObject>

- (int)audioRender:(AudioRenderMac *)audioRender readRenderData:(void *)data size:(int)size;

@end

@interface AudioRenderMac : NSObject

@property (nonatomic, weak) id<AudioRenderMacDelegate> delegate;

- (instancetype)initWithSampleRate:(int)sampleRate channelCount:(int)channelCount;

- (void)startRender;

- (void)stopRender;

@end
