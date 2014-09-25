//
//  NGContactUtils.h
//  NGFramework
//
//  Created by Cody Kimberling on 7/3/14.
//  Copyright (c) 2014 nGen Works. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NGContact.h"

@interface NGContactUtils : NSObject

+ (NGContactActionType)actionTypeForString:(NSString *)string;
+ (NSString *)actionTypeStringForActionType:(NGContactActionType)actionType;

+ (NSArray *)actionTypesForContact:(NGContact *)contact;
+ (NSString *)defaultActionTypeStringForContact:(NGContact *)contact;

+ (BOOL)isPhoneAction:(NGContactActionType)type;
+ (BOOL)isSocialAction:(NGContactActionType)type;
+ (BOOL)multipleEntriesForType:(NGContactActionType)type andContact:(NGContact *)contact;

+ (NGContact *)mergeWithContact:(NGContact *)contactIn withLinkedContact:(NGContact *)linkedContact;

@end