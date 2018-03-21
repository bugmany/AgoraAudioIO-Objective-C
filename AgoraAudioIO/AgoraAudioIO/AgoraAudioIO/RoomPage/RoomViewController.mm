//
//  SRXRoomViewController.m
//  OpenVoiceCall-OC
//
//  Created by CavanSu on 2017/9/18.
//  Copyright © 2017 Agora. All rights reserved.
//

#import "RoomViewController.h"
#import <AgoraAudioKit/AgoraRtcEngineKit.h>
#import <AgoraAudioKit/IAgoraRtcEngine.h>
#import <AgoraAudioKit/IAgoraMediaEngine.h>
#import "AppID.h"
#import "InfoCell.h"
#import "InfoModel.h"
#import "InfoTableView.h"
#import "AudioController.h"
#import "AudioWriteToFile.h"
#import "LogAudioSessionStatus.h"

@interface RoomViewController () <AgoraRtcEngineDelegate, AudioControllerDelegate>

@property (nonatomic, strong) NSMutableArray *infoArray;
@property (weak, nonatomic) IBOutlet UILabel *roomNameLabel;
@property (weak, nonatomic) IBOutlet InfoTableView *tableView;
@property (nonatomic, strong) AgoraRtcEngineKit *agoraKit;
@property (strong, nonatomic) AudioController *audioController;

@end

static NSObject *threadLockCapture;
static NSObject *threadLockPlay;

#pragma mark - C++ AgoraAudioFrameObserver
class AgoraAudioFrameObserver : public agora::media::IAudioFrameObserver
{
private:
    
    // total buffer length of per second
    enum { kBufferLengthBytes = 441 * 2 * 2 * 50 }; // 88200 bytes
    
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
        @synchronized(threadLockCapture) {
            
            int readBytes = sampleRate / 100 * channels * audioFrame.bytesPerSample;
            
            if (availableBytes < readBytes) {
                return false;
            }
            
        
            audioFrame.samplesPerSec = sampleRate;
            unsigned char tmp[960]; // The most rate:@48k fs, channels = 1, the most total size = 960;
            

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
          
            return true;
        }
        
    }
    
    
#pragma mark- <C++ Render>
    // read Audio data from byteBuffer_play to audioUnit
    int readAudioData(void* data, int bytesLength) 
    {
        @synchronized(threadLockPlay) {
            
            if (NULL == data || bytesLength < 1 || availableBytes_play < bytesLength) {
                return 0;
            }
            
           
            int readBytes = bytesLength;
            
            unsigned char tmp[2048]; // unsigned char takes up 1 byte
            
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
            
            return readBytes;
        }
        
    }
    
    // recive remote audio stream, push audio data to byteBuffer_play
    virtual bool onPlaybackAudioFrame(AudioFrame& audioFrame) override
    {
        @synchronized(threadLockPlay) {
            
            if (audioFrame.renderTimeMs <= 0) {
                return false;
            }
            
            int bytesLength = audioFrame.samples * audioFrame.channels * audioFrame.bytesPerSample;
            char *data = (char *)audioFrame.buffer;
            
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
    
    virtual bool onPlaybackAudioFrameBeforeMixing(unsigned int uid, AudioFrame& audioFrame) override { return true; }
    
    virtual bool onMixedAudioFrame(AudioFrame& audioFrame) override { return true; }
};

static AgoraAudioFrameObserver* s_audioFrameObserver;

@implementation RoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupViews];
    
    [self initAgoraKitAndInitAudioController];
}


#pragma mark - setupViews
- (void)setupViews {
    self.roomNameLabel.text = self.channelName;
    self.tableView.backgroundColor = [UIColor clearColor];
}


