#import "GamePlayLayer.h"

// Not included in "cocos2d.h"
#import "CCPhysicsSprite.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"

@implementation GamePlayLayer


static GamePlayLayer* GPLInstance;

+ (id)scene {
    
    CCScene *scene = [CCScene node];
    GamePlayLayer *layer = [GamePlayLayer node];
    [scene addChild:layer];
    return scene;
    
}

- (void)reloadScene 
{    
    // Reload the current scene
    CCScene *scene = [GamePlayLayer scene];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionZoomFlipX transitionWithDuration:0.5 scene:scene]];
}

+(GamePlayLayer*)sharedGPL
{
    NSAssert(GPLInstance != nil, @"GPL not yet initialized!");
	return GPLInstance;
}

#pragma mark - Setting up the gameplay layer
- (id)init {
    
    if ((self=[super init])) {
        
        self.isTouchEnabled = YES;
        CGSize winSize = [CCDirector sharedDirector].winSize;
        

        // Create a world
        b2Vec2 gravity = b2Vec2(0.0f, -10.0f);
        bool doSleep = true;
        bool continuousPhysics = true;
        _world = new b2World(gravity);
       
        _world->SetAllowSleeping(doSleep);
        
        _world->SetContinuousPhysics(continuousPhysics);
        
        m_debugDraw = new GLESDebugDraw( PTM_RATIO );
        _world->SetDebugDraw(m_debugDraw);
        
        uint32 flags = 0;
        flags += b2Draw::e_shapeBit;
        //		flags += b2Draw::e_jointBit;
        //		flags += b2Draw::e_aabbBit;
        //		flags += b2Draw::e_pairBit;
        //		flags += b2Draw::e_centerOfMassBit;
        m_debugDraw->SetFlags(flags);		
        
        
        contactListener = new ContactListener();
        contactListener->Initialize();
        _world->SetContactListener(contactListener);
        
        // Create edges around the entire screen
        b2Vec2 lowerLeftCorner = b2Vec2(50.0/PTM_RATIO,0);
        b2Vec2 lowerRightCorner = b2Vec2((winSize.width-50.0)/PTM_RATIO, 0);
        b2Vec2 upperLeftCorner = b2Vec2(50.0/PTM_RATIO, winSize.height/PTM_RATIO);
        b2Vec2 upperRightCorner = b2Vec2((winSize.width-50.0)/PTM_RATIO, winSize.height/PTM_RATIO);
        
        // Define the static container body, which will provide the collisions at screen borders.
        b2BodyDef screenBorderDef;
        screenBorderDef.position.Set(0, 0);
        screenBorderBody_ = _world->CreateBody(&screenBorderDef);
        b2EdgeShape screenBorderShape;
        
        // Create fixtures for the four borders (the border shape is re-used)
        screenBorderShape.Set(lowerLeftCorner, lowerRightCorner);
        screenBorderBody_->CreateFixture(&screenBorderShape, 0);
        screenBorderShape.Set(lowerRightCorner, upperRightCorner);
        screenBorderBody_->CreateFixture(&screenBorderShape, 0);
        screenBorderShape.Set(upperRightCorner, upperLeftCorner);
        screenBorderBody_->CreateFixture(&screenBorderShape, 0);
        screenBorderShape.Set(upperLeftCorner, lowerLeftCorner);
        screenBorderBody_->CreateFixture(&screenBorderShape, 0);
        
        beasties = [[CCArray alloc] initWithCapacity:kNumberOfBeasts];
        bombs = [[CCArray alloc] initWithCapacity:100];
        stickies = [[CCArray alloc] initWithCapacity:100];
        sparks = [[CCArray alloc] initWithCapacity:100];
        nodeRemoveList = [[CCArray alloc] initWithCapacity:100];
        
        containmentZone = CGRectMake(([self winSize].width/2.0)-50.0, 1.5, 100.0, 70.0);
        
        [self resetGameParameters];
        
        [self setTimeStep:kTimeStep andVelocityIterations:kVelocityIterations andPositionIterations:kPositionIterations];
        
        [self layoutGameControls];
        
        [self layoutStaticElements];
        
        // [self addTestSprite];
        
        //[self enableBox2dDebugDrawing];
        
        [self addIntroView];
        
    }
    
    return self;
}

#pragma mark - Game Intro View
-(void)addIntroView
{
    UIView *glView = [CCDirector sharedDirector].openGLView;
    
    self.givc = [[GameIntroViewController alloc] init];
    [self.givc setDelegate:self];
    [glView addSubview: self.givc.view];
    
}

-(void)gameIntroView:(UIView*)view didFinishWithOption:(NSInteger)option
{
    if (option == 1)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prepareGame) name:TENDRIL_SUCCESS object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prepareGame) name:TENDRIL_FAILURE object:nil];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prepareGame) name:CANNED_SUCCESS object:nil];
    }
    self.energyData = [[EnergyDataManager alloc] init];
    [self.energyData setupForOption:option];
}

-(void)prepareGame
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.givc.view removeFromSuperview];
    [self layoutDynamicElements];
    [self scheduleUpdate];
    
    [self schedule:@selector(teslaSpark) interval:1];
}

-(void)resetGameParameters
{
    teslaActive = YES;
    
    cannonAngle = 0.0;
    
    weaponChoice = kStickyType;
}

-(void)setTimeStep:(float)timeStep andVelocityIterations:(int32)velocityIterations andPositionIterations:(int32)positionIterations
{
    _timeStep = timeStep;
    _velocityIterations = velocityIterations;
    _positionIterations = positionIterations;
}


