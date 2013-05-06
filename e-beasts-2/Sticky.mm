//
//  Sticky.m
//  e-beasts
//
//  Created by Beaudry Kock on 7/6/12.
//  Copyright 2012 University of Oxford. All rights reserved.
//

#import "Sticky.h"


@implementation Sticky

+(id)stickyWithParentNode:(CCNode *)parentNode andWorld:(b2World *)world andInitialVector:(b2Vec2)vector andInitialPosition:(CGPoint)position
{
    [[GB2ShapeCache sharedShapeCache]
     addShapesWithFile:@"ebeasts-shapes.plist"];
    
    return [[[self alloc] initWithParentNode:parentNode andWorld:world andInitialVector:vector andInitialPosition:position] autorelease];
}

-(id)initWithParentNode:(CCNode *)parentNode andWorld: (b2World*)world andInitialVector:(b2Vec2)vector andInitialPosition:(CGPoint)position
{
    if ((self  = [super init]))
    {
        self.tag = kStickyTag;
        UID = arc4random()%1000;
        fuse = 5.0;
        [parentNode addChild:self];
        
        CGSize screenSize = [[CCDirector sharedDirector] winSize];
        
        stickySprite = [CCSprite spriteWithFile:@"sticky.png"];
        stickySprite.position = position;
        stickySprite.tag = self.tag;
        [stickySprite setAccessibilityLabel:[NSString stringWithFormat:@"%i",UID]];
        [self addChild:stickySprite];
        
        b2BodyDef stickyBodyDef;
        stickyBodyDef.type = b2_dynamicBody;
        stickyBodyDef.position.Set(stickySprite.position.x/PTM_RATIO, stickySprite.position.y/PTM_RATIO);
        stickyBodyDef.userData = stickySprite;
        stickyBody = world->CreateBody(&stickyBodyDef);
        
        // PhysicsEditor
        [[GB2ShapeCache sharedShapeCache]
         addFixturesToBody:stickyBody forShapeName:@"sticky"];
        
        [stickySprite setAnchorPoint:[[GB2ShapeCache sharedShapeCache] anchorPointForShape:@"sticky"]];
        
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
         
         stickyBody->CreateFixture(&beastShapeDef);
         */
        
        b2Vec2 force = vector;
        stickyBody->SetLinearDamping(0.5f);
        stickyBody->ApplyLinearImpulse(force, stickyBodyDef.position);
        
        [self scheduleUpdate];
    }
    
    return self;
}

-(void)update:(ccTime) delta
{
    fuse -= delta;
        
    stickySprite.position = ccp(stickyBody->GetPosition().x * PTM_RATIO,
                                stickyBody->GetPosition().y * PTM_RATIO);
    
    stickySprite.rotation = -1 * CC_RADIANS_TO_DEGREES(stickyBody->GetAngle());
    
    //CGPoint position = CGPointMake(stickyBody->GetPosition().x * PTM_RATIO, stickyBody->GetPosition().y * PTM_RATIO);
    //b2Vec2 force = [self generateUpdateForceForPos:position];
    //stickyBody->ApplyLinearImpulse(force, stickyBody->GetPosition());
    
}

-(void)deactivateBody
{
    stickyBody->SetAwake(false);
}

-(void)destroyBody
{
    [self deactivateBody];
    b2World *world = stickyBody->GetWorld();
    world->DestroyBody(stickyBody);
}

-(int)getUID
{
    return UID;
}

-(float)getFuse
{
    return fuse;
}

-(CCSprite*)stickySprite
{
    return stickySprite;
}

@end
