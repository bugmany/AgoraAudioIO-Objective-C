//
//  AudioCapture.m
//  AudioCapture
//
//  Created by CavanSu on 10/11/2017.
//  Copyright © 2017 Agora. All rights reserved.
//

#import "AudioCaptureMac.h"
#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudioTypes.h>

#define InputBus 1

@interface AudioCaptureMac ()

@property (nonatomic, assign) AudioUnit captureAudioUnit;
@property (nonatomic, assign) int sampleRate;
@property (nonatomic, assign) int channelCount;

@end

@implementation AudioCaptureMac

- (instancetype)initWithSampleRate:(int)sampleRate channelCount:(int)channelCount {
    
    if (self = [super init]) {
        self.sampleRate = sampleRate;
        self.channelCount = channelCount;
        
        [self setUpAudioComponent];
        [self setUpAudioStreamFormat];
        [self setUpCaptureCallBack];
    }
    
    return self;
}

#pragma mark - <Step 1, Set Up Audio Component>
- (void)setUpAudioComponent {
    // AudioComponentDescription
    AudioComponentDescription componentDesc;
    componentDesc.componentType = kAudioUnitType_Output;
    componentDesc.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    componentDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    componentDesc.componentFlags = 0;
    componentDesc.componentFlagsMask = 0; 
    
    // AudioComponent
    AudioComponent captureComponent = AudioComponentFindNext(NULL, &componentDesc);
    OSStatus status = AudioComponentInstanceNew(captureComponent, &_captureAudioUnit);
    if (status != noErr)  {
        NSLog(@"Couldn't create audio capture component instance, status : %d \n",status);
    }
}

#pragma mark - <Step 2, Set Up Audio Stream Format>
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
    
    // Set up EnableIO Property; Input = 1;
    UInt32 inputFlag = 1;
    
    AudioUnitSetProperty(_captureAudioUnit,
                         kAudioOutputUnitProperty_EnableIO,
                         kAudioUnitScope_Input,
                         InputBus,
                         &inputFlag,
                         sizeof(inputFlag));
    
    // Set up Stream Property
    AudioUnitSetProperty(_captureAudioUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Output,
                         InputBus,
                         &streamFormatDesc,
                         sizeof(streamFormatDesc));
}

#pragma mark - <Step 3, Set Up Capture Call Back>
- (void)setUpCaptureCallBack {
    
    AURenderCallbackStruct captureCallBackStruck;
    captureCallBackStruck.inputProcRefCon = (__bridge void * _Nullable)(self);
    captureCallBackStruck.inputProc = captureCallBack;
    
    AudioUnitSetProperty(_captureAudioUnit,
                         kAudioOutputUnitProperty_SetInputCallback,
                         kAudioUnitScope_Global,
                         InputBus,
                         &captureCallBackStruck,
                         sizeof(captureCallBackStruck));
    
    AudioUnitInitialize(_captureAudioUnit);
}

#pragma mark - <Capture Call Back>
static OSStatus captureCallBack(void *inRefCon,
                                AudioUnitRenderActionFlags *ioActionFlags,
                                const AudioTimeStamp *inTimeStamp,
                                UInt32 inBusNumber, // inputBus = 1
                                UInt32 inNumberFrames, 
                                AudioBufferList *ioData)
{
    AudioCaptureMac *audioCapture = (__bridge AudioCaptureMac *)inRefCon;
    
    AudioUnit captureUnit = [(__bridge AudioCaptureMac *)inRefCon captureAudioUnit];
        
    if (!inRefCon) return 0;
    
    AudioBuffer buffer;
    buffer.mData = NULL;
    buffer.mDataByteSize = 0;
    buffer.mNumberChannels = 1;
    
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0] = buffer;
    
    OSStatus status = AudioUnitRender(captureUnit,
                                      ioActionFlags,
                                      inTimeStamp,
                                      inBusNumber,
                                      inNumberFrames,
                                      &bufferList);
    
    if (!status) {
        
        if ([audioCapture.delegate respondsToSelector:@selector(audioCapture:didCaptureData:bytesLength:)]) {
            [audioCapture.delegate audioCapture:audioCapture didCaptureData:(unsigned char *)bufferList.mBuffers[0].mData bytesLength:bufferList.mBuffers[0].mDataByteSize];
        }
        
    }
    
    return 0;
}

#pragma mark - <Capture Start or Stop>
- (void)startCapture {
    AudioOutputUnitStart(_captureAudioUnit);
}

- (void)stopCapture {
    AudioOutputUnitStop(_captureAudioUnit);
    AudioComponentInstanceDispose(_captureAudioUnit);
    _captureAudioUnit = nil;
}

@end
