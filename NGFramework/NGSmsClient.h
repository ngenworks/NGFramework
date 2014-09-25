//
//  NGSmsClient.h
//  NGFramework
//
//  Created by Cody Kimberling on 7/3/14.
//  Copyright (c) 2014 nGen Works. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MFMessageComposeViewController.h>

@interface NGSmsClient : NSObject<MFMessageComposeViewControllerDelegate>

+ (instancetype)sharedInstance;

- (BOOL)canSendText;
- (void)sendTextFromViewController:(id)viewController toNumber:(NSString *)number;

@end