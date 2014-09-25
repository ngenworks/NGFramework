//
//  NGSocialClient.h
//  Photo Dialer
//
//  Created by Cody Kimberling on 7/7/14.
//  Copyright (c) 2014 nGen Works. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Social/Social.h>

@interface NGTwitterClient : NSObject

- (BOOL)isTwitterServiceAvailable;
- (void)sendDirectMessageToUserNamed:(NSString *)username withMessage:(NSString *)message;

@end