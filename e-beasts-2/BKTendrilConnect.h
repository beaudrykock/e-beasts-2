//
//  BKTendrilConnect.h
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

#import <UIKit/UIKit.h>
#import "NSData+Base64.h"
#import "PDKeychainBindingsController.h"
#import "BKTendrilAuth.h"

@protocol BKTendrilConnectDelegateProtocol <NSObject>
    -(void)tendrilConnectDidReturnData:(NSDictionary*)jsonDict forConnectionType:(NSInteger)connectionType;
    -(void)tendrilConnectDidFail;
@end

@interface BKTendrilConnect : NSObject <BKTendrilAuthDelegateProtocol>
{
    BKTendrilAuth *tendrilAuth;
    id <BKTendrilConnectDelegateProtocol> delegate;
    NSString *clientSecret;
    NSString *clientID;
    NSString *scope;
    NSString *xRoute;
    NSString * password;
    NSString * username;
    NSString * grantType;
    NSInteger userID;
    NSString *externalAccountID;
    NSMutableData * data;
    NSInteger requestType;
    BOOL authorized;
    BOOL parameterized;
}

@property (nonatomic, strong) NSString *externalAccountID;
@property (nonatomic) NSInteger requestType;
@property (nonatomic) BOOL authorized;
@property (nonatomic, assign) id <BKTendrilConnectDelegateProtocol> delegate;
@property (nonatomic, strong) BKTendrilAuth *tendrilAuth;
@property (nonatomic) NSInteger userID;
@property (nonatomic, copy) NSString *grantType;
@property (nonatomic, copy) NSString *scope;
@property (nonatomic, copy) NSString *xRoute;
@property (nonatomic, copy) NSString *clientSecret;
@property (nonatomic, copy) NSString *clientID;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, strong) NSMutableData *data;

-(void)authorize;
-(void)getProjectedConsumptionDataAtResolution:(NSString*)resolution;
-(void)getConsumptionDataFrom:(NSTimeInterval)fromSecs to:(NSTimeInterval)toSecs;
-(void)getUserInformation;
-(void)printAccessToken;
-(void)getMeterReadingFrom:(NSTimeInterval)fromSecs to:(NSTimeInterval)toSecs;

@end