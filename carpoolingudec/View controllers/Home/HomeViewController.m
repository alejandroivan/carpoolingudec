//
//  HomeViewController.m
//  carpoolingudec
//
//  Created by Alejandro Melo Domínguez on 30-07-17.
//  Copyright © 2017 Alejandro Melo Domínguez. All rights reserved.
//

#import "HomeViewController.h"
@import GoogleMaps;












@interface HomeViewController ()
@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@end












@implementation HomeViewController {
    BOOL _didCenterMapOverMyLocationWhenViewDidLoad;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.mapView.myLocationEnabled  = YES;
    
    // Suscribirse a las notificaciones globales de cambio de ubicación
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didUpdateToNewLocation:)
                                                 name:@"LOCATION_UPDATE"
                                               object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/











#pragma mark - Location
- (void)didUpdateToNewLocation:(NSNotification *)notification {
    CLLocation *newLocation = notification.userInfo[@"location"];
    
    if ( ! _didCenterMapOverMyLocationWhenViewDidLoad ) {
        _didCenterMapOverMyLocationWhenViewDidLoad = YES;
        
        CLLocationCoordinate2D coordinate   = newLocation.coordinate;
        float zoom                          = 14.0f;
        CLLocationDirection bearing         = self.mapView.camera.bearing;
        double viewingAngle                 = self.mapView.camera.viewingAngle;
        
        GMSCameraPosition *cameraPosition   = [GMSCameraPosition cameraWithTarget:coordinate
                                                                             zoom:zoom
                                                                          bearing:bearing
                                                                     viewingAngle:viewingAngle];
        
        [self.mapView animateToCameraPosition:cameraPosition];
    }
}

@end
