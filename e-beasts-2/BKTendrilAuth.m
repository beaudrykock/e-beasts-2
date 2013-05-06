//
//  BKTendrilAuth.m
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

#import "BKTendrilAuth.h"

@interface BKTendrilAuth ()
-(void)storeTokenDetails;
-(void)loadTokenDetails;
-(BOOL)hasStoredToken;
-(void)requestAuthToken;
-(void)refreshAuthToken;
@end

@implementation NSString (URLEncode)
- (NSString *) urlEncode
{
    NSString * encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                                     (__bridge CFStringRef)self,
                                                                                                     NULL,
                                                                                                     (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                     kCFStringEncodingUTF8));
    return encodedString;
}
@end

@implementation BKTendrilAuth

-(id)init {
    if ( self = [super init] ) {
    }
    return self;
}

-(void)authenticate
{
    self.data = [NSMutableData dataWithCapacity:500];
    
    // Use this to populate keychain with access token/refresh token from web or other source
    //[self setTestDetails];
    
    [self loadTokenDetails];
    
    if (![self hasStoredToken])
    {
        [self requestAuthToken];
    }
    else if ([self hasStoredToken] && ![self tokenIsCurrent])
    {
        [self refreshAuthToken];
    }
    else
    {
        [self.delegate authorizationOutcome:YES];
    }
}

