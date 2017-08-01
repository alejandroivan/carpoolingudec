//
//  LeftMenuItemViewController.m
//  carpoolingudec
//
//  Created by Alejandro Melo Domínguez on 31-07-17.
//  Copyright © 2017 Alejandro Melo Domínguez. All rights reserved.
//

#import "LeftMenuItemViewController.h"



static NSString *kLeftMenuItemImageName = @"ic_menu_white_36pt";












@interface LeftMenuItemViewController ()

@end












@implementation LeftMenuItemViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.leftMenuItem                       = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:kLeftMenuItemImageName]
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:self
                                                                              action:@selector(toggleSideMenu:)];
    self.navigationItem.leftBarButtonItem   = self.leftMenuItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */


- (IBAction)toggleSideMenu:(id)sender {
    LOG(@"Toggle side menu!");
    TOGGLE_SIDEMENU_LEFT();
}

@end
