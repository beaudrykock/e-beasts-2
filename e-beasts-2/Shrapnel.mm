//
//  Shrapnel.m
//  e-beasts
//
//  Created by Beaudry Kock on 7/16/12.
//  Copyright 2012 University of Oxford. All rights reserved.
//

#import "Shrapnel.h"


@implementation Shrapnel
+(id)shrapnelWithParentNode:(CCNode *)parentNode andWorld:(b2World *)world andInitialVector:(b2Vec2)vector andInitialPosition:(CGPoint)position
{
    [[GB2ShapeCache sharedShapeCache]
     addShapesWithFile:@"ebeasts-shapes.plist"];
    
    return [[[self alloc] initWithParentNode:parentNode andWorld:world andInitialVector:vector andInitialPosition:position] autorelease];
}

-(id)initWithParentNode:(CCNode *)parentNode andWorld: (b2World*)world andInitialVector:(b2Vec2)vector andInitialPosition:(CGPoint)position
{
    if ((self  = [super init]))
    {
        self.tag = kShrapnelTag;
        UID = arc4random()%1000;
        fuse = 2.5;
        [parentNode addChild:self];
        
        sprite = [CCSprite spriteWithFile:@"shrapnel.png"];
        sprite.position = position;
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
         addFixturesToBody:body forShapeName:@"shrapnel"];
        
        [sprite setAnchorPoint:[[GB2ShapeCache sharedShapeCache] anchorPointForShape:@"shrapnel"]];
        
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
        
        [self scheduleUpdate];
    }
    
    return self;
}

-(void)update:(ccTime) delta
{
    fuse -= delta;
    
    sprite.position = ccp(body->GetPosition().x * PTM_RATIO,
                                body->GetPosition().y * PTM_RATIO);
    
    sprite.rotation = -1 * CC_RADIANS_TO_DEGREES(body->GetAngle());
    
    if (fuse<0.01)
    {
        body->DestroyFixture(body->GetFixtureList());
        [self removeFromParentAndCleanup:YES];
    }
    
}
@end
