//
//  NGSmsClient.m
//  NGFramework
//
//  Created by Cody Kimberling on 7/3/14.
//  Copyright (c) 2014 nGen Works. All rights reserved.
//

#import "NGSmsClient.h"


@interface NGSmsClient ()

@property (nonatomic) MFMessageComposeViewController *messageComposeViewController;

@end

@implementation NGSmsClient

+ (instancetype)sharedInstance
{
    static NGSmsClient *client = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        client = [[super allocWithZone:nil] init];
    });
    
    return [client init];
}

+ (id)allocWithZone:(NSZone *)zone
{
    return self.sharedInstance;
}

- (void)setupMailComposeViewController
{
    self.messageComposeViewController = [MFMessageComposeViewController new];
    self.messageComposeViewController.messageComposeDelegate = self;
}

- (BOOL)canSendText
{
    return [MFMessageComposeViewController canSendText];
}

- (void)sendTextFromViewController:(id)viewController toNumber:(NSString *)number
{
//    NSString *formatted = [NSString stringWithFormat:@"sms:%@", number];
//    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:formatted]]) {
//        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:formatted]];
//    }

    [self setupMailComposeViewController];
    [self.messageComposeViewController setRecipients:@[number]];

    [viewController presentViewController:self.messageComposeViewController animated:YES completion:nil];
}

#pragma mark - MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    if (result == MessageComposeResultCancelled) {
        [self.messageComposeViewController dismissViewControllerAnimated:YES completion:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidDismissOverlayView object:nil];
        }];
    }
    else if (result == MessageComposeResultSent) {
        [self.messageComposeViewController dismissViewControllerAnimated:YES completion:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidDismissOverlayView object:nil];
        }];
    }
    else if (result == MessageComposeResultFailed) {
        [self showErrorAlertView];
    }
    else {
        NSLog(@"Unknown error occurred sending message: %d", result);
    }
}

#pragma mark - Message Error Message

- (void)showErrorAlertView
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"An error occured while attempting to send this message, try again"
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles: nil];
    [alert show];
}

@end