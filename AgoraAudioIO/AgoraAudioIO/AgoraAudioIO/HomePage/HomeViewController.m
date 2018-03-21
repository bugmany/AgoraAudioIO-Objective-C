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

@interface HomeViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *joinButton;
@property (weak, nonatomic) IBOutlet UILabel *welcomeLabel;
@property (weak, nonatomic) IBOutlet UITextField *channelNameTextField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sampleRateSegControl;
@property (strong, nonatomic) IBOutletCollection(ChooseButton) NSArray *ChooseButtonArray;

@property (weak, nonatomic) UIButton *lastButton;
@property (nonatomic, assign) AudioMode audioMode;
@property (strong, nonatomic) NSArray *sampleRateArray;

@end

@implementation HomeViewController

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = ThemeColor;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.channelNameTextField.delegate = self;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.joinButton.layer.cornerRadius = self.joinButton.height_SRX * 0.5;
    self.joinButton.backgroundColor = [UIColor whiteColor];
    [self.joinButton setTitleColor:ThemeColor forState:UIControlStateNormal];
    self.welcomeLabel.adjustsFontSizeToFitWidth = YES;
}


- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(nullable id)sender {
    BOOL YesOrNo = self.channelNameTextField.text.length > 0 ? YES : NO;
    YesOrNo = self.audioMode == 0 ? NO : YES;
    
    return YesOrNo;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(nullable id)sender {
    RoomViewController *roomVC = segue.destinationViewController;
    roomVC.channelName = self.channelNameTextField.text;
    roomVC.audioMode = self.audioMode;
    roomVC.sampleRate = (int)[self.sampleRateArray[self.sampleRateSegControl.selectedSegmentIndex] intValue];
}

- (IBAction)editingChannelName:(UITextField *)sender {
    
    NSString *legalChannelName = [SRXChannelNameCheck channelNameCheckLegal:sender.text];
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
            self.audioMode = AudioMode_SelfCapture_SDKRender;
            break;
            
        case 1:
            self.audioMode = AudioMode_SDKCapture_SDKRender;
            break;
            
        case 2:
            self.audioMode = AudioMode_SDKCapture_SDKRender;
            break;
            
        case 3:
            self.audioMode = AudioMode_SelfCapture_SelfRender;
            break;
    }
    
    self.lastButton = sender;
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
