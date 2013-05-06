//
//  Ebeast.m
//  e-beasts
//
//  Created by Beaudry Kock on 7/6/12.
//  Copyright 2012 University of Oxford. All rights reserved.
//

#import "Ebeast.h"


@implementation Ebeast

+(id)ebeastWithParentNode:(CCNode *)parentNode andWorld:(b2World *)world 
{
    [[GB2ShapeCache sharedShapeCache]
     addShapesWithFile:@"ebeasts-shapes.plist"];
    
    return [[[self alloc] initWithParentNode:parentNode andWorld:world] autorelease];
}

-(id)initWithParentNode:(CCNode *)parentNode andWorld: (b2World*)world
{
    if ((self  = [super init]))
    {
        self.tag = kEbeastTag;
        UID = arc4random()%1000;
        [parentNode addChild:self];
        
        CGSize screenSize = [[CCDirector sharedDirector] winSize];
        
        // TEST - polygon-shaped flight paths
        maximumVertices = 15.0;
        currentVertex = 1;
        // flightPathType = arc4random_uniform(3);
        flightPathType = kHoppingPath;
        flightAlterationAngle = 360.0/maximumVertices;
        if (flightPathType == kHoppingPath)
        {
            flightSegmentLength = 60.0;
        }
        else
        {
            flightSegmentLength = 30.0;
        }
        ebeastSprite = [CCSprite spriteWithFile:@"ebeast.png"];
        ebeastSprite.position = CGPointMake(screenSize.width/2.0, screenSize.width/4.0);
        ebeastSprite.tag = self.tag;
        [ebeastSprite setAccessibilityLabel:[NSString stringWithFormat:@"%i",UID]];
        [self addChild:ebeastSprite];
        
        lastPosition = ebeastSprite.position;
        baselinePosition = lastPosition;
        
        b2BodyDef beastBodyDef;
        beastBodyDef.type = b2_dynamicBody;
        beastBodyDef.position.Set(ebeastSprite.position.x/PTM_RATIO, ebeastSprite.position.y/PTM_RATIO);
        beastBodyDef.userData = ebeastSprite;
        beastBody = world->CreateBody(&beastBodyDef);
        
        // PhysicsEditor
        [[GB2ShapeCache sharedShapeCache]
         addFixturesToBody:beastBody forShapeName:@"ebeast"];
          
        [ebeastSprite setAnchorPoint:[[GB2ShapeCache sharedShapeCache] anchorPointForShape:@"ebeast"]];
        
        attachedStickies = [[NSMutableDictionary dictionaryWithCapacity:5] retain];
        
        stepsToChangeDirection = (kMinStepsBeforeDirectionChange+(arc4random()%kMaxStepsBeforeDirectionChange));
        changeDirection = stepsToChangeDirection;
        currentDirection = 1;
        unitForce_x = kMinUnitForce_x+(arc4random()%kMaxUnitForce_x);
        unitForce_y = kMinUnitForce_y+(arc4random()%kMaxUnitForce_y);
        
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
        
        beastBody->CreateFixture(&beastShapeDef);
        */
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        motionRect = CGRectMake(0.0, winSize.height/4.0, winSize.width, winSize.height/2.0);
        
        b2Vec2 force = b2Vec2(0, 10);
        beastBody->SetLinearDamping(0.5f);
        beastBody->ApplyLinearImpulse(force, beastBodyDef.position);
        
        [self scheduleUpdate];
        [self schedule:@selector(impulse) interval:0.5];
    }
    
    return self;
}

-(void)update:(ccTime) delta
{
    frameCount += delta;
    
    stationaryCount++;
    directionCount++;
    
    ebeastSprite.position = ccp(beastBody->GetPosition().x * PTM_RATIO,
                          beastBody->GetPosition().y * PTM_RATIO);
    
    ebeastSprite.rotation = -1 * CC_RADIANS_TO_DEGREES(beastBody->GetAngle());
    
    CGPoint position = CGPointMake(beastBody->GetPosition().x * PTM_RATIO, beastBody->GetPosition().y * PTM_RATIO);
    b2Vec2 impulseForce = [self generateUpdateForceForPos:position];
    b2Vec2 sustainingForce = [self generateUpwardForceForPos:position];
    
    beastBody->ApplyForce(sustainingForce, beastBody->GetPosition());
    beastBody->ApplyLinearImpulse(impulseForce, beastBody->GetPosition());
}

