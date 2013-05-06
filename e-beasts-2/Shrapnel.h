//
//  Shrapnel.h
//  e-beasts
//
//  Created by Beaudry Kock on 7/16/12.
//  Copyright 2012 University of Oxford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Box2D.h"
#import "GB2ShapeCache.h"

@interface Shrapnel : CCNode {
    CCSprite *sprite;
    b2Body * body;
    int UID;
    float fuse;
}

+(id) shrapnelWithParentNode:(CCNode*)parentNode andWorld:(b2World*)world andInitialVector:(b2Vec2)vector andInitialPosition:(CGPoint)position;
-(id) initWithParentNode:(CCNode*)parentNode andWorld:(b2World*)world andInitialVector:(b2Vec2)vector andInitialPosition:(CGPoint)position;


@end
