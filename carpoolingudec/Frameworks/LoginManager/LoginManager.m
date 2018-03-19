//
//  LoginManager.m
//  carpoolingudec
//
//  Created by Alejandro Melo Domínguez on 30-07-17.
//  Copyright © 2017 Alejandro Melo Domínguez. All rights reserved.
//

#import "LoginManager.h"
#import <AFNetworking/AFNetworking.h>












// Debugging
static BOOL kUdeCAlumnosLoginDebuggingEnabledDefaultValue = NO; // Valor por defecto para debugging. YES = Imprimir logs.

// URLs
NSString * const kURLStringLoginPost            = @"http://m.udec.cl/login-response.php";
NSString * const kURLStringLoginGet             = @"http://m.udec.cl/infodaMovil.php";
NSString * const kURLStringResponseParser       = @"https://local.penquistas.cl/index.php/account/check_login";
NSString * const kURLStringLogoutGet            = @"https://local.penquistas.cl/index.php/account/logout";

// Form fields (POST)
NSStringEncoding const kLoginPostRequestEncoding        = NSUTF8StringEncoding;
NSStringEncoding const kLoginPostResponseEncoding       = NSUTF8StringEncoding;
NSStringEncoding const kResponseParserRequestEncoding   = NSUTF8StringEncoding;
NSStringEncoding const kResponseParserResponseEncoding  = NSUTF8StringEncoding;
NSString * const kLoginPostFormFieldUsernameKey         = @"user";
NSString * const kLoginPostFormFieldPasswordKey         = @"pass";
NSString * const kResponseParserHTMLKey                 = @"html";

// Singleton
static LoginManager *__loginManagerCarpoolingUdeC;












@interface LoginManager ()
/*
 AFNetworking
 */
@property (strong, nonatomic) AFURLSessionManager *sessionManager;

/*
 Status properties
 */
@property (assign, atomic) BOOL loggedIn;
@property (strong, atomic) NSString * _Nullable username;
@end












@implementation LoginManager {
    NSString *_tempUsername;
    NSString *_tempPassword;
}











#pragma mark - Singleton
+ (instancetype _Nonnull)sharedManager {
    @synchronized (self) {
        if ( ! __loginManagerCarpoolingUdeC ) {
            __loginManagerCarpoolingUdeC = [self new];
        }
        
        return __loginManagerCarpoolingUdeC;
    }
}











#pragma mark - Initialization
- (instancetype _Nonnull)init {
    if ( self = [super init] ) {
        self.debugEnabled   = kUdeCAlumnosLoginDebuggingEnabledDefaultValue;
        
        self.sessionManager = nil;
        self.loggedIn       = NO;
        self.username       = nil;
    }
    
    return self;
}











#pragma mark - Login
#pragma mark Método público
/*
 Recibe una solicitud de inicio de sesión desde otras partes de la app,
 tomando username, password y un block de término.
 */
- (void)loginWithUsername:(NSString * _Nonnull)username password:(NSString * _Nonnull)password completionHandler:(void (^ _Nonnull)(BOOL loggedIn, NSError * _Nullable error, NSString * _Nullable response))completionHandler {
    
    _tempUsername = nil;
    _tempPassword = nil;
    
    [self sendLoginPostWithUsername:username
                           password:password
                  completionHandler:completionHandler];
    
}


#pragma mark Flujo
/**
 Envía los datos por POST a los servidores UdeC e interpreta la respuesta
 */
