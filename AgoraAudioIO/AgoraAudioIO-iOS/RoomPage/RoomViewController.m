//
//  SRXRoomViewController.m
//  OpenVoiceCall-OC
//
//  Created by CavanSu on 2017/9/18.
//  Copyright © 2017 Agora. All rights reserved.
//

#import "RoomViewController.h"
#import <AgoraAudioKit/AgoraRtcEngineKit.h>
#import "AppID.h"
#import "InfoCell.h"
#import "InfoModel.h"
#import "InfoTableView.h"
#import "AudioController.h"
#import "AudioWriteToFile.h"
#import "LogAudioSessionStatus.h"
#import "ExternalAudio.h"

@interface RoomViewController () <AgoraRtcEngineDelegate>
@property (weak, nonatomic) IBOutlet UILabel *roomNameLabel;
@property (weak, nonatomic) IBOutlet InfoTableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *roleChangedButton;

@property (nonatomic, strong) AgoraRtcEngineKit *agoraKit;
@property (nonatomic, strong) ExternalAudio *exAudio;
@property (nonatomic, strong) NSMutableArray *infoArray;
@property (nonatomic, assign) int channels;
@end

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
    self.roleChangedButton.hidden = self.channelMode == ChannelModeLiveBroadcast ? NO : YES;
    if (self.roleChangedButton.hidden == YES) return;
    self.roleChangedButton.selected = self.clientRole == ClientRoleAudience ? YES : NO;
}

#pragma mark - initAgoraKitAndInitAudioController
- (void)initAgoraKitAndInitAudioController {
    self.channels = 1;
    self.agoraKit = [AgoraRtcEngineKit sharedEngineWithAppId:[AppID appID] delegate:self];
    
    if (self.channelMode == ChannelModeLiveBroadcast) {
        [self.agoraKit setChannelProfile:AgoraChannelProfileLiveBroadcasting];
        AgoraClientRole role = self.clientRole == ClientRoleBroadcast ? AgoraClientRoleBroadcaster : AgoraClientRoleAudience;
        [self.agoraKit setClientRole:role];
    }
    
    if (self.audioMode != AudioCRMode_SDKCapture_SDKRender) {
        self.exAudio = [ExternalAudio sharedExternalAudio];
        [self.exAudio setupExternalAudioWithAgoraKit:self.agoraKit sampleRate:_sampleRate channels:_channels audioCRMode:self.audioMode IOType:IOUnitTypeRemoteIO];
    }
  
    switch (self.audioMode) {
        case AudioCRMode_ExterCapture_SDKRender:
            [self.tableView appendInfoToTableViewWithInfo:[NSString stringWithFormat:@"AudioCRMode_ExterCapture_SDKRender"]];
            [self.agoraKit enableExternalAudioSourceWithSampleRate:_sampleRate channelsPerFrame:_channels];
            break;
            
        case AudioCRMode_SDKCapture_ExterRender:
            [self.tableView appendInfoToTableViewWithInfo:[NSString stringWithFormat:@"AudioCRMode_SDKCapture_ExterRender"]];
            [self.agoraKit setParameters: @"{\"che.audio.external_capture\": false}"];
            [self.agoraKit setParameters: @"{\"che.audio.external_render\": true}"];
            [self.agoraKit setPlaybackAudioFrameParametersWithSampleRate:(NSInteger)_sampleRate channel:_channels mode:AgoraAudioRawFrameOperationModeReadOnly samplesPerCall:(NSInteger)_sampleRate * _channels * 0.01];
            break;
            
        case AudioCRMode_SDKCapture_SDKRender:
            [self.tableView appendInfoToTableViewWithInfo:[NSString stringWithFormat:@"AudioCRMode_SDKCapture_SDKRender"]];
            [self.agoraKit setParameters: @"{\"che.audio.external_capture\": false}"];
            [self.agoraKit setParameters: @"{\"che.audio.external_render\": false}"];
            break;
            
        case AudioCRMode_ExterCapture_ExterRender:
            [self.tableView appendInfoToTableViewWithInfo:[NSString stringWithFormat:@"AudioCRMode_ExterCapture_ExterRender"]];
            [self.agoraKit setParameters: @"{\"che.audio.external_capture\": true}"];
            [self.agoraKit setParameters: @"{\"che.audio.external_render\": true}"];
            [self.agoraKit setRecordingAudioFrameParametersWithSampleRate:(NSInteger)_sampleRate channel:_channels mode:AgoraAudioRawFrameOperationModeWriteOnly samplesPerCall:(NSInteger)_sampleRate * _channels * 0.01];
            [self.agoraKit setPlaybackAudioFrameParametersWithSampleRate:(NSInteger)_sampleRate channel:_channels mode:AgoraAudioRawFrameOperationModeReadOnly samplesPerCall:(NSInteger)_sampleRate * _channels * 0.01];
            break;
            
        default:
            break;
    }
    
    [self.agoraKit joinChannelByToken:nil channelId:self.channelName info:nil uid:0 joinSuccess:nil];
}

#pragma mark- Click Buttons
- (IBAction)clickMuteButton:(UIButton *)sender {
    [self.agoraKit muteLocalAudioStream:sender.selected];
}

- (IBAction)clickHungUpButton:(UIButton *)sender {
    sender.enabled = NO;
    
    if (self.audioMode != AudioCRMode_SDKCapture_SDKRender) {
        [self.exAudio stopWork];
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

- (IBAction)clickRoleChangedButton:(UIButton *)sender {
    sender.selected = !sender.selected;
    AgoraClientRole role = sender.selected == YES ? AgoraClientRoleAudience : AgoraClientRoleBroadcaster;
    [self.agoraKit setClientRole:role];
}

#pragma mark- <AgoraRtcEngineDelegate>
// Self joined success
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinChannel:(NSString*)channel withUid:(NSUInteger)uid elapsed:(NSInteger) elapsed {
    
    [self.tableView appendInfoToTableViewWithInfo:[NSString stringWithFormat:@"Self join channel with uid:%zd", uid]];
    [self.agoraKit setEnableSpeakerphone:YES];
   
    if (self.audioMode != AudioCRMode_SDKCapture_SDKRender) {
        [self.exAudio startWork];
    }
    
    if (self.audioMode == AudioCRMode_ExterCapture_ExterRender || self.audioMode == AudioCRMode_SDKCapture_ExterRender) {
        [[AVAudioSession sharedInstance] setPreferredSampleRate:_sampleRate error:nil];
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

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurError:(AgoraErrorCode)errorCode {
    [self.tableView appendInfoToTableViewWithInfo:[NSString stringWithFormat:@"Error Code:%zd", errorCode]];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraUserOfflineReason)reason {
    [self.tableView appendInfoToTableViewWithInfo:[NSString stringWithFormat:@"Uid:%zd didOffline reason:%zd", uid, reason]];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didRejoinChannel:(NSString *)channel withUid:(NSUInteger)uid elapsed:(NSInteger)elapsed {
    [self.tableView appendInfoToTableViewWithInfo:[NSString stringWithFormat:@"Self Rejoin Channel"]];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didClientRoleChanged:(AgoraClientRole)oldRole newRole:(AgoraClientRole)newRole {
    NSString *newRoleStr = newRole == AgoraClientRoleAudience ? @"Audience" : @"Broadcast";
    [self.tableView appendInfoToTableViewWithInfo:[NSString stringWithFormat:@"Self became %@", newRoleStr]];
}

#pragma mark - StatusBar Style
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
