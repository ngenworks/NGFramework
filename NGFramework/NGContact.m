//
//  NGContact.m
//  Photo Dialer
//
//  Created by Cody Kimberling on 7/1/14.
//  Copyright (c) 2014 nGen Works. All rights reserved.
//

#import "NGContact.h"
#import "CKStringUtils.h"
#import "NGMailClient.h"
#import "NGAddressBookUtils.h"
#import "CKStringUtils.h"
#import "NGContact.h"
#import "NGContactEntry.h"

static NSString *kIdentifierKey = @"identifier";
static NSString *kFirstNameKey = @"firstName";
static NSString *kLastNameKey = @"lastName";
static NSString *kEmailEntriesKey = @"emailEntries";
static NSString *kPhoneEntriesKey = @"phoneEntries";

static NSString *kSelectedEmailKey = @"selectedEmail";
static NSString *kSelectedFacetimeKey = @"selectedFacetime";
static NSString *kSelectedPhoneKey = @"selectedPhone";
static NSString *kSelectedTextKey = @"selectedText";

static NSString *kImageKey = @"image";
static NSString *kHasContactImageKey = @"hasContactImage";
static NSString *kTwitterEntryTypeKey = @"twitter";
static NSString *kDefaultActionTypeKey = @"defaultActionType";
static NSString *kDisplayOrderKey = @"displayOrder";

@implementation NGContact

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]){
        self.identifier = [aDecoder decodeObjectForKey:kIdentifierKey];
        self.firstName = [aDecoder decodeObjectForKey:kFirstNameKey];
        self.lastName = [aDecoder decodeObjectForKey:kLastNameKey];
        self.emailEntries = [aDecoder decodeObjectForKey:kEmailEntriesKey];
        self.phoneEntries = [aDecoder decodeObjectForKey:kPhoneEntriesKey];

        self.selectedEmail = [aDecoder decodeObjectForKey:kSelectedEmailKey];
        self.selectedFacetime = [aDecoder decodeObjectForKey:kSelectedFacetimeKey];
        self.selectedPhone = [aDecoder decodeObjectForKey:kSelectedPhoneKey];
        self.selectedText = [aDecoder decodeObjectForKey:kSelectedTextKey];
        
        self.image = [aDecoder decodeObjectForKey:kImageKey];
        self.hasContactImage = [aDecoder decodeBoolForKey:kHasContactImageKey];
        self.defaultActionType = [aDecoder decodeIntegerForKey:kDefaultActionTypeKey];
        self.twitterEntry = [aDecoder decodeObjectForKey:kTwitterEntryTypeKey];
        self.displayOrder = [aDecoder decodeIntegerForKey:kDisplayOrderKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.identifier forKey:kIdentifierKey];
    [aCoder encodeObject:self.firstName forKey:kFirstNameKey];
    [aCoder encodeObject:self.lastName forKey:kLastNameKey];
    [aCoder encodeObject:self.emailEntries forKey:kEmailEntriesKey];
    [aCoder encodeObject:self.phoneEntries forKey:kPhoneEntriesKey];

    [aCoder encodeObject:self.selectedEmail forKey:kSelectedEmailKey];
    [aCoder encodeObject:self.selectedFacetime forKey:kSelectedFacetimeKey];
    [aCoder encodeObject:self.selectedPhone forKey:kSelectedPhoneKey];
    [aCoder encodeObject:self.selectedText forKey:kSelectedTextKey];

    [aCoder encodeObject:self.image forKey:kImageKey];
    [aCoder encodeBool:self.hasContactImage forKey:kHasContactImageKey];
    [aCoder encodeInteger:self.defaultActionType forKey:kDefaultActionTypeKey];
    [aCoder encodeObject:self.twitterEntry forKey:kTwitterEntryTypeKey];
    [aCoder encodeInteger:self.displayOrder forKey:kDisplayOrderKey];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    NGContact *contactCopy = [NGContact new];
    contactCopy.identifier = self.identifier;
    contactCopy.firstName = self.firstName;
    contactCopy.lastName = self.lastName;
    contactCopy.emailEntries = self.emailEntries;
    contactCopy.phoneEntries = self.phoneEntries;
    
    contactCopy.selectedEmail = self.selectedEmail;
    contactCopy.selectedFacetime = self.selectedFacetime;
    contactCopy.selectedPhone = self.selectedPhone;
    contactCopy.selectedText = self.selectedText;

    contactCopy.image = self.image;
    contactCopy.hasContactImage = self.hasContactImage;
    contactCopy.defaultActionType = self.defaultActionType;
    contactCopy.twitterEntry = self.twitterEntry;
    contactCopy.displayOrder = self.displayOrder;

    return contactCopy;
}

- (void)clearSelectedDefaultValues
{
    self.selectedEmail = nil;
    self.selectedFacetime = nil;
    self.selectedPhone = nil;
    self.selectedText = nil;
}

#pragma mark - Helpers

// get the display name of the contact. Uses the user's choice of first, last or last, first name order from iOS settings
- (NSString *)displayName
{
    return [self compositeName:YES];
}

// used on favorites view when contact does not have an image. Uses sort order from user's address book to determine
// name to display
- (NSString *)shortName
{
    return [CKStringUtils defaultStringIfEmpty:self.lastName forString:self.firstName];
}

- (NSString *)sortName
{
    BOOL sortByFirstName = ([NGAddressBookUtils sharedInstance].sortByFirstName);
    return [self compositeName:sortByFirstName];
}

- (NSString *)compositeName:(BOOL)firstNameFirst
{
    NSString *firstField = (firstNameFirst) ? self.firstName : self.lastName;
    NSString *lastField = !(firstNameFirst) ? self.firstName : self.lastName;
    NSMutableString *name = [NSMutableString new];

    BOOL firstFieldNotEmpty = [CKStringUtils isNotEmpty:firstField];
    if (firstFieldNotEmpty) {
        [name appendString:firstField];
    }
    
    if ([CKStringUtils isNotEmpty:lastField]) {
        if (firstFieldNotEmpty) {
            NSString *lastFieldWithSpacePrefix = [NSString stringWithFormat:@" %@", lastField];
            [name appendString:lastFieldWithSpacePrefix];
        } else {
            [name appendString:lastField];
        }
    }
    return name;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"id: %@ | Name: %@ | Selected: Facetime=%@, Phone=%@, Text=%@, Email=%@ | Display Order: %ld", self.identifier.stringValue, self.displayName, self.selectedFacetime, self.selectedPhone, self.selectedText, self.selectedEmail, (long)self.displayOrder];
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:NGContact.class]){
        return NO;
    }
    
    return self.identifier.integerValue == [[object identifier] integerValue];
}

- (NSUInteger)hash
{
    return self.identifier.unsignedIntegerValue;
}

@end