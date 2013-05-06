/*
 *  ContactListener.h
 *  PhysicsBox2d
 *
 *  Created by Steffen Itterheim on 17.09.10.
 *  Copyright 2010 Steffen Itterheim. All rights reserved.
 *
 */

#import "cocos2d.h"
#import "Box2D.h"

class ContactListener : public b2ContactListener
{
private:
	void BeginContact(b2Contact* contact);
	void PreSolve(b2Contact* contact, const b2Manifold* oldManifold);
	void PostSolve(b2Contact* contact, const b2ContactImpulse* impulse);
	void EndContact(b2Contact* contact);
    
public:
    void ClearBombedBeastUID(int uid);
    void ClearElectrifiedBeastUID(int uid);
    void Initialize();
    NSMutableArray *uidsAdded;
    NSMutableArray *bombedBeastUIDs;
    NSMutableArray *electrifiedBeastUIDs;
    NSMutableArray *needsJoint;
    NSMutableArray *bombsNeedingDetonation;
    NSMutableArray *sparksNeedingRemoval;
    NSMutableArray *electrifiedBeasts;
    NSMutableArray *explosionImpactedBeasts;
    bool jointsArrayInitialized; 
    NSMutableArray *contactPoints_x;
    NSMutableArray *contactPoints_y;
};