//
//  NGAddressBookUtils.m
//  Photo Dialer
//
//  Created by Cody Kimberling on 7/1/14.
//  Copyright (c) 2014 nGen Works. All rights reserved.
//

#import "NGAddressBookUtils.h"
#import "NGContact.h"
#import "CKStringUtils.h"
#import "NGContactEntry.h"
#import "NGContactTwitterEntry.h"
//#import "CKDeviceUtils.h"
#import "NGContactUtils.h"
#import <AddressBookUI/AddressBookUI.h>

@interface NGAddressBookUtils ()

@property (nonatomic) ABAddressBookRef addressBook;
@property (nonatomic, copy) NoArgumentBlock successBlock;
@property (nonatomic, copy) NoArgumentBlock failureBlock;

@end

@implementation NGAddressBookUtils

+ (instancetype)sharedInstance;
{
    static NGAddressBookUtils *sharedInstance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        if (!sharedInstance) {
            sharedInstance = [[super allocWithZone:nil] init];
        }
    });
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedInstance];
}

- (BOOL)canAccessAddressBook
{
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    
    return (status != kABAuthorizationStatusDenied);
}

- (void)fetchContacts
{
    NoArgumentBlock failureBlock = ^{};

    if (!self.deviceContacts) {
        self.deviceContacts = [NSMutableDictionary new];
    }

    // property indicating fetching is currently processing...
    if (!self.isFetchingDeviceContacts)
        self.isFetchingDeviceContacts = YES;

    NSLog(@"1) fetchContacts");
    [self fetchOrRequestAndFetchAddressBookContactsWithSuccessBlock:^(NSArray *contacts){
        [contacts enumerateObjectsUsingBlock:^(NGContact *contact, NSUInteger idx, BOOL *stop) {
            // Populate a dictionary containing the starting letter of the display name
            // with an array of contacts that match that requirement
            NSString *firstLetter = [NSString stringWithFormat:@"%C", [contact.sortName characterAtIndex:0]];
            if (!self.deviceContacts[firstLetter]) {
                self.deviceContacts[firstLetter] = [NSMutableArray new];
                [self.deviceContacts[firstLetter] addObject:contact];
            } else {
                if (![self.deviceContacts[firstLetter] containsObject:contact])
                    [self.deviceContacts[firstLetter] addObject:contact];
            }
        }];

        // re-order and group contacts by alphabet letter
        for (NSString *letter in self.deviceContacts.allKeys) {
            self.deviceContacts[letter] = [self orderedValuesForKey:letter];
        }
        self.isFetchingDeviceContacts = NO;
        
        // now that contacts have finished loading, lets notify views that may need updating
        NSLog(@"Contacts finished loading, updating UI...");
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidUpdateContacts object:nil];
    } andFailureBlock:failureBlock];
}

- (NSArray *)orderedKeys
{
    return [self.deviceContacts.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (NSMutableArray *)orderedValuesForKey:(NSString *)key
{
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortName" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSSet *set = self.deviceContacts[key];
    NSMutableArray *sortedContacts = [NSMutableArray arrayWithArray:[[set allObjects] sortedArrayUsingDescriptors:@[sort]]];
    return sortedContacts;
}

- (void)fetchOrRequestAndFetchAddressBookContactsWithSuccessBlock:(SingleArgumentBlock)successBlock andFailureBlock:(NoArgumentBlock)failureBlock;
{
    // Set success and failure blocks from caller's block definitions
    self.successBlock = successBlock;
    self.failureBlock = failureBlock;
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    if(addressBook) {
        self.addressBook = CFAutorelease(addressBook);
        
        ABAddressBookRegisterExternalChangeCallback(self.addressBook, nil, (__bridge void *)(self));
        NSLog(@"2) fetchOrRequestAndFetchAddressBookContactsWithSuccessBlock.ABAddressBookRequestAccessWithCompletion");
        ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [self initializeContactsArrayFromAddressBookContacts];
            });
        });
    } else {
        if (self.failureBlock) {
            self.failureBlock();
        }
    }
}

