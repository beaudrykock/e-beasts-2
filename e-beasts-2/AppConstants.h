//
//  AppConstants.h
//  e-beasts
//
//  Created by Beaudry Kock on 7/5/12.
//  Copyright (c) 2012 University of Oxford. All rights reserved.
//

// debugging
#define DEBUG_EDM 1

#define kTimeStep 0.03f
#define kVelocityIterations 8
#define kPositionIterations 1
#define PTM_RATIO 32.0

// world properties
#define kNumberOfBeasts 1
#define kTolerance 5.0

// e-beast flight dynamics
#define kCircularPath 1
#define kHoppingPath 2
#define kFigureEightPath 3
#define kMaxFlightLevel 9
#define kNumberOfFlightLevels 10
#define kClimbing 0
#define kDescending 1
#define kLevelFlight 2
#define kLeft 0
#define kRight 1
#define kMaxStepsBeforeDirectionChange 10
#define kMinStepsBeforeDirectionChange 5
#define kMinUnitForce_x 2
#define kMinUnitForce_y 2
#define kMaxUnitForce_x 5
#define kMaxUnitForce_y 5

// weapons
#define kStickyType 1
#define kExplosiveBombType 2
#define kImplosiveBombType 3


// cannon
#define kBarrelUpperAngleLimit_right 135.0
#define kBarrelLowerAngleLimit_right 45.0

// sprite types
#define kEbeastTag 4
#define kStickyTag 5
#define kCannonTag 6
#define kBombTag 7
#define kShrapnelTag 8
#define kContainmentLidTag 9
#define kSparkTag 10

// particle swarms
#define kExplosionTag 10
#define kSmokeTag 11
#define kSparkShowerTag 12

// Cartesian
#define kAxis_x 0
#define kAxis_y 1

// TENDRIL
#define CANNED_SUCCESS @"canned data loaded"
#define TENDRIL_SUCCESS @"tendril success"
#define TENDRIL_FAILURE @"tendril failure"
#define kEnergyPerSprite 10.0
//

// CONTROL TAGS
#define kEnergyIndicatorTag 1

// SCORING
#define kDemandResponseScoreType 0

#define kScoreBoost_1 100.0
#define kScoreBoost_2 200.0
#define kScoreBoost_3 300.0