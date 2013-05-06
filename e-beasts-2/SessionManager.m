//
//  SessionManager.m
//  e-beasts-2
//
//  Created by Beaudry Kock on 10/22/12.
//  Copyright (c) 2012 Beaudry Kock. All rights reserved.
//

#import "SessionManager.h"

@implementation SessionManager

static SessionManager* sharedSingleton = nil;

+(SessionManager*)sharedSessionManager
{
    if (sharedSingleton == nil)
    {
        sharedSingleton = [[super allocWithZone:NULL] init];
    }
    return sharedSingleton;
}

+(id)allocWithZone:(NSZone *)zone
{
    return [[self sharedSessionManager] retain];
}

-(id)copyWithZone:(NSZone*)zone
{
    return self;
}

-(id)retain
{
    return self;
}

-(NSUInteger)retainCount
{
    return NSUIntegerMax;
}

-(void)release
{
    
}

-(id)autorelease
{
    return self;
}

@end
