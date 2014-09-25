//
//  NGMailClient.m
//  NGFramework
//
//  Created by Cody Kimberling on 7/3/14.
//  Copyright (c) 2014 nGen Works. All rights reserved.
//

#import "NGMailClient.h"

@interface NGMailClient ()

@property (nonatomic) MFMailComposeViewController *mailComposeViewController;

@end

@implementation NGMailClient

+ (instancetype)sharedInstance
{
    static NGMailClient *client = nil;
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
    self.mailComposeViewController = [MFMailComposeViewController new];
    self.mailComposeViewController.mailComposeDelegate = self;
}

- (BOOL)canSendMail
{
    return MFMailComposeViewController.canSendMail;
}

- (void)sendEmailMessageFromViewController:(id)viewController toAddress:(NSString *)address
{
    [self setupMailComposeViewController];
    [self.mailComposeViewController setToRecipients:@[address]];

    [viewController presentViewController:self.mailComposeViewController animated:YES completion:nil];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self.mailComposeViewController dismissViewControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidDismissOverlayView object:nil];
    }];
}

#pragma mark - Mail Error Message

- (void)showErrorAlertView
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"An error occured while attempting to send an email message, try again"
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles: nil];
    [alert show];
}

@end