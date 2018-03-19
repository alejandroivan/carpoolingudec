//
//  AppDelegate.m
//  carpoolingudec
//
//  Created by Alejandro Melo Domínguez on 30-07-17.
//  Copyright © 2017 Alejandro Melo Domínguez. All rights reserved.
//

#import "AppDelegate.h"
#import "LoginViewController.h"
#import "GoogleMapsAPIKey.h"
#import "HomeViewController.h"
#import "LocationManager.h"
#import "LoginManager.h"
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
    
    /*
     LocationManager
     */
    [self startUpdatingLocation];
    
    
    /*
     Side Menu
     */
    LOG(@"[%@] Setting up side menu...", NSStringFromClass(self.class));
    UINavigationController *leftMenuNavigationController    = [[GET_ROOTVIEWCONTROLLER() storyboard] instantiateViewControllerWithIdentifier:@"SideMenuNavigationController"];
    UINavigationController *rightMenuNavigationController   = nil;
    
    MFSideMenuContainerViewController *container = [MFSideMenuContainerViewController containerWithCenterViewController:GET_ROOTVIEWCONTROLLER()
                                                                                                 leftMenuViewController:leftMenuNavigationController
                                                                                                rightMenuViewController:rightMenuNavigationController];
    
    container.menuSlideAnimationEnabled = YES;
    container.menuSlideAnimationFactor  = 3.0f;
    container.shadow.enabled            = YES;
    container.shadow.radius             = 1.0f;
    container.shadow.color              = [UIColor blackColor];
    container.shadow.opacity            = 0.75f;
    
    container.menuWidth                 = [[UIScreen mainScreen] bounds].size.width - 62.0f;
    
    self.sideMenuContainer              = container;
    self.window.rootViewController      = container;
    
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
    /*
     Login Screen
     */
    LOG(@"\n\nREVALIDATING SESSION\n\n");
    
    ActivityIndicatorViewController *activityIndicatorViewController;
    if ( [self.window.rootViewController isKindOfClass:[ActivityIndicatorViewController class]] ) {
        activityIndicatorViewController = (ActivityIndicatorViewController *) self.window.rootViewController;
    }
    else {
        activityIndicatorViewController = (ActivityIndicatorViewController *) [[(UINavigationController *)[self.sideMenuContainer centerViewController] viewControllers] lastObject];
    }
    
    [activityIndicatorViewController showIndicator];
    
    [[LoginManager sharedManager] revalidateSessionFromCredentialsWithCompletionHandler:^(BOOL loggedIn, BOOL withCredentials, NSError *error) {
        [activityIndicatorViewController hideIndicator];
        
        if ( ! loggedIn ) {
            [self showLoginScreen:withCredentials];
            
            if ( error.code == 401 ) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self showAlertWithTitle:@"Cuenta no habilitada"
                                     message:@"Esta cuenta no se encuentra habilitada."
                                proceedTitle:nil
                               proceedAction:nil
                                 cancelTitle:@"Cerrar"
                                cancelAction:nil];
                });
            }
        }
    }];
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











#pragma mark - Login
static UIViewController *loginScreenViewController;
static BOOL loginIsShown = NO;

- (void)showLoginScreen:(BOOL)animated {
    LOG(@"animated=%@", animated ? @"YES" : @"NO");
    
    UIViewController *parentVC  = GET_ROOTVIEWCONTROLLER();
    parentVC                    = [parentVC isKindOfClass:[UINavigationController class]] ? parentVC : [GET_SIDEMENU() centerViewController];
    
    if ( ! loginScreenViewController ) {
        loginScreenViewController               = [parentVC.storyboard instantiateViewControllerWithIdentifier:@"LoginNavigationController"];
        loginScreenViewController.view.frame    = parentVC.view.frame;
    }
    
    if ( ! loginIsShown ) {
        loginIsShown = YES;
        
        [GET_SIDEMENU() setPanMode:MFSideMenuPanModeNone];
        
        if ( ! animated ) {
            
            [loginScreenViewController willMoveToParentViewController:parentVC];
            
            [loginScreenViewController.view setAlpha:1.0];
            [parentVC.view addSubview:loginScreenViewController.view];
            [parentVC.view bringSubviewToFront:loginScreenViewController.view];
            
            [loginScreenViewController didMoveToParentViewController:parentVC];
            
        }
        else {
            
            [loginScreenViewController willMoveToParentViewController:parentVC];
            
            [loginScreenViewController.view setAlpha:0.0];
            [parentVC.view addSubview:loginScreenViewController.view];
            [parentVC.view bringSubviewToFront:loginScreenViewController.view];
            
            [UIView animateWithDuration:0.5
                             animations:^{
                                 loginScreenViewController.view.alpha = 1.0;
                             }
                             completion:^(BOOL finished) {
                                 [loginScreenViewController didMoveToParentViewController:parentVC];
                             }];
            
        }
        
        [self stopUpdatingLocation];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didGetLoginStatusUpdate:)
                                                     name:@"LOGIN_STATUS"
                                                   object:nil];
    }
}


- (void)hideLoginScreen:(BOOL)animated {
    LOG(@"animated=%@", animated ? @"YES" : @"NO");
    
    if ( ! loginScreenViewController || ! loginIsShown ) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"LOGIN_STATUS"
                                                  object:nil];
    
    if ( ! animated ) {
        
        [loginScreenViewController willMoveToParentViewController:nil];
        [loginScreenViewController.view setAlpha:1.0];
        [loginScreenViewController.view removeFromSuperview];
        [loginScreenViewController didMoveToParentViewController:nil];
        [GET_SIDEMENU() setPanMode:MFSideMenuPanModeDefault];
        
        loginScreenViewController = nil;
        loginIsShown = NO;
        
    }
    else {
        
        [loginScreenViewController willMoveToParentViewController:nil];
        [loginScreenViewController.view setAlpha:1.0];
        
        [UIView animateWithDuration:0.5f
                         animations:^{
                             loginScreenViewController.view.alpha = 0.0;
                         }
                         completion:^(BOOL finished) {
                             [loginScreenViewController didMoveToParentViewController:nil];
                             [loginScreenViewController.view removeFromSuperview];
                             [GET_SIDEMENU() setPanMode:MFSideMenuPanModeDefault];
                             
                             loginScreenViewController = nil;
                             loginIsShown = NO;
                         }];
        
    }
    
}

- (void)didGetLoginStatusUpdate:(NSNotification *)notification {
    NSDictionary *info  = notification.userInfo;
    BOOL loggedIn       = [info[@"logged_in"] boolValue];
    
    if ( loggedIn ) {
        [self hideLoginScreen:YES];
    }
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
