//
//  SRXHomeViewController.m
//  OpenVoiceCall-OC
//
//  Created by CavanSu on 2017/9/16.
//  Copyright © 2017 Agora. All rights reserved.
//

#import "HomeViewController.h"
#import "ChannelNameCheck.h"
#import "RoomViewController.h"
#import "ChooseButton.h"
#import "AudioOptions.h"
#import "DefaultChannelName.h"

@interface HomeViewController () <UITextFieldDelegate>
@property (strong, nonatomic) IBOutletCollection(ChooseButton) NSArray *ChooseButtonArray;
@property (weak, nonatomic) IBOutlet UIButton *joinButton;
@property (weak, nonatomic) IBOutlet UILabel *welcomeLabel;
@property (weak, nonatomic) IBOutlet UITextField *channelNameTextField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sampleRateSegControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *chaModeSegControl;

@property (nonatomic, assign) AudioCRMode audioMode;
@property (nonatomic, assign) ChannelMode channelMode;
@property (nonatomic, assign) ClientRole clientRole;
@property (nonatomic, strong) NSArray *sampleRateArray;
@property (nonatomic, weak) UIButton *lastButton;
@end

@implementation HomeViewController

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = ThemeColor;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateViews];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.joinButton.layer.cornerRadius = self.joinButton.height_CS * 0.5;
}

- (void)updateViews {
    self.channelNameTextField.delegate = self;
    self.channelNameTextField.text = [DefaultChannelName getDefaultChannelName];
    
    self.joinButton.backgroundColor = [UIColor whiteColor];
    [self.joinButton setTitleColor:ThemeColor forState:UIControlStateNormal];
    self.welcomeLabel.adjustsFontSizeToFitWidth = YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(nullable id)sender {
    int sampleRate = (int)[self.sampleRateArray[self.sampleRateSegControl.selectedSegmentIndex] intValue];
    
    RoomViewController *roomVC = segue.destinationViewController;
    roomVC.channelName = self.channelNameTextField.text;
    roomVC.audioMode = self.audioMode;
    roomVC.channelMode = self.channelMode;
    roomVC.sampleRate = sampleRate;
    if (roomVC.channelMode == ChannelModeLiveBroadcast) {
        roomVC.clientRole = self.clientRole;
    }
}

- (IBAction)editingChannelName:(UITextField *)sender {
    NSString *legalChannelName = [ChannelNameCheck channelNameCheckLegal:sender.text];
    sender.text = legalChannelName;
}

- (IBAction)chooseMode:(UIButton *)sender {
    if (self.lastButton == sender) {
        self.audioMode = 0;
        self.lastButton = nil;
        return;
    }
    
    for (ChooseButton *btn in self.ChooseButtonArray) {
        if (btn != sender) {
            [btn cancelSelected];
        }
    }
    
    switch (sender.tag) {
        case 0:
            self.audioMode = AudioCRMode_ExterCapture_SDKRender;
            break;
        case 1:
            self.audioMode = AudioCRMode_SDKCapture_ExterRender;
            break;
        case 2:
            self.audioMode = AudioCRMode_SDKCapture_SDKRender;
            break;
        case 3:
            self.audioMode = AudioCRMode_ExterCapture_ExterRender;
            break;
    }

    self.lastButton = sender;
}

- (IBAction)joinButtonClick:(UIButton *)sender {
    self.channelMode = self.chaModeSegControl.selectedSegmentIndex == 0 ? ChannelModeCommunication : ChannelModeLiveBroadcast;
    
    if (self.channelMode == ChannelModeLiveBroadcast) {
        [self presentClientOptions];
    }
    else {
        [self enterRoom];
    }
}

- (void)enterRoom {
    BOOL YesOrNo = self.channelNameTextField.text.length > 0 ? YES : NO;
    YesOrNo = self.audioMode == 0 ? NO : YES;
    if (YesOrNo == NO) return;
    [DefaultChannelName setDefaultChannelName:self.channelNameTextField.text];
    [self performSegueWithIdentifier:@"MainToRoom" sender:nil];
}

- (void)presentClientOptions {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Choose Role" message:nil preferredStyle:UIAlertControllerStyleAlert];
    __weak HomeViewController *weaself = self;
    UIAlertAction *audience = [UIAlertAction actionWithTitle:@"Audience" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        weaself.clientRole = ClientRoleAudience;
        [weaself enterRoom];
    }];
    
    UIAlertAction *broadcast = [UIAlertAction actionWithTitle:@"Broadcast" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        weaself.clientRole = ClientRoleBroadcast;
        [weaself enterRoom];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:audience];
    [alert addAction:broadcast];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.channelNameTextField endEditing:YES];
    return YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.channelNameTextField endEditing:YES];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (NSArray *)sampleRateArray {
    if (!_sampleRateArray) {
        _sampleRateArray = @[@44100, @48000];
    }
    return _sampleRateArray;
}

@end