-(void)layoutGameControls
{
    CGSize size = [[CCDirector sharedDirector] winSize];
    
    
    CCMenuItemImage* pause = [CCMenuItemImage itemFromNormalImage:@"stop.png" selectedImage:nil];
    CCMenuItemImage* resume = [CCMenuItemImage itemFromNormalImage:@"go.png" selectedImage:nil];
    CCMenuItemToggle *pause_resume_toggle = [CCMenuItemToggle itemWithTarget:self selector:@selector(pauseGame) items:pause, resume, nil];

    CCSprite* reload = [CCSprite spriteWithFile:@"reload.png"];
    CCSprite* reload_sel = [CCSprite spriteWithFile:@"reload_sel.png"];
    CCMenuItemSprite *reloadItem = [CCMenuItemSprite itemFromNormalSprite:reload selectedSprite:reload_sel target:self selector:@selector(reloadGame)];
    
    CCMenu *menu = [CCMenu menuWithItems:pause_resume_toggle, reloadItem, nil];
    menu.position = CGPointMake(45, size.height-25);
    [self addChild:menu];
    [menu alignItemsHorizontallyWithPadding:5.0];
    
    // weapon control toggle
    CCMenuItemImage* sticky_untoggled = [CCMenuItemImage itemFromNormalImage:@"sticky_untoggled_btn.png" selectedImage:nil];
    CCMenuItemImage* sticky_toggled = [CCMenuItemImage itemFromNormalImage:@"sticky_toggled_btn.png" selectedImage:nil];
    sticky_toggle = [CCMenuItemToggle itemWithTarget:self selector:@selector(setStickyAsWeapon) items:sticky_untoggled, sticky_toggled, nil];

    CCMenuItemImage* bomb_untoggled = [CCMenuItemImage itemFromNormalImage:@"bomb_untoggled_btn.png" selectedImage:nil];
    CCMenuItemImage* bomb_toggled = [CCMenuItemImage itemFromNormalImage:@"bomb_toggled_btn.png" selectedImage:nil];
    bomb_toggle = [CCMenuItemToggle itemWithTarget:self selector:@selector(setBombAsWeapon) items:bomb_untoggled, bomb_toggled, nil];
    
    CCMenuItemImage* suction_untoggled = [CCMenuItemImage itemFromNormalImage:@"suction_untoggled_btn.png" selectedImage:nil];
    CCMenuItemImage* suction_toggled = [CCMenuItemImage itemFromNormalImage:@"suction_toggled_btn.png" selectedImage:nil];
    suction_toggle = [CCMenuItemToggle itemWithTarget:self selector:@selector(setSuctionAsWeapon) items:suction_untoggled, suction_toggled, nil];
    
    CCMenu *rightWeaponControl = [CCMenu menuWithItems:sticky_toggle, bomb_toggle, suction_toggle, nil];
    rightWeaponControl.position = CGPointMake(size.width-25.0, size.height-80.0);
    [rightWeaponControl alignItemsVerticallyWithPadding:5.0];
    [self addChild:rightWeaponControl];
    
    CCMenuItemImage* traj_inactive_state = [CCMenuItemImage itemFromNormalImage:@"trajectory_sel_btn.png" selectedImage:nil];
    CCMenuItemImage* traj_active_state = [CCMenuItemImage itemFromNormalImage:@"trajectory_btn.png" selectedImage:nil];
    CCMenuItemToggle *toggleTrajectory = [CCMenuItemToggle itemWithTarget:self selector:@selector(toggleTrajectoryDrawing) items:traj_inactive_state, traj_active_state, nil];
    
    //CCMenu *weaponControl = [CCMenu menuWithItems:toggleTrajectory, nil];
    //weaponControl.position = CGPointMake(25.0, (size.height/2));
    //[self addChild:weaponControl];
    //[weaponControl alignItemsVerticallyWithPadding:5.0];
    
    // CANNON CONTROL
    cannonControl_right = [CCSprite spriteWithFile:@"sliderBackground.png"];
    cannonControl_right.tag = self.tag;
    cannonControl_right.position = CGPointMake([self winSize].width-25.0, 86.0);
    [self addChild:cannonControl_right z:1000]; 
    
    cannonControl_left = [CCSprite spriteWithFile:@"sliderBackground.png"];
    cannonControl_left.tag = self.tag;
    cannonControl_left.position = CGPointMake(25.0, 86.0);
    [self addChild:cannonControl_left z:1000];
    
    // ENERGY CAPTURE LEVEL INDICATOR
    CCSprite *energyLevelIndicator = [CCSprite spriteWithFile:@"20-pct-past.png"];
    energyLevelIndicator.position = CGPointMake((size.width/2.0), size.height-15.0);
    energyLevelIndicator.scale = 0.6;
    [energyLevelIndicator setTag:kEnergyIndicatorTag];
    [self addChild:energyLevelIndicator];
    
    // slider to control unit force of bugs
    //slider = [CCSlider sliderWithBackgroundFile: @"sliderBG.png" thumbFile: @"sliderThumb.png"];
    //slider.tag = 1;
    //[slider setMinValue:0.0 andMaxValue:1.0];
    //[self addChild:slider];
    //slider.position = CGPointMake(50.0, 100.0);
    //slider.delegate = self;
    
}

- (void) valueChanged: (float) value tag: (int) tag 
{
    switch (tag) {
        case 1:
        {
            Ebeast *beast = (Ebeast*)[self getChildByTag:kEbeastTag];
            [beast setUnitForce:value * 20.0 forAxis:kAxis_y];
            break;
        }
        case 2:
        {
            cannonAngle = value;
        }
        default:
            break;
    }
}

