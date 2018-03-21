//
//  AudioRender.h
//  Audio-Source
//
//  Created by CavanSu on 12/11/2017.
//  Copyright © 2017 Agora. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AudioRender;

@protocol AudioRenderDelegate <NSObject>

- (int)audioRender:(AudioRender *)audioRender
      didRenderData:(unsigned char *)data
         bytesLength:(int)bytesLength;
@end

@interface AudioRender : NSObject

@property (nonatomic, weak) id<AudioRenderDelegate> delegate;

- (instancetype)initWithSampleRate:(int)sampleRate channelCount:(int)channelCount;

- (void)startRender;

- (void)stopRender;

@end