- (void)sendLoginPostWithUsername:(NSString * _Nonnull)username password:(NSString * _Nonnull)password completionHandler:(void (^ _Nonnull)(BOOL loggedIn, NSError * _Nullable error, NSString * _Nullable response))completionHandler {
    
    // 1)
    // Enviar datos de login a la URL correspondiente.
    
    NSError *requestError;
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    NSURLRequest *postRequest           = [serializer requestWithMethod:@"POST"
                                                              URLString:kURLStringLoginPost
                                                             parameters:@{
                                                                          kLoginPostFormFieldUsernameKey: username,
                                                                          kLoginPostFormFieldPasswordKey: password
                                                                          }
                                                                  error:&requestError];
    
    if ( ! requestError ) {
        _tempUsername = username;
        _tempPassword = password;
        
        void (^completionHandlerWithClearingUsername)(BOOL loggedIn, NSError * _Nullable error, NSString * _Nullable response) = ^void(BOOL loggedIn, NSError * _Nullable error, NSString * _Nullable response) {
            
            self.loggedIn = loggedIn;
            
            if ( loggedIn ) {
                self.username = _tempUsername;
            }
            
            completionHandler(loggedIn, error, response);
        };
        
        NSURLSessionDataTask *task  = [self.sessionManager dataTaskWithRequest:postRequest
                                                             completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                                                                 if ( ! error || error.code == NSURLErrorBadServerResponse ) {
                                                                     
                                                                     // 2)
                                                                     // Como la respuesta es siempre inválida (incluso si los datos son correctos), enviar GET a otra URL.
                                                                     // Así se puede obtener datos reales.
                                                                     
                                                                     if ( self.debugEnabled ) {
                                                                         NSLog(@"[%@] sendLoginPostWithUsername:password:completionHandler: %@",
                                                                               NSStringFromClass(self.class),
                                                                               error.code == NSURLErrorBadServerResponse ? @"Bad server response" : @"Unknown error"
                                                                               );
                                                                     }
                                                                     
                                                                     [self getLoginResponseWithCompletionHandler:completionHandlerWithClearingUsername];
                                                                     
                                                                 }
                                                                 else {
                                                                     
                                                                     if ( self.debugEnabled ) {
                                                                         NSLog(@"[%@] POST error (%ld): %@", NSStringFromClass(self.class), (long) error.code, error.localizedDescription);
                                                                     }
                                                                     
                                                                     completionHandlerWithClearingUsername(NO, error, @"El servidor UdeC no responde a la petición POST.");
                                                                     
                                                                 }
                                                             }];
        [task resume];
        
    }
    else {
        LOG(@"Error al armar el NSURLRequest.");
        _tempUsername = nil;
        _tempPassword = nil;
    }
    
}


/**
 Una vez enviados los datos, este método toma la respuesta del servidor UdeC
 y comprueba su validez. Luego llama al block, informando si fue login exitoso o no.
 
 Ya que los POST siempre devuelven respuestas extrañas (redirecciones en vez de datos reales),
 se hace un GET extra para comprobar si pasó o no el login.
 */
- (void)getLoginResponseWithCompletionHandler:(void (^ _Nonnull)(BOOL loggedIn, NSError * _Nullable error, NSString * _Nullable response))completionHandler {
    
    NSURL *getURL               = [NSURL URLWithString:kURLStringLoginGet];
    NSURLRequest *getRequest    = [NSURLRequest requestWithURL:getURL];
    
    NSURLSessionDataTask *task  = [self.sessionManager dataTaskWithRequest:getRequest
                                                         completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                                                             if ( ! error ) {
                                                                 
                                                                 // 3)
                                                                 // Se obtuvo el HTML de respuesta, enviar a servicio local
                                                                 // para parsearlo y obtener estado de login.
                                                                 NSString *html = [[NSString alloc] initWithData:responseObject
                                                                                                        encoding:kLoginPostResponseEncoding];
                                                                 
                                                                 if ( self.debugEnabled ) {
                                                                     NSLog(@"[%@] getLoginResponseWithCompletionHandler: %@\n\n%@\n\n",
                                                                           NSStringFromClass(self.class),
                                                                           @"No error on getting login response",
                                                                           html
                                                                           );
                                                                 }
                                                                 
                                                                 [self parseLoginWithHTML:html
                                                                        completionHandler:completionHandler];
                                                                 
                                                             }
                                                             else {
                                                                 
                                                                 if ( self.debugEnabled ) {
                                                                     NSLog(@"[%@] GET error: %@", NSStringFromClass(self.class), error.localizedDescription);
                                                                 }
                                                                 
                                                                 _tempUsername = nil;
                                                                 _tempPassword = nil;
                                                                 
                                                                 completionHandler(NO, error, @"El servidor UdeC no responde a la petición GET.");
                                                             }
                                                         }];
    [task resume];
}