- (void)initializeContactsArrayFromAddressBookContacts
{
    NSLog(@"3) initializeContactsArrayFromAddressBookContacts");
    // Address book instance should exist, otherwise bail
    ABAddressBookRef addressBook = self.addressBook;
    if (!addressBook) {
        if (self.failureBlock) {
            self.failureBlock();
        }
        return;
    }

    // ALL people from address book, including duplicates via Linked Contacts/et al
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex numberOfPeople  = ABAddressBookGetPersonCount(addressBook);
    
    // set contact count so we can check progress indicator
    self.contactCount = numberOfPeople;

    // aggregate set to collect merged between top-level and linked contacts
    NSMutableSet *unifiedContactSet = [NSMutableSet set];
    
    // list of linked persons already added to final contact list
    NSMutableSet *linkedPersonsToSkip = [NSMutableSet set];

    NSLog(@"4) looping to create contacts, this may take some time...");
    // iterate over all address book people
    for (int i = 0; i < numberOfPeople; i++) {
        ABRecordRef person = CFArrayGetValueAtIndex(allPeople, i);
        
        // Skip this linked person next time, as weve already added to the final set
        if ([linkedPersonsToSkip containsObject:(__bridge id)(person)]) {
            continue;
        }

        // create contact
        NGContact *contact = [self mergedContactComposedOfTopLevelContactWithAllLinkedContactsFromPerson:person];

        if (contact) {
            // check if there are linked contacts & merge their contact info
            NSArray *linkedRecordsArray = (__bridge NSArray *)ABPersonCopyArrayOfAllLinkedPeople(person);
            if (linkedRecordsArray.count > 1) {
                // to be skipped next time this top-level person exists, if applicable
                [linkedPersonsToSkip addObjectsFromArray:linkedRecordsArray];

                // merge linked contact info
                for (int m=0; m < linkedRecordsArray.count; m++) {
                    ABRecordRef iLinkedPerson = (__bridge ABRecordRef)([linkedRecordsArray objectAtIndex:m]);

                    // skip if same person
                    if (iLinkedPerson == person) {
                        continue;
                    }
                    // merge original contact with linked contact
                    NGContact *linkedContact = [self contactFromPerson:iLinkedPerson];
                    contact = [NGContactUtils mergeWithContact:contact withLinkedContact:linkedContact];
                }
            }
            // add merged contact to list of unified people
            [unifiedContactSet addObject:contact];

            SEL progressSelector = NSSelectorFromString(@"updateLoadingProgressIndicatorWithValue:");

            // increment the number of contacts that have been loaded
            self.contactsLoadedCount = self.contactsLoadedCount + 1;

            if ([self.contactLoadingProgressDelegate respondsToSelector:progressSelector]) {
                NSNumber *progressCount = [self progressCount];
                // update UI thread for contact loading indicator (ContactsVC)
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.contactLoadingProgressDelegate performSelector:progressSelector withObject:progressCount];
                });

            }
        }
    }
    // assuring contact has a valid means of communication before adding them to the list
    NSArray *updatedContacts = [self arrayOfContactsContainingAtLeastOneActionTypeFromContacts:unifiedContactSet.allObjects];

    // sort list of contacts by "sortName" property
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortName" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSArray *sortedContacts = [updatedContacts sortedArrayUsingDescriptors:@[sort]];

    // C memory cleanup - TODO: We may need a few more of these :)
    CFRelease(addressBook);
    CFRelease(allPeople);

    NSLog(@"6) Calling success block");

    // call success block, assuming one exists
    if (self.successBlock) {
        // if delegate is a loading indicator delegate, update UI thread for 100% progress
        SEL progressSelector = NSSelectorFromString(@"updateLoadingProgressIndicatorWithValue:");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.contactLoadingProgressDelegate performSelector:progressSelector withObject:[NSNumber numberWithFloat:1.0]];
        });
        self.successBlock(sortedContacts);
    }
}

