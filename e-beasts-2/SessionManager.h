//
//  SessionManager.h
//  e-beasts-2
//
//  Created by Beaudry Kock on 10/22/12.
//  Copyright (c) 2012 Beaudry Kock. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SessionManager : NSObject
{

}

+(SessionManager*)sharedSessionManager;

@property (nonatomic) NSInteger sessionID;

@end
