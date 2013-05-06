//
//  CoreDataManager.h
//  e-beasts
//
//  Created by Beaudry Kock on 8/16/12.
//  Copyright (c) 2012 University of Oxford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SharedConstants.h"
#import "BKTendrilConnect.h"
#import "EnergyUse.h"
#import "EnergyCapture.h"
#import "EnergyBank.h"
#import "JSON.h"
#import "ScoreTracker.h"
#import "SessionManager.h"
@class AppDelegate;

@interface EnergyDataManager : NSObject <BKTendrilConnectDelegateProtocol>
{
    NSTimeInterval start;
    NSTimeInterval end;
}
@property (nonatomic) float energyAccount;
@property (readonly, nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (readonly, nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (readonly, nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) BKTendrilConnect *tendrilConnect;

-(void)setupForOption:(NSInteger)option;
- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
-(NSInteger)getPreviousConsumptionInSprites;
-(NSInteger)getProjectedConsumptionInSprites;
-(BOOL)isAuthorized;
-(void)recordEnergyCapture:(float)energyCaptured;
-(void)printCaptureRecords;
-(float)getEnergyCapacityForSession;
-(float)getEnergyAccountLevel;
-(float)getBankedEnergy;

@end
