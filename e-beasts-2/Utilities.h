//
//  Utilities.h
//  e-beasts
//
//  Created by Beaudry Kock on 8/16/12.
//  Copyright (c) 2012 University of Oxford. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utilities : NSObject
{}

+(NSTimeInterval)secondsAtLastLaunch;
+(void)setSecondsAtLaunch:(NSTimeInterval)seconds;
+(NSInteger)generateSessionID;

@end
