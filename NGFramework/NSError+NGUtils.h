//
//  NSError+NGUtils.h
//  NGFramework
//
//  Created by Cody Kimberling on 7/9/14.
//  Copyright (c) 2014 nGen Works. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (NGUtils)

+ (NSError *)errorWithMessage:(NSString *)message andCode:(NSInteger)code;

@end