#pragma mark - initAgoraKitAndInitAudioController
- (void)initAgoraKitAndInitAudioController {
    
    self.agoraKit = [AgoraRtcEngineKit sharedEngineWithAppId:[AppID appID] delegate:self];

    threadLockCapture = [[NSObject alloc] init];
    threadLockPlay = [[NSObject alloc] init];
    
    switch (self.audioMode) {
        case AudioMode_SelfCapture_SDKRender:
            [self.tableView appendInfoToTableViewWithInfo:[NSString stringWithFormat:@"AudioMode_SelfCapture_SDKRender"]];
            
            self.audioController = [AudioController audioController];
            self.audioController.delegate = self;
            [self.audioController setUpAudioSessionWithSampleRate:self.sampleRate channelCount:1];
            [self.audioController setUpAudioCapture];
            
            [self.agoraKit enableExternalAudioSourceWithSampleRate:self.sampleRate channelsPerFrame:1];
            [self.agoraKit setRecordingAudioFrameParametersWithSampleRate:(NSInteger)self.sampleRate channel:1 mode:AgoraRtc_RawAudioFrame_OpMode_WriteOnly samplesPerCall:(NSInteger)self.sampleRate * 1 * 0.01];
            
            break;
            
        case AudioMode_SDKCapture_SelfRender:
            [self.tableView appendInfoToTableViewWithInfo:[NSString stringWithFormat:@"AudioMode_SDKCapture_SelfRender"]];
            
            self.audioController = [AudioController audioController];
            self.audioController.delegate = self;
            [self.audioController setUpAudioSessionWithSampleRate:self.sampleRate channelCount:1];
            [self.audioController setUpAudioRender];
            [self.agoraKit setParameters: @"{\"che.audio.external_capture\": false}"];
            [self.agoraKit setParameters: @"{\"che.audio.external_render\": true}"];
            
            [self.agoraKit setPlaybackAudioFrameParametersWithSampleRate:(NSInteger)self.sampleRate channel:1 mode:AgoraRtc_RawAudioFrame_OpMode_ReadOnly samplesPerCall:(NSInteger)self.sampleRate * 1 * 0.01];
            
            break;
            
        case AudioMode_SDKCapture_SDKRender:
            [self.tableView appendInfoToTableViewWithInfo:[NSString stringWithFormat:@"AudioMode_SDKCapture_SDKRender"]];
            
            [self.agoraKit setParameters: @"{\"che.audio.external_capture\": false}"];
            [self.agoraKit setParameters: @"{\"che.audio.external_render\": false}"];
            break;
            
        case AudioMode_SelfCapture_SelfRender:
            [self.tableView appendInfoToTableViewWithInfo:[NSString stringWithFormat:@"AudioMode_SelfCapture_SelfRender"]];
            
            self.audioController = [AudioController audioController];
            self.audioController.delegate = self;
            [self.audioController setUpAudioSessionWithSampleRate:self.sampleRate channelCount:1];
            [self.audioController setUpAudioCapture];
            [self.audioController setUpAudioRender];
            
            [self.agoraKit setParameters: @"{\"che.audio.external_capture\": true}"];
            [self.agoraKit setParameters: @"{\"che.audio.external_render\": true}"];
           
          
            // Set capture format
            [self.agoraKit setRecordingAudioFrameParametersWithSampleRate:(NSInteger)self.sampleRate channel:1 mode:AgoraRtc_RawAudioFrame_OpMode_WriteOnly samplesPerCall:(NSInteger)self.sampleRate * 1 * 0.01]; // samplesPerCall : sampleRate * channels * duration
            [self.agoraKit setPlaybackAudioFrameParametersWithSampleRate:(NSInteger)self.sampleRate channel:1 mode:AgoraRtc_RawAudioFrame_OpMode_ReadOnly samplesPerCall:(NSInteger)self.sampleRate * 1 * 0.01];
            
            break;
            
        default:
            break;
    }
    
    
    if (self.audioMode != AudioMode_SDKCapture_SDKRender) {
    
        agora::rtc::IRtcEngine* rtc_engine = (agora::rtc::IRtcEngine*)self.agoraKit.getNativeHandle;
        agora::util::AutoPtr<agora::media::IMediaEngine> mediaEngine;
        
        mediaEngine.queryInterface(rtc_engine, agora::rtc::AGORA_IID_MEDIA_ENGINE);
        
        if (mediaEngine) {
            s_audioFrameObserver = new AgoraAudioFrameObserver();
            s_audioFrameObserver -> sampleRate = self.sampleRate;
            s_audioFrameObserver -> sampleRate_play = self.sampleRate;
            mediaEngine->registerAudioFrameObserver(s_audioFrameObserver);
        }
        
    }
    
    [self.agoraKit joinChannelByKey:nil channelName:self.channelName info:nil uid:0 joinSuccess:nil];
}

#pragma mark- Click Buttons
- (IBAction)clickMuteButton:(UIButton *)sender {

    [self.agoraKit muteLocalAudioStream:sender.selected];
}

