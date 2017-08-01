//
//  AppDelegate.m
//  carpoolingudec
//
//  Created by Alejandro Melo Domínguez on 30-07-17.
//  Copyright © 2017 Alejandro Melo Domínguez. All rights reserved.
//

#import "AppDelegate.h"
#import "GoogleMapsAPIKey.h"
#import "LocationManager.h"
@import Firebase;
@import GoogleMaps;
@import GooglePlaces;

@interface AppDelegate ()
@property (weak, nonatomic) LocationManager *locationManager;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [FIRApp configure];
    [GMSServices provideAPIKey:kGoogleMapsAPIKey];
    [GMSPlacesClient provideAPIKey:kGoogleMapsAPIKey];
    
    // Comenzar a obtener la ubicación en todo momento
    [self startUpdatingLocation];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}











#pragma mark - Location
- (void)startUpdatingLocation {
    if ( ! self.locationManager ) {
        self.locationManager = [LocationManager sharedManager];
    }
    
    [self.locationManager startUpdatingLocation];
}

- (void)stopUpdatingLocation {
    [self.locationManager stopUpdatingLocation];
}












#pragma mark - Main Queue
- (void)runBlockOnMainQueue:(void (^)())block {
    if ( ! block ) {
        return;
    }
    
    if ( [self currentQueueIsMainQueue] ) {
        block();
    }
    else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

- (BOOL)currentQueueIsMainQueue {
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    return ( dispatch_queue_get_label(mainQueue) == dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) );
}


#pragma mark Alert helper

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message proceedTitle:(NSString *)proceedTitle proceedAction:(void (^)())proceedAction cancelTitle:(NSString *)cancelTitle cancelAction:(void (^)())cancelAction {
    
    [self showAlertWithTitle:title
                     message:message
                proceedTitle:proceedTitle
               proceedAction:proceedAction
                 cancelTitle:cancelTitle
                cancelAction:cancelAction
            showProceedInRed:NO];
    
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message proceedTitle:(NSString *)proceedTitle proceedAction:(void (^)())proceedAction cancelTitle:(NSString *)cancelTitle cancelAction:(void (^)())cancelAction showProceedInRed:(BOOL)showProceedInRed {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    
    
    if ( proceedTitle ) {
        proceedAction = proceedAction ?: ^{};
        [alertController addAction:[UIAlertAction actionWithTitle:proceedTitle
                                                            style:( showProceedInRed ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault )
                                                          handler:proceedAction]];
    }
    
    NSString *titleForCancelButton = cancelTitle ?: @"Cancelar";
    [alertController addAction:[UIAlertAction actionWithTitle:titleForCancelButton
                                                        style:UIAlertActionStyleCancel
                                                      handler:cancelAction]];
    
    
    
    __weak UIViewController *blockViewController        = self.window.rootViewController;
    __weak typeof(alertController) blockAlertController = alertController;
    
    [self runBlockOnMainQueue:^{
        [blockViewController presentViewController:blockAlertController
                                          animated:YES
                                        completion:nil];
    }];
    
}


@end
