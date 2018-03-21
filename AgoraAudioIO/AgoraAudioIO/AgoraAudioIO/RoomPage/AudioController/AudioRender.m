//
//  AudioRender.m
//  Audio-Source
//
//  Created by CavanSu on 12/11/2017.
//  Copyright © 2017 Agora. All rights reserved.
//

#import "AudioRender.h"
#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudioTypes.h>
#import "AudioWriteToFile.h"

#define OutputBus 0

@interface AudioRender ()

@property (nonatomic, assign) AudioUnit renderAudioUnit;
@property (nonatomic, assign) int sampleRate;
@property (nonatomic, assign) int channelCount;

@end

@implementation AudioRender

- (instancetype)initWithSampleRate:(int)sampleRate channelCount:(int)channelCount {
    if (self = [super init]) {
        self.sampleRate = sampleRate;
        self.channelCount = channelCount;
        
        [self setUpAudioComponent];
        [self setUpAudioStreamFormat];
        [self setupRenderCallBack];
    }
    
    return self;
}

#pragma mark - <Step 1, Setup Audio Component>
- (void)setUpAudioComponent {
    // AudioComponentDescription
    AudioComponentDescription componentDesc;
    componentDesc.componentType = kAudioUnitType_Output;
    componentDesc.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    componentDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    componentDesc.componentFlags = 0;
    componentDesc.componentFlagsMask = 0;
    
    // AudioComponent
    AudioComponent renderComponent = AudioComponentFindNext(NULL, &componentDesc);
    AudioComponentInstanceNew(renderComponent, &_renderAudioUnit);
}

#pragma mark - <Step 2, Setup Audio Stream Format>
- (void)setUpAudioStreamFormat {
    // AudioStreamBasicDescription
    AudioStreamBasicDescription streamFormatDesc;
    streamFormatDesc.mSampleRate = _sampleRate;
    streamFormatDesc.mFormatID = kAudioFormatLinearPCM;
    streamFormatDesc.mFormatFlags = (kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked);
    streamFormatDesc.mChannelsPerFrame = _channelCount;
    streamFormatDesc.mFramesPerPacket = 1;
    streamFormatDesc.mBitsPerChannel = 16;
    streamFormatDesc.mBytesPerFrame = streamFormatDesc.mBitsPerChannel / 8 * streamFormatDesc.mChannelsPerFrame;
    streamFormatDesc.mBytesPerPacket = streamFormatDesc.mBytesPerFrame * streamFormatDesc.mFramesPerPacket;
    
    UInt32 outputFlag = 1; // OutputBus = 0
    
    AudioUnitSetProperty(_renderAudioUnit,
                         kAudioOutputUnitProperty_EnableIO,
                         kAudioUnitScope_Output,
                         OutputBus,
                         &outputFlag,
                         sizeof(outputFlag));
    
    AudioUnitSetProperty(_renderAudioUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Input,
                         OutputBus,
                         &streamFormatDesc,
                         sizeof(streamFormatDesc));
   
}

#pragma mark - <Step 3, Setup Render Call Back>
- (void)setupRenderCallBack {
    AURenderCallbackStruct renderCallback;
    renderCallback.inputProcRefCon = (__bridge void * _Nullable)(self);
    renderCallback.inputProc = renderCallBack;
    AudioUnitSetProperty(_renderAudioUnit,
                         kAudioUnitProperty_SetRenderCallback,
                         kAudioUnitScope_Input,
                         OutputBus,
                         &renderCallback,
                         sizeof(renderCallback));
    AudioUnitInitialize(_renderAudioUnit);
}

#pragma mark - <Render Call Back>
static OSStatus renderCallBack(void *inRefCon,
                                   AudioUnitRenderActionFlags *ioActionFlags,
                                   const AudioTimeStamp *inTimeStamp,
                                   UInt32 inBusNumber,
                                   UInt32 inNumberFrames,
                                   AudioBufferList *ioData)
{

    AudioRender *render = (__bridge AudioRender *)(inRefCon);
    
    ioData -> mNumberBuffers = 1;
    ioData -> mBuffers[0].mNumberChannels = 1;
    ioData -> mBuffers[0].mDataByteSize = inNumberFrames * 2;
    
    int result = 0;
    
    if ([render.delegate respondsToSelector:@selector(audioRender:didRenderData:bytesLength:)]) {
        result = [render.delegate audioRender:render didRenderData:(uint8_t*)ioData->mBuffers[0].mData bytesLength:ioData->mBuffers[0].mDataByteSize];
    }
    
    if (result == 0) {
        ioData->mBuffers[0].mDataByteSize = 0;  
    }
        
    return noErr;
}

#pragma mark - <Render Start or Stop>
- (void)startRender {
     AudioOutputUnitStart(_renderAudioUnit);
}

- (void)stopRender {
    AudioOutputUnitStop(_renderAudioUnit);
    AudioComponentInstanceDispose(_renderAudioUnit);
    _renderAudioUnit = nil;
}

@end