-(void)layoutStaticElements
{
    [[GB2ShapeCache sharedShapeCache]
     addShapesWithFile:@"ebeasts-shapes.plist"];
    
    // tesla coils
    // left
    CCSprite *tesla_left = [CCSprite spriteWithFile:@"teslaCoil.png"];
    tesla_left.tag = self.tag;
    tesla_left.position = CGPointMake(([self winSize].width/2)-([self winSize].width/8), tesla_left.contentSize.height/2);
    [self addChild:tesla_left z:500];

    b2BodyDef tesla_left_BD;
    tesla_left_BD.type = b2_staticBody;
    tesla_left_BD.position.Set((tesla_left.position.x)/PTM_RATIO,0.0);
    tesla_left_BD.userData = tesla_left;
    tesla_left_B = _world->CreateBody(&tesla_left_BD);
    
    // right
    CCSprite *tesla_right = [CCSprite spriteWithFile:@"teslaCoil.png"];
    tesla_right.tag = self.tag;
    tesla_right.position = CGPointMake(([self winSize].width/2)+([self winSize].width/8), tesla_right.contentSize.height/2);
    [self addChild:tesla_right z:500];
    
    b2BodyDef tesla_right_BD;
    tesla_right_BD.type = b2_staticBody;
    tesla_right_BD.position.Set((tesla_right.position.x)/PTM_RATIO,0.0);
    tesla_right_BD.userData = tesla_right;
    tesla_right_B = _world->CreateBody(&tesla_right_BD);
    
    // base of cannon - right
    CCSprite *cannonBaseSprite_right = [CCSprite spriteWithFile:@"cannon_base.png"];
    cannonBaseSprite_right.tag = self.tag;
    cannonBaseSprite_right.position = CGPointMake([self winSize].width-50.0, 86.0);
    [self addChild:cannonBaseSprite_right z:500];

    // base of cannon - left
    CCSprite *cannonBaseSprite_left = [CCSprite spriteWithFile:@"cannon_base_left.png"];
    cannonBaseSprite_left.tag = self.tag;
    cannonBaseSprite_left.position = CGPointMake(45.0, 86.0);
    [self addChild:cannonBaseSprite_left z:500];
    
    b2BodyDef cannonBaseBodyDef_right;
    cannonBaseBodyDef_right.type = b2_staticBody;
    cannonBaseBodyDef_right.position.Set(([self winSize].width-50.0)/PTM_RATIO,86.0/PTM_RATIO);
    cannonBaseBodyDef_right.userData = cannonBaseSprite_right;
    cannonBaseBody_right = _world->CreateBody(&cannonBaseBodyDef_right);

    b2BodyDef cannonBaseBodyDef_left;
    cannonBaseBodyDef_left.type = b2_staticBody;
    cannonBaseBodyDef_left.position.Set(50.0/PTM_RATIO,86.0/PTM_RATIO);
    cannonBaseBodyDef_left.userData = cannonBaseSprite_left;
    cannonBaseBody_left = _world->CreateBody(&cannonBaseBodyDef_left);
    
    // PhysicsEditor
    [[GB2ShapeCache sharedShapeCache]
     addFixturesToBody:tesla_left_B forShapeName:@"teslaCoil"];
    
    [[GB2ShapeCache sharedShapeCache]
     addFixturesToBody:tesla_right_B forShapeName:@"teslaCoil"];
    
    
    [[GB2ShapeCache sharedShapeCache]
     addFixturesToBody:cannonBaseBody_right forShapeName:@"cannon_base"];
    
    [[GB2ShapeCache sharedShapeCache]
     addFixturesToBody:cannonBaseBody_left forShapeName:@"cannon_base_left"];
    
    
    // CONTAINMENT - TEST
    /*
    CCSprite *containmentFloorSprite = [CCSprite spriteWithFile:@"containment_floor.png"];
    containmentFloorSprite.position = CGPointMake(([self winSize].width/2)-50.0, 1.5);
    [containmentFloorSprite setAnchorPoint:[[GB2ShapeCache sharedShapeCache] anchorPointForShape:@"containment_floor"]];
    [self addChild:containmentFloorSprite];
    b2BodyDef containmentFloorBodyDef;
    containmentFloorBodyDef.type = b2_staticBody;
    containmentFloorBodyDef.position.Set(containmentFloorSprite.position.x/PTM_RATIO, 1.5/PTM_RATIO);
    containmentFloorBodyDef.userData = containmentFloorSprite;
    containmentFloorBody = _world->CreateBody(&containmentFloorBodyDef);
    [[GB2ShapeCache sharedShapeCache]
     addFixturesToBody:containmentFloorBody forShapeName:@"containment_floor"];
    
    CCSprite *containmentLeftWallSprite = [CCSprite spriteWithFile:@"containment_wall.png"];
    containmentLeftWallSprite.position = CGPointMake(containmentFloorSprite.position.x, 1.5);
    [containmentLeftWallSprite setAnchorPoint:[[GB2ShapeCache sharedShapeCache] anchorPointForShape:@"containment_wall"]];
    [self addChild:containmentLeftWallSprite];
    b2BodyDef containmentLeftWallBodyDef;
    containmentLeftWallBodyDef.type = b2_staticBody;
    containmentLeftWallBodyDef.position.Set(containmentLeftWallSprite.position.x/PTM_RATIO, 1.5/PTM_RATIO);
    containmentLeftWallBodyDef.userData = containmentLeftWallSprite;
    containmentLeftWallBody = _world->CreateBody(&containmentLeftWallBodyDef);
    [[GB2ShapeCache sharedShapeCache]
     addFixturesToBody:containmentLeftWallBody forShapeName:@"containment_wall"];

    CCSprite *containmentRightWallSprite = [CCSprite spriteWithFile:@"containment_wall.png"];
    containmentRightWallSprite.position = CGPointMake(containmentFloorSprite.position.x+containmentFloorSprite.boundingBox.size.width, 1.5);
    [containmentRightWallSprite setAnchorPoint:[[GB2ShapeCache sharedShapeCache] anchorPointForShape:@"containment_wall"]];
    [self addChild:containmentRightWallSprite];
    b2BodyDef containmentRightWallBodyDef;
    containmentRightWallBodyDef.type = b2_staticBody;
    containmentRightWallBodyDef.position.Set(containmentRightWallSprite.position.x/PTM_RATIO, 1.5/PTM_RATIO);
    containmentRightWallBodyDef.userData = containmentRightWallSprite;
    containmentRightWallBody = _world->CreateBody(&containmentRightWallBodyDef);
    [[GB2ShapeCache sharedShapeCache]
     addFixturesToBody:containmentRightWallBody forShapeName:@"containment_wall"];
    
    tempCannonControl = [CCSlider sliderWithBackgroundFile: @"sliderBG.png" thumbFile: @"sliderThumb.png"];
    tempCannonControl.tag = 2;
    [tempCannonControl setMinValue:-1.0 andMaxValue:1.0];
    [self addChild:tempCannonControl];
    tempCannonControl.position = CGPointMake(450.0, 50.0);
    tempCannonControl.delegate = self;
     */
}

-(void)layoutDynamicElements
{
    for (int i = 0; i<([self.energyData getPreviousConsumptionInSprites]+[self.energyData getProjectedConsumptionInSprites]); i++)
    {
        Ebeast* beast = (Ebeast*)[Ebeast ebeastWithParentNode:self andWorld:_world];
        b2Vec2 tlbp = tesla_left_B->GetPosition();
        b2Vec2 trbp = tesla_right_B->GetPosition();
        CGPoint tlbpp = CGPointMake(tlbp.x*PTM_RATIO, tlbp.y*PTM_RATIO);
        CGPoint trbpp = CGPointMake(trbp.x*PTM_RATIO, trbp.y*PTM_RATIO);
        [beast setTeslaDangerZone: CGRectMake(tlbpp.x-25, 0.0, (trbpp.x-tlbpp.x)+50, 100.0)];
        [beasties addObject:beast];
        beastBody = [beast getBeastBody];
    }
    
    cannon_right = (Cannon*)[Cannon cannonWithParentNode:self andWorld:_world andBase:cannonBaseBody_right forSide:kRight];
    cannon_left = (Cannon*)[Cannon cannonWithParentNode:self andWorld:_world andBase:cannonBaseBody_left forSide:kLeft];
    
    cannonFixture_right = cannonBaseBody_right->GetFixtureList();
    cannonFixture_left = cannonBaseBody_left->GetFixtureList();
    
    //leftContainmentLid = (ContainmentLid*)[ContainmentLid leftContainmentLidWithParentNode:self andWorld:_world andAnchorBody:containmentLeftWallBody];
    //rightContainmentLid = (ContainmentLid*)[ContainmentLid rightContainmentLidWithParentNode:self andWorld:_world andAnchorBody:containmentRightWallBody];
}

#pragma mark - Game physics
-(void)update:(ccTime)delta
{
    _world->Step(_timeStep, _velocityIterations, _positionIterations);
    /*
    for (b2Body* b = _world->GetBodyList(); b != nil; b = b->GetNext())
    {
        CCSprite *sprite = (CCSprite *)b->GetUserData();                        
        sprite.position = ccp(b->GetPosition().x * PTM_RATIO,
                              b->GetPosition().y * PTM_RATIO);
        
        sprite.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());

    }*/
    //NSLog(@"STEPPING AT %f", delta); 
    [self checkBombTimers];
    [self checkStickyTimers];
    [self createStickyJoints];
    [self explodeBombs];
    [self electrifyBeasts];
    //[self checkContainment];
    [self nodeCleanup];
}

