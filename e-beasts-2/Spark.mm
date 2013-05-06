//
//  Spark.m
//  e-beasts-2
//
//  Created by Beaudry Kock on 10/15/12.
//  Copyright (c) 2012 Beaudry Kock. All rights reserved.
//


#import "Spark.h"


@implementation Spark
+(id)sparkWithParentNode:(CCNode *)parentNode andWorld:(b2World *)world andInitialVector:(b2Vec2)vector andInitialPosition:(CGPoint)position andTargetPosition:(CGPoint)targetPosition
{
    [[GB2ShapeCache sharedShapeCache]
     addShapesWithFile:@"ebeasts-shapes.plist"];
    
    return [[[self alloc] initWithParentNode:parentNode andWorld:world andInitialVector:vector andInitialPosition:position andTargetPosition:targetPosition] autorelease];
}

-(id)initWithParentNode:(CCNode *)parentNode andWorld: (b2World*)world andInitialVector:(b2Vec2)vector andInitialPosition:(CGPoint)position andTargetPosition:(CGPoint)targetPosition
{
    if ((self  = [super init]))
    {
        self.tag = kSparkTag;
        UID = arc4random()%1000;
        [parentNode addChild:self];
        targetPosition_ = targetPosition;
        
        directionTrend = (targetPosition.x > position.x) ? 0 : 1;
            
        sprite = [CCSprite spriteWithFile:@"teslaSpark.png"];
        sprite.position = position;
        x_start = sprite.position.x;
        sprite.tag = self.tag;
        [sprite setAccessibilityLabel:[NSString stringWithFormat:@"%i",UID]];
        [self addChild:sprite];
        
        b2BodyDef bodyDef;
        bodyDef.type = b2_dynamicBody;
        bodyDef.position.Set(sprite.position.x/PTM_RATIO, sprite.position.y/PTM_RATIO);
        bodyDef.userData = sprite;
        body = world->CreateBody(&bodyDef);
        
        // PhysicsEditor
        [[GB2ShapeCache sharedShapeCache]
         addFixturesToBody:body forShapeName:@"teslaSpark"];
        
        [sprite setAnchorPoint:[[GB2ShapeCache sharedShapeCache] anchorPointForShape:@"teslaSpark"]];
        
        // NON-PhysicsEditor
        /*
         // Create circle shape
         b2CircleShape circle;
         circle.m_radius = 14.5/PTM_RATIO;
         
         // Create shape definition and add to body
         b2FixtureDef beastShapeDef;
         beastShapeDef.shape = &circle;
         beastShapeDef.density = 1.0f;
         beastShapeDef.friction = 0.2f;
         beastShapeDef.restitution = 0.6f;
         
         body->CreateFixture(&beastShapeDef);
         */
        b2Vec2 force = vector;
        body->SetLinearDamping(0.5f);
        body->ApplyLinearImpulse(force, bodyDef.position);
        
        max_x_track = 65.0;
        
        streak_ = [CCMotionStreak streakWithFade:2 minSeg:2 width:2 color:ccBLUE textureFilename:@"teslaSpark.png"];
        [self addChild:streak_];
        
        [self scheduleUpdate];
    }
    
    return self;
}

-(void)update:(ccTime) delta
{
    
    sprite.position = ccp(body->GetPosition().x * PTM_RATIO,
                          body->GetPosition().y * PTM_RATIO);
    
    sprite.rotation = -1 * CC_RADIANS_TO_DEGREES(body->GetAngle());
    
    CGPoint position = CGPointMake(body->GetPosition().x * PTM_RATIO, body->GetPosition().y * PTM_RATIO);
    
    x_track = abs(position.x - x_start);
    
    //NSLog(@"Update force for spark = %f, %f", [self generateUpdateForceForPos:body->GetPosition()].x, [self generateUpdateForceForPos:body->GetPosition()].y);
    //body->SetTransform([self generateUpdateForceForPos:body->GetPosition()], body->GetAngle());
    
    [streak_ setPosition:[sprite convertToWorldSpace:CGPointZero]];
    
    //NSLog(@"ccpDistance(position, targetPosition_) = %f", ccpDistance(position, targetPosition_));
    if (ccpDistance(position, targetPosition_) < 9.0 || x_track > max_x_track)
    {
        body->DestroyFixture(body->GetFixtureList());
        [self removeFromParentAndCleanup:YES];
    }
}

-(void)deactivateBody
{
    body->SetAwake(false);
}

-(void)destroyBody
{
    [self deactivateBody];
    b2World *world = body->GetWorld();
    world->DestroyBody(body);
}

// provides the force to be generated in the impulse method
-(b2Vec2)generateUpdateForceForPos:(b2Vec2)position
{
    if (directionalState == 0) // was going up, now go down
    {
        directionalState = !directionalState;
        if (directionTrend==0) // going right
            return b2Vec2((position.x+0.1), (position.y+0.1));
        return b2Vec2((position.x-0.1), (position.y+0.1));
    }
    else // was going down, now go up
    {
        directionalState = !directionalState;
        if (directionTrend==0) // going left
            return b2Vec2((position.x+0.1), (position.y+0.1));
        return b2Vec2((position.x-0.1), (position.y+0.1));
    }
}

-(void)setUID:(int)_UID
{
    UID = _UID;
}

-(int)getUID
{
    return UID;
}

@end