#pragma mark Parser
/**
 Este método es un helper para getLoginResponseWithCompletionHandler:, que toma la respuesta
 del servidor UdeC y la envía al servidor de desarrollo para su parseo.
 
 Esto permite que el comprobar las respuestas se hagan de manera remota a la app, de esta manera,
 si cambia la respuesta, es fácilmente actualizable solo cambiando el código del backend,
 no necesitando una actualización de la app para funcionar.
 */
- (void)parseLoginWithHTML:(NSString * _Nonnull)html completionHandler:(void (^ _Nonnull)(BOOL loggedIn, NSError * _Nullable error, NSString * _Nullable response))completionHandler {
    
    // 3)
    // Se obtuvo el HTML de respuesta, enviar a servicio web
    // para parsearlo y obtener estado de login.
    
    NSError *requestError;
    
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    [serializer setValue:@"application/x-www-form-urlencoded; charset=UTF-8"
      forHTTPHeaderField:@"Content-Type"];
    
    NSURLRequest *postRequest           = [serializer requestWithMethod:@"POST"
                                                              URLString:kURLStringResponseParser
                                                             parameters:@{
                                                                          @"username"   : _tempUsername ?: @"",
                                                                          @"html"       : html
                                                                          }
                                                                  error:&requestError];
    
    NSURLSessionDataTask *task  = [self.sessionManager dataTaskWithRequest:postRequest
                                                         completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                                                             
                                                             // Actualizar cookies de sesión
                                                             NSHTTPURLResponse *httpResponse    = (NSHTTPURLResponse *) response;
                                                             NSArray *cookies                   = [NSHTTPCookie cookiesWithResponseHeaderFields:httpResponse.allHeaderFields
                                                                                                                                         forURL:httpResponse.URL];
                                                             
                                                             [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cookies
                                                                                                                forURL:httpResponse.URL
                                                                                                       mainDocumentURL:nil];
                                                             
                                                             
                                                             
                                                             
                                                             NSError *responseParserError;
                                                             NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:responseObject
                                                                                                                          options:NSJSONReadingAllowFragments
                                                                                                                            error:&responseParserError];
                                                             
                                                             if ( ! responseParserError ) {
                                                                 LOG(@"RESPONSE: %@", responseData);
                                                                 
                                                                 _serverResponse    = responseData;

                                                                 NSString *message  = responseData[@"message"];
                                                                 BOOL loggedIn      = [responseData[@"logged_in"] boolValue];
                                                                 NSInteger code     = [responseData[@"code"] integerValue];
                                                                 
//                                                                 LOG(@"\n\n\nUsername: %@\nPassword: %@\n\n\n", _tempUsername, _tempPassword);
                                                                 
                                                                 if ( loggedIn ) {
                                                                     [self saveCredentialsWithUsername:_tempUsername
                                                                                              password:_tempPassword];
                                                                     
                                                                     _tempUsername = nil;
                                                                     _tempPassword = nil;
                                                                     
                                                                     if ( completionHandler ) {
                                                                         completionHandler(loggedIn, error, message);
                                                                     }
                                                                 }
                                                                 else if ( code == 428 ) {
                                                                     
                                                                     _tempUsername = nil;
                                                                     _tempPassword = nil;
                                                                     
                                                                     if ( completionHandler ) {
                                                                         NSError *missingDataError = [NSError errorWithDomain:kLoginManagerErrorDomain
                                                                                                                         code:code
                                                                                                                     userInfo:@{
                                                                                                                                NSLocalizedFailureReasonErrorKey: responseData[@"message"] ?: @"",
                                                                                                                                NSLocalizedDescriptionKey: responseData[@"message"] ?: @"",
                                                                                                                                NSLocalizedRecoverySuggestionErrorKey: @"Regístrate con todos los datos solicitados."
                                                                                                                                }];
                                                                         
                                                                         if ( completionHandler ) {
                                                                             completionHandler(NO, missingDataError, responseData[@"message"]);
                                                                         }
                                                                     }
                                                                     
                                                                 }
                                                                 else {
                                                                     NSError *wrongAccountError = [NSError errorWithDomain:kLoginManagerErrorDomain
                                                                                                                      code:code
                                                                                                                  userInfo:@{
                                                                                                                             NSLocalizedFailureReasonErrorKey: responseData[@"message"] ?: @"",
                                                                                                                             NSLocalizedDescriptionKey: responseData[@"message"] ?: @"",
                                                                                                                             NSLocalizedRecoverySuggestionErrorKey: @"Verifica tus datos de inicio de sesión e inténtalo nuevamente."
                                                                                                                             }];
                                                                     
                                                                     if ( completionHandler ) {
                                                                         completionHandler(NO, wrongAccountError, responseData[@"message"]);
                                                                     }
                                                                 }
                                                                 
                                                             }
                                                             else {
                                                                 
                                                                 _tempUsername = nil;
                                                                 _tempPassword = nil;
                                                                 
                                                                 _serverResponse = nil;
                                                                 
                                                                 if ( completionHandler ) {
                                                                     completionHandler(NO, responseParserError, responseParserError.localizedDescription);
                                                                 }
                                                                 
                                                             }
                                                         }];
    [task resume];
    
}











