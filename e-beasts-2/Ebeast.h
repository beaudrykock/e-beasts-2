//
//  Ebeast.h
//  e-beasts
//
//  Created by Beaudry Kock on 7/6/12.
//  Copyright 2012 University of Oxford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Box2D.h"
#import "GB2ShapeCache.h"

@interface Ebeast : CCNode {
    CCSprite *ebeastSprite;
    b2Body * beastBody;
    CGRect motionRect;
    float unitForce_y;
    float unitForce_x;
    int UID;
    int verticalBallast; // translates into number of stickies attached to the sprite
    float lateralBallast; // translates into number of explosions
    NSMutableDictionary *attachedStickies;
    int stepsToChangeDirection;
    int changeDirection;
    int currentDirection;
    int flightPathType;
    int currentVertex;
    int maximumVertices;
    float flightAlterationAngle;
    float flightSegmentLength;
    CGPoint lastPosition;
    CGPoint baselinePosition;
    b2Vec2 lastForceVector;
    int stationaryCount;
    int directionCount;
    CGRect teslaDangerZone;
    float frameCount;
}

-(void)setTeslaDangerZone:(CGRect)dangerZone;
+(id) ebeastWithParentNode:(CCNode*)parentNode andWorld:(b2World*)world;
-(id) initWithParentNode:(CCNode*)parentNode andWorld:(b2World*)world;
-(b2Vec2)generateUpdateForceForPos:(CGPoint)position;
-(void)impulse;
-(void)setUnitForce:(float)force forAxis:(int)axis;
-(b2Body*)getBeastBody;
-(void)deactivateBody;
-(int)getUID;
-(void)setUID:(int)_UID;
-(void)addLateralBallast;
-(void)addVerticalBallast;
-(void)removeLateralBallast;
-(void)removeVerticalBallast;
-(void)recordAttachedStickyUID:(int)uid;
-(void)detachStickyWithUID:(int)uid;
-(void)decayLateralBallast;
-(void)recordExplosiveImpact;
-(CCSprite*)getBeastSprite;
-(void)setDormant:(BOOL)dormant;
-(void)applyForceTowards:(CGPoint)position;
-(void)applyForceAwayFrom:(CGPoint)position;
-(b2Vec2)generateUpwardForceForPos:(CGPoint)position;
-(void)electrify;
-(void)destroyBody;

@end