// provides the force to be generated in the impulse method
-(b2Vec2)generateUpwardForceForPos:(CGPoint)position
{
    BOOL testing = NO;
    
    
    float pos_y = position.y/320.0;
    
    
    if (testing)
        return b2Vec2(0.0, (1.0-pos_y)*40.0f);
    
    return b2Vec2(0.0, (1.0-pos_y)*50.0f);
}

-(void)deactivateBody
{
    beastBody->SetAwake(false);
}

-(void)setTeslaDangerZone:(CGRect)dangerZone
{
    teslaDangerZone = dangerZone;
}

#pragma mark - Motion control

// called at specified second intervals to apply a force to path
-(void)impulse
{
    CGPoint position = CGPointMake(beastBody->GetPosition().x, beastBody->GetPosition().y);
    b2Vec2 force = [self generateUpdateForceForPos:position];
    beastBody->ApplyLinearImpulse(force, beastBody->GetPosition());
}

-(void)applyForceTowards:(CGPoint)position
{
    float magnitude = 3.0f;
    float force_x = 0.0;
    float force_y = 0.0;
    b2Vec2 beastPos = beastBody->GetPosition();
    CGPoint pos = CGPointMake(beastPos.x*PTM_RATIO, beastPos.y*PTM_RATIO);
    if (pos.x < position.x)
    {
        force_x = position.x;
    }
    else 
    {
        force_x = position.x*-1;
    }
    if (pos.y < position.y)
    {
        force_y = position.y;
    }
    else 
    {
        force_y = position.y*-1;
    }
    b2Vec2 force = b2Vec2((force_x/PTM_RATIO)*magnitude, (force_y/PTM_RATIO)*magnitude);
    beastBody->ApplyLinearImpulse(force, beastBody->GetPosition());
}

-(void)applyForceAwayFrom:(CGPoint)position
{
    float magnitude = 3.0f;
    float force_x = 0.0;
    float force_y = 0.0;
    b2Vec2 beastPos = beastBody->GetPosition();
    CGPoint pos = CGPointMake(beastPos.x*PTM_RATIO, beastPos.y*PTM_RATIO);
    
    // calculate gradient between two points
    float x_gradient = abs(position.x - pos.x);
    float y_gradient = abs(position.y - pos.y);
    
    if (pos.x < position.x)
    {
        force_x = pos.x-x_gradient;
    }
    else 
    {
        force_x = pos.x+x_gradient;
    }
    if (pos.y < position.y)
    {
        force_y = pos.y-y_gradient;
    }
    else 
    {
        force_y = pos.y+y_gradient;
    }
    b2Vec2 force = b2Vec2((force_x/PTM_RATIO)*magnitude, (force_y/PTM_RATIO)*magnitude);
    beastBody->ApplyLinearImpulse(force, beastBody->GetPosition());
}

