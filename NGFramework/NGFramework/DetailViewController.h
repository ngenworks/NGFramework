//
//  DetailViewController.h
//  NGFramework
//
//  Created by Kyle Turner on 9/24/14.
//  Copyright (c) 2014 nGen Works. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

