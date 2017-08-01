//
//  AppDelegate.h
//  carpoolingudec
//
//  Created by Alejandro Melo Domínguez on 30-07-17.
//  Copyright © 2017 Alejandro Melo Domínguez. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MFSideMenu/MFSideMenu.h>
@import CoreLocation;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) MFSideMenuContainerViewController *sideMenuContainer;


/*
 Helper methods
 */
- (void)runBlockOnMainQueue:(void (^)())block;

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message proceedTitle:(NSString *)proceedTitle proceedAction:(void (^)())proceedAction cancelTitle:(NSString *)cancelTitle cancelAction:(void (^)())cancelAction;
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message proceedTitle:(NSString *)proceedTitle proceedAction:(void (^)())proceedAction cancelTitle:(NSString *)cancelTitle cancelAction:(void (^)())cancelAction showProceedInRed:(BOOL)showProceedInRed;

/*
 Servicios de ubicación
 */
@property (strong, nonatomic) CLLocation *lastLocation;
- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

/*
 Login
 */
- (void)showLoginScreen:(BOOL)animated;
- (void)hideLoginScreen:(BOOL)animated;

@end

