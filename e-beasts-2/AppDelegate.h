//
//  AppDelegate.h
//  e-beasts-2
//
//  Created by Beaudry Kock on 10/9/12.
//  Copyright Beaudry Kock 2012. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "cocos2d.h"

@interface AppController : NSObject <UIApplicationDelegate, CCDirectorDelegate>
{
	UIWindow *window_;
	UINavigationController *navController_;
	NSInteger sessionID_;
	CCDirectorIOS	*director_;							// weak ref
}

@property (nonatomic) NSInteger sessionID;
@property (nonatomic, retain) UIWindow *window;
@property (readonly) UINavigationController *navController;
@property (readonly) CCDirectorIOS *director;

-(void)test;

@end