- (NSNumber *)progressCount
{
    // convenience for calculating overall contact loading progress
    float percentage = (float)self.contactsLoadedCount / (float)self.contactCount;
    NSNumber *progress = [NSNumber numberWithFloat:percentage];
    return progress;
}

- (NGContact *)mergedContactComposedOfTopLevelContactWithAllLinkedContactsFromPerson:(ABRecordRef)person
{
    // first, create the contact instance from the person object
    __block NGContact *contact = [self contactFromPerson:person];

    // now, unfortunately, we need to lookup the linked contacts for this user
    if (contact) {
        NSMutableArray *linkedContacts = [NSMutableArray new];
        NSArray *linked = (__bridge NSArray *) ABPersonCopyArrayOfAllLinkedPeople(person);
        if (linked.count > 1) {
            // merge linked contact info
            for (int j = 0; j < linked.count; j++) {
                ABRecordRef linkedPerson = CFBridgingRetain(linked[j]);
                
                // if not same object, add to collection
                if (linkedPerson != person) {
                    NGContact *linkedContact = [self contactFromPerson:linkedPerson];
                    if (linkedContact) {
                        [linkedContacts addObject:linkedContact];
                    }
                }
            }
        }
        // iterate over linked contacts, and merge them with the existing top-level contact instance
        [linkedContacts enumerateObjectsUsingBlock:^(NGContact *linkedContact, NSUInteger index, BOOL *stop) {
            // merge top-level contact with linked contact.
            contact = [NGContactUtils mergeWithContact:contact withLinkedContact:linkedContact];
        }];
    }

    return contact;
}

- (NSArray *)arrayOfContactsContainingAtLeastOneActionTypeFromContacts:(NSArray *)contacts
{
    NSMutableArray *updatedContacts = [NSMutableArray new];
    [contacts enumerateObjectsUsingBlock:^(NGContact *contact, NSUInteger idx, BOOL *stop) {
        if ([NGContactUtils actionTypesForContact:contact].count > 0){
            [updatedContacts addObject:contact];
        }
    }];
    return updatedContacts;
}

- (NSArray *)updatedContactsFromContacts:(NSArray *)contacts
{
    ABAddressBookRef addressBook = self.addressBook;
    if (!addressBook) {
        return contacts;
    }
    
    NSMutableArray *updatedContacts = [NSMutableArray new];
    
    [contacts enumerateObjectsUsingBlock:^(NGContact *oldContact, NSUInteger index, BOOL *stop) {
        
        ABRecordID recordID = oldContact.identifier.intValue;
        ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook, recordID);
        
        NGContact *contact = [self contactFromPerson:person];
        
        if (contact) {
            
            [self mergeContact:contact withLinkedContactsFromPerson:person];
            
            // Only override the default action type if it is unknown, otherwise, the
            // contact only has one option and the default has already been set
            if (contact.defaultActionType == NGContactActionTypeUknown) {
                contact.defaultActionType = oldContact.defaultActionType;
            }
            
            if (contact.displayOrder == NSIntegerMax) {
                contact.displayOrder = oldContact.displayOrder;
            }

            contact.selectedFacetime = oldContact.selectedFacetime;
            contact.selectedPhone = oldContact.selectedPhone;
            contact.selectedEmail = oldContact.selectedEmail;
            contact.selectedText = oldContact.selectedText;
            
            [updatedContacts addObject:contact];
        }
    }];
    
    return updatedContacts;
}

- (void)updateContactImageFromContact:(NGContact *)contact withImage:(UIImage *)image
{
    ABAddressBookRef addressBook = self.addressBook;
    ABRecordID recordID = contact.identifier.intValue;
    ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook, recordID);

    NSData *imageData = UIImageJPEGRepresentation(image, 1);
    CFErrorRef *error;
    ABPersonSetImageData(person, (__bridge CFDataRef)imageData, error);
    ABAddressBookSave (addressBook, error);
    CFRelease(addressBook);
}

