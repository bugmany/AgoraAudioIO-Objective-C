//
//  AudioCapture.h
//  AudioCapture
//
//  Created by CavanSu on 10/11/2017.
//  Copyright © 2017 Agora. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AudioCaptureMac;

@protocol AudioCaptureMacDelegate <NSObject>

- (void)audioCapture:(AudioCaptureMac *)audioCapture
                  didCaptureData:(unsigned char *)data
                     bytesLength:(int)bytesLength;
@end

@interface AudioCaptureMac : NSObject

@property (nonatomic, weak) id<AudioCaptureMacDelegate> delegate;

- (instancetype)initWithSampleRate:(int)sampleRate channelCount:(int)channelCount;

- (void)startCapture;

- (void)stopCapture;

@end
