//
//  NGDeviceUtils.h
//  NGFramework
//
//  Created by Kyle Turner on 9/24/14.
//  Copyright (c) 2014 nGen Works. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NGDeviceUtils : NSObject

+ (BOOL)isPodIdiom;
+ (BOOL)isPhoneIdiom;
+ (BOOL)isPadIdiom;
+ (BOOL)isFourInchDevice;
+ (BOOL)isThreeInchDevice;
+ (BOOL)isPortraitOrientation;

+ (CGFloat)threeInchPhoneWidth;
+ (CGFloat)threeInchPhoneHeight;
+ (CGFloat)fourInchPhoneWidth;
+ (CGFloat)fourInchPhoneHeight;

@end