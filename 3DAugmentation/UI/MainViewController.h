//
//  MainViewController.h
//  ARWorld
//
//  Created by Alexandr Stepanov on 23.09.11.
//  Copyright 2011 Home,sweet home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "CameraController.h"
#import "Recognizer.h"

@class EAGLView;
@class isgl3DAugmentedView;
@interface MainViewController : UIViewController<RecognizerDelegate, CameraControllerDelegate> {
    CameraController *              _cameraController;

    UIImageView *                   _debugImageView;
    UILabel *                       _trackNotificationLabel;
    
    EAGLView *                      _glView;
    
    isgl3DAugmentedView *           _augmentedView;
    
    Recognizer *                    _recognizer;
    BOOL                            _objectFound;
    BOOL                            _modelWasShowed;
    
    int                             _lostIterations;
}

@property (atomic) BOOL recognitionIsOn;
@property (nonatomic, retain) UIImage *snapshot;
@property (nonatomic, assign) UIView *isglView;

- (void)startObjectRecognition;
- (void)stopRecognition;

@end