- (void)mergeContact:(NGContact *)contact withLinkedContactsFromPerson:(ABRecordRef)person
{
    // check if there are linked contacts & merge their contact information
    NSArray *linked = (__bridge NSArray *) ABPersonCopyArrayOfAllLinkedPeople(person);
    if (linked.count > 1) {
        
        // merge linked contact info
        for (int j = 0; j < linked.count; j++) {
            ABRecordRef linkedPerson = CFBridgingRetain(linked[j]);
            
            // merge if not same object
            if (linkedPerson != person) {
                NGContact *linkedContact = [self contactFromPerson:linkedPerson];
                if (linkedContact) {
                    contact = [NGContactUtils mergeWithContact:contact withLinkedContact:linkedContact];
                }
            }
        }
    }
}

- (BOOL)sortByFirstName
{
    ABPersonSortOrdering sortOrder = ABPersonGetSortOrdering();
    return (sortOrder == kABPersonSortByFirstName);
}

#pragma mark - Helpers

- (NGContactTwitterEntry *)twitterEntryForPerson:(ABRecordRef)person
{
    NGContactTwitterEntry *socialEntry;
    
    NSArray *linkedPeople = (__bridge_transfer NSArray *)ABPersonCopyArrayOfAllLinkedPeople(person);
    
    for (int x = 0; x < linkedPeople.count; x++) {
        ABMultiValueRef socialApps = ABRecordCopyValue((__bridge ABRecordRef)[linkedPeople objectAtIndex:x], kABPersonSocialProfileProperty);
        
        CFIndex socialCount = ABMultiValueGetCount(socialApps);
        
        for (int i = 0; i < socialCount; i++) {
            NSDictionary *socialItem = (__bridge_transfer NSDictionary*)ABMultiValueCopyValueAtIndex(socialApps, i);
            
            NSString *socialProfileServiceString = [socialItem objectForKey:(NSString *)kABPersonSocialProfileServiceKey];
            
            NSString *profileServiceString = (NSString *)kABPersonSocialProfileServiceTwitter;
            
            if ([socialProfileServiceString isEqualToString:profileServiceString]) {
                
                NSString *username = [socialItem objectForKey:(NSString *)kABPersonSocialProfileUsernameKey];
                
                if ([CKStringUtils isNotEmpty:username]) {
                    socialEntry = [NGContactTwitterEntry new];
                    socialEntry.username = username;
                }
            }
        }
        
        if (!socialApps) {
            CFRelease(socialApps);
        }
    }
    return socialEntry;
}

- (NSArray *)contactEntriesForPerson:(ABRecordRef)person withRawArray:(NSArray *)array ofType:(NGContactEntryType)type andProperty:(ABMultiValueRef)property
{
    NSMutableArray *entries = @[].mutableCopy;
    [array enumerateObjectsUsingBlock:^(NSString *emailAddress, NSUInteger idx, BOOL *stop) {
        
        NGContactEntry *entry = NGContactEntry.new;
        
        CFStringRef locLabel = ABMultiValueCopyLabelAtIndex(property, idx);
        entry.type = type;
        entry.key = (__bridge NSString*) ABAddressBookCopyLocalizedLabel(locLabel);
        entry.value = [CKStringUtils stringByTrimmingLeadingAndTrailingWhitespaceCharactersInString:emailAddress];
        
        [entries addObject:entry];
    }];
    
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"key" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    return [entries sortedArrayUsingDescriptors:@[descriptor]];
}

