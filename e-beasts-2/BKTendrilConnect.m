//
//  BKTendrilConnect.m
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

#import "BKTendrilConnect.h"

@implementation BKTendrilConnect

-(id)init {
    if ( self = [super init] ) {
        
    }
    return self;
}

// CALL THIS FIRST
-(void)authorize
{
    if (!parameterized)
    {
        [self setClientID:CLIENT_ID];
        [self setClientSecret:CLIENT_SECRET];
        [self setPassword:PASSWORD];
        [self setUsername:USERNAME];
        [self setUserID:USER_ID];
        [self setExternalAccountID:EXTERNAL_ACCOUNT_ID];
        [self setXRoute:X_ROUTE];
        [self setScope:SCOPE];
        [self setGrantType:GRANT_TYPE];
        
        parameterized = YES;
    }
    
    self.tendrilAuth = [[BKTendrilAuth alloc] init];
    [self.tendrilAuth setClientID:self.clientID];
    [self.tendrilAuth setClientSecret:self.clientSecret];
    [self.tendrilAuth setScope: self.scope];
    [self.tendrilAuth setPassword:self.password];
    [self.tendrilAuth setUsername:self.username];
    [self.tendrilAuth setGrantType:self.grantType];
    [self.tendrilAuth setXRoute:self.xRoute];
    [self.tendrilAuth setDelegate: self];
    
    [self.tendrilAuth authenticate];
}

