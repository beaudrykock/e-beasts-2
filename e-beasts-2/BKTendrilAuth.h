//
//  BKTendrilAuth.h
//  tendril-test
//
//  Created by Beaudry Kock on 8/13/12.
//  Copyright (c) 2012 Beaudry Kock / Better World Coding. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.

#import <Foundation/Foundation.h>
#import "SharedConstants.h"
#import "PDKeychainBindingsController.h"
#import "SBJsonParser.h"

// **DO NOT MODIFY**
//-----------------------------------------------------------

#define kNewToken 0
#define kRefreshToken 1

#define tokenURL @"/oauth/access_token"

// STORING ACCESS TOKEN +  DETAILS
#define ud_accessTokenDetailsKey @"accessTokenDetailsKey"
#define kc_refreshTokenKey @"refreshTokenKey"
#define kc_accessTokenKey @"accessTokenKey"

// ACCESS TOKEN JSON PARAMETERS
#define json_accessToken @"access_token"
#define json_refreshToken @"refresh_token"
#define json_issuedAt @"issued_at"
#define json_expiresIn @"expires_in"
#define json_scope @"scope"

@interface NSString (URLEncode)
- (NSString *) urlEncode;
@end

@protocol BKTendrilAuthDelegateProtocol <NSObject>

- (void)authorizationOutcome:(BOOL)success;

@end

@interface BKTendrilAuth : NSObject
{
    id <BKTendrilAuthDelegateProtocol> delegate;
    NSString * clientID;
    NSString * clientSecret;
    NSString * grantType;
    NSString * scope;
    NSString * xRoute;
    NSString * password;
    NSString * username;
    NSString* accessToken;
    NSString* refreshToken;
    NSDictionary *accessTokenDetails;
    NSMutableData * data;
    NSInteger requestType;
}

@property (nonatomic, assign) id <BKTendrilAuthDelegateProtocol> delegate;
@property (nonatomic) NSInteger requestType;
@property (nonatomic, copy) NSString *scope;
@property (nonatomic, copy) NSString *xRoute;
@property (nonatomic, copy) NSString *grantType;
@property (nonatomic, copy) NSString *clientSecret;
@property (nonatomic, copy) NSString *clientID;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, copy) NSString *refreshToken;
@property (nonatomic, strong) NSDictionary *accessTokenDetails;
@property (nonatomic, strong) NSMutableData *data;

// PUBLIC METHODS
-(void)authenticate;
-(BOOL)tokenIsCurrent;
-(void)printAccessToken;

@end
