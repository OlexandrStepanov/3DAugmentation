/*
 * iSGL3D: http://isgl3d.com
 *
 * Copyright (c) 2010-2011 Stuart Caunt
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import "Isgl3dAppDelegate.h"
#import "Isgl3dViewController.h"
#import "Isgl3d.h"

@implementation Isgl3dAppDelegate

@synthesize window = _window;
@synthesize glViewController=_glViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	// Create the UIWindow
	_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	// Set the director to display the FPS
	[Isgl3dDirector sharedInstance].displayFPS = DEBUG_IS_ON; 

	// Create the UIViewController
	_glViewController = [[Isgl3dViewController alloc] initWithNibName:nil bundle:nil];
	_glViewController.wantsFullScreenLayout = YES;
	
	// Create OpenGL view (here for OpenGL ES 1.1)
	Isgl3dEAGLView * glView = [Isgl3dEAGLView viewWithFrameForES1:[_window bounds]];

	// Set view in director
	[Isgl3dDirector sharedInstance].openGLView = glView;
	
	// Specify auto-rotation strategy if required (for example via the UIViewController and only landscape)
	[Isgl3dDirector sharedInstance].autoRotationStrategy = Isgl3dAutoRotationByUIViewController;
	[Isgl3dDirector sharedInstance].allowedAutoRotations = Isgl3dAllowedAutoRotationsPortraitOnly;
	
	// Enable retina display : uncomment if desired
	[[Isgl3dDirector sharedInstance] enableRetinaDisplay:YES];

	// Enables anti aliasing (MSAA) : uncomment if desired (note may not be available on all devices and can have performance cost)
//	[Isgl3dDirector sharedInstance].antiAliasingEnabled = YES;
	
	// Set the animation frame rate
	[[Isgl3dDirector sharedInstance] setAnimationInterval:1.0/24.0];

	// Add the OpenGL view to the view controller
	_glViewController.view = glView;
        
    // Make the opengl view transparent
	[Isgl3dDirector sharedInstance].openGLView.backgroundColor = [UIColor clearColor];
	[Isgl3dDirector sharedInstance].openGLView.opaque = NO;
	[Isgl3dDirector sharedInstance].backgroundColorString = @"00000000"; 
    
    // Set the device orientation
	[Isgl3dDirector sharedInstance].deviceOrientation = Isgl3dOrientationPortrait;	
        
    return YES;
}

- (void) dealloc {
	if (_glViewController) {
		[_glViewController release];
	}
	if (_window) {
		[_window release];
	}
	
	[super dealloc];
}

- (void) createViews {
	// Implement in sub-classes
}

- (void) applicationWillResignActive:(UIApplication *)application {
	[[Isgl3dDirector sharedInstance] pause];
}

- (void) applicationDidBecomeActive:(UIApplication *)application {
	[[Isgl3dDirector sharedInstance] resume];
}

- (void) applicationDidEnterBackground:(UIApplication *)application {
	[[Isgl3dDirector sharedInstance] stopAnimation];
}

- (void) applicationWillEnterForeground:(UIApplication *)application {
	[[Isgl3dDirector sharedInstance] startAnimation];
}

- (void) applicationWillTerminate:(UIApplication *)application {
	// Remove the OpenGL view from the view controller
	[[Isgl3dDirector sharedInstance].openGLView removeFromSuperview];
	
	// End and reset the director	
	[Isgl3dDirector resetInstance];
	
	// Release
	[_glViewController release];
	_glViewController = nil;
	[_window release];
	_window = nil;
}

- (void) applicationDidReceiveMemoryWarning:(UIApplication *)application {
	[[Isgl3dDirector sharedInstance] onMemoryWarning];
}

- (void) applicationSignificantTimeChange:(UIApplication *)application {
	[[Isgl3dDirector sharedInstance] onSignificantTimeChange];
}

@end
