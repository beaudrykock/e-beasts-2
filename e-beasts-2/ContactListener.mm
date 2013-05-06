/*
 *  ContactListener.mm
 *  PhysicsBox2d
 *
 *  Created by Steffen Itterheim on 17.09.10.
 *  Copyright 2010 Steffen Itterheim. All rights reserved.
 *
 */

#import "ContactListener.h"
#import "Ebeast.h"
#import "Sticky.h"
#import "b2bodyWrapper.h"

void ContactListener::BeginContact(b2Contact* contact)
{
	b2Body* bodyA = contact->GetFixtureA()->GetBody();
	b2Body* bodyB = contact->GetFixtureB()->GetBody();
	CCSprite* spriteA = (CCSprite*)bodyA->GetUserData();
	CCSprite* spriteB = (CCSprite*)bodyB->GetUserData();
	
    // make joint between sticky and ebeast on contact
	if (spriteA.tag == kEbeastTag && spriteB.tag == kStickyTag)
	{
        b2bodyWrapper *wrapper_a = [[b2bodyWrapper alloc] init];
        [wrapper_a setBody:bodyA];
        [wrapper_a setUID:[spriteA.accessibilityLabel intValue]];
        [wrapper_a setTag: kEbeastTag];
        
        b2bodyWrapper *wrapper_b = [[b2bodyWrapper alloc] init];
        [wrapper_b setBody:bodyB];
        [wrapper_b setUID:[spriteB.accessibilityLabel intValue]];
        [wrapper_b setTag: kStickyTag];
        
        [needsJoint addObject: wrapper_a];
        [needsJoint addObject: wrapper_b];
        
        //normal manifold contains all info...
        int numPoints = contact->GetManifold()->pointCount;
        
        //...world manifold is helpful for getting locations
        b2WorldManifold worldManifold;
        contact->GetWorldManifold( &worldManifold );
        
        for (int i = 0; i < numPoints; i++)
        {
            [contactPoints_x addObject:[NSNumber numberWithFloat:worldManifold.points[i].x]];
            [contactPoints_y addObject:[NSNumber numberWithFloat:worldManifold.points[i].y]];
        }
        //b2RevoluteJointDef jointDef;
        //jointDef.Initialize(bodyA, bodyB, bodyA->GetWorldCenter());
        //bodyA->GetWorld()->CreateJoint(&jointDef);
        
	}
	else if (spriteB.tag == kEbeastTag && spriteA.tag == kStickyTag)
	{
        b2bodyWrapper *wrapper_b = [[b2bodyWrapper alloc] init];
        [wrapper_b setBody:bodyB];
        [wrapper_b setUID:[spriteB.accessibilityLabel intValue]];
        [wrapper_b setTag: kEbeastTag];
        
        b2bodyWrapper *wrapper_a = [[b2bodyWrapper alloc] init];
        [wrapper_a setBody:bodyA];
        [wrapper_a setUID:[spriteA.accessibilityLabel intValue]];
        [wrapper_a setTag: kStickyTag];
        
        [needsJoint addObject: wrapper_b];
        [needsJoint addObject: wrapper_a];
        
        //normal manifold contains all info...
        int numPoints = contact->GetManifold()->pointCount;
        
        //...world manifold is helpful for getting locations
        b2WorldManifold worldManifold;
        contact->GetWorldManifold( &worldManifold );
        
        for (int i = 0; i < numPoints; i++)
        {
            [contactPoints_x addObject:[NSNumber numberWithFloat:worldManifold.points[i].x]];
            [contactPoints_y addObject:[NSNumber numberWithFloat:worldManifold.points[i].y]];
        }
		//b2RevoluteJointDef jointDef;
        //jointDef.Initialize(bodyB, bodyA, bodyB->GetWorldCenter());
        //bodyB->GetWorld()->CreateJoint(&jointDef);
	}
    // bomb and e-beast contact
    else if (spriteA.tag == kEbeastTag && spriteB.tag == kBombTag)
	{
        b2bodyWrapper *wrapper_a = [[b2bodyWrapper alloc] init];
        [wrapper_a setBody:bodyA];
        [wrapper_a setUID:[spriteA.accessibilityLabel intValue]];
        if (![bombedBeastUIDs containsObject: spriteA.accessibilityLabel])
        {
            [bombedBeastUIDs addObject: spriteA.accessibilityLabel];
            [explosionImpactedBeasts addObject: wrapper_a];
        }
        
        b2bodyWrapper *wrapper_b = [[b2bodyWrapper alloc] init];
        [wrapper_b setBody:bodyB];
        [wrapper_b setUID:[spriteB.accessibilityLabel intValue]];
        
        if (![uidsAdded containsObject: spriteB.accessibilityLabel])
        {
            [uidsAdded addObject: spriteB.accessibilityLabel];
            [bombsNeedingDetonation addObject: wrapper_b];
        }
    }
    else if (spriteB.tag == kEbeastTag && spriteA.tag == kBombTag)
	{
        b2bodyWrapper *wrapper_a = [[b2bodyWrapper alloc] init];
        [wrapper_a setBody:bodyA];
        [wrapper_a setUID:[spriteA.accessibilityLabel intValue]];
        [bombsNeedingDetonation addObject: wrapper_a];
        
        b2bodyWrapper *wrapper_b = [[b2bodyWrapper alloc] init];
        [wrapper_b setBody:bodyB];
        [wrapper_b setUID:[spriteB.accessibilityLabel intValue]];
        if (![bombedBeastUIDs containsObject: spriteB.accessibilityLabel])
        {
            [bombedBeastUIDs addObject: spriteB.accessibilityLabel];
            [explosionImpactedBeasts addObject: wrapper_b];
        }
        
        if (![uidsAdded containsObject: spriteA.accessibilityLabel])
        {
            [uidsAdded addObject: spriteA.accessibilityLabel];
            [bombsNeedingDetonation addObject: wrapper_a];
        }
    }
    else if (spriteA.tag == kEbeastTag && spriteB.tag == kSparkTag)
    {
        b2bodyWrapper *wrapper_a = [[b2bodyWrapper alloc] init];
        [wrapper_a setBody:bodyA];
        [wrapper_a setUID:[spriteA.accessibilityLabel intValue]];
        if (![electrifiedBeastUIDs containsObject: spriteA.accessibilityLabel])
        {
            NSLog(@"Adding beast and beast UID to electrified arrays");
            [electrifiedBeastUIDs addObject: spriteA.accessibilityLabel];
            [electrifiedBeasts addObject: wrapper_a];
        }
        
        b2bodyWrapper *wrapper_b = [[b2bodyWrapper alloc] init];
        [wrapper_b setBody:bodyB];
        [wrapper_b setUID:[spriteB.accessibilityLabel intValue]];
        
        if (![uidsAdded containsObject: spriteB.accessibilityLabel])
        {
            NSLog(@"Adding spark to removal array");
            [uidsAdded addObject: spriteB.accessibilityLabel];
            [sparksNeedingRemoval addObject: wrapper_b];
        }
    }
    else if (spriteA.tag == kSparkTag && spriteB.tag == kEbeastTag)
    {
        b2bodyWrapper *wrapper_a = [[b2bodyWrapper alloc] init];
        [wrapper_a setBody:bodyB];
        [wrapper_a setUID:[spriteB.accessibilityLabel intValue]];
        if (![electrifiedBeastUIDs containsObject: spriteB.accessibilityLabel])
        {
            NSLog(@"Adding beast and beast UID to electrified arrays");
            [electrifiedBeastUIDs addObject: spriteB.accessibilityLabel];
            [electrifiedBeasts addObject: wrapper_a];
        }
        
        b2bodyWrapper *wrapper_b = [[b2bodyWrapper alloc] init];
        [wrapper_b setBody:bodyA];
        [wrapper_b setUID:[spriteA.accessibilityLabel intValue]];
        
        if (![uidsAdded containsObject: spriteA.accessibilityLabel])
        {
            NSLog(@"Adding spark to removal array");
            
            [uidsAdded addObject: spriteA.accessibilityLabel];
            [sparksNeedingRemoval addObject: wrapper_b];
        }
    }
}