#pragma mark - Logout
/**
 Si el usuario inició sesión y sus datos están almacenados, se envía una
 petición de cierre de sesión al servidor UdeC y luego se informa del
 logout exitoso.
 
 Si no hay una sesión iniciada, se informa inmediatamente del error.
 */
- (void)logoutWithCompletionHandler:(void (^ _Nullable)(BOOL loggedIn, NSError * _Nullable error, NSString * _Nullable response))completionHandler {
    
    if ( ! self.loggedIn || ! self.username ) {
        NSError *error = [NSError errorWithDomain:@"cl.penquistas.UdeCCarpooling.NotLoggedIn"
                                             code:NSURLErrorUserCancelledAuthentication
                                         userInfo:@{
                                                    NSLocalizedDescriptionKey               : @"El usuario no ha iniciado sesión.",
                                                    NSLocalizedFailureReasonErrorKey        : @"No se puede cerrar sesión porque no hay una sesión activa.",
                                                    NSLocalizedRecoverySuggestionErrorKey   : @"Se debe iniciar una sesión antes de realizar esta operación."
                                                    }];
        
        if ( completionHandler ) {
            completionHandler(NO, error, error.localizedDescription);
        }
        
        return;
    }
    
    
    
    NSURL *getURL               = [NSURL URLWithString:kURLStringLogoutGet];
    NSURLRequest *getRequest    = [NSURLRequest requestWithURL:getURL];
    
    NSURLSessionDataTask *task  = [self.sessionManager dataTaskWithRequest:getRequest
                                                         completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                                                             
                                                             // Actualizar cookies de sesión
                                                             NSHTTPURLResponse *httpResponse    = (NSHTTPURLResponse *) response;
                                                             NSArray *cookies                   = [NSHTTPCookie cookiesWithResponseHeaderFields:httpResponse.allHeaderFields
                                                                                                                                         forURL:httpResponse.URL];
                                                             
                                                             [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cookies
                                                                                                                forURL:httpResponse.URL
                                                                                                       mainDocumentURL:nil];
                                                             
                                                             
                                                             // Responder al completionHandler
                                                             NSError *responseParserError;
                                                             NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:responseObject
                                                                                                                          options:NSJSONReadingAllowFragments
                                                                                                                            error:&responseParserError];
                                                             
                                                             if ( ! error ) {
                                                                 NSString *message  = responseData[@"message"];
                                                                 BOOL loggedIn      = [responseData[@"logged_in"] boolValue];
                                                                 
                                                                 
                                                                 self.loggedIn = loggedIn;
                                                                 
                                                                 if ( ! loggedIn ) {
                                                                     self.username = nil;
                                                                     self.sessionManager = nil;
                                                                 }
                                                                 
                                                                 _tempUsername = nil;
                                                                 _tempPassword = nil;
                                                                 
                                                                 if ( completionHandler ) {
                                                                     completionHandler(loggedIn, nil, message);
                                                                 }
                                                             }
                                                             else {
                                                                 _tempUsername = nil;
                                                                 _tempPassword = nil;
                                                                 
                                                                 if ( completionHandler ) {
                                                                     completionHandler(self.loggedIn, error, error.localizedDescription);
                                                                 }
                                                             }
                                                             
                                                             [self clearCredentials];
                                                         }];
    
    [task resume];
    
}











