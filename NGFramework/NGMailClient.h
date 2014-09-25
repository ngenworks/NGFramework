//
//  NGMailClient.h
//  Photo Dialer
//
//  Created by Cody Kimberling on 7/3/14.
//  Copyright (c) 2014 nGen Works. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface NGMailClient : NSObject<MFMailComposeViewControllerDelegate>

+ (instancetype)sharedInstance;

- (BOOL)canSendMail;
- (void)sendEmailMessageFromViewController:(id)viewController toAddress:(NSString *)address;

@end