- (NGContact *)contactFromPerson:(ABRecordRef)person
{
    if (!person) {
        return nil;
    }
    
    NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSString *lastName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
    
    ABMultiValueRef phoneProperty = ABRecordCopyValue(person, kABPersonPhoneProperty);
    NSArray *phoneArray = (__bridge_transfer NSArray *)ABMultiValueCopyArrayOfAllValues(phoneProperty);
    CFRelease(phoneProperty);
    
    ABMultiValueRef emailProperty = ABRecordCopyValue(person, kABPersonEmailProperty);
    NSArray *emailArray = (__bridge_transfer NSArray *)ABMultiValueCopyArrayOfAllValues(emailProperty);
    CFRelease(emailProperty);
    
    
    NGContactTwitterEntry *twitterSocialEntry = [self twitterEntryForPerson:person];
    
    BOOL firstOrLastNamePopulated = ([CKStringUtils isNotEmpty:firstName] || [CKStringUtils isNotEmpty:lastName]);
    BOOL phoneNumbersPopulated = (phoneArray.count > 0);
    BOOL emailAddressesPopulated = (emailArray.count > 0);
    
    BOOL atLeastOneRequiredFieldPopulated = (phoneNumbersPopulated || emailAddressesPopulated || twitterSocialEntry);
    
    if (!firstOrLastNamePopulated || !atLeastOneRequiredFieldPopulated) {
        return nil;
    }
    
    ABRecordID recordId = ABRecordGetRecordID(person);
    
    NGContact *contact = NGContact.new;
    contact.defaultActionType = NGContactActionTypeUknown;
    contact.displayOrder = NSIntegerMax;
    contact.identifier = [NSNumber numberWithInt:recordId];
    contact.firstName = [CKStringUtils defaultStringIfEmpty:@"" forString:firstName];
    contact.lastName = [CKStringUtils defaultStringIfEmpty:@"" forString:lastName];
    contact.twitterEntry = twitterSocialEntry;
    
    // Photo
    NSData *photoData;
    if(ABPersonCopyImageDataWithFormat) {
        photoData = (NSData *)CFBridgingRelease(ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail));
    } else {
        photoData = (NSData *)CFBridgingRelease(ABPersonCopyImageData(person));
    }
    
    UIImage *image = [UIImage imageWithData:photoData];
    if (image) {
        contact.image = image;
        contact.hasContactImage = YES;
    } else {
        contact.image = nil;
        contact.hasContactImage = NO;
    }
    
    // Entries (Phone/Email)
    contact.emailEntries = [self contactEntriesForPerson:person withRawArray:emailArray ofType:NGContactEntryTypeEmail andProperty:emailProperty];
    contact.phoneEntries = [self contactEntriesForPerson:person withRawArray:phoneArray ofType:NGContactEntryTypePhone andProperty:phoneProperty];
    
    // Set the default action type if only one action type exists for the user
    NSArray *actionTypes = [NGContactUtils actionTypesForContact:contact];
    
    if (actionTypes.count == 1) {
        NSString *actionName = actionTypes[0];
        contact.defaultActionType = [NGContactUtils actionTypeForString:actionName];
    }
    
    return contact;
}

- (ABAddressBookRef)addressBook
{
    CFErrorRef error = nil;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    
    if(!addressBook){
        return nil;
    }
    
    if(error){
        CFRelease(addressBook);
        return nil;
    }
    
    return addressBook;
}

#pragma mark - Dummy Contact Creation

- (ABRecordID)createNewGroup:(NSString *)groupName
{
    ABAddressBookRef addressBook = [self addressBook];
    bool GROUP_EXISTS = NO;
    ABRecordID groupID = NSIntegerMax;

    // check existing groups, dont create duplicate
    CFArrayRef groups = ABAddressBookCopyArrayOfAllGroups(addressBook);
    for (int i=0; i < ABAddressBookGetGroupCount(addressBook); i++) {
        ABRecordRef group = CFArrayGetValueAtIndex(groups, i);
        NSString *groupName = (__bridge_transfer NSString *)ABRecordCopyValue(group, kABGroupNameProperty);

        // if desired group to delete is found, set group ID and leave loop
        if ([groupName isEqualToString:groupName]) {
            NSLog(@"Group '%@' already exists, not creating duplicate, but adding contacts.", groupName);
            groupID = ABRecordGetRecordID(group);
            GROUP_EXISTS = YES;
            break;
        }
    }
    if (!GROUP_EXISTS) {
        NSLog(@"Creating new group: '%@'", groupName);
        ABRecordRef newGroup = ABGroupCreate();
        ABRecordSetValue(newGroup, kABGroupNameProperty, (__bridge CFTypeRef)(groupName), nil);
        ABAddressBookAddRecord(addressBook, newGroup, nil);
        ABAddressBookSave(addressBook, nil);
        CFRelease(addressBook);

        // must save GroupRecordID for later use!
        groupID = ABRecordGetRecordID(newGroup);
        CFRelease(newGroup);
    }
    return groupID;
}