void ContactListener::ClearBombedBeastUID(int uid)
{
    NSString *strUID = [NSString stringWithFormat:@"%i", uid];
    [bombedBeastUIDs removeObject:strUID];
}

void ContactListener::ClearElectrifiedBeastUID(int uid)
{
    NSString *strUID = [NSString stringWithFormat:@"%i", uid];
    [electrifiedBeastUIDs removeObject:strUID];
}

void ContactListener::Initialize()
{
    needsJoint = [[NSMutableArray arrayWithCapacity:100] retain];
    contactPoints_x = [[NSMutableArray arrayWithCapacity:100] retain];
    contactPoints_y = [[NSMutableArray arrayWithCapacity:100] retain];
    bombsNeedingDetonation = [[NSMutableArray arrayWithCapacity:100] retain];
    uidsAdded = [[NSMutableArray arrayWithCapacity:100] retain];
    bombedBeastUIDs = [[NSMutableArray arrayWithCapacity:100] retain];
    explosionImpactedBeasts = [[NSMutableArray arrayWithCapacity:100] retain];
    electrifiedBeastUIDs = [[NSMutableArray arrayWithCapacity:100] retain];
    electrifiedBeasts = [[NSMutableArray arrayWithCapacity:100] retain];
    sparksNeedingRemoval = [[NSMutableArray arrayWithCapacity:100] retain];
}

void ContactListener::PreSolve(b2Contact* contact, const b2Manifold* oldManifold)
{
}

void ContactListener::PostSolve(b2Contact* contact, const b2ContactImpulse* impulse)
{
}

void ContactListener::EndContact(b2Contact* contact)
{
}
