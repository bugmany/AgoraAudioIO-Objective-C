//
//  AudioController.m
//  AudioCapture
//
//  Created by CavanSu on 10/11/2017.
//  Copyright © 2017 Agora. All rights reserved.
//

#import "AudioController.h"
#import "AudioCapture.h"
#import "AudioRender.h"

@interface AudioController ()<AudioCaptureDelegate, AudioRenderDelegate>

@property (nonatomic, strong) AudioCapture *audioCapture;
@property (nonatomic, strong) AudioRender *audioRender;
@property (nonatomic, assign) int sampleRate;
@property (nonatomic, assign) int channelCount;

@end

@implementation AudioController

static double preferredIOBufferDuration = 0.02;

+ (instancetype)audioController {
    AudioController *audioController = [[self alloc] init];
    
    return audioController;
}


#pragma mark - <Step 1, Set Up Audio Session>
- (void)setUpAudioSessionWithSampleRate:(int)sampleRate channelCount:(int)channelCount {
    
    self.sampleRate = sampleRate;
    self.channelCount = channelCount;
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    NSUInteger sessionOption = AVAudioSessionCategoryOptionMixWithOthers;
    sessionOption |= AVAudioSessionCategoryOptionAllowBluetooth;
    sessionOption |= AVAudioSessionCategoryOptionDefaultToSpeaker;
    
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:sessionOption error:nil];
    [audioSession setMode:AVAudioSessionModeDefault error:nil];
  
    [audioSession setActive:YES error:nil];
    [audioSession setPreferredIOBufferDuration:preferredIOBufferDuration error:nil];
}

#pragma mark - <Step 2, Set Up Audio Capture>
- (void)setUpAudioCapture {
    [self audioCapture];
    self.audioCapture.delegate = self;
}

#pragma mark - <Step 2, Set Up Audio Render>
- (void)setUpAudioRender {
    [self audioRender];
    self.audioRender.delegate = self;
}

#pragma mark - <Step 3, Stop Capture Or Render>
- (void)stopCapture {
    [self.audioCapture stopCapture];
    self.audioCapture.delegate = nil;
}

- (void)stopRender {
    [self.audioRender stopRender];
    self.audioRender.delegate = nil;
}

#pragma mark - <Capture Start>
- (void)audioCaptureStart {
    [self.audioCapture startCapture];
}

- (void)audioRenderStart {
    [self.audioRender startRender];
}

#pragma mark - <AudioCaptureDelegate>
- (void)audioCapture:(AudioCapture *)audioCapture didCaptureData:(unsigned char *)data bytesLength:(int)bytesLength {
    
    if ([self.delegate respondsToSelector:@selector(audioController:didCaptureData:bytesLength:)]) {
        [self.delegate audioController:self didCaptureData:data bytesLength:bytesLength];
    }
}

#pragma mark - <AudioRenderDelegate>
- (int)audioRender:(AudioRender *)audioRender didRenderData:(unsigned char *)data bytesLength:(int)bytesLength {
    int result = 0;
    
    if ([self.delegate respondsToSelector:@selector(audioController:didRenderData:bytesLength:)]) {
        result = [self.delegate audioController:self didRenderData:data bytesLength:bytesLength];
    }
    
    return result;
}

#pragma mark - <Lazy Load>
- (AudioCapture *)audioCapture {
    if (!_audioCapture) {
        _audioCapture = [[AudioCapture alloc] initWithSampleRate:self.sampleRate channelCount:self.channelCount];
    }
    return _audioCapture;
}

- (AudioRender *)audioRender {
    if (!_audioRender) {
        _audioRender = [[AudioRender alloc] initWithSampleRate:self.sampleRate channelCount:self.channelCount];
    }
    return _audioRender;
}

@end