-(void)getConsumptionDataFrom:(NSTimeInterval)fromSecs to:(NSTimeInterval)toSecs
{
    if (self.authorized)
    {
        self.data = [NSMutableData dataWithCapacity:500];
        self.requestType = kConsumption;
        
        NSString *fromStr = [self getTendrilDateFromTimeInterval:fromSecs];
        NSString *toStr = [self getTendrilDateFromTimeInterval:toSecs];
        
        NSString *consumptionUpdate = [NSString stringWithFormat:@"/connect/user/%i/account/default-account/%@/RANGE;from=%@;to=%@",self.userID, self.scope, fromStr, toStr];
            
        NSString *urlStr = [NSString stringWithFormat:@"%@%@", tendrilBaseURL, consumptionUpdate];
        
    #ifdef BKDEBUG
        NSLog(@"BKTendrilConnect: url for update = %@", urlStr);
    #endif
        
        NSMutableURLRequest* getRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
        [getRequest setHTTPMethod: @"GET"];
        
        [getRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [getRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [getRequest addValue:[self.tendrilAuth accessToken] forHTTPHeaderField:@"Access_Token"];
        
#ifdef BKDEBUG_VERBOSE
        NSDictionary *dict = [getRequest allHTTPHeaderFields];
        for (NSString *key in [dict keyEnumerator])
        {
            NSLog(@"%@: %@", key, [dict objectForKey:key]);
        }
        NSLog(@"BKTendrilConnect: HTTP Body: %@", [[NSString alloc] initWithData: [getRequest HTTPBody] encoding:NSUTF8StringEncoding]);
        
#endif
        
        [NSURLConnection connectionWithRequest:getRequest
                                      delegate:self];
        
    }
    else
    {
        NSLog(@"BKTendrilConnect: You are not authorized");
    }
}

-(void)getProjectedConsumptionDataAtResolution:(NSString*)resolution
{
    if (self.authorized)
    {
        self.data = [NSMutableData dataWithCapacity:500];
        self.requestType = kConsumptionProjection;
        
        NSString *consumptionProjection = [NSString stringWithFormat:@"/connect/user/%i/account/default-account/consumption/%@/projection",self.userID, resolution];
        
        NSString *urlStr = [NSString stringWithFormat:@"%@%@", tendrilBaseURL, consumptionProjection];
        
#ifdef BKDEBUG
        NSLog(@"BKTendrilConnect: url for update = %@", urlStr);
#endif
        
        NSMutableURLRequest* getRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
        [getRequest setHTTPMethod: @"GET"];
        
        [getRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [getRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [getRequest addValue:[self.tendrilAuth accessToken] forHTTPHeaderField:@"Access_Token"];
        
#ifdef BKDEBUG_VERBOSE
        NSDictionary *dict = [getRequest allHTTPHeaderFields];
        for (NSString *key in [dict keyEnumerator])
        {
            NSLog(@"%@: %@", key, [dict objectForKey:key]);
        }
        NSLog(@"BKTendrilConnect: HTTP Body: %@", [[NSString alloc] initWithData: [getRequest HTTPBody] encoding:NSUTF8StringEncoding]);
        
#endif
        
        [NSURLConnection connectionWithRequest:getRequest
                                      delegate:self];
        
    }
    else
    {
        NSLog(@"BKTendrilConnect: You are not authorized");
    }
}

-(void)getMeterReadingFrom:(NSTimeInterval)fromSecs to:(NSTimeInterval)toSecs
{
    if (self.authorized)
    {
        self.data = [NSMutableData dataWithCapacity:500];
        requestType = kMeterReading;
        
        NSString *fromStr = [self getTendrilDateFromTimeInterval:fromSecs];
        NSString *toStr = [self getTendrilDateFromTimeInterval:toSecs];;
        NSString *meterReadingRequest = [NSString stringWithFormat:@"/connect/meter/read;external-account-id=%@;from=%@;to=%@;limit-to-latest=20;source=ACTUAL",self.externalAccountID, fromStr, toStr];
        
        NSString *urlStr = [NSString stringWithFormat:@"%@%@", tendrilBaseURL, meterReadingRequest];
        
#ifdef BKDEBUG
        NSLog(@"BKTendrilConnect: url for meter reading request = %@", urlStr);
#endif
        
        NSMutableURLRequest* getRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
        [getRequest setHTTPMethod: @"GET"];
        
        [getRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [getRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [getRequest addValue:[self.tendrilAuth accessToken] forHTTPHeaderField:@"Access_Token"];
        
#ifdef BKDEBUG_VERBOSE
        NSDictionary *dict = [getRequest allHTTPHeaderFields];
        for (NSString *key in [dict keyEnumerator])
        {
            NSLog(@"%@: %@", key, [dict objectForKey:key]);
        }
        NSLog(@"BKTendrilConnect: HTTP Body: %@", [[NSString alloc] initWithData: [getRequest HTTPBody] encoding:NSUTF8StringEncoding]);
        
#endif
        
        [NSURLConnection connectionWithRequest:getRequest
                                      delegate:self];
        
    }
    else
    {
        NSLog(@"BKTendrilConnect: You are not authorized");
    }
}


-(void)getUserInformation
{
    if (self.authorized)
    {
        requestType = kUserInformation;
        
        NSString *userInfo = [NSString stringWithFormat:@"/connect/user/%i", self.userID];
        
        NSString *userInfoReq = [NSString stringWithFormat:@"%@%@", tendrilBaseURL, userInfo];
    #ifdef BKDEBUG
        NSLog(@"BKTendrilConnect: User information request URL = %@", userInfoReq);
    #endif
        
        NSMutableURLRequest* getRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:userInfoReq] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
        [getRequest setHTTPMethod: @"GET"];
        
        [getRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [getRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [getRequest addValue:[self.tendrilAuth accessToken] forHTTPHeaderField:@"Access_Token"];
        
#ifdef BKDEBUG_VERBOSE
        NSDictionary *dict = [getRequest allHTTPHeaderFields];
        for (NSString *key in [dict keyEnumerator])
        {
            NSLog(@"%@: %@", key, [dict objectForKey:key]);
        }
        NSLog(@"BKTendrilConnect: HTTP Body: %@", [[NSString alloc] initWithData: [getRequest HTTPBody] encoding:NSUTF8StringEncoding]);
        
#endif
        
        [NSURLConnection connectionWithRequest:getRequest
                                      delegate:self];
    }
    else
    {
        NSLog(@"BKTendrilConnect: You are not authorized");
    }
}

-(void)printAccessToken
{
    [self.tendrilAuth printAccessToken];
}

// returns date in Tendril preferred format, e.g. 2011-07-01T00:00:00-0000
-(NSString*)getTendrilDateFromTimeInterval:(NSTimeInterval)interval
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'hh:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    NSString *final = [NSString stringWithFormat:@"%@%@", [dateFormatter stringFromDate:date], @"-0000"];
    
#ifdef BKDEBUG_VERBOSE
    NSLog(@"BKTendrilConnect: tendril date = %@", final);
#endif
    return final;
}

#pragma mark - NSURLConnection delegate methods
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
#ifdef BKDEBUG
    NSLog(@"BKTendrilConnect: Connection failed");
    NSLog(@"BKTendrilConnect: %@", [error description]);
    NSDictionary *details = [error userInfo];
    for (NSString *key in [details keyEnumerator])
    {
        NSLog(@"%@: %@", key, [details objectForKey:key]);
    }
#endif
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)newData
{
    if (newData != nil){
        [self.data appendData:newData];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([response respondsToSelector:@selector(statusCode)]) {
         int statusCode = [((NSHTTPURLResponse *)response) statusCode];
         if (statusCode >= 400) {
             [connection cancel];
             NSDictionary * errorInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:NSLocalizedString(@"Server returned status code %d",@""),
             statusCode]
             forKey:NSLocalizedDescriptionKey];
             NSError * statusError = [NSError errorWithDomain:@"HTTP Property Status Code" //NSHTTPPropertyStatusCodeKey
             code:statusCode
             userInfo:errorInfo];
             [self connection:connection didFailWithError:statusError];
         }
     }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    
    NSString * response = [[NSString alloc] initWithData:self.data
                                                encoding:NSUTF8StringEncoding];
#ifdef BKDEBUG_VERBOSE
    NSLog(@"BKTendrilConnect: connectionDidFinishLoading response = %@, for request type %i", response, self.requestType);
#endif
    
    SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
    NSError *error = nil;
    NSDictionary *dictionary = [jsonParser objectWithString:response error:&error];
    
    [self.delegate tendrilConnectDidReturnData:dictionary forConnectionType:self.requestType];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return cachedResponse;
}

// needed because Tendril certificate not signed by Verisign
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

#pragma mark - BKTendrilAuth protocol
- (void)authorizationOutcome:(BOOL)success
{
    self.authorized = success;
    if (!self.authorized)
    {
        NSLog(@"BKTendrilConnect: Authorization failed");
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"authorization complete" object:nil];
    }
}

@end