-(void)recordEbeastDestruction
{
    [self.energyData recordEnergyCapture: kEnergyPerSprite];
    [self showEnergyInformationMessageFor: kEnergyPerSprite];
    [self updateEnergyIndicatorLevel];
}

-(void)updateEnergyIndicatorLevel
{
    float level = [self.energyData getEnergyAccountLevel];
    
    CCSprite *energyIndicator = (CCSprite*)[self getChildByTag:kEnergyIndicatorTag];
    
    if (level <= 0.1)
    {
        [energyIndicator setTexture:[[CCSprite spriteWithFile:@"20-pct-past.png"] texture]];
    }
    else if (level <= 0.2)
    {
        [energyIndicator setTexture:[[CCSprite spriteWithFile:@"40-pct-past.png"] texture]];
    }
    else if (level <= 0.3)
    {
        [energyIndicator setTexture:[[CCSprite spriteWithFile:@"60-pct-past.png"] texture]];
    }
    else if (level <= 0.4)
    {
        [energyIndicator setTexture:[[CCSprite spriteWithFile:@"80-pct-past.png"] texture]];
    }
    else if (level <= 0.5)
    {
        [energyIndicator setTexture:[[CCSprite spriteWithFile:@"100-pct-past.png"] texture]];
    }
    else if (level <= 0.6)
    {
        [energyIndicator setTexture:[[CCSprite spriteWithFile:@"20-pct-fut.png"] texture]];
    }
    else if (level <= 0.7)
    {
        [energyIndicator setTexture:[[CCSprite spriteWithFile:@"40-pct-fut.png"] texture]];
    }
    else if (level <= 0.8)
    {
        [energyIndicator setTexture:[[CCSprite spriteWithFile:@"60-pct-fut.png"] texture]];
    }
    else if (level <= 0.9)
    {
        [energyIndicator setTexture:[[CCSprite spriteWithFile:@"80-pct-fut.png"] texture]];
    }
    else if (level <= 1.0)
    {
        [energyIndicator setTexture:[[CCSprite spriteWithFile:@"100-pct-fut.png"] texture]];
    }
}

-(void)createStickyJoints
{
    NSMutableArray *bodiesNeedingJoints = (NSMutableArray*)contactListener->needsJoint; 
    NSMutableArray *contactpoints_x = (NSMutableArray*)contactListener->contactPoints_x;
    NSMutableArray *contactpoints_y = (NSMutableArray*)contactListener->contactPoints_y;
    
    for (int i = 0; i<[bodiesNeedingJoints count]; i+=2)
    {
        b2bodyWrapper *wrapper_a = (b2bodyWrapper*)[bodiesNeedingJoints objectAtIndex:i];
        b2bodyWrapper *wrapper_b = (b2bodyWrapper*)[bodiesNeedingJoints objectAtIndex:i+1];
        b2Vec2 anchorPoint = b2Vec2([[contactpoints_x objectAtIndex:0] floatValue], [[contactpoints_y objectAtIndex:0] floatValue]);
        b2RevoluteJointDef jointDef;
        jointDef.bodyA = wrapper_a.body;
        jointDef.bodyB = wrapper_b.body;
        jointDef.localAnchorA = jointDef.bodyA->GetLocalPoint(anchorPoint);
        jointDef.localAnchorB = jointDef.bodyB->GetLocalPoint(anchorPoint);
        jointDef.referenceAngle = jointDef.bodyA->GetAngle() - jointDef.bodyB->GetAngle();
        //jointDef.Initialize(wrapper_a.body, wrapper_b.body, wrapper_a.body->GetWorldCenter());
        _world->CreateJoint(&jointDef);
        
        if ([wrapper_a getTag] == kEbeastTag)
        {
            [[self getEbeastForUID:[wrapper_a getUID]] recordAttachedStickyUID:[wrapper_b getUID]];
        }
        else if ([wrapper_b getTag] == kEbeastTag) 
        {
            [[self getEbeastForUID:[wrapper_b getUID]] recordAttachedStickyUID:[wrapper_a getUID]];
        }
        
    }
    
    [contactListener->needsJoint removeAllObjects];
    [contactListener->contactPoints_x removeAllObjects];
    [contactListener->contactPoints_y removeAllObjects];
}

-(Ebeast*)getEbeastForUID:(int)uid
{
    BOOL found = NO;
    int count = 0;
    
    while (!found && count < [beasties count])
    {
        Ebeast *beast = [beasties objectAtIndex:count];
        if ([beast getUID] == uid)
        {
            found = YES;
        }
        else 
        {
            count++;
        }
    }
    
    return [beasties objectAtIndex:count];
}

-(void)explodeBombs
{
    NSMutableArray *bombsNeedingDetonation = (NSMutableArray*)contactListener->bombsNeedingDetonation;
    NSMutableArray *explosionImpactedBeasts = (NSMutableArray*)contactListener->explosionImpactedBeasts;
    
    for (int i = 0; i<[bombsNeedingDetonation count]; i++)
    {
        b2bodyWrapper *wrapper = (b2bodyWrapper*)[bombsNeedingDetonation objectAtIndex:i];
        b2Body *body = wrapper.body;
        b2Vec2 posVec = body->GetPosition();
        CGPoint position = CGPointMake(posVec.x*PTM_RATIO, posVec.y*PTM_RATIO);
        [self explosionAtPosition:position];
        [self removeBombWithUID:[wrapper getUID]];
        
        b2bodyWrapper *wrapper_beast = (b2bodyWrapper*)[explosionImpactedBeasts objectAtIndex:i];
        [[self getEbeastForUID:[wrapper_beast getUID]] recordExplosiveImpact];
        contactListener->ClearBombedBeastUID([wrapper_beast getUID]);
    }
    
    [contactListener->bombsNeedingDetonation removeAllObjects];
    [contactListener->explosionImpactedBeasts removeAllObjects];
    
}

-(void)electrifyBeasts
{
    NSMutableArray *sparksNeedingRemoval = (NSMutableArray*)contactListener->sparksNeedingRemoval;
    NSMutableArray *electrifedBeasts = (NSMutableArray*)contactListener->electrifiedBeasts;
    
    for (int i = 0; i<[sparksNeedingRemoval count]; i++)
    {
        b2bodyWrapper *wrapper = (b2bodyWrapper*)[sparksNeedingRemoval objectAtIndex:i];
        b2Body *body = wrapper.body;
        b2Vec2 posVec = body->GetPosition();
        CGPoint position = CGPointMake(posVec.x*PTM_RATIO, posVec.y*PTM_RATIO);
        [self sparkShowerAtPosition: position];
        [self removeSparkWithUID:[wrapper getUID]];
        
        b2bodyWrapper *wrapper_beast = (b2bodyWrapper*)[electrifedBeasts objectAtIndex:i];
        b2Body *beastBody = wrapper_beast.body;
        posVec = beastBody->GetPosition();
        position = CGPointMake(posVec.x*PTM_RATIO, posVec.y*PTM_RATIO);
        
        [[self getEbeastForUID:[wrapper_beast getUID]] electrify];
        
        id waitForRemoval = [CCDelayTime actionWithDuration:0.5];
        id removeBeast = [CCCallBlock actionWithBlock:^{
           [nodeRemoveList addObject:[self getEbeastForUID:[wrapper_beast getUID]]];
            [self recordEbeastDestruction];
            [self beastExplosionAtPosition:position];
        }];
        [self runAction:[CCSequence actions:waitForRemoval, removeBeast,nil]];
        
        
        contactListener->ClearElectrifiedBeastUID([wrapper_beast getUID]);
    }
    
    [contactListener->sparksNeedingRemoval removeAllObjects];
    [contactListener->electrifiedBeasts removeAllObjects];
}

