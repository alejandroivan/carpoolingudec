//
//  ActivityIndicatorViewController.m
//  carpoolingudec
//
//  Created by Alejandro Melo Domínguez on 31-07-17.
//  Copyright © 2017 Alejandro Melo Domínguez. All rights reserved.
//

#import "ActivityIndicatorViewController.h"

@interface ActivityIndicatorViewController ()
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@end


static const CGFloat activityIndicatorSize = 64.0f;


@implementation ActivityIndicatorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.activityIndicator                      = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activityIndicator.backgroundColor      = [[UIColor blackColor] colorWithAlphaComponent:0.6f];
    self.activityIndicator.clipsToBounds        = YES;
    self.activityIndicator.layer.cornerRadius   = 4.0f;
    self.activityIndicator.hidesWhenStopped     = YES;
    
    [self.view addSubview:self.activityIndicator];
    [self.view bringSubviewToFront:self.activityIndicator];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.activityIndicator.frame = CGRectMake(
                                              CGRectGetMidX(self.view.bounds) - activityIndicatorSize/2.0f,
                                              CGRectGetMidY(self.view.bounds) - activityIndicatorSize/2.0f,
                                              activityIndicatorSize,
                                              activityIndicatorSize
                                              );
    
}

- (void)showIndicator {
    [GET_APPDELEGATE() runBlockOnMainQueue:^{
        [self.view setUserInteractionEnabled:NO];
        [self.activityIndicator startAnimating];
    }];
}

- (void)hideIndicator {
    [GET_APPDELEGATE() runBlockOnMainQueue:^{
        [self.view setUserInteractionEnabled:YES];
        [self.activityIndicator stopAnimating];
    }];
}


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
@end
