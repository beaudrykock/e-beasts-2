//
//  Cannon.h
//  e-beasts
//
//  Created by Beaudry Kock on 7/10/12.
//  Copyright (c) 2012 University of Oxford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Box2D.h"
#import "GB2ShapeCache.h"
#import "GLES-Render.h"

@interface Cannon : CCNode {
    CCSprite *cannonSprite;
    b2Body * cannonBody;
    b2Joint * revJoint;
    NSInteger side; // left or right
}

@property (nonatomic, assign) b2Body *cannonBody;

+(id) cannonWithParentNode:(CCNode*)parentNode andWorld:(b2World*)world andBase:(b2Body*)baseBody forSide:(NSInteger)_side;
-(id) initWithParentNode:(CCNode*)parentNode andWorld:(b2World*)world andBase:(b2Body*)baseBody forSide:(NSInteger)_side;
-(b2Joint*)getRevoluteJoint;
-(CGFloat) width;
-(CGFloat) height;
-(CCSprite*)getSprite;

@end