- (void)requestAuthToken
{
    self.requestType = kNewToken;
    
    NSString* fullTokenURL = [NSString stringWithFormat:@"%@%@",tendrilBaseURL,tokenURL];

#ifdef BKDEBUG
    NSLog(@"request token URL = %@", fullTokenURL);
#endif
    
    NSMutableURLRequest* postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fullTokenURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    [postRequest setHTTPMethod: @"POST"];
    
    NSString * oauth_client_id = [self.clientID urlEncode];
    NSString * oauth_client_secret = [self.clientSecret urlEncode];
    NSString * oauth_grant_type = [self.grantType urlEncode];
    NSString * oauth_scope = [self.scope urlEncode];
    NSString * oauth_x_route = [self.xRoute urlEncode];
    NSString * oauth_password = [self.password urlEncode];
    NSString * oauth_username = [self.username urlEncode];
    
    NSArray * parameterArray =  [NSArray arrayWithObjects:
                                 [NSString stringWithFormat:@"%@%%3D%@", @"client_id", oauth_client_id],
                                 [NSString stringWithFormat:@"%@%%3D%@", @"client_secret", oauth_client_secret],
                                 [NSString stringWithFormat:@"%@%%3D%@", @"grant_type", oauth_grant_type],
                                 [NSString stringWithFormat:@"%@%%3D%@", @"username", oauth_username],
                                 [NSString stringWithFormat:@"%@%%3D%@", @"password", oauth_password],
                                 [NSString stringWithFormat:@"%@%%3D%@", @"scope", oauth_scope],
                                 [NSString stringWithFormat:@"%@%%3D%@", @"x_route", oauth_x_route],
                                 nil];
    [postRequest setHTTPBody:[[parameterArray componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding]];
    NSString* userAgent = @"iOS";
    [postRequest setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    
    [self.data setLength:0];
    
#ifdef BKDEBUG_VERBOSE
    NSDictionary *dict = [postRequest allHTTPHeaderFields];
    for (NSString *key in [dict keyEnumerator])
    {
        NSLog(@"%@: %@", key, [dict objectForKey:key]);
    }
    NSLog(@"HTTP body: %@", [[NSString alloc] initWithData: [postRequest HTTPBody] encoding:NSUTF8StringEncoding]);
    
#endif
    
    [NSURLConnection connectionWithRequest:postRequest
                                  delegate:self];
}

- (void)refreshAuthToken
{
    self.requestType = kRefreshToken;
    
    
    NSString* fullTokenURL = [NSString stringWithFormat:@"%@%@",tendrilBaseURL,tokenURL];
    
#ifdef BKDEBUG
    NSLog(@"BKTendrilAuth: refresh token URL = %@", fullTokenURL);
#endif
    
    NSMutableURLRequest* postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fullTokenURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    
    [postRequest setHTTPMethod: @"POST"];
    
    NSString * oauth_grant_type = [@"refresh_token" urlEncode];
    NSString * oauth_refresh_token = [self.refreshToken urlEncode];
    NSString * oauth_scope = [self.scope urlEncode];
    
    NSArray * parameterArray =  [NSArray arrayWithObjects:
                                 [NSString stringWithFormat:@"%@%%3D%@", @"grant_type", oauth_grant_type],
                                 [NSString stringWithFormat:@"%@%%3D%@", @"refresh_token", oauth_refresh_token],
                                 [NSString stringWithFormat:@"%@%%3D%@", @"scope", oauth_scope],
                                 nil];
    
    [postRequest setHTTPBody:[[parameterArray componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSString* userAgent = @"iOS";
    [postRequest setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    
    [self.data setLength:0];
    
#ifdef BKDEBUG_VERBOSE
    NSDictionary *dict = [postRequest allHTTPHeaderFields];
    for (NSString *key in [dict keyEnumerator])
    {
        NSLog(@"%@: %@", key, [dict objectForKey:key]);
    }
    NSLog(@"HTTP Body: %@", [[NSString alloc] initWithData: [postRequest HTTPBody] encoding:NSUTF8StringEncoding]);
    
#endif
    
    [NSURLConnection connectionWithRequest:postRequest
                                  delegate:self];
}

#pragma mark - NSURLConnection delegate methods
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"BKTendrilConnect: authorization failed");
    NSLog(@"BKTendrilConnect: %@", [error description]);
    NSDictionary *details = [error userInfo];
    for (NSString *key in [details keyEnumerator])
    {
        NSLog(@"%@: %@", key, [details objectForKey:key]);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)newData
{
    if (newData != nil){
#ifdef BKDEBUG_VERBOSE
        NSLog(@"appending data... %@", [[NSString alloc] initWithData:newData encoding:NSUTF8StringEncoding]);
        NSLog(@"data length = %i", [self.data length]);
#endif
        [self.data appendData:newData];
    }
}

-(NSURLRequest*)connection:(NSURLConnection*)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    
    
#ifdef BKDEBUG_VERBOSE
    NSLog(@"redirection");
    NSDictionary *dict = [request allHTTPHeaderFields];
    for (NSString *key in [dict keyEnumerator])
    {
        NSLog(@"%@: %@", key, [dict objectForKey:key]);
    }
    NSLog(@"HTTP URL: %@", [request URL]);
    NSLog(@"HTTP Body: %@", [[NSString alloc] initWithData: [request HTTPBody] encoding:NSUTF8StringEncoding]);
    NSLog(@"HTTP method: %@", [request HTTPMethod]);
#endif
    
    NSURLRequest *newRequest = request;
    if (response) {
        newRequest = nil;
    }
    return newRequest;
    
    
    
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
             NSError * statusError = [NSError errorWithDomain:@"HTTP Property Status Code" code:statusCode userInfo:errorInfo];
             [self connection:connection didFailWithError:statusError];
         }
     }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    
    NSString * response = [[NSString alloc] initWithData:self.data
                                                 encoding:NSUTF8StringEncoding];
    
#ifdef BKDEBUG_VERBOSE
    NSLog(@"BKTendrilConnect: response = %@, for request type %i", response, self.requestType);
#endif
    
    SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
    NSError *error = nil;
    NSDictionary *dictionary = [jsonParser objectWithString:response error:&error];
    
    if ([dictionary objectForKey:json_accessToken])
    {
#ifdef BKDEBUG
        NSLog(@"Successfully obtained access token");
#endif
        self.accessToken = [dictionary objectForKey:json_accessToken];
        self.refreshToken = [dictionary objectForKey:json_refreshToken];
        self.accessTokenDetails = [NSDictionary dictionaryWithObjectsAndKeys:[dictionary objectForKey:json_expiresIn], json_expiresIn,
                                   [dictionary objectForKey:json_issuedAt], json_issuedAt,
                                   [dictionary objectForKey:json_scope], json_scope,nil];
        [self storeTokenDetails];
        
        [self.delegate authorizationOutcome:YES];
    }
    else
    {
        [self.delegate authorizationOutcome:NO];
    }
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

#pragma mark - Token management
-(BOOL)hasStoredToken
{
    return [[[PDKeychainBindings sharedKeychainBindings] objectForKey:kc_accessTokenKey] length]>0;
}

-(BOOL)tokenIsCurrent
{
    NSString *issuedAtStr = [self.accessTokenDetails objectForKey:json_issuedAt];
    NSString *expiresInStr = [self.accessTokenDetails objectForKey:json_expiresIn];
    
#ifdef BKDEBUG_VERBOSE
    NSLog(@"BKTendrilAuth: issuedAtStr = %@", issuedAtStr);
    NSLog(@"BKTendrilAuth: expiresInStr = %@", expiresInStr);
#endif
    
    NSTimeInterval issuedAt = [issuedAtStr longLongValue];
    NSTimeInterval expiresIn = [expiresInStr integerValue];
    
    NSDate *date = [NSDate date];
    NSTimeInterval current = [date timeIntervalSince1970]*1000;
    NSTimeInterval expiry = issuedAt+(expiresIn*1000);
    
#ifdef BKDEBUG_VERBOSE
    NSLog(@"BKTendrilAuth: current = %f", current);
    NSLog(@"BKTendrilAuth: expiry = %f", expiry);
#endif
    
    if (current>expiry)
        return NO;
    return YES;
}

-(void)storeTokenDetails
{
    PDKeychainBindings *bindings=[PDKeychainBindings sharedKeychainBindings];
    [bindings setObject:self.accessToken forKey:kc_accessTokenKey];
    [bindings setObject:self.refreshToken forKey:kc_refreshTokenKey];
    
    [[NSUserDefaults standardUserDefaults] setObject:self.accessTokenDetails forKey:ud_accessTokenDetailsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setTestDetails
{
    self.accessToken = @"<INSERT ACCESS TOKEN FOR TESTING>";
    self.refreshToken = @"<INSERT REFRESH TOKEN FOR TESTING>";
    
    self.accessTokenDetails = [NSDictionary dictionaryWithObjectsAndKeys:@"<INSERT EXPIRES IN>", json_expiresIn,
                               @"<INSERT ISSUED AT>", json_issuedAt,
                               @"<INSERT CONSUMPTION>", json_scope,nil];
    
    [self storeTokenDetails];
}

-(void)loadTokenDetails
{
    self.accessToken = [[PDKeychainBindings sharedKeychainBindings] objectForKey:kc_accessTokenKey];
    self.refreshToken = [[PDKeychainBindings sharedKeychainBindings] objectForKey:kc_refreshTokenKey];
    self.accessTokenDetails = [[NSUserDefaults standardUserDefaults] dictionaryForKey:ud_accessTokenDetailsKey];
    
#ifndef BKDEBUG
    NSLog(@"Access token as string: %@", self.accessToken);
    NSLog(@"Refresh token as string: %@", self.refreshToken);
#endif
}

-(void)printAccessToken
{
    NSLog(@"Access token as string: %@", self.accessToken);
    NSLog(@"Refresh token as string: %@", self.refreshToken);
}

@end
