//
//  LocationManager.h
//  carpoolingudec
//
//  Created by Alejandro Melo Domínguez on 31-07-17.
//  Copyright © 2017 Alejandro Melo Domínguez. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreLocation;

@interface LocationManager : NSObject

@property (strong, nonatomic, readonly) CLLocation *location;

@property (assign, nonatomic, readonly) BOOL isActive;
@property (assign, nonatomic) BOOL notifyUsingNotificationCenter;

+ (instancetype)sharedManager;

- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

@end
