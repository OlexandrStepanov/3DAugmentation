//
//  MainViewController.m
//  ARWorld
//
//  Created by Alexandr Stepanov on 23.09.11.
//  Copyright 2011 Home,sweet home. All rights reserved.
//

#import "MainViewController.h"
#import "ControlWizzard.h"
#import "UIImage+Resize.h"
#import "UIImage+IplImage.h"
#import "Notifications.h"
#import "Recognizer.h"
#import "EAGLView.h"
#import "AppDelegate.h"
#import "Isgl3dViewController.h"
#import "CubeView.h"
#import "RunManView.h"

@interface MainViewController(Private)
    - (void)loadCameraView;
    - (void)showInitialTrackingFrame;
    - (void)showActionsSheet;
    - (void)initializeObjectRecognition;
    - (void)objectFound;
    - (void)objectLost;
@end

@implementation MainViewController

@synthesize recognitionIsOn;
@synthesize snapshot;
@synthesize isglView;

- (void)dealloc {
    [self stopRecognition];
    RELEASE_AND_NULIFY(_recognizer);
    
    [_glView release];
    [_cameraController release];
    [_debugImageView release];
    [_trackNotificationLabel release];
    self.snapshot = nil;
    
    [super dealloc];
}

#pragma mark - Initialization

- (id)init {
    if ((self=[super init])) {
        _cameraController = nil;
        _debugImageView = nil;
        _trackNotificationLabel = nil;
        _glView = nil;
                
        _recognizer = nil;
        self.recognitionIsOn = NO;
        self.snapshot = nil;
        
        _lostIterations = 0;
    }
    
    return self;
}

- (void)loadView {
    CGSize windowSize = [ControlWizzard windowBoundsSize];
    self.view = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, windowSize.width, windowSize.height)] autorelease];
    self.view.backgroundColor = [UIColor clearColor];
    
    [self loadCameraView];
    [self initializeObjectRecognition];
    
    _glView = nil;
//    _glView = [[EAGLView alloc] initWithFrame:CGRectMake(0.0, 0.0, windowSize.width, windowSize.height)];
//    [self.view addSubview:_glView];
//    [_glView startAnimation];
    
//    Create isGl3D View, and add it behind the camera
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [self addChildViewController:appDelegate.glViewController];
    self.isglView = appDelegate.glViewController.view;
    [self.view addSubview:self.isglView];
    
    _augmentedView = [CubeView view];
//    _augmentedView = [RunManView view];
    [[Isgl3dDirector sharedInstance] addView:_augmentedView];
    
    // Run the director
	[[Isgl3dDirector sharedInstance] run];
    [[Isgl3dDirector sharedInstance] stopAnimation];
    self.isglView.hidden = YES;
}

- (void)loadCameraView {
    _cameraController = [[CameraController alloc] init];
    _cameraController.mainController = self;
    [self addChildViewController:_cameraController];
    [self.view addSubview:_cameraController.view];
    
    if (DEBUG_IS_ON) {
        _debugImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 120, 180.0)];
        _debugImageView.image = nil;
        _debugImageView.backgroundColor = [UIColor blackColor];
        _debugImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.view addSubview:_debugImageView];
    }
    else {
        _debugImageView = nil;
    }
    
    _trackNotificationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 440.0, 320.0, 20.0)];
    _trackNotificationLabel.textAlignment = UITextAlignmentCenter;
    _trackNotificationLabel.textColor = [UIColor whiteColor];
    _trackNotificationLabel.backgroundColor = [UIColor clearColor];
    _trackNotificationLabel.text = @"";
    _trackNotificationLabel.font = [UIFont systemFontOfSize:16.0];
    [self.view addSubview:_trackNotificationLabel];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
//    if (DEBUG_IS_ON) {
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(performDebugNotification:)
//                                                     name:kDebugInformationTranslationVector object:nil];
//    }
    
    [self startObjectRecognition];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
        
    _objectFound = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self stopRecognition];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [self stopRecognition];
    RELEASE_AND_NULIFY(_recognizer);
    
    // Release any retained subviews of the main view.
    RELEASE_AND_NULIFY(_cameraController);
    RELEASE_AND_NULIFY(_trackNotificationLabel);
    RELEASE_AND_NULIFY(_debugImageView);
    RELEASE_AND_NULIFY(_glView);
    
//    [[Isgl3dDirector sharedInstance] end];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - RecognizerDelegate methods

- (void)updateDebugImage:(UIImage *)debugImage isTracking:(BOOL)isTracking {
    if (DEBUG_IS_ON && debugImage) {
        [_debugImageView performSelectorOnMainThread:@selector(setImage:)
                                          withObject:debugImage waitUntilDone:NO];
    }
}

