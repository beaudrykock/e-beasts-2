//
//  Utilities.m
//  e-beasts
//
//  Created by Beaudry Kock on 8/16/12.
//  Copyright (c) 2012 University of Oxford. All rights reserved.
//

#import "Utilities.h"

@implementation Utilities

+(NSTimeInterval)secondsAtLastLaunch
{
    NSTimeInterval secondsAtLastLaunch = -1;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"secondsAtLastLaunch"])
    {
        NSNumber *number = (NSNumber*)[[NSUserDefaults standardUserDefaults] objectForKey:@"secondsAtLastLaunch"];
        secondsAtLastLaunch = [number longLongValue];
    }
    NSDate *date = [NSDate date];
    NSTimeInterval now = [date timeIntervalSince1970];
    
    if (secondsAtLastLaunch<0 || secondsAtLastLaunch < (now-(3600*24)))
    {
        return (now-(3600*24));
    }
    return secondsAtLastLaunch;
}

+(void)setSecondsAtLaunch:(NSTimeInterval)seconds
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLongLong:seconds] forKey:@"secondsAtLastLaunch"];
}

// call this ONCE on application launch; session ID is then stored in the app delegate
+(NSInteger)generateSessionID
{
    NSInteger oldSessionID = 0;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"sessionID"])
    {
        oldSessionID = [[NSUserDefaults standardUserDefaults] integerForKey:@"sessionID"];
    }
    NSInteger newSessionID = oldSessionID+1;
    
    [[NSUserDefaults standardUserDefaults] setInteger:newSessionID forKey:@"sessionID"];
    
    return newSessionID;
}

@end
