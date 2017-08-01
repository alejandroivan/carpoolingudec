//
//  UIViewController+KeyboardHelper.m
//  candidatosudd
//
//  Created by dpsmac1 on 28-06-16.
//  Copyright © 2016 Universidad del Desarrollo. All rights reserved.
//

#import <objc/runtime.h>
#import "UIViewController+KeyboardHelper.h"

static void *TapGestureRecognizerKHPropertyKey      = &TapGestureRecognizerKHPropertyKey;
static void *TapGestureRecognizerViewsKHPropertyKey = &TapGestureRecognizerViewsKHPropertyKey;
static void *ScrollViewKHPropertyKey                = &ScrollViewKHPropertyKey;




@implementation UIViewController (KeyboardHelper)

// Getter/setter for tap gesture recognizer
- (void)setTapGestureRecognizerKH:(UITapGestureRecognizer *)tgr {
    objc_setAssociatedObject( self, TapGestureRecognizerKHPropertyKey, tgr, OBJC_ASSOCIATION_RETAIN_NONATOMIC );
}

- (UITapGestureRecognizer *)tapGestureRecognizerKH {
    return objc_getAssociatedObject( self, TapGestureRecognizerKHPropertyKey );
}

// Getter/setter for tap gesture recognizer views array
- (void)setTapGestureRecognizerViewsKH:(UITapGestureRecognizer *)tgr {
    objc_setAssociatedObject( self, TapGestureRecognizerViewsKHPropertyKey, tgr, OBJC_ASSOCIATION_RETAIN_NONATOMIC );
}

- (UITapGestureRecognizer *)tapGestureRecognizerViewsKH {
    return objc_getAssociatedObject( self, TapGestureRecognizerViewsKHPropertyKey );
}

// Getter/setter for the scroll view outlet
- (void)setScrollViewKH:(UIScrollView *)scrollViewKH {
    objc_setAssociatedObject( self, ScrollViewKHPropertyKey, scrollViewKH, OBJC_ASSOCIATION_RETAIN_NONATOMIC );
}

- (UIScrollView *)scrollViewKH {
    return objc_getAssociatedObject( self, ScrollViewKHPropertyKey );
}



#pragma mark - Tap Gesture Recognizer setup
- (void)configureTapGestureRecognizer {
    [self configureTapGestureRecognizerWithView:self.view];
}

- (void)configureTapGestureRecognizerWithView:(UIView *)theView {
    self.tapGestureRecognizerKH                           = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapOnMainView:)];
    self.tapGestureRecognizerKH.cancelsTouchesInView      = NO;
    self.tapGestureRecognizerKH.numberOfTapsRequired      = 1;
    self.tapGestureRecognizerKH.numberOfTouchesRequired   = 1;
    
    [self addGestureRecognizerToView:theView];
}

- (void)addGestureRecognizerToView:(UIView *)theView {
    if ( [self.tapGestureRecognizerViewsKH containsObject:theView] ) {
        return;
    }
    
    [self.tapGestureRecognizerViewsKH addObject:theView];
    [theView addGestureRecognizer:self.tapGestureRecognizerKH];
}

- (void)removeGestureRecognizerFromView:(UIView *)theView {
    [theView removeGestureRecognizer:self.tapGestureRecognizerKH];
    [self.tapGestureRecognizerViewsKH removeObject:theView];
}

- (void)removeGestureRecognizerFromAllViews {
    for ( UIView *theView in self.tapGestureRecognizerViewsKH ) {
        [self removeGestureRecognizerFromView:theView];
    }
}

- (void)handleTapOnMainView:(UITapGestureRecognizer *)sender { // Override on view controller if needed
    [self dismissKeyboard];
}





#pragma mark - Dismiss Keyboard
- (void)dismissKeyboard {
    [self changeFirstResponderToView:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField { // Override on view controller
    [self dismissKeyboard];
    return YES;
}


#pragma mark - Find First Responder
- (UIView *)findFirstResponder {
    return [self findFirstResponderFromViewController:self];
}



- (UIView *)findFirstResponderFromViewController:(UIViewController *)viewController {
    return [self findFirstResponderFromView:viewController.view];
}



- (UIView *)findFirstResponderFromView:(UIView *)rootView {
    UIView *firstResponder = [rootView isFirstResponder] ? rootView : nil;
    
    if ( ! firstResponder ) {
        for (UIView *subview in rootView.subviews ) {
            firstResponder = [self findFirstResponderFromView:subview];
            
            if ( firstResponder ) {
                break;
            }
        }
    }
    
    return firstResponder;
}




#pragma mark Change First Responder
- (void)changeFirstResponderToView:(UIView *)nextResponder {
    UIView *firstResponder = [self findFirstResponder];
    
    if ( firstResponder == nextResponder ) {
        return;
    }
    
    [firstResponder resignFirstResponder];
    [nextResponder becomeFirstResponder];
}

















#pragma mark Show inputs when keyboard appears
// Call this method somewhere in your view controller setup code.

- (void)registerForKeyboardNotifications {
    
    if ( ! self.scrollViewKH ) {
#ifdef DEBUG
#if DEBUG == 1
        NSLog(@"<KeyboardEvent> registerForKeyboardNotifications should only be called after setting the UIScrollView (setScrollViewKH: method)");
#endif
#endif
        return;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)registerForKeyboardNotificationsWithScrollView:(UIScrollView *)theScrollView {
    [self setScrollViewKH:theScrollView];
    [self registerForKeyboardNotifications];
}

- (void)deregisterForKeyboardNotifications {
    [self setScrollViewKH:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification {
    if ( ! self.scrollViewKH ) {
#ifdef DEBUG
#if DEBUG == 1
        NSLog(@"<KeyboardEvent> Se debe definir la UIScrollView utilizando el método setScrollViewKH:");
#endif
#endif
        return;
    }
    
    UIScrollView *scrollView            = (UIScrollView *) self.scrollViewKH;
    NSDictionary* info                  = [aNotification userInfo];
    CGSize kbSize                       = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    UIView *activeView                  = [self findFirstResponderFromView:self.view];
    
    UIEdgeInsets contentInsets          = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    scrollView.contentInset             = contentInsets;
    scrollView.scrollIndicatorInsets    = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect        = self.view.frame;
    aRect.size.height   -= kbSize.height;
    
    CGPoint originPoint = activeView.frame.origin;
    CGPoint endPoint    = activeView.frame.origin;
    endPoint.x          += activeView.frame.size.width;
    endPoint.y          += activeView.frame.size.height;
    
    if ( ! CGRectContainsPoint(aRect, originPoint) || ! CGRectContainsPoint(aRect, endPoint) ) {
        [scrollView scrollRectToVisible:activeView.frame animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    if ( ! self.scrollViewKH ) {
#ifdef DEBUG
#if DEBUG == 1
        NSLog(@"<KeyboardEvent> Se debe definir la UIScrollView utilizando el método setScrollViewKH:");
#endif
#endif
        return;
    }
    
    UIScrollView *scrollView            = (UIScrollView *) self.scrollViewKH;
    UIEdgeInsets contentInsets          = UIEdgeInsetsZero;
    
    scrollView.contentInset             = contentInsets;
    scrollView.scrollIndicatorInsets    = contentInsets;
}

@end
