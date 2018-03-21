//
//  AudioCapture.h
//  AudioCapture
//
//  Created by CavanSu on 10/11/2017.
//  Copyright © 2017 Agora. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AudioCapture;

@protocol AudioCaptureDelegate <NSObject>

- (void)audioCapture:(AudioCapture *)audioCapture
                  didCaptureData:(unsigned char *)data
                     bytesLength:(int)bytesLength;
@end

@interface AudioCapture : NSObject

@property (nonatomic, weak) id<AudioCaptureDelegate> delegate;

- (instancetype)initWithSampleRate:(int)sampleRate channelCount:(int)channelCount;

- (void)startCapture;

- (void)stopCapture;

@end
