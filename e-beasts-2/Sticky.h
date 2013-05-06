//
//  Sticky.h
//  e-beasts
//
//  Created by Beaudry Kock on 7/6/12.
//  Copyright 2012 University of Oxford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Box2D.h"
#import "GB2ShapeCache.h"

@interface Sticky : CCNode {
    CCSprite *stickySprite;
    b2Body * stickyBody;
    float unitForce;
    int UID;
    float fuse;
}

+(id) stickyWithParentNode:(CCNode*)parentNode andWorld:(b2World*)world andInitialVector:(b2Vec2)vector andInitialPosition:(CGPoint)position;
-(id) initWithParentNode:(CCNode*)parentNode andWorld:(b2World*)world andInitialVector:(b2Vec2)vector andInitialPosition:(CGPoint)position;
-(int)getUID;
-(void)deactivateBody;
-(void)destroyBody;
-(float)getFuse;
-(CCSprite*)stickySprite;

@end
