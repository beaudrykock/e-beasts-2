#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"
#import "Ebeast.h"
#import "Sticky.h"
#import "ContactListener.h"
#import "b2bodyWrapper.h"
#import "Cannon.h"
#import "Bomb.h"
#import "Shrapnel.h"
#import "Spark.h"
#import "ContainmentLid.h"
#import "EnergyDataManager.h"
#import "GameIntroViewController.h"
#import "ApplicanceUseData.h"

enum
{
	kTagBatchNode,
};

@interface GamePlayLayer : CCLayer <GameIntroViewControllerDelegateProtocol>{
    b2World *_world;
    ContactListener *contactListener;
    b2Body *screenBorderBody_;
    b2Fixture *_bottomFixture;
    float _timeStep;
    int32 _velocityIterations;
    int32 _positionIterations;
    CCLabelTTF *_gamePausedLabel;
    b2Fixture *_beastFixture;
    CCArray *beasties;
    CCArray *bombs;
    CCArray *stickies;
    CCArray *sparks;
    CCArray *nodeRemoveList;
    float cannonAngle;
    b2MouseJoint *mouseJoint_left;
    b2MouseJoint *mouseJoint_right;
    b2Body *tesla_left_B;
    b2Body *tesla_right_B;
    b2Body *cannonBaseBody_left;
    b2Body *cannonBaseBody_right;
    //b2Body *containmentFloorBody;
    //b2Body *containmentLeftWallBody;
    //b2Body *containmentRightWallBody;
    //ContainmentLid *leftContainmentLid;
    //ContainmentLid *rightContainmentLid;
    b2Body *beastBody; // temp
    Cannon *cannon_right;
    Cannon *cannon_left;
    b2Fixture *cannonFixture_right;
    b2Fixture *cannonFixture_left;
    float barrelAngle; // stores angle of barrel relative to original joint position (90')
    int weaponChoice;
    CGRect containmentZone;
    CCSprite *cannonControl_left;    
    CCSprite *cannonControl_right;
    GLESDebugDraw *debugDraw;
    BOOL drawProjectileTrajectory;
    BOOL projectileTrajectoryDrawn;
    //CCRibbon *trajectoryRibbon;
    int touchMovement;
    BOOL gamePaused;
    BOOL teslaActive;
    
    // weapon control - right cannon
    CCMenuItemToggle *sticky_toggle;
    CCMenuItemToggle *bomb_toggle;
    CCMenuItemToggle *suction_toggle;
        
    EnergyDataManager *energyData;
    GameIntroViewController *givc;
    
    // debugging
    GLESDebugDraw *m_debugDraw;		// strong ref
    
    NSInteger sparkVectorType;
}

+ (id) scene;
+ (GamePlayLayer*)sharedGPL;
- (void)layoutGameControls;
-(b2Vec2)toMeters:(CGPoint)point;
-(CGPoint)toPixels:(b2Vec2)vec;
-(void)addTestSprite;
-(void)setTimeStep:(float)timeStep andVelocityIterations:(int32)velocityIterations andPositionIterations:(int32)positionIterations;
-(CGSize)winSize;
-(CCSpriteBatchNode*) getSpriteBatch;
-(void)layoutStaticElements;
-(void)layoutDynamicElements;
-(void)fireForSide:(NSInteger)side;
-(void)createStickyJoints;
-(void)explodeBombs;
-(void)explosionAtPosition:(CGPoint)position;
-(void)smokeAtPosition:(CGPoint)position;
-(void)removeBombWithUID:(int)UID;
-(void)addToNodeRemoveList:(CCNode*)node;
-(void)checkBombTimers;
-(void)checkStickyTimers;
-(void)removeStickyWithUID:(int)UID;
-(Ebeast*)getEbeastForUID:(int)uid;
-(void)drawTrajectoryForSide:(NSInteger)side;
-(b2Vec2)getTrajectoryPointWithStartingPosition:(b2Vec2)startingPosition andStartingVelocity:(b2Vec2)startingVelocity andSteps:(float)steps;
-(void)drawTrajectoryWithStartingPosition:(CGPoint)startingPos andStartingVelocity:(CGPoint)startingVel;
-(void)toggleTrajectoryDrawing;
//-(void)openContainment;
- (void)reloadScene;
-(void)enableBox2dDebugDrawing;

@property (nonatomic, strong) GameIntroViewController *givc;
@property (nonatomic, strong) EnergyDataManager *energyData;

@end