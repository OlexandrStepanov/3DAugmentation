//
//  RecognizerBase.m
//  ArtAndAR
//
//  Created by Alexandr Stepanov on 22.12.11.
//  Copyright (c) 2011 Home,sweet home. All rights reserved.
//

#include "timeDebug.h"
#include "highgui.h"

#import "Notifications.h"
#import "RecognizerBase.h"
#import "UIImage+IplImage.h"

@implementation RecognizerBase

@synthesize delegate=_delegate;
@synthesize recognitionTimer=_recognitionTimer;
@synthesize lastFrameSize=_lastFrameSize;
@synthesize defaultThreadPriority=_defaultThreadPriority;

- (void)dealloc {
//    Here will be release _recognitionLoop
    [self stopRecognition];
    
    [_stateLock release];
    [_lastFrameSizeLock release];
    [_recognitionLoopLock release];
    self.recognitionTimer = nil;
    
    [super dealloc];
}

- (id)init {
    if ((self = [super init])) {
        _recognitionLoop = nil;
        _recognitionLoopLock = [[NSLock alloc] init];
        self.recognitionTimer = nil;
        
        _lastFrameSizeLock = [[NSLock alloc] init];
        self.lastFrameSize = CGSizeMake(1.0, 1.0);
        
        _stateLock = [[NSLock alloc] init];
        _recognizerState = RecognizerStateObjectNotFound;
        
        _isTracking = NO;
        _defaultThreadPriority = RECOGNITION_THREAD_PRIORITY;
    }
    
    return self;
}

#pragma mark - Thread logic

- (void)startRecognition {
    if (!self.delegate) {
        ARLog(@"ERROR: Start recognition without setting delegate");
        return;
    }
    
    BOOL flag;
    [_recognitionLoopLock lock];
        flag = (_recognitionLoop != nil);
    [_recognitionLoopLock unlock];
    if (flag)       //  _recognitionLoop != nil
        [self stopRecognition];
    
    self.recognitionTimer = [NSTimer timerWithTimeInterval:RECOGNITION_TIMER_INTERVAL target:self
                                                  selector:@selector(recognitionTimer:)
                                                  userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.recognitionTimer forMode:NSDefaultRunLoopMode];
    
    _recognitionLoop = [[NSThread alloc] initWithTarget:self selector:@selector(recognitionLoop) object:nil];
    [_recognitionLoop setName:@"Recognition thread"];
    [_recognitionLoop setThreadPriority:_defaultThreadPriority];
    [_recognitionLoop start];
}

- (void)stopRecognition {
    [self.recognitionTimer invalidate];
    self.recognitionTimer = nil;
    
    if (_recognitionLoop) {
        [_recognitionLoopLock lock];
            [_recognitionLoop cancel];
        [_recognitionLoopLock unlock];
        
        BOOL flag = YES;
        while (flag) {
            [_recognitionLoopLock lock];
                flag = (_recognitionLoop != nil);
            [_recognitionLoopLock unlock];
            
            [NSThread sleepForTimeInterval:0.05];
        }
    }
}

#pragma mark - To overwright

- (BOOL)detectOnImage:(IplImage*)image {
    ARLog(@"ERROR: detectOnImage: in %@ should be overwrighten", [self debugDescription]);
    return NO;
}

- (void)recognitionLoop {
    ARLog(@"ERROR: recognitionLoop: in %@ should be overwrighten", [self debugDescription]);
}

- (void)recognitionTimer:(NSTimer*)timer {
    ARLog(@"ERROR: recognitionTimer: in %@ should be overwrighten", [self debugDescription]);
}

                         

@end
