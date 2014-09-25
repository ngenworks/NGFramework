//
//  NGContact.h
//  NGFramework
//
//  Created by Cody Kimberling on 7/1/14.
//  Copyright (c) 2014 nGen Works. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import "NGContactTwitterEntry.h"

typedef enum : NSInteger {
    NGContactActionTypeUknown,
    NGContactActionTypePhone,
    NGContactActionTypeText,
    NGContactActionTypeFacetime,
    NGContactActionTypeEmail,
    NGContactActionTypeTwitter
} NGContactActionType;

static NSString *kUnknownDisplayName = @"Unnown";
static NSString *kPhoneDisplayName = @"Phone";
static NSString *kTextDisplayName = @"Text";
static NSString *kFacetimeDisplayName = @"FaceTime";
static NSString *kEmailDisplayName = @"Email";
static NSString *kTwitterDisplayName = @"Twitter";

@interface NGContact : NSObject<NSCoding, NSCopying>

@property (nonatomic) NSNumber *identifier;
@property (nonatomic) NSString *firstName;
@property (nonatomic) NSString *lastName;
@property (nonatomic) NSArray *emailEntries;
@property (nonatomic) NSArray *phoneEntries;

@property (nonatomic) NSString *selectedEmail;
@property (nonatomic) NSString *selectedPhone;
@property (nonatomic) NSString *selectedText;
@property (nonatomic) NSString *selectedFacetime;

@property (nonatomic) UIImage *image;
@property (nonatomic) BOOL hasContactImage;
@property (nonatomic) NGContactActionType defaultActionType;
@property (nonatomic) NGContactTwitterEntry *twitterEntry;
@property (nonatomic) NSInteger displayOrder;

- (NSString *)displayName;
- (NSString *)shortName;
- (NSString *)sortName;
- (void)clearSelectedDefaultValues;

@end