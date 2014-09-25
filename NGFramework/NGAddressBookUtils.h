//
//  NGAddressBookUtils.h
//  NGFramework
//
//  Created by Cody Kimberling on 7/1/14.
//  Copyright (c) 2014 nGen Works. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NGContact.h"


@interface NGAddressBookUtils : NSObject

+ (instancetype)sharedInstance;

- (BOOL)canAccessAddressBook;
- (void)fetchContacts;
- (void)fetchOrRequestAndFetchAddressBookContactsWithSuccessBlock:(SingleArgumentBlock)successBlock andFailureBlock:(NoArgumentBlock)failureBlock;

- (NSArray *)updatedContactsFromContacts:(NSArray *)contacts;
- (void)updateContactImageFromContact:(NGContact *)contact withImage:(UIImage *)image;
- (BOOL)sortByFirstName;

// Progress of loading contacts into memory
- (NSNumber *)progressCount;

// Dummy Contact Creation/Deletion
- (void)createDummyContactsWithCount:(int)contactCount;
- (void)deleteGroupAndContactsWithName:(NSString *)groupName;

@property (nonatomic) NSMutableDictionary *deviceContacts;
@property (assign, nonatomic) NSInteger contactCount;
@property (assign, nonatomic) NSInteger contactsLoadedCount;
@property (assign) BOOL isFetchingDeviceContacts;
@property (assign, nonatomic) id contactLoadingProgressDelegate;

@end