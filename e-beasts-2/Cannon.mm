//
//  Cannon.m
//  e-beasts
//
//  Created by Beaudry Kock on 7/10/12.
//  Copyright (c) 2012 University of Oxford. All rights reserved.
//

#import "Cannon.h"

@implementation Cannon
@synthesize cannonBody;

+(id)cannonWithParentNode:(CCNode *)parentNode andWorld:(b2World *)world andBase:(b2Body*)baseBody forSide:(NSInteger)_side
{
    
    [[GB2ShapeCache sharedShapeCache]
     addShapesWithFile:@"ebeasts-shapes.plist"];
    
    return [[[self alloc] initWithParentNode:parentNode andWorld:world andBase:baseBody forSide:_side] autorelease];
}

-(id)initWithParentNode:(CCNode *)parentNode andWorld: (b2World*)world andBase:(b2Body*)baseBody forSide:(NSInteger)_side
{
    if ((self  = [super init]))
    {
        side = _side;
        self.tag = kCannonTag;
        [parentNode addChild:self];
        
        CGSize screenSize = [[CCDirector sharedDirector] winSize];
        
        cannonSprite = [CCSprite spriteWithFile:@"cannon_barrel.png"];
        cannonSprite.tag = self.tag;
        [self addChild:cannonSprite z:1000];
        
        b2BodyDef cannonBodyDef;
        cannonBodyDef.type = b2_dynamicBody;
        cannonBodyDef.linearDamping = 1;
        cannonBodyDef.angularDamping = 1;
        
        float x_meters = (screenSize.width-50)/PTM_RATIO;
        float y_meters = 86/PTM_RATIO;
        
        if (side==kLeft)
        {
            x_meters = 45.0/PTM_RATIO;
        }
        
        cannonBodyDef.position.Set(x_meters,y_meters);
        cannonBodyDef.userData = cannonSprite;
        
        //cannonBodyDef.angle = CC_DEGREES_TO_RADIANS(45);
        cannonBody = world->CreateBody(&cannonBodyDef);
        
        // PhysicsEditor
        [[GB2ShapeCache sharedShapeCache]
         addFixturesToBody:cannonBody forShapeName:@"cannon_barrel"];
        
        [cannonSprite setAnchorPoint:[[GB2ShapeCache sharedShapeCache] anchorPointForShape:@"cannon_barrel"]];
        
        // Create a joint to fix the catapult to the floor.
        b2RevoluteJointDef cannonJointDef;
        b2Vec2 vec = b2Vec2(x_meters,y_meters);
        cannonJointDef.Initialize(baseBody, cannonBody, vec);
        cannonJointDef.enableLimit = true;
        
        float upperLimit = kBarrelUpperAngleLimit_right;
        float lowerLimit = kBarrelLowerAngleLimit_right;
        if (side==kLeft)
        {
            upperLimit*=-1;
            lowerLimit*=-1;
        }
        
        cannonJointDef.upperAngle = CC_DEGREES_TO_RADIANS(upperLimit);
        cannonJointDef.lowerAngle  = CC_DEGREES_TO_RADIANS(lowerLimit);
        
        revJoint = cannonBody->GetWorld()->CreateJoint(&cannonJointDef);
        
        //b2RevoluteJoint* cannonJoint = (b2RevoluteJoint*)cannonBody->CreateJoint(&cannonJointDef);
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
         
         cannonBody->CreateFixture(&beastShapeDef);
         */
        
        
        [self scheduleUpdate];
    }
    
    return self;
}

-(void)update:(ccTime) delta
{
    cannonSprite.position = ccp(cannonBody->GetPosition().x * PTM_RATIO,
                                cannonBody->GetPosition().y * PTM_RATIO);
    
    cannonSprite.rotation = -1 * CC_RADIANS_TO_DEGREES(cannonBody->GetAngle());
    
    //CGPoint position = CGPointMake(cannonBody->GetPosition().x * PTM_RATIO, cannonBody->GetPosition().y * PTM_RATIO);
    //b2Vec2 force = [self generateUpdateForceForPos:position];
    //cannonBody->ApplyLinearImpulse(force, cannonBody->GetPosition());
    
}



-(b2Joint*)getRevoluteJoint
{
    return revJoint;
}

-(CGFloat) width
{
    return [cannonSprite boundingBox].size.width;
}

-(CGFloat) height
{
    return [cannonSprite boundingBox].size.height;
}

-(CCSprite*)getSprite{
    return cannonSprite;
}

@end
