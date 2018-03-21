//
//  LogAudioSessionStatus.m
//  AgoraAudioIO
//
//  Created by CavanSu on 14/12/2017.
//  Copyright © 2017 Agora. All rights reserved.
//

#import "LogAudioSessionStatus.h"
#import <AVFoundation/AVFoundation.h>

/*
 // MixWithOthers is only valid with AVAudioSessionCategoryPlayAndRecord, AVAudioSessionCategoryPlayback, and  AVAudioSessionCategoryMultiRoute
 AVAudioSessionCategoryOptionMixWithOthers            = 0x1,
 
 
 
 // DuckOthers is only valid with AVAudioSessionCategoryAmbient, AVAudioSessionCategoryPlayAndRecord, AVAudioSessionCategoryPlayback, and AVAudioSessionCategoryMultiRoute
AVAudioSessionCategoryOptionDuckOthers                = 0x2,
 
 
 
// AllowBluetooth is only valid with AVAudioSessionCategoryRecord and AVAudioSessionCategoryPlayAndRecord
AVAudioSessionCategoryOptionAllowBluetooth    __TVOS_PROHIBITED __WATCHOS_PROHIBITED        = 0x4,
 
 
 
// DefaultToSpeaker is only valid with AVAudioSessionCategoryPlayAndRecord
AVAudioSessionCategoryOptionDefaultToSpeaker __TVOS_PROHIBITED __WATCHOS_PROHIBITED        = 0x8,
 
 
 
// InterruptSpokenAudioAndMixWithOthers is only valid with AVAudioSessionCategoryPlayAndRecord, AVAudioSessionCategoryPlayback, and AVAudioSessionCategoryMultiRoute
AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers NS_AVAILABLE_IOS(9_0) = 0x11,
 
 
 
// AllowBluetoothA2DP is only valid with AVAudioSessionCategoryPlayAndRecord
AVAudioSessionCategoryOptionAllowBluetoothA2DP API_AVAILABLE(ios(10.0), watchos(3.0), tvos(10.0)) = 0x20,
 
 
// AllowAirPlay is only valid with AVAudioSessionCategoryPlayAndRecord
AVAudioSessionCategoryOptionAllowAirPlay API_AVAILABLE(ios(10.0), tvos(10.0)) __WATCHOS_PROHIBITED = 0x40,
 
 */

@implementation LogAudioSessionStatus

+ (void)logAudioSessionStatusWithCallPosition:(NSString *)position {
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    NSLog(@"<LogAudio> category : %@, categoryOptions : %lu , mode : %@", [session category], (unsigned long)[session categoryOptions], [session mode]);
    
    for (AVAudioSessionPortDescription *pd in [session currentRoute].inputs) {
        NSLog(@"<LogAudio> currentRoute Inputs : %@", pd.portName);
    }
    
    for (AVAudioSessionPortDescription *pd in [session currentRoute].outputs) {
        NSLog(@"<LogAudio> currentRoute Outputs : %@", pd.portName);
    }
    
    NSLog(@"<LogAudio> sampleRate : %f", [session preferredSampleRate]);
    NSLog(@"<LogAudio> -----------------------position : %@", position);
}

@end
