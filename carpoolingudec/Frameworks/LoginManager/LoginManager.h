//
//  LoginManager.h
//  carpoolingudec
//
//  Created by Alejandro Melo Domínguez on 30-07-17.
//  Copyright © 2017 Alejandro Melo Domínguez. All rights reserved.
//

#import <Foundation/Foundation.h>


// Error domain
static NSString * _Nonnull kLoginManagerErrorDomain = @"cl.penquistas.carpoolingudec.LoginManager.ErrorDomain";
static NSInteger kLoginManagerErrorNeedsRegistrationCode = 428;


@interface LoginManager : NSObject
@property (assign, nonatomic) BOOL debugEnabled;
@property (assign, atomic, readonly) BOOL loggedIn;
@property (strong, atomic, readonly) NSString * _Nullable username;
@property (strong, nonatomic, readonly) NSDictionary *serverResponse;


/**
 Singleton, solo debería existir un LoginManager en todo momento.
 */
+ (instancetype _Nonnull)sharedManager;


/**
 Métodos para iniciar/cerrar sesión
 */
- (void)loginWithUsername:(NSString * _Nonnull)username password:(NSString * _Nonnull)password completionHandler:(void (^ _Nonnull)(BOOL loggedIn, NSError * _Nullable error, NSString * _Nullable response))completionHandler;
- (void)logoutWithCompletionHandler:(void (^ _Nullable)(BOOL loggedIn, NSError * _Nullable error, NSString * _Nullable response))completionHandler;

/**
 Método para revalidar sesión. Se utiliza para validar al volver a abrir la app.
 */
- (void)revalidateSessionFromCredentialsWithCompletionHandler:(void (^ _Nonnull)(BOOL loggedIn, BOOL withCredentials, NSError * _Nullable error))completionHandler;

@end
