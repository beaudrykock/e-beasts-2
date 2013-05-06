//
//  GameIntroViewController.m
//  e-beasts
//
//  Created by Beaudry Kock on 8/15/12.
//  Copyright (c) 2012 University of Oxford. All rights reserved.
//

#import "GameIntroViewController.h"

@implementation GameIntroViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)init
{
    self = [super initWithNibName:@"GameIntroViewController" bundle:nil];
    if (self != nil)
    {
        // Further initialization if needed
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(IBAction)selectOption:(id)sender
{
    UIButton *button = (UIButton*)sender;
    
    [self.delegate gameIntroView:self.view didFinishWithOption:button.tag];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
