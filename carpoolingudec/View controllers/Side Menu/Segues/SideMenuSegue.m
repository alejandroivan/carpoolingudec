//
//  SideMenuSegue.m
//  carpoolingudec
//
//  Created by Alejandro Melo Domínguez on 31-07-17.
//  Copyright © 2017 Alejandro Melo Domínguez. All rights reserved.
//

#import "SideMenuSegue.h"

@implementation SideMenuSegue

- (id)initWithIdentifier:(NSString *)identifier source:(UIViewController *)source destination:(UIViewController *)destination {
    return [super initWithIdentifier:identifier
                              source:source
                         destination:destination];
}

- (void)perform {
    __weak MFSideMenuContainerViewController *sideMenu  = [GET_APPDELEGATE() sideMenuContainer];
    sideMenu.centerViewController                       = self.destinationViewController;
    
    [sideMenu setMenuState:MFSideMenuStateClosed
                completion:nil];
}

@end