#pragma mark - Session validation
- (void)revalidateSessionFromCredentialsWithCompletionHandler:(void (^ _Nonnull)(BOOL loggedIn, BOOL withCredentials, NSError *error))completionHandler {
    NSString *username = [self credentialForKey:@"username"];
    NSString *password = [self credentialForKey:@"password"];
    
    if ( ! username || ! password ) {
        completionHandler(NO, NO, nil);
        return;
    }
    
    [self loginWithUsername:username
                   password:password
          completionHandler:^(BOOL loggedIn, NSError * _Nullable error, NSString * _Nullable response) {
              _tempUsername = nil;
              _tempPassword = nil;
              
              if ( ! loggedIn ) {
                  [self clearCredentials];
                  
                  self.loggedIn = NO;
                  self.username = nil;
              }
              
              if ( completionHandler ) {
                  completionHandler(loggedIn, YES, error);
              }
          }];
}











#pragma mark - Custom getter
/**
 Lazy loading de AFURLSessionManager.
 La configura para desactivar la caché en las peticiones y, además,
 intenta seguir las peticiones de redirección (HTTP 301) si las hay.
 */
- (AFURLSessionManager *)sessionManager {
    if ( ! _sessionManager ) {
        NSURLSessionConfiguration *configuration    = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.requestCachePolicy            = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
        
        _sessionManager                             = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
        _sessionManager.responseSerializer          = [AFHTTPResponseSerializer serializer];
        
        [_sessionManager setTaskWillPerformHTTPRedirectionBlock:^NSURLRequest * _Nonnull(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, NSURLResponse * _Nonnull response, NSURLRequest * _Nonnull request) {
            return request;
        }];
    }
    
    return _sessionManager;
}











#pragma mark - Credentials persistence

- (void)saveCredentialsWithUsername:(NSString * _Nonnull)username password:(NSString * _Nonnull)password {
    [NSStandardUserDefaults setObject:username
                               forKey:@"user_username"];
    [NSStandardUserDefaults setObject:password
                               forKey:@"user_password"];
    
    [NSStandardUserDefaults synchronize];
}

- (NSString *)credentialForKey:(NSString *)key {
    if ( ! [key isEqualToString:@"username"] && ! [key isEqualToString:@"password"] ) {
        LOG(@"Invalid key for accessing credentials.");
        return nil;
    }
    
    return [NSStandardUserDefaults stringForKey:[@"user_" stringByAppendingString:key]];
}

- (void)clearCredentials {
    [NSStandardUserDefaults removeObjectForKey:@"user_username"];
    [NSStandardUserDefaults removeObjectForKey:@"user_password"];
    [NSStandardUserDefaults synchronize];
}
@end
