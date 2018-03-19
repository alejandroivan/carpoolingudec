//
//  DriversShowRouteViewController.m
//  carpoolingudec
//
//  Created by Alejandro Melo Domínguez on 19-03-18.
//  Copyright © 2018 Alejandro Melo Domínguez. All rights reserved.
//

#import "DriversShowRouteViewController.h"
#import "LocationManager.h"
@import GoogleMaps;




@interface DriversShowRouteViewController ()
@property (weak, nonatomic) IBOutlet GMSMapView *mapView;

@end




@implementation DriversShowRouteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    __weak LocationManager *lm = [LocationManager sharedManager];
    LOG(@"Location for University: %@", lm.locationForUniversity);
    LOG(@"Location for Home: %@", lm.locationForHome);
    
    [LocationManager getDirectionsByCarWithOrigin:lm.locationForHome
                                      destination:lm.locationForUniversity
                                completionHandler:^(BOOL success, NSDictionary *directions) {
                                    LOG(@"DIRECTIONS: %@", directions);
                                }];
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

@end
