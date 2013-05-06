//
//  b2bodyWrapper.m
//  e-beasts
//
//  Created by Beaudry Kock on 7/9/12.
//  Copyright (c) 2012 University of Oxford. All rights reserved.
//

#import "b2bodyWrapper.h"

@implementation b2bodyWrapper
@synthesize body;

-(int)getUID
{
    return UID;
}

-(void)setUID:(int)_UID
{
    UID = _UID;
}

-(int)getTag
{
    return tag;
}

-(void)setTag:(int)_tag
{
    tag = _tag;
}



@end
