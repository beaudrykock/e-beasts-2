//
//  CoreDataManager.m
//  e-beasts
//
//  Created by Beaudry Kock on 8/16/12.
//  Copyright (c) 2012 University of Oxford. All rights reserved.
//

#import "EnergyDataManager.h"

@implementation EnergyDataManager

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

-(void)setupForOption:(NSInteger)option
{
    
    if (option==0)
    {
        NSString *jsonString = @"{\"@accountId\":\"aid_kc\",\"@toDate\":\"2012-10-10T12:41:13.000+00:00\",\"@fromDate\":\"2012-10-09T12:41:13.000+00:00\",\"cost\":\"3.84\",\"consumption\":35.50318,\"conversionFactorList\":{\"conversionFactor\":[{\"unitName\":\"lbs of CO2\",\"factor\":1.29300}]},\"componentList\":{\"component\":[{\"@actualReadingsCount\":96,\"@toDate\":\"2012-10-10T12:41:13.000+00:00\",\"@fromDate\":\"2012-10-09T12:41:13.000+00:00\",\"cost\":\"3.84\",\"consumption\":35.50318,\"componentList\":{\"component\":[{\"@peak\":false,\"@rateKey\":\"A\",\"cost\":\"1.30\",\"consumption\":16.30818},{\"@peak\":true,\"@rateKey\":\"B\",\"cost\":\"0.91\",\"consumption\":8.31600},{\"@peak\":true,\"@rateKey\":\"C\",\"cost\":\"1.63\",\"consumption\":10.87900}]}}]}}";
        NSDictionary *jsonValue = [jsonString JSONValue];
        [self newConsumptionRecordWithDictionary:jsonValue];
        
        NSString *jsonStringProjected = @"{\"@accountId\":\"callme_mrcool\",\"@toDate\":\"2012-10-14T06:00:00.000+00:00\",\"@fromDate\":\"2012-10-07T06:00:00.000+00:00\",\"cost\":\"31.44\",\"consumption\":261.93022}";
        NSDictionary *jsonValueProj = [jsonStringProjected JSONValue];
        [self newConsumptionProjectionRecordWithDictionary:jsonValueProj];
        
        [self initializeEnergyAccount];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CANNED_SUCCESS object:nil];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateConsumptionData) name:@"authorization complete" object:nil];
        self.tendrilConnect = [[BKTendrilConnect alloc] init];
        [self.tendrilConnect setDelegate:self];
        [self.tendrilConnect authorize];
    }
}

-(void)updateConsumptionData
{
#ifdef DEBUG_EDM
    NSLog(@"Updating consumption data");
#endif
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSDate *date = [NSDate date];
    end = [date timeIntervalSince1970];
    start = [Utilities secondsAtLastLaunch];
    
    // make sure seconds at launch is tracked, so that consumption between now
    // and previous launch can be calculated NEXT time round
    [Utilities setSecondsAtLaunch: end];
    
    [self.tendrilConnect getConsumptionDataFrom:start to:end];
    [self.tendrilConnect getProjectedConsumptionDataAtResolution:kWeekly];
}


-(BOOL)isAuthorized
{
    return self.tendrilConnect.authorized;
}

-(NSInteger)getPreviousConsumptionInSprites
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"EnergyUse" inManagedObjectContext:[self managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    
    // return only past consumption data, sorted to have most recently added entry first
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isProjected='NO'"];
    [fetchRequest setPredicate:predicate];
    NSSortDescriptor *dateSort = [[NSSortDescriptor alloc] initWithKey:@"queriedDate" ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:dateSort]];
    [fetchRequest setFetchLimit:1];
    
    NSArray *fetchedObjects = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
    
    NSNumber *consumption = nil;
    for (EnergyUse *energyUse in fetchedObjects) {
        consumption = [energyUse valueForKey:@"consumption"];
    }
    // TODO: uncomment when not testing
    //return rint([consumption floatValue]/kEnergyPerSprite);
    return 1;
}

