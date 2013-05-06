//
//  ContainmentLid.m
//  e-beasts
//
//  Created by Beaudry Kock on 7/17/12.
//  Copyright 2012 University of Oxford. All rights reserved.
//

#import "ContainmentLid.h"


@implementation ContainmentLid
@synthesize body;

+(id)leftContainmentLidWithParentNode:(CCNode *)parentNode andWorld:(b2World *)world andAnchorBody:(b2Body*)anchorBody
{
    
    [[GB2ShapeCache sharedShapeCache]
     addShapesWithFile:@"ebeasts-shapes.plist"];
    
    return [[[self alloc] initWithParentNode:parentNode andWorld:world andAnchorBody:anchorBody andSide:0] autorelease];
}

+(id)rightContainmentLidWithParentNode:(CCNode *)parentNode andWorld:(b2World *)world andAnchorBody:(b2Body*)anchorBody
{
    
    [[GB2ShapeCache sharedShapeCache]
     addShapesWithFile:@"ebeasts-shapes.plist"];
    
    return [[[self alloc] initWithParentNode:parentNode andWorld:world andAnchorBody:anchorBody andSide:1] autorelease];
}

-(id)initWithParentNode:(CCNode *)parentNode andWorld: (b2World*)world andAnchorBody:(b2Body*)anchorBody andSide:(NSInteger)side
{
    if ((self  = [super init]))
    {
        lidOpenPeriod = 3.0;
        containmentSide = side;
        
        self.tag = kContainmentLidTag;
        [parentNode addChild:self];
        
        CGSize screenSize = [[CCDirector sharedDirector] winSize];
        
        if (side==0)
        {
            sprite = [CCSprite spriteWithFile:@"containment_lid_left.png"];
        }   
        else
        {
            sprite = [CCSprite spriteWithFile:@"containment_lid_right.png"];
        }
        sprite.tag = self.tag;
        [self addChild:sprite z:1000];
        
        b2BodyDef bodyDef;
        bodyDef.type = b2_dynamicBody;
        bodyDef.linearDamping = 1;
        bodyDef.angularDamping = 1;
        if (side==0)
        {
            b2Vec2 anchorBodyPos = anchorBody->GetPosition();
            bodyDef.position.Set(anchorBodyPos.x,anchorBodyPos.y+(71/PTM_RATIO));
        }
        else 
        {
            b2Vec2 anchorBodyPos = anchorBody->GetPosition();
            bodyDef.position.Set(anchorBodyPos.x,anchorBodyPos.y+(71/PTM_RATIO));
        }
        bodyDef.userData = sprite;
        //bodyDef.angle = CC_DEGREES_TO_RADIANS(50);
        body = world->CreateBody(&bodyDef);
        
        // PhysicsEditor
        if (side==0)
        {
            [[GB2ShapeCache sharedShapeCache]
          addFixturesToBody:body forShapeName:@"containment_lid_left"];
            [sprite setAnchorPoint:[[GB2ShapeCache sharedShapeCache] anchorPointForShape:@"containment_lid_left"]];
            
        }   
        else
        {
            [[GB2ShapeCache sharedShapeCache]
             addFixturesToBody:body forShapeName:@"containment_lid_right"];
            
            [sprite setAnchorPoint:[[GB2ShapeCache sharedShapeCache] anchorPointForShape:@"containment_lid_right"]];
            
        }
        // Create a joint to fix the catapult to the floor.
        //
        
        b2Vec2 anchorBodyPos = anchorBody->GetPosition();
        float addition = 0.0f;
        if (side==1) addition = 3.0f/PTM_RATIO;
        b2Vec2 vec = b2Vec2(anchorBodyPos.x+addition,anchorBodyPos.y+(71/PTM_RATIO));
        jointDef.Initialize(anchorBody, body, vec);
        jointDef.enableLimit = true;
        
        if (side==kLeft)
        {
            jointDef.upperAngle = CC_DEGREES_TO_RADIANS(90);
            jointDef.lowerAngle  = CC_DEGREES_TO_RADIANS(0);
        }
        else 
        {
            jointDef.upperAngle = CC_DEGREES_TO_RADIANS(0);
            jointDef.lowerAngle  = CC_DEGREES_TO_RADIANS(-90);
        }
        revJoint = body->GetWorld()->CreateJoint(&jointDef);
        [self scheduleUpdate];
    }
    
    return self;
}

-(void)update:(ccTime) delta
{
    sprite.position = ccp(body->GetPosition().x * PTM_RATIO,
                                body->GetPosition().y * PTM_RATIO);
    
    sprite.rotation = -1 * CC_RADIANS_TO_DEGREES(body->GetAngle());
    
    if (lidOpen)
    {
        lidOpenPeriod-=delta;
        
        if (lidOpenPeriod<0.01)
        {
            lidOpenPeriod = 3.0;
            lidOpen = NO;
            [self close];
        }
    }
}

-(void)open
{
    if (!lidOpen)
    {
        b2RevoluteJoint *joint = (b2RevoluteJoint*)revJoint;
        joint->EnableMotor(true);
        joint->SetMaxMotorTorque(10.0);
        
        if (containmentSide == kLeft)
        {
            joint->SetMotorSpeed(10.0);
        }
        else {
            joint->SetMotorSpeed(-10.0);
        }
        lidOpen = YES;
    }
}

-(void)close
{
    
    b2RevoluteJoint *joint = (b2RevoluteJoint*)revJoint;        
    if (containmentSide == kLeft)
    {
        joint->SetMotorSpeed(-10.0);
    }
    else {
        joint->SetMotorSpeed(10.0);
    }
    
}

-(b2Joint*)getRevoluteJoint
{
    return revJoint;
}

-(CGFloat) width
{
    return [sprite boundingBox].size.width;
}

-(CGFloat) height
{
    return [sprite boundingBox].size.height;
}

-(CCSprite*)getSprite{
    return sprite;
}
@end