- (IBAction)clickHungUpButton:(UIButton *)sender {
    
    sender.enabled = NO;
    
    if (self.audioMode == AudioMode_SDKCapture_SelfRender || self.audioMode == AudioMode_SelfCapture_SelfRender) {
        [self.audioController stopRender];
    }
    
    if (self.audioMode == AudioMode_SelfCapture_SelfRender || self.audioMode == AudioMode_SelfCapture_SDKRender) {
        [self.audioController stopCapture];
    }
    
    if (self.audioMode != AudioMode_SDKCapture_SDKRender) {
        
        agora::rtc::IRtcEngine* rtc_engine = (agora::rtc::IRtcEngine *)self.agoraKit.getNativeHandle;
        agora::util::AutoPtr<agora::media::IMediaEngine> mediaEngine;
        mediaEngine.queryInterface(rtc_engine, agora::rtc::AGORA_IID_MEDIA_ENGINE);
        
        delete s_audioFrameObserver;
        
        if (mediaEngine) {
            mediaEngine->registerAudioFrameObserver(NULL);
        }
    }
    
    if (self.audioMode == AudioMode_SelfCapture_SDKRender) {
        [self.agoraKit disableExternalAudioSource];
    }
    
    [self.agoraKit leaveChannel:nil];
    [AgoraRtcEngineKit destroy];
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)clickSpeakerButton:(UIButton *)sender {
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        sender.selected = NO;
    }
    else {
        [self.agoraKit setEnableSpeakerphone:!sender.selected];
    }
    
}

#pragma mark- <AudioCaptureDelegate>
- (void)audioController:(AudioController *)controller didCaptureData:(unsigned char *)data bytesLength:(int)bytesLength {
    
    if (self.audioMode == AudioMode_SelfCapture_SDKRender) {
        [self.agoraKit pushExternalAudioFrameRawData:data samples:(NSUInteger)bytesLength / 2 / 1 timestamp:0];
    }
    else {
        if (s_audioFrameObserver) {
            s_audioFrameObserver -> pushExternalData(data, bytesLength);
        }
    }
}

- (int)audioController:(AudioController *)controller didRenderData:(unsigned char *)data bytesLength:(int)bytesLength {
    int result = 0;
    
    if (s_audioFrameObserver) {
        result = s_audioFrameObserver -> readAudioData(data, bytesLength);
    }

    return result;
}

#pragma mark- <AgoraRtcEngineDelegate>
// Self joined success
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinChannel:(NSString*)channel withUid:(NSUInteger)uid elapsed:(NSInteger) elapsed {
    
    [self.tableView appendInfoToTableViewWithInfo:[NSString stringWithFormat:@"Self join channel with uid:%zd", uid]];
    [self.agoraKit setEnableSpeakerphone:YES];
    
    if (self.audioMode == AudioMode_SelfCapture_SDKRender || self.audioMode == AudioMode_SelfCapture_SelfRender) {
        [self.audioController audioCaptureStart];
    }
    
    if (self.audioMode == AudioMode_SelfCapture_SelfRender || self.audioMode == AudioMode_SDKCapture_SelfRender) {
        [self.audioController audioRenderStart];
    }
    
    if (self.audioMode == AudioMode_SelfCapture_SelfRender || self.audioMode == AudioMode_SDKCapture_SelfRender) {
        [[AVAudioSession sharedInstance] setPreferredSampleRate:self.sampleRate error:nil];
    }
    
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed {
    [self.tableView appendInfoToTableViewWithInfo:[NSString stringWithFormat:@"Uid:%zd joined channel with elapsed:%zd", uid, elapsed]];
}

- (void)rtcEngineConnectionDidInterrupted:(AgoraRtcEngineKit *)engine {
    [self.tableView appendInfoToTableViewWithInfo:@"Connection Did Interrupted"];
}

- (void)rtcEngineConnectionDidLost:(AgoraRtcEngineKit *)engine {
    [self.tableView appendInfoToTableViewWithInfo:@"Connection Did Lost"];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurError:(AgoraRtcErrorCode)errorCode {
    [self.tableView appendInfoToTableViewWithInfo:[NSString stringWithFormat:@"Error Code:%zd", errorCode]];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraRtcUserOfflineReason)reason {
    [self.tableView appendInfoToTableViewWithInfo:[NSString stringWithFormat:@"Uid:%zd didOffline reason:%zd", uid, reason]];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didRejoinChannel:(NSString *)channel withUid:(NSUInteger)uid elapsed:(NSInteger)elapsed {
    [self.tableView appendInfoToTableViewWithInfo:[NSString stringWithFormat:@"Self Rejoin Channel"]];
}

#pragma mark - StatusBar Style
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