-(EnergyUse*) getActualEnergyUseObjectForSessionID:(NSInteger)sessionID
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"EnergyUse" inManagedObjectContext:[self managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    
    // return only past consumption data, sorted to have most recently added entry first
    NSString *predicateStr = [NSString stringWithFormat:@"isProjected='NO' AND sessionID = '%i'",sessionID];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateStr];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setFetchLimit:1];
    
    NSArray *fetchedObjects = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
    
    return [fetchedObjects objectAtIndex:0];
}

-(EnergyUse*)getProjectedEnergyUseObjectForSessionID:(NSInteger)sessionID
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"EnergyUse" inManagedObjectContext:[self managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    
    // return only past consumption data, sorted to have most recently added entry first
    NSString *predicateStr = [NSString stringWithFormat:@"isProjected='YES' AND sessionID = '%i'",sessionID];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateStr];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setFetchLimit:1];
    
    NSArray *fetchedObjects = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
    
    return [fetchedObjects objectAtIndex:0];
}

-(NSArray*)getTimePeriodOfProjectedEnergyUseForSessionID:(NSInteger)sessionID
{
    EnergyUse *energyUse = [self getProjectedEnergyUseObjectForSessionID:sessionID];
    
    return [NSArray arrayWithObjects:energyUse.startSeconds, energyUse.endSeconds, nil];
}

-(float)getProjectedEnergyUseForSessionID:(NSInteger)sessionID
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"EnergyUse" inManagedObjectContext:[self managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    
    // return only past consumption data, sorted to have most recently added entry first
    NSString *predicateStr = [NSString stringWithFormat:@"isProjected='YES' AND sessionID = '%i'",sessionID];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateStr];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setFetchLimit:1];
    
    NSArray *fetchedObjects = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
    
    NSNumber *consumption = nil;
    for (EnergyUse *energyUse in fetchedObjects) {
        consumption = [energyUse valueForKey:@"consumption"];
    }
    
    return [consumption floatValue];
}

-(NSInteger)getProjectedConsumptionInSprites
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"EnergyUse" inManagedObjectContext:[self managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    
    // return only past consumption data, sorted to have most recently added entry first
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isProjected='YES'"];
    [fetchRequest setPredicate:predicate];
    NSSortDescriptor *dateSort = [[NSSortDescriptor alloc] initWithKey:@"queriedDate" ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:dateSort]];
    [fetchRequest setFetchLimit:1];
    
    NSArray *fetchedObjects = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
    
    NSNumber *consumption = nil;
    for (EnergyUse *energyUse in fetchedObjects) {
        consumption = [energyUse valueForKey:@"consumption"];
    }
    
    // TODO: uncomment when not testing
    //return rint([consumption floatValue]/kEnergyPerSprite);
    
    return 0;
}

// call once in setup
-(void)initializeEnergyAccount
{
    self.energyAccount = 0.0;
}

-(void)recordEnergyCapture:(float)energyCaptured
{
#ifdef DEBUG_EDM
    NSLog(@"Adding new capture record");
#endif
    
    NSManagedObjectContext *context = [self managedObjectContext];
    
    EnergyCapture *energyCapture = [NSEntityDescription insertNewObjectForEntityForName:@"EnergyCapture" inManagedObjectContext:context];
    
    energyCapture.energyCaptured = [NSNumber numberWithFloat:energyCaptured];
    energyCapture.dateCaptured = [NSDate date];
    energyCapture.sessionID = [NSNumber numberWithInt:[[SessionManager sharedSessionManager] sessionID]];
    
    NSLog(@"Logging energycapture with value %f, date %@ and session ID %i", [energyCapture.energyCaptured floatValue], energyCapture.dateCaptured.description, energyCapture.sessionID.intValue);
    
    NSError *error;
    if (![context save:&error]) {
        GTMLoggerDebug(@"failed to save with error = %@", [error description]);
    }
    
#ifdef DEBUG_EDM
    [self printCaptureRecords];
#endif
    
    self.energyAccount += (energyCaptured);
    
    if ([self getEnergyAccountLevel] > 0.5)
    {
        float energy = (([self getEnergyAccountLevel]-0.5)*2.0)*([self getProjectedConsumptionInSprites]*kEnergyPerSprite);
        [self bankEnergy: energy];
    }
}

