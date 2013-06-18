//
//  RecognizerBase.h
//  ArtAndAR
//
//  Created by Alexandr Stepanov on 22.12.11.
//  Copyright (c) 2011 Home,sweet home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@protocol RecognizerDelegate 

- (void)updateDebugImage:(UIImage*)debugImage isTracking:(BOOL)flag;

// This is only for debugging
- (void)transformThresholdOverheaded:(NSNumber*)overhead;

@end

typedef enum RecognizerState{
    RecognizerStateObjectNotFound = 0,
    RecognizerStateObjectFound,
    RecognizerStateObjectLost
} RecognizerState; 


@interface RecognizerBase : NSObject {
    id<RecognizerDelegate>          _delegate;
    
    NSThread *                      _recognitionLoop;
    NSLock *                        _recognitionLoopLock;
    NSTimer *                       _recognitionTimer;
    
    CGSize                          _lastFrameSize;
    NSLock *                        _lastFrameSizeLock;
    
    NSLock *                        _stateLock;
    RecognizerState                 _recognizerState;
    
    BOOL                            _isTracking;
    
    float                           _defaultThreadPriority;
}

@property (nonatomic, assign) id<RecognizerDelegate> delegate;
@property (nonatomic, retain) NSTimer *recognitionTimer;
@property (nonatomic) CGSize lastFrameSize;
@property (nonatomic) float defaultThreadPriority;

- (void)startRecognition;
- (void)stopRecognition;

//NOTE: should be overrided in subclasses
- (BOOL)detectOnImage:(IplImage*)image;
- (void)recognitionTimer:(NSTimer*)timer;
- (void)recognitionLoop;

@end