-(void)removeSparkWithUID:(NSInteger)UID
{
    BOOL found = NO;
    int count = 0;
    
    while (!found && count < [sparks count])
    {
        Spark *spark = [sparks objectAtIndex:count];
        if ([spark getUID] == UID)
        {
            found = YES;
        }
        else
        {
            count++;
        }
    }
    
    [self addToNodeRemoveList:[sparks objectAtIndex:count]];

}

-(void)checkBombTimers
{
    int count = 0;
    for (Bomb *bomb in bombs)
    {
        if ([bomb getFuse]<1.0)
        {
            [self explosionAtPosition:CGPointMake([bomb bombSprite].position.x, [bomb bombSprite].position.y)];
            [self removeBombWithUID:[bomb getUID]];
        }
        count++;
    }
}

-(void)checkStickyTimers
{
    int count = 0;
    for (Sticky *sticky in stickies)
    {
        if ([sticky getFuse]<1.0)
        {
            [self smokeAtPosition:CGPointMake([sticky stickySprite].position.x, [sticky stickySprite].position.y)];
            [self removeStickyWithUID:[sticky getUID]];
        }
        count++;
    }
}

-(void)removeBombWithUID:(int)UID
{
    BOOL found = NO;
    int count = 0;
    
    while (!found && count < [bombs count])
    {
        Bomb *bomb = [bombs objectAtIndex:count];
        if ([bomb getUID] == UID)
        {
            found = YES;
            //[bomb destroyBody];
        }
        else 
        {
            count++;
        }
    }

    [self addToNodeRemoveList:[bombs objectAtIndex:count]];
}

-(void)removeStickyWithUID:(int)UID
{
    BOOL found = NO;
    int count = 0;
    
    while (!found && count < [stickies count])
    {
        Sticky *sticky = [stickies objectAtIndex:count];
        if ([sticky getUID] == UID)
        {
            found = YES;
        }
        else 
        {
            count++;
        }
    }
    
    for (Ebeast *beast in beasties)
    {
        [beast detachStickyWithUID:UID];
    }
    
    [self addToNodeRemoveList:[stickies objectAtIndex:count]];
}

-(void)addToNodeRemoveList:(CCNode*)node
{
#ifdef DEBUG_GPL
    NSLog(@"adding node to remove list");
#endif
    [nodeRemoveList addObject:node];
}

-(void)nodeCleanup
{
    for (CCNode *node in nodeRemoveList)
    {
        if ([node isKindOfClass:[Bomb class]])
        {
            Bomb* bomb = (Bomb*)node;
            [bomb destroyBody];
            [bombs removeObject:bomb];
        }
        else if ([node isKindOfClass:[Sticky class]])
        {
            Sticky* sticky = (Sticky*)node;
            [sticky destroyBody];
            [stickies removeObject:sticky];
        }
        else if ([node isKindOfClass:[Spark class]])
        {
            Spark* spark = (Spark*)node;
            [spark destroyBody];
            [sparks removeObject:spark];
        }
        else if ([node isKindOfClass:[Ebeast class]])
        {
            Ebeast* ebeast = (Ebeast*)node;
            [ebeast destroyBody];
            [beasties removeObject:ebeast];
        }
        
        [self removeChild:node cleanup:YES];
    }
    [nodeRemoveList removeAllObjects];
}

-(void)sparkShowerAtPosition:(CGPoint)position
{
    CCParticleSystem *system = [CCParticleSystemQuad particleWithFile:@"sparkShower.plist"];
    system.position = position;
    [self addChild:system z:1 tag:kSparkShowerTag];
    
    id waitForSpark = [CCDelayTime actionWithDuration:0.5];
    id removeSpark = [CCCallBlock actionWithBlock:^{
        [self removeChild:system cleanup:YES];
    }];
    [self runAction:[CCSequence actions:waitForSpark, removeSpark,nil]];
}

-(void)explosionAtPosition:(CGPoint)position
{
    if (weaponChoice == kExplosiveBombType)
    {
        CCParticleSystem *system = [CCParticleSystemQuad particleWithFile:@"explosion.plist"];
        system.position = position;
        [self addChild:system z:1 tag:kExplosionTag];
        
        [self createShockwaveAtPosition:position];
    }
    else {
        CCParticleSystem *system = [CCParticleSystemQuad particleWithFile:@"implosion.plist"];
        system.position = position;
        [self addChild:system z:1 tag:kExplosionTag];
        
        [self createVortexAtPosition:position];
    }
    
    /* SHRAPNEL
    b2Vec2 initialVector;
    float alpha = 0.0;
    float force = 100.0;
    // test shrapnel
    for (int i = 0; i<8; i++)
    {
        float x = 0.0;
        float y = 0.0;
        // TODO: create initial vector
        
        if (i == 0)
        {
            x = 0.0;
            y = force;
        }
        else if (i==4)
        {
            x = 0.0;
            y = -1 * force;
        }
        else {
            x = force * cosf(alpha);
            y = force * sinf(alpha);
        }
        
        initialVector.x = x*PTM_RATIO;
        initialVector.y = y*PTM_RATIO;
        
        
        [Shrapnel shrapnelWithParentNode:self andWorld:_world andInitialVector:initialVector andInitialPosition:position];
        
        alpha += 45.0;
    }*/
}

