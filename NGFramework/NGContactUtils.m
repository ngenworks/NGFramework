//
//  NGContactUtils.m
//  Photo Dialer
//
//  Created by Cody Kimberling on 7/3/14.
//  Copyright (c) 2014 nGen Works. All rights reserved.
//

#import "NGContactUtils.h"
#import "NGMailClient.h"
#import "NGSmsClient.h"
#import "NGTwitterClient.h"
#import "NGContactEntry.h"
#import "NGAddressBookUtils.h"
#import "CKStringUtils.h"
#import "NGDeviceUtils.h"

@implementation NGContactUtils

+ (NSArray *)actionTypesForContact:(NGContact *)contact
{
    // use a set so action types (facetime) are not added more than once
    NSMutableSet *actionTypes = [NSMutableSet new];

    if (contact.phoneEntries.count > 0) {
        // all devices can use facetime
        [actionTypes addObject:kFacetimeDisplayName];
        
        // only phones are allowed to use make calls
        // while iPods and iPads can use iMessages, they cannot
        // send messages to non-iMessage devices, so we'll leave them out
        if ([NGDeviceUtils isPhoneIdiom]) {
            [actionTypes addObject:kPhoneDisplayName];
            
            if ([[NGSmsClient sharedInstance] canSendText]){
                [actionTypes addObject:kTextDisplayName];
            }
        }
    }
    
    if (contact.emailEntries.count > 0) {
        // add facetime
        [actionTypes addObject:kFacetimeDisplayName];
        
        if ([[NGMailClient sharedInstance] canSendMail]) {
            [actionTypes addObject:kEmailDisplayName];
        }
    }
    
    // if twitter and an account is setup
    if (contact.twitterEntry && [[NGTwitterClient new] isTwitterServiceAvailable]) {
        [actionTypes addObject:kTwitterDisplayName];
    }

    return [[actionTypes.allObjects sortedArrayUsingSelector:@selector(compare:)] mutableCopy];
}

+ (NGContactActionType)actionTypeForString:(NSString *)string
{
    if ([string isEqualToString:kPhoneDisplayName]) {
        return NGContactActionTypePhone;
    }
    
    if ([string isEqualToString:kTextDisplayName]) {
        return NGContactActionTypeText;
    }
    
    if ([string isEqualToString:kFacetimeDisplayName]) {
        return NGContactActionTypeFacetime;
    }
    
    if ([string isEqualToString:kEmailDisplayName]) {
        return NGContactActionTypeEmail;
    }
    
    if ([string isEqualToString:kTwitterDisplayName]) {
        return NGContactActionTypeTwitter;
    }
    return NGContactActionTypeUknown;
}

+ (NSString *)actionTypeStringForActionType:(NGContactActionType)actionType
{
    if (actionType == NGContactActionTypePhone) {
        return kPhoneDisplayName;
    }
    
    if (actionType == NGContactActionTypeText) {
        return kTextDisplayName;
    }
    
    if (actionType == NGContactActionTypeFacetime) {
        return kFacetimeDisplayName;
    }
    
    if (actionType == NGContactActionTypeEmail) {
        return kEmailDisplayName;
    }
    
    if (actionType == NGContactActionTypeTwitter) {
        return kTwitterDisplayName;
    }
    return kUnknownDisplayName;
}

+ (NSString *)defaultActionTypeStringForContact:(NGContact *)contact
{
    return [self actionTypeStringForActionType:contact.defaultActionType];
}

+ (BOOL)isPhoneAction:(NGContactActionType)type
{
    return (type == NGContactActionTypePhone || type == NGContactActionTypeText || type == NGContactActionTypeFacetime);
}

+ (BOOL)isSocialAction:(NGContactActionType)type
{
    return (type == NGContactActionTypeTwitter);
}