-(void)bankEnergy:(float)energyToBank
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"EnergyBank" inManagedObjectContext:[self managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    
    NSArray *fetchedObjects = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
    
    if ([fetchedObjects count]==0)
    {
        EnergyBank *bank = [NSEntityDescription insertNewObjectForEntityForName:@"EnergyBank" inManagedObjectContext:[self managedObjectContext]];
        if (![[self managedObjectContext] save:&error]) {
            GTMLoggerDebug(@"EnergyDataManager: failed to save with error = %@", [error localizedDescription]);
        }
        
        [bank setSavingsAccount:[NSNumber numberWithFloat:energyToBank]];
        
        if (![[self managedObjectContext] save:&error]) {
            GTMLoggerDebug(@"EnergyDataManager: failed to save with error = %@", [error localizedDescription]);
        }
    }
    else
    {
        EnergyBank *bank = [fetchedObjects objectAtIndex:0];
        
        float oldValue = [bank.savingsAccount floatValue];
        
        oldValue += energyToBank;
        
        [bank setSavingsAccount:[NSNumber numberWithFloat:oldValue]];
        
        if (![[self managedObjectContext] save:&error]) {
            GTMLoggerDebug(@"EnergyDataManager: failed to save with error = %@", [error localizedDescription]);
        }
    }
}

-(float)getBankedEnergy
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"EnergyBank" inManagedObjectContext:[self managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    
    NSArray *fetchedObjects = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
    
    EnergyBank *bank = [fetchedObjects objectAtIndex:0];
    
    return [bank.savingsAccount floatValue];
}

-(void)newConsumptionRecordWithDictionary:(NSDictionary*)dictionary
{
#ifdef DEBUG_EDM
    NSLog(@"Adding new consumption record");
#endif
    for (NSString *key in [dictionary allKeys])
    {
        NSLog(@"Object for key %@ = %@", key, [dictionary objectForKey:key]);
    }
    
    NSString *consumptionStr = (NSString*)[dictionary objectForKey:@"consumption"];
    NSNumber* consumption = [NSNumber numberWithInteger:[consumptionStr integerValue]];
    
    NSString *costStr = (NSString*)[dictionary objectForKey:@"cost"];
    NSDecimalNumber* cost = [NSDecimalNumber decimalNumberWithString:costStr];
    
    NSManagedObjectContext *context = [self managedObjectContext];
    
    EnergyUse *energyUse = [NSEntityDescription insertNewObjectForEntityForName:@"EnergyUse" inManagedObjectContext:context];
    [energyUse setSessionID:[NSNumber numberWithInt:[[SessionManager sharedSessionManager] sessionID]]];
    
    [energyUse setValue:[NSDate date] forKey: @"queriedDate"];
    [energyUse setValue:[NSNumber numberWithBool:NO] forKey:@"isProjected"];
    [energyUse setValue:cost forKey:@"cost"];
    [energyUse setValue:consumption forKey:@"consumption"];
    
    NSNumber *fromSecs = [NSNumber numberWithLongLong:start];
    NSNumber *toSecs = [NSNumber numberWithLongLong:end];
    
    [energyUse setValue:fromSecs forKey:@"startSeconds"];
    [energyUse setValue:toSecs forKey:@"endSeconds"];
    
    NSError *error;
    if (![context save:&error]) {
        GTMLoggerDebug(@"EnergyDataManager: failed to save with error = %@", [error localizedDescription]);
    }
    
#ifdef DEBUG_EDM
    [self printConsumptionRecords];
#endif
}

