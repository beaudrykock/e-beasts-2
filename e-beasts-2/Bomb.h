//
//  Bomb.h
//  e-beasts
//
//  Created by Beaudry Kock on 7/11/12.
//  Copyright 2012 University of Oxford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Box2D.h"
#import "GB2ShapeCache.h"
@class GamePlayLayer;
@interface Bomb : CCNode {
    CCSprite *bombSprite;
    b2Body * bombBody;
    int tag;
    int UID;
    float fuse;
    int type;
}

+(id) bombWithParentNode:(CCNode*)parentNode andWorld:(b2World*)world andInitialVector:(b2Vec2)vector andInitialPosition:(CGPoint)position andType:(int)_type;
-(id) initWithParentNode:(CCNode*)parentNode andWorld:(b2World*)world andInitialVector:(b2Vec2)vector andInitialPosition:(CGPoint)position andType:(int)_type;
-(int)getUID;
-(void)deactivateBody;
-(void)destroyBody;
-(float)getFuse;
-(CCSprite*)bombSprite;
-(int)getType;

@end
