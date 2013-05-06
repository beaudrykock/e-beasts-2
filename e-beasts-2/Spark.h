//
//  Spark.h
//  e-beasts-2
//
//  Created by Beaudry Kock on 10/15/12.
//  Copyright (c) 2012 Beaudry Kock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Box2D.h"
#import "GB2ShapeCache.h"

@interface Spark : CCNode {
    CCSprite *sprite;
    b2Body * body;
    int UID;
    float fuse;
    int directionTrend;
    int directionalState;
    CGPoint targetPosition_;
    CCMotionStreak *streak_;
    float x_start;
    float x_track;
    float max_x_track;
}

+(id) sparkWithParentNode:(CCNode*)parentNode andWorld:(b2World*)world andInitialVector:(b2Vec2)vector andInitialPosition:(CGPoint)position andTargetPosition:(CGPoint)targetPosition;
-(id) initWithParentNode:(CCNode*)parentNode andWorld:(b2World*)world andInitialVector:(b2Vec2)vector andInitialPosition:(CGPoint)position andTargetPosition:(CGPoint)targetPosition;
-(b2Vec2)generateUpdateForceForPos:(b2Vec2)position;
-(void)destroyBody;
-(void)electrify;
-(int)getUID;
-(void)setUID:(int)_UID;

@end
