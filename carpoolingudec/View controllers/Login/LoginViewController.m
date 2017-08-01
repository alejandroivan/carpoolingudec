//
//  LoginViewController.m
//  carpoolingudec
//
//  Created by Alejandro Melo Domínguez on 31-07-17.
//  Copyright © 2017 Alejandro Melo Domínguez. All rights reserved.
//

#import "LoginViewController.h"
#import "UIViewController+KeyboardHelper.h"
#import "LoginManager.h"

@interface LoginViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self registerForKeyboardNotificationsWithScrollView:self.scrollView];
    [self configureTapGestureRecognizer];
    [self addGestureRecognizerToView:self.navigationController.view];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self removeGestureRecognizerFromAllViews];
    [self deregisterForKeyboardNotifications];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)login {
    [self showIndicator];
    
    LoginManager *loginManager = [LoginManager sharedManager];
    
    [loginManager loginWithUsername:self.usernameTextField.text
                           password:self.passwordTextField.text
                  completionHandler:^(BOOL loggedIn, NSError * _Nullable error, NSString * _Nullable response) {
                      [self hideIndicator];
                      
                      if ( loggedIn ) {
                          [GET_APPDELEGATE() hideLoginScreen:YES];
                      }
                      else {
                          [GET_APPDELEGATE() showAlertWithTitle:@"Error al iniciar sesión"
                                                        message:[NSString stringWithFormat:@"No se ha podido iniciar sesión. %@", response]
                                                   proceedTitle:nil
                                                  proceedAction:nil
                                                    cancelTitle:@"Cerrar"
                                                   cancelAction:nil];
                      }
                  }];
}

- (IBAction)goToMyWebsite {
    NSURL *url = [NSURL URLWithString:@"http://penquistas.cl/"];
    
    if ( [[UIApplication sharedApplication] canOpenURL:url] ) {
        [[UIApplication sharedApplication] openURL:url
                                           options:@{}
                                 completionHandler:nil];
    }
}











#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ( textField == self.usernameTextField ) {
        [self changeFirstResponderToView:self.passwordTextField];
    }
    else if ( textField == self.passwordTextField ) {
        [self dismissKeyboard];
    }
    
    return YES;
}

@end