- (void)createDummyContactsWithCount:(int)contactCount
{
    ABRecordID groupRecordID = [self createNewGroup:@"Dummy Contacts"];
    ABAddressBookRef addressBook = [self addressBook];

    for (int i=0; i < contactCount; i++) {
        ABRecordRef newPerson = ABPersonCreate();

        // add person info
        ABRecordSetValue(newPerson, kABPersonFirstNameProperty, CFSTR("Alberto"), nil);
        ABRecordSetValue(newPerson, kABPersonLastNameProperty, CFSTR("Pasca"), nil);
        ABRecordSetValue(newPerson, kABPersonOrganizationProperty, CFSTR("albertopasca.it"), nil);

        ABMutableMultiValueRef multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        
        ABMultiValueAddValueAndLabel(multiPhone, @"328-1111111", kABHomeLabel, NULL);
        ABMultiValueAddValueAndLabel(multiPhone,@"02-222222", kABWorkLabel, NULL);
        ABRecordSetValue(newPerson, kABPersonPhoneProperty, multiPhone,nil);
        CFRelease(multiPhone);

        ABMutableMultiValueRef multiEmail = ABMultiValueCreateMutable(kABMultiStringPropertyType);

        ABMultiValueAddValueAndLabel(multiEmail, @"info@albertopasca.it", kABWorkLabel, NULL);
        ABMultiValueAddValueAndLabel(multiEmail, @"alberto@home.com", kABHomeLabel, NULL);

        ABRecordSetValue(newPerson, kABPersonEmailProperty, multiEmail, nil);

        CFRelease(multiEmail);

        ABAddressBookAddRecord(addressBook, newPerson, nil);

        ABRecordRef group = ABAddressBookGetGroupWithRecordID(addressBook, groupRecordID);
        ABGroupAddMember(group, newPerson, nil);

        CFRelease(newPerson);
    }
    ABAddressBookSave(addressBook, nil);
    CFRelease(addressBook);
}

- (void)deleteGroupAndContactsWithName:(NSString *)groupName
{
    ABAddressBookRef addressBook = [self addressBook];
    CFArrayRef groups = ABAddressBookCopyArrayOfAllGroups(addressBook);
    ABRecordID groupID = 0;
    
    for (int i=0; i < ABAddressBookGetGroupCount(addressBook); i++) {
        ABRecordRef group = CFArrayGetValueAtIndex(groups, i);
        NSString *groupName = (__bridge_transfer NSString *)ABRecordCopyValue(group, kABGroupNameProperty);
        
        // if desired group to delete is found, set group ID and leave loop
        if ([groupName isEqualToString:groupName]) {
            groupID = ABRecordGetRecordID(group);
            break;
        }
        else {
            NSLog(@"Group '%@' not found, exiting...", groupName);
            groupID = NSIntegerMax;
            return;
        }
    }
    ABAddressBookRef group = ABAddressBookGetGroupWithRecordID(addressBook, groupID);

    // lookup group members
    CFArrayRef groupMembers = ABGroupCopyArrayOfAllMembers(group);
    CFIndex sourceCount = 0;

    if (groupMembers)
        sourceCount = CFArrayGetCount(groupMembers);

    for (int i=0; i < sourceCount; i++) {
        ABRecordRef member = CFArrayGetValueAtIndex(groupMembers, i);
        bool removed = ABGroupRemoveMember(group, member, nil);
        bool deletedMember = ABAddressBookRemoveRecord(addressBook, member, nil);

        NSLog(@"Member '%@' removed from group: '%d', deleted: %d", ABRecordCopyValue(member, kABPersonLastNameProperty), removed, deletedMember);
    }
    CFErrorRef error = NULL;
    ABAddressBookRemoveRecord(addressBook, group, &error);
    ABAddressBookSave(addressBook, &error);
}

@end