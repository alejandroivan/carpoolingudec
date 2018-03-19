//
//  LocationManager.m
//  carpoolingudec
//
//  Created by Alejandro Melo Domínguez on 31-07-17.
//  Copyright © 2017 Alejandro Melo Domínguez. All rights reserved.
//

#import "LocationManager.h"
#import "LoginManager.h"
@import GoogleMaps;
@import GooglePlaces;

static LocationManager *__locationManagerSharedInstance;












@interface LocationManager() <CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *location;

@property (assign, nonatomic) BOOL isActive;
@property (assign, nonatomic) LocationManagerAuthorizationStatus authorizationStatus;
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
        
        [self updateAuthorizationStatus];
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










#pragma mark - Authorization status
- (void)updateAuthorizationStatus {
    switch ( [CLLocationManager authorizationStatus] ) {
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse: {
            self.authorizationStatus = LocationManagerAuthorizationStatusAuthorized;
            break;
        }
            
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted: {
            self.authorizationStatus = LocationManagerAuthorizationStatusNotAuthorized;
            break;
        }
            
        default:
        case kCLAuthorizationStatusNotDetermined: {
            self.authorizationStatus = LocationManagerAuthorizationStatusUndetermined;
            break;
        }
    }
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
    
    [self updateAuthorizationStatus];
    [self.delegate locationManager:self didUpdateAuthorizationStatus:self.authorizationStatus];
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
    
    [self.delegate locationManager:self
                 didUpdateLocation:newLocation];
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




#pragma mark - Fixed locations
- (CLLocation *)locationForUniversity {
    static CLLocation *location = nil;
    
    if ( ! location ) {
        location = [[CLLocation alloc] initWithLatitude:-36.8292642
                                              longitude:-73.0359495];
    }
    
    return location;
}

- (CLLocation *)locationForHome {
    NSNumber *latitude  = [[LoginManager sharedManager] serverResponse][@"data"][@"casa_latitud"];
    NSNumber *longitude = [[LoginManager sharedManager] serverResponse][@"data"][@"casa_longitud"];
    
    if ( ! latitude || ! longitude || latitude == (id) [NSNull null] || longitude == (id) [NSNull null] ) {
        return nil;
    }
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude.doubleValue
                                                      longitude:longitude.doubleValue];
    
    return location;
}

+ (void)getDirectionsByCarWithOrigin:(CLLocation *)origin destination:(CLLocation *)destination completionHandler:(void (^)(BOOL success, NSDictionary *directions))completionHandler {
    static NSString *baseUrlString = @"https://maps.googleapis.com/maps/api/directions/json?";
    
    if ( ! origin || ! destination ) {
        if ( completionHandler ) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completionHandler(NO, nil);
            }];
        }
        return;
    }
    
    NSString *originString = [NSString stringWithFormat:@"origin=%.10g,%.10g", origin.coordinate.latitude, origin.coordinate.longitude];
    NSString *destinationString = [NSString stringWithFormat:@"destination=%.10g,%.10g", destination.coordinate.latitude, destination.coordinate.longitude];
    
    NSString *queryUrlString = [NSString stringWithFormat:@"%@%@&%@",
                                baseUrlString,
                                originString,
                                destinationString
                                ];
    NSURL *queryURL = [NSURL URLWithString:queryUrlString];
    
    LOG(@"Querying URL: %@", queryURL.absoluteString);
    
    if ( queryURL ) {
        [[NSOperationQueue new] addOperationWithBlock:^{
            NSData *directionsData = [[NSData alloc] initWithContentsOfURL:queryURL];
            NSError *error;
            
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:directionsData
                                                                 options:NSJSONReadingMutableContainers
                                                                   error:&error];
            
            if ( ! error ) {
                if ( completionHandler ) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        completionHandler(YES, json);
                    }];
                }
                
                return;
            }
            else {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    completionHandler(NO, nil);
                }];
            }
        }];
        
        return;
    }
    
    if ( completionHandler ) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            completionHandler(NO, nil);
        }];
    }
}

@end
