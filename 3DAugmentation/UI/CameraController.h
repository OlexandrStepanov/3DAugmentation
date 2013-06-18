//
//  CameraController.h
//  ARWorld
//
//  Created by Alexandr Stepanov on 21.09.11.
//  Copyright 2011 Home,sweet home. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

@protocol CameraControllerDelegate 

- (void)processFrame:(IplImage*)mat videoRect:(CGRect)rect
    videoOrientation:(AVCaptureVideoOrientation)orientation;

@end

@class TKLoadingView;
@interface CameraController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate> {
    
    TKLoadingView *                 _loadingAlertView;
    
    IplImage *                      _capturedImage;
    
    AVCaptureVideoDataOutput *      _videoOutput;
    
    UILabel *                       _fpsDebugLabel;
}

@property (nonatomic, assign) id<CameraControllerDelegate> mainController;
@property (nonatomic, retain) AVCaptureSession * captureSession;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer * previewLayer;

@property (nonatomic, retain) UIImage *imageFromCamera;
@property (nonatomic) BOOL saveImageFromCamera;

//NOTE: You should to release returned image
//- (IplImage*)getCapturedImage;

@end