// creates a spark which passes from either left or right coil to opposite coil
-(void)teslaSpark
{
    b2Vec2 initialVector;
    CGPoint targetPos;
    CGPoint startPos;
    CCSprite *teslaSprite_R = (CCSprite*)tesla_right_B->GetUserData();
    CCSprite *teslaSprite_L = (CCSprite*)tesla_left_B->GetUserData();
    //NSLog(@"arc4random_uniform(1) = %i", arc4random_uniform(2));
    if (arc4random_uniform(2)==0) // going right
    {
        startPos = CGPointMake((tesla_left_B->GetPosition().x*PTM_RATIO)+25.0, (tesla_left_B->GetPosition().y * PTM_RATIO)+(teslaSprite_L.contentSize.height));
        
        targetPos = CGPointMake((tesla_right_B->GetPosition().x*PTM_RATIO)-25.0, (tesla_right_B->GetPosition().y * PTM_RATIO)+(teslaSprite_R.contentSize.height));
        
        if (sparkVectorType==0)
        {
            initialVector = b2Vec2(2.8/PTM_RATIO, 2.8/PTM_RATIO);
        }
        else if (sparkVectorType == 1)
        {
            initialVector = b2Vec2(3.8/PTM_RATIO, 1.8/PTM_RATIO);
        }
        else
        {
            initialVector = b2Vec2(4.8/PTM_RATIO, 1.0/PTM_RATIO);
        }
        sparkVectorType++;
        if (sparkVectorType==3) sparkVectorType = 0;
        //NSLog(@"Going right: startPos %f, %f; targetPos: %f, %f; initialVector: %f, %f", startPos.x, startPos.y, targetPos.x, targetPos.y, initialVector.x, initialVector.y);
        
    }
    else // going left
    {
        startPos = CGPointMake((tesla_right_B->GetPosition().x*PTM_RATIO)-25.0, (tesla_right_B->GetPosition().y * PTM_RATIO)+(teslaSprite_R.contentSize.height));
        
        targetPos = CGPointMake((tesla_left_B->GetPosition().x*PTM_RATIO)+25.0, (tesla_left_B->GetPosition().y * PTM_RATIO)+(teslaSprite_L.contentSize.height));
        
        if (sparkVectorType==0)
        {
            initialVector = b2Vec2(-2.8/PTM_RATIO, 2.8/PTM_RATIO);
        }
        else if (sparkVectorType == 1)
        {
            initialVector = b2Vec2(-3.8/PTM_RATIO, 1.8/PTM_RATIO);
        }
        else
        {
            initialVector = b2Vec2(-4.8/PTM_RATIO, 1.0/PTM_RATIO);
        }
        sparkVectorType++;
        if (sparkVectorType==3) sparkVectorType = 0;
        //NSLog(@"Going left: startPos %f, %f; targetPos: %f, %f; initialVector: %f, %f", startPos.x, startPos.y, targetPos.x, targetPos.y, initialVector.x, initialVector.y);
    }
    
    if (teslaActive)
    {
        Spark *spark = (Spark*)[Spark sparkWithParentNode:self andWorld:_world andInitialVector:initialVector andInitialPosition:startPos andTargetPosition:targetPos];
        [sparks addObject:spark];
    }
}

// creates a temporary suction for all nearby e-beasts
-(void)createVortexAtPosition:(CGPoint)position
{
    for (Ebeast *beast in beasties)
    {
        CGPoint currentPos = beast.getBeastSprite.position;
        if (ccpDistance(position, currentPos)<300.0)
        {
            [beast applyForceTowards:position];
        }
    }

}

-(void)createShockwaveAtPosition:(CGPoint)position
{
    for (Ebeast *beast in beasties)
    {
        CGPoint currentPos = beast.getBeastSprite.position;
        if (ccpDistance(position, currentPos)<300.0)
        {
            [beast applyForceAwayFrom:position];
        }
    }
}

-(void)smokeAtPosition:(CGPoint)position
{
    CCParticleSystem *system = [CCParticleSystemQuad particleWithFile:@"sticky_death.plist"];
    system.position = position;
    system.autoRemoveOnFinish = YES;
    [self addChild:system z:1 tag:kSmokeTag];
}

-(void)beastExplosionAtPosition:(CGPoint)position
{
    CCParticleSystem *system = [CCParticleSystemQuad particleWithFile:@"byebyebeast.plist"];
    system.position = position;
    system.autoRemoveOnFinish = YES;
    [self addChild:system z:1 tag:kSmokeTag];
}

-(CCSpriteBatchNode*) getSpriteBatch
{
	return (CCSpriteBatchNode*)[self getChildByTag:kTagBatchNode];
}

#pragma mark - Game play control
-(void)fireForSide:(NSInteger)side
{
    Cannon* cannonOnSide = cannon_right;
    if (side==kLeft)
        cannonOnSide = cannon_left;
        
    b2RevoluteJoint *revJoint = (b2RevoluteJoint*)[cannonOnSide getRevoluteJoint];
    barrelAngle = revJoint->GetJointAngle();
    float force = 600.0;
    float conv = CC_DEGREES_TO_RADIANS(90.0);
    float y = (sinf(conv-barrelAngle)*force);
    
    float x = (sqrtf((force*force)-(y*y)));
    
    if (side==kRight)
        x = (sqrtf((force*force)-(y*y)))*-1;
    
    b2Vec2 vector = [self toMeters:CGPointMake(x, y)];
    float y_add = (cosf((CC_DEGREES_TO_RADIANS(180)-barrelAngle))*30.0)*-1;
    float x_add = (sqrtf((30.0*30.0)-(y_add*y_add)));
    
    CGPoint launchPosition;
    if (side==kRight)
    {
        launchPosition = CGPointMake((cannonOnSide.cannonBody->GetPosition().x*PTM_RATIO)-x_add, (cannonOnSide.cannonBody->GetPosition().y*PTM_RATIO)+y_add);
    }
    else {
        launchPosition = CGPointMake((cannonOnSide.cannonBody->GetPosition().x*PTM_RATIO)+x_add, (cannonOnSide.cannonBody->GetPosition().y*PTM_RATIO)+y_add);
    }
    if (weaponChoice == kStickyType)
    {
        Sticky *sticky = [Sticky stickyWithParentNode:self andWorld:_world andInitialVector:vector andInitialPosition:launchPosition];
        [stickies addObject:sticky];
    }
    else  
    {
        Bomb *bomb = (Bomb*)[Bomb bombWithParentNode:self andWorld:_world andInitialVector:vector andInitialPosition:launchPosition andType:weaponChoice];
        [bombs addObject:bomb];
    }
}

/*
-(void)openContainment
{
    [leftContainmentLid open];
    [rightContainmentLid open];
}
*/

// cycles back between stickies and bomb types
-(void)changeWeapon
{
    weaponChoice++;
    if (weaponChoice>3) weaponChoice = 1;
}

-(void)setStickyAsWeapon
{
    weaponChoice = kStickyType;
    
    // toggle other items
    [bomb_toggle setSelectedIndex:0];
    [suction_toggle setSelectedIndex:0];
}

-(void)setBombAsWeapon
{
    weaponChoice = kExplosiveBombType;
    [suction_toggle setSelectedIndex:0];
    [sticky_toggle setSelectedIndex:0];
}

-(void)setSuctionAsWeapon
{
    weaponChoice = kImplosiveBombType;
    [bomb_toggle setSelectedIndex:0];
    [sticky_toggle setSelectedIndex:0];
}

