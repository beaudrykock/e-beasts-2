//
//  ApplicanceUseData.m
//  e-beasts-2
//
//  Created by Beaudry Kock on 10/10/12.
//  Copyright (c) 2012 Beaudry Kock. All rights reserved.
//

#import "ApplicanceUseData.h"

@implementation ApplicanceUseData

// all amounts in total kW
+(NSString*)applianceUseMatchingEnergyCaptured:(float)energyCaptured
{
    if (energyCaptured<0.003)
    {
        return @"toasting a slice of bread";
    }
    else if (energyCaptured<0.09)
    {
        return @"using your computer for an hour";
    }
    else if (energyCaptured<0.15)
    {
        return @"running your stereo for an hour";
    }
    else if (energyCaptured<0.25)
    {
        return @"running a load of laundry";
    }
    else if (energyCaptured<1.2)
    {
        return @"running your A/C for an hour";
    }
    else if (energyCaptured<1.5)
    {
        return @"using a space heater for an hour";
    }
    else if (energyCaptured<2.0)
    {
        return @"making a cup of coffee";
    }
    else if (energyCaptured<2.7)
    {
        return @"drying a load of laundry";
    }
    else if (energyCaptured<3.0)
    {
        return @"watching TV for an hour";
    }
    else if (energyCaptured<3.2)
    {
        return @"baking in the oven for an hour";
    }
    else if (energyCaptured<3.75)
    {
        return @"using a microwave oven for 5 minutes";
    }
    else if (energyCaptured<13)
    {
        return @"running a dehumidifier for a day";
    }
    else if (energyCaptured<63)
    {
        return @"what your fridge uses in a month";
    }
    else if (energyCaptured<183)
    {
        return @"what your freezer uses in a month";
    }
    return @"NO_DATA";
}

@end
