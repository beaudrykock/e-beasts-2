//
//  Bomb.m
//  e-beasts
//
//  Created by Beaudry Kock on 7/11/12.
//  Copyright 2012 University of Oxford. All rights reserved.
//

#import "Bomb.h"


@implementation Bomb
+(id)bombWithParentNode:(CCNode *)parentNode andWorld:(b2World *)world andInitialVector:(b2Vec2)vector andInitialPosition:(CGPoint)position andType:(int)_type
{
    [[GB2ShapeCache sharedShapeCache]
     addShapesWithFile:@"ebeasts-shapes.plist"];
    
    return [[[self alloc] initWithParentNode:parentNode andWorld:world andInitialVector:vector andInitialPosition:position andType:_type] autorelease];
}

-(id)initWithParentNode:(CCNode *)parentNode andWorld: (b2World*)world andInitialVector:(b2Vec2)vector andInitialPosition:(CGPoint)position andType:(int)_type
{
    if ((self  = [super init]))
    {
        type = _type;
        tag = kBombTag;
        UID = arc4random()%1000;
        if (type==kExplosiveBombType)
        {
            fuse = 5.0;
        }
        else {
            fuse = 1.5;
        }
        [parentNode addChild:self];
        
        CGSize screenSize = [[CCDirector sharedDirector] winSize];
        
        bombSprite = [CCSprite spriteWithFile:@"bomb.png"];
        bombSprite.position = position;
        bombSprite.tag = tag;
#ifdef DEBUG_BOMB
        NSLog(@"bombSprite tag = %i", bombSprite.tag);
#endif
        [bombSprite setAccessibilityLabel:[NSString stringWithFormat:@"%i",UID]];
        [self addChild:bombSprite];
        
        b2BodyDef bombBodyDef;
        bombBodyDef.type = b2_dynamicBody;
        bombBodyDef.position.Set(bombSprite.position.x/PTM_RATIO, bombSprite.position.y/PTM_RATIO);
        bombBodyDef.userData = bombSprite;
        bombBody = world->CreateBody(&bombBodyDef);
        
        // PhysicsEditor
        [[GB2ShapeCache sharedShapeCache]
         addFixturesToBody:bombBody forShapeName:@"bomb"];
        
        [bombSprite setAnchorPoint:[[GB2ShapeCache sharedShapeCache] anchorPointForShape:@"bomb"]];
        
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
         
         bombBody->CreateFixture(&beastShapeDef);
         */
        
        b2Vec2 force = vector;
        bombBody->SetLinearDamping(0.5f);
        bombBody->ApplyLinearImpulse(force, bombBodyDef.position);
        
        [self scheduleUpdate];
    }
    
    return self;
}

-(void)deactivateBody
{
    bombBody->SetAwake(false);
}

-(void)destroyBody
{
    [self deactivateBody];
    b2World *world = bombBody->GetWorld();
    world->DestroyBody(bombBody);
}

-(void)update:(ccTime) delta
{
    fuse -= delta;
        
    bombSprite.position = ccp(bombBody->GetPosition().x * PTM_RATIO,
                                bombBody->GetPosition().y * PTM_RATIO);
    
    bombSprite.rotation = -1 * CC_RADIANS_TO_DEGREES(bombBody->GetAngle());
    
    //CGPoint position = CGPointMake(bombBody->GetPosition().x * PTM_RATIO, bombBody->GetPosition().y * PTM_RATIO);
    //b2Vec2 force = [self generateUpdateForceForPos:position];
    //bombBody->ApplyLinearImpulse(force, bombBody->GetPosition());
    
}

-(int)getUID
{
    return UID;
}

-(float)getFuse
{
    return fuse;
}

-(CCSprite*)bombSprite
{
    return bombSprite;
}

-(void)setType:(int)_type
{
    type = _type;
}

-(int)getType
{
    return type;
}

@end
