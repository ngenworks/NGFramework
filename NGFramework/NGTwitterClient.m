//
//  NGSocialClient.m
//  NGFramework
//
//  Created by Cody Kimberling on 7/7/14.
//  Copyright (c) 2014 nGen Works. All rights reserved.
//

#import "NGTwitterClient.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import "NSError+NGUtils.h"


static NSString *kTwitterApiKey = @"L3NSoj4rMkmr3tnyNrmBzfo7T";
static NSString *kTwitterApiSecret = @"xIWyMOP5HzMAdFMtQzJFcjwXtUkPXoYiH6GK6k3tGHaXcVyLoa";

@interface NGTwitterClient ()

@property (nonatomic) BOOL requestInProgress;

@end

@implementation NGTwitterClient

- (BOOL)isTwitterServiceAvailable
{
    return [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter];
}

- (void)sendDirectMessageToUserNamed:(NSString *)username withMessage:(NSString *)message
{
    if (self.requestInProgress) {
        return;
    }
    
    ACAccountStore *accountStore = [ACAccountStore new];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    self.requestInProgress = YES;
    // Request access from the user to use their Twitter accounts.
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {

        if (granted) {
            NSArray *accounts = [accountStore accountsWithAccountType:accountType];
            
            if (accounts.count > 0) {
                ACAccount *account = accounts.firstObject;

                [self sendDirectMessage:message fromAccont:account toUser:username successBlock:^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSocialMessageSent object:nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidDismissOverlayView object:nil];
                    self.requestInProgress = NO;
                } andFailureBlock:^(NSError *error) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSocialMessageNotSent object:nil userInfo:@{kNotificationObjectKey : error}];
                    self.requestInProgress = NO;
                }];
            } else {
                self.requestInProgress = NO;
            }
            
        } else {
            NSError *error = [NSError errorWithMessage:@"NGFramework does not have access to your Twitter accounts.  Adjust this in Settings and try again." andCode:-1];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSocialMessageNotSent object:nil userInfo:@{kNotificationObjectKey : error}];
            self.requestInProgress = NO;
        }
    }];
}

#pragma mark - Twitter API Calls

- (void)sendDirectMessage:(NSString *)message fromAccont:(ACAccount *)account toUser:(NSString *)username successBlock:(NoArgumentBlock)successBlock andFailureBlock:(SingleArgumentBlock)failureBlock
{
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/direct_messages/new.json"];
    NSDictionary *params = @{@"screen_name" : username, @"text" : message};
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:url parameters:params];
    request.account = account;
    
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        
        // If successful, call success block
        if (!error && (urlResponse.statusCode == 200)) {
            if (successBlock) {
                successBlock();
            }
        } else {
            
            SingleArgumentBlock sendErrorWithMessage = ^(NSString *message) {
                NSError *error = [NSError errorWithMessage:message andCode:urlResponse.statusCode];
                if (failureBlock) {
                    failureBlock(error);
                }
            };
            
            // default error message
            NSString *errorMessage = @"Could not send Direct Message, try again";
            
            NSError *jsonParsingError;
            id json = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonParsingError];
            
            // if we have standard http error, a json parsing error, or the json was serialized into an unrecognized format
            // call the error block with the default message.
            if (error || jsonParsingError || ![json isKindOfClass:[NSDictionary class]]) {
                sendErrorWithMessage(errorMessage);
            }
            
            // Attempt to extract the Twitter error.  The @"errors" object of the dictionary is an array,
            // but we'll only grab the first object (if available) to have some containts on the UI of the error message
            // displayed to the user
            NSDictionary *jsonDict = (NSDictionary *)json;
            NSArray *errors = jsonDict[@"errors"];
            if (errors.count > 0) {
                errorMessage = errors[0][@"message"] ?: errorMessage;
            }
            
            sendErrorWithMessage(errorMessage);
        }
    }];
}

@end