// provides the force to be generated in the impulse method
-(b2Vec2)generateUpdateForceForPos:(CGPoint)position
{
    float force_x = 0;
    float force_y = 0;
    
    BOOL testing = NO;
    
    if (testing)
    {
        return b2Vec2(0.0,0.0);
    }

    
    // first determine if an update should be made
    if (ccpDistance(position, lastPosition) > flightSegmentLength && flightPathType == kCircularPath)
    {
        float vectorAngle = 0.0;
        if ((currentVertex*flightAlterationAngle)<=90.1)
        {
            vectorAngle = ((currentVertex*flightAlterationAngle));
            force_x = sinf(CC_DEGREES_TO_RADIANS(vectorAngle))*1.0;
            force_y = sqrtf((1.0-(force_x*force_x)));
        }
        else if ((currentVertex*flightAlterationAngle)<=180.1)
        {
            vectorAngle = 180-((currentVertex*flightAlterationAngle));
            force_x = sinf(CC_DEGREES_TO_RADIANS(vectorAngle))*1.0;
            force_y = sqrtf((1.0-(force_x*force_x)))*-1;
        }
        else if ((currentVertex*flightAlterationAngle)<=270.1)
        {
            vectorAngle = (currentVertex*flightAlterationAngle)-180.0;
            force_x = sinf(CC_DEGREES_TO_RADIANS(vectorAngle))*-1.0;
            force_y = sqrtf((1.0-(force_x*force_x)))*-1;
        }
        else 
        {
            vectorAngle = 360-((currentVertex*flightAlterationAngle));
            force_x = sinf(CC_DEGREES_TO_RADIANS(vectorAngle))*-1.0;
            force_y = sqrtf((1.0-(force_x*force_x)));
        }
#ifdef DEBUG_EBEAST
        NSLog(@"");
        NSLog(@"current vertex * flightAlterationAngle = %f", currentVertex * flightAlterationAngle); 
        NSLog(@"vector angle = %f", vectorAngle);
        NSLog(@"force_x = %f", force_x);
        NSLog(@"force_y = %f", force_y);
        NSLog(@"current vertx = %i", currentVertex);
#endif
        lastForceVector = b2Vec2(force_x, force_y);
        lastForceVector *= 1.0f;
        lastPosition = position;
        currentVertex++;
        
        if (currentVertex>maximumVertices)
            currentVertex = 1;
    }
    else if (flightPathType == kHoppingPath && ccpDistance(position, lastPosition) > flightSegmentLength)
    {
        // random pause, every 3-6 seconds
        if (frameCount < ((3+arc4random_uniform(3))*60.0))
        {
            force_x = arc4random_uniform(1.5)*1.0f;
            force_y = arc4random_uniform(1.5)*1.0f;
            int factor = arc4random() % 2 ? 1 : -1;
            force_x *= factor;
            force_y *= factor;
            
            // check if e-beast is anywhere near tesla zone - if so, evasive action
            if (CGRectContainsPoint(teslaDangerZone, position))
            {
                // EVASIVE ACTION - punch upwards (keep x the same)
                force_y = 3.5;
            }
            
            lastForceVector = b2Vec2(force_x, force_y);
        }
        else
        {
            lastForceVector = b2Vec2(0.0,0.0);
            frameCount = 0;
        }
        lastPosition = position;
    }
    else if (flightPathType == kFigureEightPath && ccpDistance(position, lastPosition) > flightSegmentLength)
    {
        
    }
    
    return lastForceVector;
}

-(void)decayLateralBallast
{
    if (lateralBallast > 0.01)
        lateralBallast -= (0.001*lateralBallast);
}

-(void)recordExplosiveImpact
{
    // note that lateral ballast decays in time
    [self addLateralBallast];
}

-(void)electrify
{
    beastBody->SetActive(false);
}

-(void)destroyBody
{
    [self deactivateBody];
    b2World *world = beastBody->GetWorld();
    world->DestroyBody(beastBody);
}

-(void)recordAttachedStickyUID:(int)uid
{
    NSString *key = [NSString stringWithFormat:@"%i",uid];
    [attachedStickies setObject:[NSNumber numberWithInt:uid] forKey:key];
    [self addVerticalBallast];
}

-(void)detachStickyWithUID:(int)uid
{
    NSString *key = [NSString stringWithFormat:@"%i",uid];
    if ([attachedStickies objectForKey:key])
    {
        [attachedStickies removeObjectForKey:[NSNumber numberWithInt:uid]];
        [self removeVerticalBallast];
    }
}

// allows setting of the unit force from the GPL class
-(void)setUnitForce:(float)force forAxis:(int)axis
{
    switch (axis) {
        case kAxis_x:
            unitForce_x = force;
            break;
        case kAxis_y:
            unitForce_y = force;
        default:
            break;
    }
}

-(void)setDormant:(BOOL)dormant
{
    if (dormant)
    {
        unitForce_x = 0.0;
        unitForce_y = 0.0;
    }
}

-(void)addLateralBallast
{
    lateralBallast++;
}

-(void)removeLateralBallast
{
    lateralBallast-=1.0;
    if (lateralBallast < 0.0) lateralBallast = 0.0;
}

-(void)addVerticalBallast
{
    verticalBallast++;
}

-(void)removeVerticalBallast
{
    verticalBallast--;
    
    if (verticalBallast < 0) verticalBallast = 0;
}

-(CCSprite*)getBeastSprite
{
    return ebeastSprite;
}

-(b2Body*)getBeastBody
{
    return beastBody;
}

-(void)setUID:(int)_UID
{
    UID = _UID;
}

-(int)getUID
{
    return UID;
}

-(void)dealloc
{
    [attachedStickies release];
    
}

@end