// determine if a contact with given action type has multiple entries
+ (BOOL)multipleEntriesForType:(NGContactActionType)type andContact:(NGContact *)contact
{
    // Twitter is the only social action at the time and only one account is currently supported
    if ([self isSocialAction:type]) {
        return NO;
    }

    // If a default has been selected, no need to display secondary picker
    BOOL hasSelectedValue = contact.selectedEmail || contact.selectedFacetime || contact.selectedPhone || contact.selectedText;

    if (hasSelectedValue) {
        return NO;
    }

    NSInteger emailCount = (contact.emailEntries.count) ?: 0;
    NSInteger phoneCount = (contact.phoneEntries.count) ?: 0;
    
    // if more than one email. All devices can make facetime calls, return YES
    if (emailCount > 1) {
        return YES;
    }

    // if more than one phone & type is phone (phone, text, facetime) - return YES
    if ([self isPhoneAction:type] && (phoneCount > 1)) {
        return YES;
    }
    
    // if type if facetime and email + phone counts are larger than 1
    if (type == NGContactActionTypeFacetime) {
        return (emailCount + phoneCount) > 1;
    }

    // default to NO
    return NO;
}

#pragma mark - Merge methods (used when dealing with linked contacts)

+ (NGContact *)mergeWithContact:(NGContact *)contactIn withLinkedContact:(NGContact *)linkedContact
{
    NGContact *mergedContact = [contactIn copy];
    
    // firstName
    if ([CKStringUtils isEmpty:contactIn.firstName] && [CKStringUtils isNotEmpty:linkedContact.firstName]) {
        mergedContact.firstName = linkedContact.firstName;
    }
    
    // lastName
    if ([CKStringUtils isEmpty:contactIn.lastName] && [CKStringUtils isNotEmpty:linkedContact.lastName]) {
        mergedContact.lastName = linkedContact.lastName;
    }
    
    // selected defaults
    if ([CKStringUtils isEmpty:contactIn.selectedEmail] && [CKStringUtils isNotEmpty:linkedContact.selectedEmail]) {
        mergedContact.selectedEmail = linkedContact.selectedEmail;
    }
    
    if ([CKStringUtils isEmpty:contactIn.selectedFacetime] && [CKStringUtils isNotEmpty:linkedContact.selectedFacetime]) {
        mergedContact.selectedFacetime = linkedContact.selectedFacetime;
    }
    
    if ([CKStringUtils isEmpty:contactIn.selectedPhone] && [CKStringUtils isNotEmpty:linkedContact.selectedPhone]) {
        mergedContact.selectedPhone = linkedContact.selectedPhone;
    }

    if ([CKStringUtils isEmpty:contactIn.selectedText] && [CKStringUtils isNotEmpty:linkedContact.selectedText]) {
        mergedContact.selectedText = linkedContact.selectedText;
    }
    
    // email
    mergedContact.emailEntries = [self mergedEntriesWithContact:contactIn linkedContact:linkedContact andEntryType:NGContactEntryTypeEmail];
    
    // phone
    mergedContact.phoneEntries = [self mergedEntriesWithContact:contactIn linkedContact:linkedContact andEntryType:NGContactEntryTypePhone];
    
    // image.  override only if image does not exist on contact
    if (!contactIn.image && linkedContact.image) {
        mergedContact.image = linkedContact.image;
    }
    
    // Twitter. override only if image does not exist on contact
    if (!contactIn.twitterEntry && linkedContact.twitterEntry) {
        mergedContact.twitterEntry = linkedContact.twitterEntry;
    }
    
    return mergedContact;
}

+ (NSArray *)mergedEntriesWithContact:(NGContact *)contactIn linkedContact:(NGContact *)linkedContact andEntryType:(NGContactEntryType)type
{
    NSArray *originalEntries = (type == NGContactEntryTypeEmail) ? contactIn.emailEntries : contactIn.phoneEntries;
    NSArray *newEntries = (type == NGContactEntryTypeEmail) ? linkedContact.emailEntries : linkedContact.phoneEntries;
    
    NSMutableSet *mergedEntries = [NSMutableSet new];
    
    if (originalEntries.count > 0) {
        [mergedEntries addObjectsFromArray:originalEntries];
    }
    
    if (newEntries.count > 0) {
        
        [mergedEntries addObjectsFromArray:newEntries];
    }
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"key" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    return [mergedEntries sortedArrayUsingDescriptors:@[descriptor]];
}

@end