-(void)newConsumptionProjectionRecordWithDictionary:(NSDictionary*)dictionary
{
#ifdef DEBUG_EDM
    NSLog(@"Adding new consumption projection record");
#endif
    for (NSString *key in [dictionary allKeys])
    {
        NSLog(@"Object for key %@ = %@", key, [dictionary objectForKey:key]);
    }
    
    NSManagedObjectContext *context = [self managedObjectContext];
    
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    EnergyUse *energyUse = [NSEntityDescription insertNewObjectForEntityForName:@"EnergyUse" inManagedObjectContext:context];
    
    [energyUse setSessionID:[NSNumber numberWithInt:[appDelegate sessionID]]];
    [energyUse setValue:[NSDate date] forKey: @"queriedDate"];
    [energyUse setValue:[NSNumber numberWithBool:YES] forKey:@"isProjected"];
    
    NSNumber *fromSecs = [NSNumber numberWithLongLong:[self getTimeIntervalFromTendrilDate:[dictionary objectForKey:@"fromDate"]]];
    NSNumber *toSecs = [NSNumber numberWithLongLong:[self getTimeIntervalFromTendrilDate:[dictionary objectForKey:@"toDate"]]];
    // take share of the projected cost and consumption proportional to the start-end value from
    // the past consumption data, so that the projection is over the same period as the past consumption
    NSTimeInterval diff_past = end-start;
    NSTimeInterval diff_proj = [toSecs longLongValue]-[fromSecs longLongValue];
    float frac = diff_past/diff_proj;
    
    [energyUse setValue:[NSNumber numberWithLongLong:start] forKey:@"startSeconds"];
    [energyUse setValue:[NSNumber numberWithLongLong:end] forKey:@"endSeconds"];
    
    NSString *consumptionStr = (NSString*)[dictionary objectForKey:@"consumption"];
    NSNumber* consumption = [NSNumber numberWithInteger:([consumptionStr floatValue]*frac)];
    
    NSString *costStr = (NSString*)[dictionary objectForKey:@"cost"];
    float costFl = [costStr floatValue];
    costFl *= frac;
    NSNumber *costNbr = [NSNumber numberWithFloat:costFl];
    NSDecimalNumber* cost = [NSDecimalNumber decimalNumberWithString:[costNbr stringValue]];
    
    [energyUse setValue:cost forKey:@"cost"];
    [energyUse setValue:consumption forKey:@"consumption"];
    
    
    NSError *error;
    if (![context save:&error]) {
        GTMLoggerDebug(@"EnergyDataManager: failed to save with error = %@", [error localizedDescription]);
    }
    
#ifdef DEBUG_EDM
    [self printConsumptionRecords];
#endif
}

/*
 * determines whether the promised energy use reductions matched real world reductions
 * over the originally promised period
 */
-(void)confirmRealWorldReductions
{
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    NSInteger previousSessionID = [[appDelegate sessionID] integerValue]-1;
    
    // only take action if this is >1st session
    if (previousSessionID>0)
    {
        // get originally projected energy use for previous session
        float originalProjectedUse = [self getProjectedEnergyUseForSessionID:previousSessionID];
        
        NSArray *timePeriod_OPU = [self getTimePeriodOfProjectedEnergyUseForSessionID:previousSessionID];
        float startSecs_OPU = [[timePeriod_OPU objectAtIndex:0] floatValue];
        float endSecs_OPU = [[timePeriod_OPU objectAtIndex:0] floatValue];
        
        float energyPromised = [self getBankedEnergy];
        
        NSTimeInterval secondsSinceLastPlay = end-start;
        
        float actualEnergyUse = [[[self getActualEnergyUseObjectForSessionID:[[appDelegate sessionID] integerValue]] consumption] integerValue];
        
        float frac = (endSecs_OPU-startSecs_OPU)/secondsSinceLastPlay;
        
        float actualUseOverProjectedPeriod = actualEnergyUse*frac;
        
        if ((originalProjectedUse-actualUseOverProjectedPeriod) >= energyPromised)
        {
            [self updateScoreType: kDemandResponseScoreType withValue: kScoreBoost_1];
        }
    }
}

