//
//  ScoreTracker.h
//  e-beasts-2
//
//  Created by Beaudry Kock on 10/12/12.
//  Copyright (c) 2012 Beaudry Kock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ScoreTracker : NSManagedObject

@property (nonatomic, retain) NSNumber * demandResponseScore;

@end