- (void)transformThresholdOverheaded:(NSNumber*)overhead {
    if (DEBUG_IS_ON) {
        if (![NSThread isMainThread]) {
            [self performSelectorOnMainThread:@selector(transformThresholdOverheaded:) 
                                   withObject:overhead waitUntilDone:NO];
            return;
        }
        
        [_trackNotificationLabel setText:@"TRANSFORM OVERHEAD"];
        [self performSelector:@selector(eraseTrackNotificationLabel) withObject:nil afterDelay:1.0];
    }
    
//    Set _lostIterations to high value, to hide model immediately
    _lostIterations = 10;
}

#pragma mark Frame proccessing

- (void)processFrame:(IplImage*)image videoRect:(CGRect)rect
    videoOrientation:(AVCaptureVideoOrientation)orientation {
    //    Preccess frame only if recognition is on
    if (self.recognitionIsOn) {
        @synchronized(_recognizer){ 
            if ([_recognizer detectOnImage:image])
                [self objectFound];
            else
                [self objectLost];
        }
    }
}

- (void)objectFound {
    _lostIterations = 0;
    
//    Build model view matrix
    [_recognizer buildModelViewMatrixUseOld:_objectFound];
    
    BOOL forceSetFlag = NO;
    if (!_objectFound) {
        _objectFound = YES;
        forceSetFlag = YES;
        
        _glView.isVisible = YES;
        
        [[Isgl3dDirector sharedInstance] performSelectorOnMainThread:@selector(startAnimation) 
                                                          withObject:nil waitUntilDone:NO];
        [self performSelectorOnMainThread:@selector(hideUnHideGlView:)
                               withObject:[NSNumber numberWithBool:NO]
                            waitUntilDone:NO];
    }
    
    [_glView setModelViewMatrix:[_recognizer getModelViewMatrix]];
    [_augmentedView setModelViewMatrix:[_recognizer getModelViewMatrix] forceSet:forceSetFlag];
}

- (void)objectLost {    
    if (_objectFound && _lostIterations > 0) {
        _objectFound = NO;
        
        _glView.isVisible = NO;
        
        [[Isgl3dDirector sharedInstance] performSelectorOnMainThread:@selector(stopAnimation) 
                                                          withObject:nil waitUntilDone:NO];
        [self performSelectorOnMainThread:@selector(hideUnHideGlView:)
                               withObject:[NSNumber numberWithBool:YES]
                            waitUntilDone:NO];
    }
    
    _lostIterations++;
}

- (void)hideUnHideGlView:(NSNumber*)flag {
    self.isglView.hidden = [flag boolValue];
}


#pragma mark - Recognizer Initialization

- (void)initializeObjectRecognition {
    _trackNotificationLabel.text = @"Initializing. Please wait ...";
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(recognitionInitialized:) 
                                                 name:kRecognizerWasInitialized
                                               object:nil];
    [NSThread detachNewThreadSelector:@selector(initializeRecognizer) 
                             toTarget:self withObject:nil];
}

- (void)startObjectRecognition {    
    _trackNotificationLabel.text = @"Recognition started";
    [self performSelector:@selector(eraseTrackNotificationLabel) withObject:nil afterDelay:3.0];
    
    self.recognitionIsOn = YES;
}

- (void)stopRecognition {
    if (_recognizer) {
        @synchronized(_recognizer) {
//            Hide all elements
            [self objectLost];
            self.recognitionIsOn = NO;            
        }
    }
}

- (void)initializeRecognizer {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [NSThread setThreadPriority:INIT_RECOGNIZER_THREAD_PRIORITY];
    
    @synchronized(_recognizer) {
        _recognizer = [[Recognizer alloc] initWithModelName:
                       [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:MODEL_NAME]];
        _recognizer.delegate = self;
    }
     
    [[NSNotificationCenter defaultCenter] postNotificationName:kRecognizerWasInitialized object:nil];
    
    [pool release];
}

- (void)eraseTrackNotificationLabel {
    [_trackNotificationLabel setText:nil];
}

- (void)recognitionInitialized:(NSNotification*)notification {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(recognitionInitialized:)
                               withObject:notification waitUntilDone:NO];
        return;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kRecognizerWasInitialized
                                                  object:nil];
    
    _trackNotificationLabel.text = @"Initializing complete";
    [self performSelector:@selector(startObjectRecognition) withObject:nil afterDelay:0.8];
}

#pragma mark - Debug Notifications

- (void)performDebugNotification:(NSNotification*)notification {
    if ([[notification name] isEqualToString:kDebugInformationTranslationVector]) {
        NSDictionary *userInfo = [notification userInfo];
        NSString *string = [NSString stringWithFormat:@"t: %.1f, %.1f, %.1f", 
                            [[userInfo objectForKey:@"x"] floatValue], 
                            [[userInfo objectForKey:@"y"] floatValue],
                            [[userInfo objectForKey:@"z"] floatValue]];
        [_trackNotificationLabel performSelectorOnMainThread:@selector(setText:)
                                                  withObject:string
                                               waitUntilDone:NO];
    }
}

@end
