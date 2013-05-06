//
//  GameIntroViewController.h
//  e-beasts
//
//  Created by Beaudry Kock on 8/15/12.
//  Copyright (c) 2012 University of Oxford. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GameIntroViewControllerDelegateProtocol <NSObject>
-(void)gameIntroView:(UIView*)view didFinishWithOption:(NSInteger)option;
@end

@interface GameIntroViewController : UIViewController
{
    id delegate;
}

@property (nonatomic, assign) id <GameIntroViewControllerDelegateProtocol> delegate;

@end
