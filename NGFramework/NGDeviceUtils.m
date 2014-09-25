//
//  NGDeviceUtils.m
//  NGFramework
//
//  Created by Kyle Turner on 9/24/14.
//  Copyright (c) 2014 nGen Works. All rights reserved.
//

#import "NGDeviceUtils.h"

static CGFloat kPhoneWidth = 320.0;
static CGFloat kThreeInchPhoneHeight = 480.0;
static CGFloat kFourInchPhoneHeight = 568.0;

@implementation NGDeviceUtils

+ (BOOL)isPodIdiom
{
    return !([UIDevice.currentDevice.model.lowercaseString rangeOfString:@"ipod"].location == NSNotFound);
}

+ (BOOL)isPhoneIdiom
{
    return !([UIDevice.currentDevice.model.lowercaseString rangeOfString:@"iphone"].location == NSNotFound);
}

+ (BOOL)isPadIdiom
{
    return !([UIDevice.currentDevice.model.lowercaseString rangeOfString:@"ipad"].location == NSNotFound);
}

+ (BOOL)isFourInchDevice
{
    return (self.isPhoneIdiom || self.isPodIdiom) && (UIScreen.mainScreen.bounds.size.height == 568);
}

+ (BOOL)isThreeInchDevice
{
    return (self.isPhoneIdiom || self.isPodIdiom) && ![self isFourInchDevice];
}

+ (CGFloat)keyboardHeight
{
    return (self.isPhoneIdiom) ? 216.0 : 264.0;
}

+ (BOOL)isPortraitOrientation
{
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    return UIDeviceOrientationIsPortrait(interfaceOrientation);
}

+ (CGFloat)threeInchPhoneWidth
{
    return kPhoneWidth;
}

+ (CGFloat)threeInchPhoneHeight
{
    return kThreeInchPhoneHeight;
}

+ (CGFloat)fourInchPhoneWidth
{
    return kPhoneWidth;
}

+ (CGFloat)fourInchPhoneHeight
{
    return kFourInchPhoneHeight;
}

@end