//
//  AudioController.mm
//  AgoraAudioIO
//
//  Created by suleyu on 2017/12/15.
//  Copyright © 2017 Agora. All rights reserved.
//

#import "AudioControllerMac.h"
#import "../../../../../media_sdk3/interface/cpp/IAgoraRtcEngine.h"
#import "../../../../../media_sdk3/interface/cpp/IAgoraMediaEngine.h"

static NSObject *threadLockCapture;
static NSObject *threadLockPlay;

static const int kBufferLengthBytes =  48000 * 2 * 2;

class AgoraAudioFrameObserver : public agora::media::IAudioFrameObserver
{
private:
    // capture
    char byteBuffer[kBufferLengthBytes]; // char take up 1 byte, byterBuffer[] take up 88200 bytes
    int readIndex = 0;
    int writeIndex = 0;
    int availableBytes = 0;
    int channels = 1;
    
    // play
    char byteBuffer_play[kBufferLengthBytes];
    int readIndex_play = 0;
    int writeIndex_play = 0;
    int availableBytes_play = 0;
    int channels_play = 1;
    
public:
    int sampleRate = 0;
    int sampleRate_play = 0;
    
#pragma mark- <C++ Capture>
    // push audio data to special buffer(Array byteBuffer)
    // bytesLength = date length
    void pushExternalData(void* data, int bytesLength)
    {
        if (NULL == data || bytesLength < 1 || threadLockCapture == nil) {
            return;
        }
        
        @synchronized(threadLockCapture) {
            
            if (availableBytes + bytesLength > kBufferLengthBytes) {
                readIndex = 0;
                writeIndex = 0;
                availableBytes = 0;
            }
            
            if (writeIndex + bytesLength > kBufferLengthBytes) {
                int left = kBufferLengthBytes - writeIndex;
                memcpy(byteBuffer + writeIndex, data, left);
                memcpy(byteBuffer, (char *)data + left, bytesLength - left);
                writeIndex = bytesLength - left;
            }
            else {
                memcpy(byteBuffer + writeIndex, data, bytesLength);
                writeIndex += bytesLength;
            }
            
            availableBytes += bytesLength;
        }
    }
    
    // copy byteBuffer to audioFrame.buffer
    virtual bool onRecordAudioFrame(AudioFrame& audioFrame) override
    {
        if (threadLockCapture == nil) {
            return true;
        }
        
        @synchronized(threadLockCapture) {
            
            int readBytes = audioFrame.samples * audioFrame.channels * audioFrame.bytesPerSample;
            
            if (availableBytes < readBytes) {
                return false;
            }
            
            unsigned char *tmp = (unsigned char *)malloc(readBytes);
            if (tmp == NULL) {
                return false;
            }
            
            if (readIndex + readBytes > kBufferLengthBytes) {
                int left = kBufferLengthBytes - readIndex;
                memcpy(tmp, byteBuffer + readIndex, left);
                memcpy(tmp + left, byteBuffer, readBytes - left);
                readIndex = readBytes - left;
            }
            else {
                memcpy(tmp, byteBuffer + readIndex, readBytes);
                readIndex += readBytes;
            }
            
            availableBytes -= readBytes;
            
            if (channels == audioFrame.channels) {
                memcpy(audioFrame.buffer, tmp, readBytes);
            }
            
            free(tmp);
            return true;
        }
    }
    
#pragma mark- <C++ Render>
    // read Audio data from byteBuffer_play to audioUnit
    int readAudioData(void* data, int bytesLength)
    {
        if (NULL == data || bytesLength < 1 || threadLockPlay == nil) {
            return 0;
        }
        
        @synchronized(threadLockPlay) {

            if (availableBytes_play < bytesLength) {
                return 0;
            }
            
            int readBytes = bytesLength;
            unsigned char *tmp = (unsigned char *)malloc(readBytes);
            if (tmp == NULL) {
                return 0;
            }
            
            if (readIndex_play + readBytes > kBufferLengthBytes) {
                int left = kBufferLengthBytes - readIndex_play;
                memcpy(tmp, byteBuffer_play + readIndex_play, left);
                memcpy(tmp + left, byteBuffer_play, readBytes - left);
                readIndex_play = readBytes - left;
            }
            else {
                memcpy(tmp, byteBuffer_play + readIndex_play, readBytes);
                readIndex_play += readBytes;
            }
            
            availableBytes_play -= readBytes;
            
            if (channels_play == 1) {
                memcpy(data, tmp, readBytes);
            }
            
            free(tmp);
            return readBytes;
        }
    }
    
