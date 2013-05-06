//
//  b2bodyWrapper.h
//  e-beasts
//
//  Created by Beaudry Kock on 7/9/12.
//  Copyright (c) 2012 University of Oxford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Box2D.h"
#import "cocos2d.h"

@interface b2bodyWrapper : NSObject
{
    b2Body *body;
    int tag;
    int UID;
}

@property (nonatomic, assign) b2Body *body;

-(int)getTag;
-(void)setTag:(int)_tag;
-(int)getUID;
-(void)setUID:(int)_UID;
@end
