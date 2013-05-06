//
//  EnergyCapture.h
//  e-beasts-2
//
//  Created by Beaudry Kock on 10/23/12.
//  Copyright (c) 2012 Beaudry Kock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface EnergyCapture : NSManagedObject

@property (nonatomic, retain) NSDate * dateCaptured;
@property (nonatomic, retain) NSNumber * energyCaptured;
@property (nonatomic, retain) NSNumber * sessionID;

@end
