//
//  AppDelegate.m
//  3DAugmentation
//
//  Created by Alexandr Stepanov on 11.02.12.
//  Copyright (c) 2012 Home,sweet home. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "Isgl3dViewController.h"
#import "Isgl3dDirector.h"
#import "CubeView.h"

@implementation AppDelegate

@synthesize viewController = _viewController;

- (void)dealloc
{
    [_viewController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [super application:application didFinishLaunchingWithOptions:launchOptions];
        
    self.viewController = [[MainViewController alloc] init];
    
    // Override point for customization after application launch.
    self.window.rootViewController = self.viewController;    
    [self.window makeKeyAndVisible];
    return YES;
}


@end
