//
//  AppDelegate.h
//  carpoolingudec
//
//  Created by Alejandro Melo Domínguez on 30-07-17.
//  Copyright © 2017 Alejandro Melo Domínguez. All rights reserved.
//

#import <UIKit/UIKit.h>
@import CoreLocation;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;


/**
 Servicios de ubicación
 */
@property (strong, nonatomic) CLLocation *lastLocation;
- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

@end

