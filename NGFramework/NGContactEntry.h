//
//  NGContactEntry
//  Photo Dialer
//
//  Created by Cody Kimberling on 7/1/14.
//  Copyright (c) 2014 nGen Works. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSInteger {
    NGContactEntryTypePhone,
    NGContactEntryTypeEmail
} NGContactEntryType;

@interface NGContactEntry : NSObject<NSCoding, NSCopying>

@property (nonatomic) NGContactEntryType type;
@property (nonatomic) NSString *key;
@property (nonatomic) NSString *value;

- (NSString *)formattedValue;

@end