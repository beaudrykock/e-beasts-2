//
//  ContainmentLid.h
//  e-beasts
//
//  Created by Beaudry Kock on 7/17/12.
//  Copyright 2012 University of Oxford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Box2D.h"
#import "GB2ShapeCache.h"
#import "GLES-Render.h"

@interface ContainmentLid : CCNode {
    CCSprite *sprite;
    b2Body * body;
    b2Joint * revJoint;
    b2RevoluteJointDef jointDef;
    NSInteger containmentSide;
    BOOL lidOpen;
    float lidOpenPeriod;
}

@property (nonatomic, assign) b2Body *body;

+(id) leftContainmentLidWithParentNode:(CCNode*)parentNode andWorld:(b2World*)world andAnchorBody:(b2Body*)anchorBody;
+(id) rightContainmentLidWithParentNode:(CCNode*)parentNode andWorld:(b2World*)world andAnchorBody:(b2Body*)anchorBody;
-(id) initWithParentNode:(CCNode*)parentNode andWorld:(b2World*)world andAnchorBody:(b2Body*)anchorBody andSide:(NSInteger)side;
-(b2Joint*)getRevoluteJoint;
-(CCSprite*)getSprite;
-(void)open;
-(void)close;

@end
