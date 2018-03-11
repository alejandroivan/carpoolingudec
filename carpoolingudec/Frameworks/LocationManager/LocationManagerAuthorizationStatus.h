//
//  LocationManagerAuthorizationStatus.h
//  carpoolingudec
//
//  Created by Alejandro Melo Domínguez on 10-03-18.
//  Copyright © 2018 Alejandro Melo Domínguez. All rights reserved.
//

#ifndef LocationManagerAuthorizationStatus_h
#define LocationManagerAuthorizationStatus_h

typedef NS_ENUM(NSInteger, LocationManagerAuthorizationStatus) {
    LocationManagerAuthorizationStatusNotAuthorized,
    LocationManagerAuthorizationStatusAuthorized,
    LocationManagerAuthorizationStatusUndetermined
};

#endif /* LocationManagerAuthorizationStatus_h */