#pragma mark - Score management
-(void)updateScoreType: (NSInteger)scoreType withValue: (float)value
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"ScoreTracker" inManagedObjectContext:[self managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    
    NSArray *fetchedObjects = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
    
    if ([fetchedObjects count] == 0)
    {
        ScoreTracker *scoreTracker = [NSEntityDescription insertNewObjectForEntityForName:@"ScoreTracker" inManagedObjectContext:[self managedObjectContext]];
        if (![[self managedObjectContext] save:&error]) {
            GTMLoggerDebug(@"EnergyDataManager: failed to save with error = %@", [error localizedDescription]);
        }
        
        [scoreTracker setDemandResponseScore:[NSNumber numberWithFloat:value]];
        
        if (![[self managedObjectContext] save:&error]) {
            GTMLoggerDebug(@"EnergyDataManager: failed to save with error = %@", [error localizedDescription]);
        }
    }
    else
    {
        ScoreTracker *scoreTracker = [fetchedObjects objectAtIndex:0];
        
        float oldScore = scoreTracker.demandResponseScore.floatValue;
        oldScore += value;
        
        [scoreTracker setDemandResponseScore:[NSNumber numberWithFloat:oldScore]];
        
        if (![[self managedObjectContext] save:&error]) {
            GTMLoggerDebug(@"EnergyDataManager: failed to save with error = %@", [error localizedDescription]);
        }
    }
}

// converts date in Tendril preferred format, e.g. 2011-07-01T00:00:00-0000 to time interval
-(NSTimeInterval)getTimeIntervalFromTendrilDate:(NSString*)tendrilDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'hh:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    NSDate *dateFromString = [dateFormatter dateFromString:tendrilDate];
    
    NSTimeInterval interval = [dateFromString timeIntervalSince1970];
    
#ifdef BKDEBUG_VERBOSE
    NSLog(@"BKTendrilConnect: time interval from tendril date %@ = %f", tendrilDate,interval);
#endif
    return interval;
}

-(float)getEnergyCapacityForSession
{
    return ([self getProjectedConsumptionInSprites]*kEnergyPerSprite)+([self getPreviousConsumptionInSprites]*kEnergyPerSprite);
}

-(float)getEnergyAccountLevel
{
    return self.energyAccount / [self getEnergyCapacityForSession];
}

-(void)printConsumptionRecords
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"EnergyUse" inManagedObjectContext:[self managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    
    NSArray *fetchedObjects = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
    
    for (EnergyUse *energyUse in fetchedObjects) {
        NSLog(@"Energy use object in core data...");
        NSLog(@"Start seconds: %@", [energyUse valueForKey:@"startSeconds"]);
        NSLog(@"End seconds: %@", [energyUse valueForKey:@"endSeconds"]);
        NSLog(@"Consumption: %@", [energyUse valueForKey:@"consumption"]);
        NSLog(@"Cost: %@", [energyUse valueForKey:@"cost"]);
    }

}

-(void)printCaptureRecords
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"EnergyCapture" inManagedObjectContext:[self managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    
    NSArray *fetchedObjects = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
    
    for (EnergyCapture *energyCapture in fetchedObjects) {
        NSLog(@"Energy capture object in core data...");
        NSLog(@"Captured date: %@", [[energyCapture dateCaptured] description]);
        NSLog(@"Energy captured: %f", [[energyCapture energyCaptured] floatValue]);
        NSLog(@"Session ID: %i", [[energyCapture sessionID] intValue]);
    }
    
}

#pragma mark - BKTendrilConnect delegate methods
-(void)tendrilConnectDidReturnData:(NSDictionary*)jsonDict forConnectionType:(NSInteger)connectionType
{
    // consume your data here...
    // connectionType (referenced in SharedConstants) can be used to determine what kind of data should be expected
    if (connectionType == kConsumption)
    {
        [self newConsumptionRecordWithDictionary:jsonDict];
        [self initializeEnergyAccount];
        [[NSNotificationCenter defaultCenter] postNotificationName:TENDRIL_SUCCESS object:nil];
    }
    else if (connectionType == kConsumptionProjection)
    {
        [self newConsumptionProjectionRecordWithDictionary:jsonDict];
        [[NSNotificationCenter defaultCenter] postNotificationName:TENDRIL_SUCCESS object:nil];
    }
}

-(void)tendrilConnectDidFail
{
    [[NSNotificationCenter defaultCenter] postNotificationName:TENDRIL_FAILURE object:nil];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"e-beasts-2" withExtension:@"mom"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"e-beasts-2"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