    // recive remote audio stream, push audio data to byteBuffer_play
    virtual bool onPlaybackAudioFrame(AudioFrame& audioFrame) override
    {
        if (threadLockPlay == nil) {
            return true;
        }
        
        @synchronized(threadLockPlay) {
            
//            if (audioFrame.renderTimeMs <= 0) {
//                return true;
//            }
            
            int bytesLength = audioFrame.samples * audioFrame.channels * audioFrame.bytesPerSample;
            unsigned char *data = (unsigned char *)audioFrame.buffer;
            
            sampleRate_play = audioFrame.samplesPerSec;
            channels_play = audioFrame.channels;
            
            if (availableBytes_play + bytesLength > kBufferLengthBytes) {
                readIndex_play = 0;
                writeIndex_play = 0;
                availableBytes_play = 0;
            }
            
            if (writeIndex_play + bytesLength > kBufferLengthBytes) {
                int left = kBufferLengthBytes - writeIndex_play;
                memcpy(byteBuffer_play + writeIndex_play, data, left);
                memcpy(byteBuffer_play, (char *)data + left, bytesLength - left);
                writeIndex_play = bytesLength - left;
            }
            else {
                memcpy(byteBuffer_play + writeIndex_play, data, bytesLength);
                writeIndex_play += bytesLength;
            }
            
            availableBytes_play += bytesLength;
            
            return true;
        }
    }
    
    virtual bool onPlaybackAudioFrameBeforeMixing(unsigned int uid, AudioFrame& audioFrame) override {
        return true;
    }
    
    virtual bool onMixedAudioFrame(AudioFrame& audioFrame) override {
        return true;
    }
};

#pragma mark -

@interface AudioControllerMac ()
{
    AgoraRtcEngineKit *agoraRtcEngine;
    AgoraAudioFrameObserver *audioFrameObserver;
}
@end

@implementation AudioControllerMac

- (void)registerToRtcEngine:(AgoraRtcEngineKit *)rtcEngine audioMode:(AudioMode)audioMode sampleRate:(int)sampleRate {
    if (agoraRtcEngine) {
        [self deregister];
    }

    agora::rtc::IRtcEngine* rtc_engine = (agora::rtc::IRtcEngine*)rtcEngine.getNativeHandle;
    agora::util::AutoPtr<agora::media::IMediaEngine> mediaEngine;
    mediaEngine.queryInterface(rtc_engine, agora::AGORA_IID_MEDIA_ENGINE);
    if (mediaEngine) {
        if ((audioMode & AudioMode_SelfCapture) != 0) {
            threadLockCapture = [[NSObject alloc] init];
        }
        
        if ((audioMode & AudioMode_SelfRender) != 0) {
            threadLockPlay = [[NSObject alloc] init];
        }
        
        audioFrameObserver = new AgoraAudioFrameObserver();
        audioFrameObserver->sampleRate = sampleRate;
        mediaEngine->registerAudioFrameObserver(audioFrameObserver);
        
        agoraRtcEngine = rtcEngine;
    }
}

- (void)deregister {
    if (agoraRtcEngine == nil) {
        return;
    }
    
    agora::rtc::IRtcEngine* rtc_engine = (agora::rtc::IRtcEngine*)agoraRtcEngine.getNativeHandle;
    agora::util::AutoPtr<agora::media::IMediaEngine> mediaEngine;
    mediaEngine.queryInterface(rtc_engine, agora::AGORA_IID_MEDIA_ENGINE);
    if (mediaEngine) {
        mediaEngine->registerAudioFrameObserver(NULL);
    }
    
    delete audioFrameObserver;
    audioFrameObserver = NULL;
    
    threadLockCapture = nil;
    threadLockPlay = nil;
}

- (void)pushExternalData:(void *)data length:(int)length {
    audioFrameObserver->pushExternalData(data, length);
}

- (int)readAudioData:(void *)data length:(int)length {
    return audioFrameObserver->readAudioData(data, length);
}

@end
