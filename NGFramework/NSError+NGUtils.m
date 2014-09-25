//
//  NSError+NGUtils.m
//  NGFramework
//
//  Created by Cody Kimberling on 7/9/14.
//  Copyright (c) 2014 nGen Works. All rights reserved.
//

#import "NSError+NGUtils.h"

@implementation NSError (NGUtils)

+ (NSError *)errorWithMessage:(NSString *)message andCode:(NSInteger)code
{
    return [NSError errorWithDomain:@"com.ngenworks" code:code userInfo:@{NSLocalizedDescriptionKey : message}];
}

@end