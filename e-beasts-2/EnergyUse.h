//
//  EnergyUse.h
//  e-beasts-2
//
//  Created by Beaudry Kock on 10/11/12.
//  Copyright (c) 2012 Beaudry Kock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface EnergyUse : NSManagedObject

@property (nonatomic, retain) NSNumber * consumption;
@property (nonatomic, retain) NSNumber * cost;
@property (nonatomic, retain) NSNumber * endSeconds;
@property (nonatomic, retain) NSNumber * isProjected;
@property (nonatomic, retain) NSDate * queriedDate;
@property (nonatomic, retain) NSNumber * startSeconds;
@property (nonatomic, retain) NSNumber * sessionID;

@end
