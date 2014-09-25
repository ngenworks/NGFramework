//
//  NGConstants.h
//  NGFramework
//
//  Created by Cody Kimberling on 7/9/14.
//  Copyright (c) 2014 nGen Works. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NGConstants : NSObject

FOUNDATION_EXPORT NSString * const kNotificationObjectKey;
FOUNDATION_EXPORT NSString * const kNotificationSocialMessageSent;
FOUNDATION_EXPORT NSString * const kNotificationSocialMessageNotSent;
FOUNDATION_EXPORT NSString * const kNotificationUpdatingContacts;
FOUNDATION_EXPORT NSString * const kNotificationDidUpdateContacts;
FOUNDATION_EXPORT NSString * const kNotificationDidRemoveContact;
FOUNDATION_EXPORT NSString * const kNotificationDidDismissOverlayView;

@end