-(void)pauseGame
{
    if (!gamePaused)
    {
        _gamePausedLabel = [CCLabelTTF labelWithString:@"GAME PAUSED" fontName:@"Helvetica" fontSize:32];
        [self addChild:_gamePausedLabel];
#ifdef DEBUG_GPL
        NSLog(@"%f", ([self winSize].width/2)-(_gamePausedLabel.texture.contentSize.width/2));
#endif
        _gamePausedLabel.position = CGPointMake(([self winSize].width/2), [self winSize].height/2);
        
        _timeStep = 0.0;
        _velocityIterations = 0;
        _positionIterations = 0;
        
        gamePaused = !gamePaused;
    }
    else 
    {
        [self resumeGame];
    }
}

-(void)resumeGame
{
    gamePaused = !gamePaused;
    
    [self removeChild:_gamePausedLabel cleanup:YES];
    _timeStep = kTimeStep;
    _velocityIterations = kVelocityIterations;
    _positionIterations = kPositionIterations;
}

-(void)reloadGame
{
    [self reloadScene];
}

#pragma mark - Game feedback
-(void)showEnergyInformationMessageFor:(float)energyCaptured
{
    NSString *congratsMessage = [NSString stringWithFormat:@"You captured %f watts", energyCaptured];
    CCLabelTTF *congratulationsLabel = [CCLabelTTF labelWithString:congratsMessage fontName:@"Helvetica" fontSize:25];
    [self addChild:congratulationsLabel];
#ifdef DEBUG_GPL
    NSLog(@"%f", ([self winSize].width/2)-(congratulationsLabel.texture.contentSize.width/2));
#endif
    congratulationsLabel.position = CGPointMake(([self winSize].width/2), [self winSize].height/2);
    
    // energy information message
    NSString *energyInfoMessage = [NSString stringWithFormat:@"Your energy use was similar to %@", [ApplicanceUseData applianceUseMatchingEnergyCaptured:energyCaptured]];
    CCLabelTTF *informLabel = [CCLabelTTF labelWithString:energyInfoMessage fontName:@"Helvetica" fontSize:15];
    [self addChild:informLabel];
    
    informLabel.position = CGPointMake(([self winSize].width/2), [self winSize].height/2 + congratulationsLabel.contentSize.height + 10.0);
}

#pragma mark - Trajectory drawing and management
-(void)toggleTrajectoryDrawing
{
    // TODO: reimplement for cocos2d 2.0
    /*
    if (!drawProjectileTrajectory)
    {
        drawProjectileTrajectory = YES;
    }
    else {
        drawProjectileTrajectory = NO;
        projectileTrajectoryDrawn = NO;
        [self removeChild:trajectoryRibbon cleanup:YES];
    }*/
}

-(void)drawTrajectoryForSide:(NSInteger)side
{
    // TODO: redo for cocos2d 2.0
    
    /*
    if (drawProjectileTrajectory)
    {
        if (projectileTrajectoryDrawn)
        {
            // first remove any existing trajectory, since this could be called repeatedly in a short space of time
            [self removeChild:trajectoryRibbon cleanup:YES];
            projectileTrajectoryDrawn = NO;
        }
        
        projectileTrajectoryDrawn = YES;
        b2RevoluteJoint *revJoint = (b2RevoluteJoint*)[cannon_right getRevoluteJoint];
        if (side==kLeft)
            revJoint = (b2RevoluteJoint*)[cannon_left getRevoluteJoint];
        
        barrelAngle = revJoint->GetJointAngle();
        float force = 800.0;
        float conv = CC_DEGREES_TO_RADIANS(90.0);
        float y = (sinf(conv-barrelAngle)*force);
        float x = (sqrtf((force*force)-(y*y)))*-1;
        b2Vec2 vector = [self toMeters:CGPointMake(x, y)];
        float y_add = (cosf((CC_DEGREES_TO_RADIANS(180)-barrelAngle))*30.0)*-1;
        float x_add = (sqrtf((30.0*30.0)-(y_add*y_add)));

        CGPoint launchPosition = CGPointMake((cannon_right.cannonBody->GetPosition().x*PTM_RATIO)-x_add, (cannon_right.cannonBody->GetPosition().y*PTM_RATIO)+y_add);
        
        if (side==kLeft)
            launchPosition = CGPointMake((cannon_left.cannonBody->GetPosition().x*PTM_RATIO)+x_add, (cannon_left.cannonBody->GetPosition().y*PTM_RATIO)+y_add);
        
        [self drawTrajectoryWithStartingPosition:launchPosition andStartingVelocity:CGPointMake(x, y)];
    }*/
}

-(b2Vec2)getTrajectoryPointWithStartingPosition:(b2Vec2)startingPosition andStartingVelocity:(b2Vec2)startingVelocity andSteps:(float)steps
{
    // TODO: redo for cocos2d 2.0
    /*
    //velocity and gravity are given per second but we want time step values here
    float t = 1 / 60.0f; // seconds per time step (at 60fps)
    b2Vec2 stepVelocity = t * startingVelocity; // m/s
    b2Vec2 stepGravity = t * t * _world->GetGravity(); // m/s/s
    
    return startingPosition + steps * stepVelocity + 0.5f * (steps*steps+steps) * stepGravity;*/
}

-(void)drawTrajectoryWithStartingPosition:(CGPoint)startingPos andStartingVelocity:(CGPoint)startingVel
{
    // TODO: redo for cocos2d 2.0
    /*
    b2Vec2 startingPosition = b2Vec2(startingPos.x/PTM_RATIO, startingPos.y/PTM_RATIO);
    b2Vec2 startingVelocity = b2Vec2(startingVel.x/PTM_RATIO, startingVel.y/PTM_RATIO);
    
    ccColor4B myColor = ccc4(255, 255, 255, 150);
    
    // TODO: replace this, since CCRibbon deprecated in 2.0
    /*trajectoryRibbon = [CCRibbon ribbonWithWidth:5 image:@"traj_path_dot.png" length:5 color:myColor fade:0.7f];
    
    [self addChild:trajectoryRibbon z:8];
    
    for (int i = 0; i < 120; i++) { // 2 seconds at 60fps
        b2Vec2 trajectoryPosition = [self getTrajectoryPointWithStartingPosition:startingPosition andStartingVelocity:startingVelocity andSteps:i];
        [trajectoryRibbon addPointAt:ccp(trajectoryPosition.x*PTM_RATIO,trajectoryPosition.y*PTM_RATIO) width:5];
    }*/
}



#pragma mark - Touch management
- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
#ifdef DEBUG_GPL
    NSLog(@"touches began");
