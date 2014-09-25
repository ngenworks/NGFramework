//
//  NGContactSocialEntry.m
//  NGFramework
//
//  Created by Cody Kimberling on 7/7/14.
//  Copyright (c) 2014 nGen Works. All rights reserved.
//

#import "NGContactTwitterEntry.h"

static NSString *kUsernameKey = @"username";

@implementation NGContactTwitterEntry

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]){
        self.username = [aDecoder decodeObjectForKey:kUsernameKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.username forKey:kUsernameKey];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    NGContactTwitterEntry *contactTwitterEntryCopy = [NGContactTwitterEntry new];
    contactTwitterEntryCopy.username = self.username;
    
    return contactTwitterEntryCopy;
}

- (NSString *)description
{
    return self.username;
}

@end