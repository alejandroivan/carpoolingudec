//
//  LocationManagerUpdatesDelegate.h
//  carpoolingudec
//
//  Created by Alejandro Melo Domínguez on 10-03-18.
//  Copyright © 2018 Alejandro Melo Domínguez. All rights reserved.
//

#ifndef LocationManagerUpdatesDelegate_h
#define LocationManagerUpdatesDelegate_h

#import "LocationManagerAuthorizationStatus.h"
#import <CoreLocation/CLLocation.h>
@class LocationManager;

@protocol LocationManagerUpdatesDelegate
@optional
- (void)locationManager:(LocationManager *)locationManager didUpdateAuthorizationStatus:(LocationManagerAuthorizationStatus)authorizationStatus;
@required
- (void)locationManager:(LocationManager *)locationManager didUpdateLocation:(CLLocation *)location;
@end

#endif /* LocationManagerUpdatesDelegate_h */
