//
//  NGContactEntry
//  NGFramework
//
//  Created by Cody Kimberling on 7/1/14.
//  Copyright (c) 2014 nGen Works. All rights reserved.
//

#import "NGContactEntry.h"

static NSString *kContactEntryTypeKey = @"type";
static NSString *kKeyKey = @"key";
static NSString *kValueKey = @"value";

@implementation NGContactEntry

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]){
        self.type = [aDecoder decodeIntegerForKey:kContactEntryTypeKey];
        self.key = [aDecoder decodeObjectForKey:kKeyKey];
        self.value = [aDecoder decodeObjectForKey:kValueKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:self.type forKey:kContactEntryTypeKey];
    [aCoder encodeObject:self.key forKey:kKeyKey];
    [aCoder encodeObject:self.value forKey:kValueKey];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    NGContactEntry *contactEntryCopy = [NGContactEntry new];
    contactEntryCopy.type = self.type;
    contactEntryCopy.key = self.key;
    contactEntryCopy.value = self.value;
    
    return contactEntryCopy;
}

- (NSString *)formattedValue
{
    if (self.type == NGContactEntryTypePhone) {
        NSCharacterSet *set = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
        return [[self.value componentsSeparatedByCharactersInSet:set] componentsJoinedByString:@""];
    }
    return self.value;
}

- (NSString *)description
{
    NSString *typeString = (self.type == NGContactEntryTypePhone) ? @"Phone" : @"Email";
    return [NSString stringWithFormat:@"(%@) %@ | %@", typeString, self.key, self.value];
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:NGContactEntry.class]){
        return NO;
    }
    
    NGContactEntry *obj = (NGContactEntry *)object;
    
    NSString *valueString = (NSString *)self.value;
    NSString *comparisonValueString = (NSString *)obj.value;

    return [valueString isEqualToString:comparisonValueString];
}

- (NSUInteger)hash
{
    return self.value.hash;
}

@end