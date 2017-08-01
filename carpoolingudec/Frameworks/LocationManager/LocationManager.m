//
//  LocationManager.m
//  carpoolingudec
//
//  Created by Alejandro Melo Domínguez on 31-07-17.
//  Copyright © 2017 Alejandro Melo Domínguez. All rights reserved.
//

#import "LocationManager.h"
@import GoogleMaps;
@import GooglePlaces;

static LocationManager *__locationManagerSharedInstance;












@interface LocationManager() <CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *location;

@property (assign, nonatomic) BOOL isActive;
@end












@implementation LocationManager


#pragma mark - Initializers

+ (instancetype)sharedManager {
    @synchronized (self) {
        if ( ! __locationManagerSharedInstance ) {
            __locationManagerSharedInstance = [self new];
        }
        
        return __locationManagerSharedInstance;
    }
}


- (instancetype)init {
    if ( self = [super init] ) {
        self.locationManager                                    = [CLLocationManager new];
        self.locationManager.desiredAccuracy                    = kCLLocationAccuracyBest;
        self.locationManager.distanceFilter                     = kCLDistanceFilterNone;
        self.locationManager.allowsBackgroundLocationUpdates    = NO;
        self.locationManager.delegate                           = self;
        
        self.isActive                                           = NO;
        self.notifyUsingNotificationCenter                      = YES;
    }
    
    return self;
}












#pragma mark - Start/stop getting location

- (void)startUpdatingLocation {
    [self askForLocationPermissionsWithCompletionHandler:^(BOOL authorized) {
        self.isActive = authorized;
        
        if ( authorized ) {
            [self.locationManager startUpdatingLocation];
        }
        else {
#ifdef DEBUG
            NSLog(@"[%@](-startUpdatingLocation) No hay permisos para utilizar la ubicación.", NSStringFromClass(self.class));
#endif
        }
    }];
}



- (void)stopUpdatingLocation {
    if ( ! self.isActive ) {
#ifdef DEBUG
        NSLog(@"[%@](-stopUpdatingLocation) No se está registrando la ubicación.", NSStringFromClass(self.class));
#endif
        return;
    }
    
    self.isActive = NO;
    [self.locationManager stopUpdatingLocation];
}












#pragma mark - Permissions
void (^__waitingForPermissionsCompletionHandler)(BOOL authorized) = nil;

- (void)askForLocationPermissionsWithCompletionHandler:(void (^)(BOOL authorized))completionHandler {
#ifdef DEBUG
    NSLog(@"[%@](-askForLocationPermissions) Solicitando permiso para acceder a la ubicación.", NSStringFromClass(self.class));
#endif
    switch ( [CLLocationManager authorizationStatus] ) {
            
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            /*
             Uso de localización autorizado
             */
            completionHandler(YES);
            break;
            
        case kCLAuthorizationStatusNotDetermined:
            /*
             Permisos no determinados, solicitar acceso
             */
            [self.locationManager requestWhenInUseAuthorization];
            __waitingForPermissionsCompletionHandler = completionHandler;
            break;
            
        default:
            /*
             Uso de localización no autorizado
             */
            completionHandler(NO);
            break;
            
    }
}











#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *newLocation = [locations lastObject];
    
    if ( newLocation.horizontalAccuracy < 0 ) {
        // Ignorar esta ubicación porque no es relativamente exacta
        return;
    }
    
    self.location = newLocation;
    
    if ( self.notifyUsingNotificationCenter ) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"LOCATION_UPDATE"
                                                            object:nil
                                                          userInfo:@{
                                                                     @"location" : newLocation
                                                                     }];
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if ( ! __waitingForPermissionsCompletionHandler ) {
        return;
    }
    
    switch ( status ) {
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            /*
             Uso de localización autorizado
             */
            __waitingForPermissionsCompletionHandler(YES);
            break;
            
        default:
            /*
             Uso de localización no autorizado
             */
            __waitingForPermissionsCompletionHandler(NO);
            break;
    }
    
    __waitingForPermissionsCompletionHandler = nil;
}

@end