#endif
    //if (mouseJoint != nil) return;
    
    UITouch *myTouch = [touches anyObject];
    CGPoint location = [myTouch locationInView:[myTouch view]];
    location = [[CCDirector sharedDirector] convertToGL:location];
    
    if (CGRectContainsPoint(cannonControl_right.boundingBox, location))
    {
        // disable joint limits to allow movement
        b2RevoluteJoint *revJoint = (b2RevoluteJoint*)[cannon_right getRevoluteJoint];
        revJoint->EnableLimit(false);
        
        b2Vec2 locationWorld = b2Vec2(location.x/PTM_RATIO, location.y/PTM_RATIO);
        
        b2MouseJointDef md;
        md.bodyA = screenBorderBody_;
        md.bodyB = cannon_right.cannonBody;
        md.target = locationWorld;
        md.maxForce = 1000.0f * cannon_right.cannonBody->GetMass();
        
        mouseJoint_right = (b2MouseJoint *)_world->CreateJoint(&md);
        cannon_right.cannonBody->SetAwake(true);
    }
    if (CGRectContainsPoint(cannonControl_left.boundingBox, location))
    {
        // disable joint limits to allow movement
        b2RevoluteJoint *revJoint = (b2RevoluteJoint*)[cannon_left getRevoluteJoint];
        revJoint->EnableLimit(false);
        
        b2Vec2 locationWorld = b2Vec2(location.x/PTM_RATIO, location.y/PTM_RATIO);
        
        b2MouseJointDef md;
        md.bodyA = screenBorderBody_;
        md.bodyB = cannon_left.cannonBody;
        md.target = locationWorld;
        md.maxForce = 1000.0f * cannon_left.cannonBody->GetMass();
        
        mouseJoint_left = (b2MouseJoint *)_world->CreateJoint(&md);
        cannon_left.cannonBody->SetAwake(true);
    }
}

- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (mouseJoint_left == nil && mouseJoint_right == nil) return;
    
    UITouch *myTouch = [touches anyObject];
    CGPoint location = [myTouch locationInView:[myTouch view]];
    
    location = [[CCDirector sharedDirector] convertToGL:location];
    
    if (CGRectContainsPoint(cannonControl_left.boundingBox, location))
    {
        b2RevoluteJoint *revJoint = (b2RevoluteJoint*)[cannon_left getRevoluteJoint];
        barrelAngle = revJoint->GetJointAngle();
        float upper = kBarrelLowerAngleLimit_right*-1;
        float lower = kBarrelUpperAngleLimit_right*-1;
        
        revJoint->SetLimits(CC_DEGREES_TO_RADIANS(lower), CC_DEGREES_TO_RADIANS(upper));
        revJoint->EnableLimit(true);
        
        // set location.x to be a standard value
        if (location.x < 23.0 || location.x > 27.0)
            location.x = 25.0;
        
        b2Vec2 locationWorld = b2Vec2(location.x/PTM_RATIO, location.y/PTM_RATIO);
        
        mouseJoint_left->SetTarget(locationWorld);

        [self drawTrajectoryForSide:kLeft];
    }
    else if (CGRectContainsPoint(cannonControl_right.boundingBox, location))
    {
        b2RevoluteJoint *revJoint = (b2RevoluteJoint*)[cannon_right getRevoluteJoint];
        barrelAngle = revJoint->GetJointAngle();
        revJoint->SetLimits(CC_DEGREES_TO_RADIANS(kBarrelLowerAngleLimit_right), CC_DEGREES_TO_RADIANS(kBarrelUpperAngleLimit_right));
        revJoint->EnableLimit(true);
        
        // set location.y to be a standard value
        if (location.x > ([self winSize].width-27.0) || location.x < ([self winSize].width-23.0))
            location.x = [self winSize].width-25.0;
        
        b2Vec2 locationWorld = b2Vec2(location.x/PTM_RATIO, location.y/PTM_RATIO);
        
        mouseJoint_right->SetTarget(locationWorld);
        
        [self drawTrajectoryForSide:kLeft];
    }
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (mouseJoint_left != nil)
    {
        b2RevoluteJoint *revJoint = (b2RevoluteJoint*)[cannon_left getRevoluteJoint];
        barrelAngle = revJoint->GetJointAngle();
        //NSLog(@"barrelAngle = %f", CC_RADIANS_TO_DEGREES(barrelAngle));
        revJoint->SetLimits(barrelAngle, barrelAngle);
        revJoint->EnableLimit(true);
        _world->DestroyJoint(mouseJoint_left);
        mouseJoint_left = nil;
        [self fireForSide:kLeft];    
    }
    else if (mouseJoint_right != nil)
    {
        b2RevoluteJoint *revJoint = (b2RevoluteJoint*)[cannon_right getRevoluteJoint];
        barrelAngle = revJoint->GetJointAngle();
        //NSLog(@"barrelAngle = %f", CC_RADIANS_TO_DEGREES(barrelAngle));
        revJoint->SetLimits(barrelAngle, barrelAngle);
        revJoint->EnableLimit(true);
        _world->DestroyJoint(mouseJoint_right);
        mouseJoint_right = nil;
        [self fireForSide:kRight];    
    }
    else {
        UITouch *myTouch = [touches anyObject];
        CGPoint location = [myTouch locationInView:[myTouch view]];
        location = [[CCDirector sharedDirector] convertToGL:location];
        
        #ifdef DEBUG_GPL
        NSLog(@"Mouse click at %f, %f", location.x, location.y);
#endif
    }
}

#pragma mark - Testing
-(void)addTestSprite
{
    CCSprite *pea = [CCSprite spriteWithFile:@"testBody.png"];
    pea.position = ccp(100, 100);
    pea.tag = 100;
    [self addChild:pea];
    
    // Create ball body 
    b2BodyDef peaBodyDef;
    peaBodyDef.type = b2_dynamicBody;
    peaBodyDef.position.Set(100/PTM_RATIO, 100/PTM_RATIO);
    peaBodyDef.userData = pea;
    b2Body * peaBody = _world->CreateBody(&peaBodyDef);
    
    // Create circle shape
    b2CircleShape circle;
    circle.m_radius = 14.5/PTM_RATIO;
    
    // Create shape definition and add to body
    b2FixtureDef peaShapeDef;
    peaShapeDef.shape = &circle;
    peaShapeDef.density = 0.3f;
    peaShapeDef.friction = 0.5f;
    peaShapeDef.restitution = 0.4f;
    
    peaBody->CreateFixture(&peaShapeDef);
    
    b2Vec2 force = b2Vec2(10, 20);
    peaBody->SetLinearDamping(0.5f);
    peaBody->ApplyLinearImpulse(force, peaBodyDef.position);
}

#pragma mark - Utilities
-(b2Vec2)toMeters:(CGPoint)point
{
    return b2Vec2(point.x / PTM_RATIO, point.y / PTM_RATIO);
}

-(CGPoint)toPixels:(b2Vec2)vec
{
    return ccpMult(CGPointMake(vec.x, vec.y), PTM_RATIO);
}

-(CGSize)winSize
{
    return [[CCDirector sharedDirector] winSize];
}

#ifdef DEBUG
-(void) draw
{
	//
	// IMPORTANT:
	// This is only for debug purposes
	// It is recommend to disable it
	//
	[super draw];
	
	ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );
	
	kmGLPushMatrix();
	
	_world->DrawDebugData();
	
	kmGLPopMatrix();
}
#endif
-(void)dealloc
{
    delete _world;
    screenBorderBody_ = NULL;
    delete contactListener;
    
    
    [super dealloc];
}

@end
