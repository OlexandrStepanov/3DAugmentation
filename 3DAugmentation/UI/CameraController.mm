//
//  CameraController.m
//  ARWorld
//
//  Created by Alexandr Stepanov on 21.09.11.
//  Copyright 2011 Home,sweet home. All rights reserved.
//

#import "CameraController.h"
#import "ControlWizzard.h"
#import "Notifications.h"

#include "highgui.h"

@interface CameraController(_private)

- (void)setupCaptureSession;
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer;
- (void)stopCapture;

@end

@implementation CameraController

@synthesize captureSession, previewLayer;
@synthesize mainController;
@synthesize imageFromCamera, saveImageFromCamera;


-(void)dealloc {
    [self stopCapture];
    
    if (_capturedImage) {
        cvReleaseImage(&_capturedImage);
    }
        
    [_loadingAlertView release];
    self.imageFromCamera = nil;
    [_fpsDebugLabel release];
    
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        _loadingAlertView = nil;
        _capturedImage = NULL;
        
        self.mainController = nil;
        self.saveImageFromCamera = NO;
        self.imageFromCamera = nil;
    }
    
    return self;
}

- (void)loadView {
//    
    CGSize windowSize = [ControlWizzard windowBoundsSize];
    self.view = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, windowSize.width, windowSize.height)] autorelease];
    self.view.backgroundColor = [UIColor blackColor];
    
    _fpsDebugLabel = nil;
}

- (void)viewWillAppear:(BOOL)animated {    
    [self setupCaptureSession];
}

- (void)viewDidDisappear:(BOOL)animated {
//    Stop camera captioning
    [self stopCapture];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)shouldAutorotate {
    return NO;
}


#pragma mark Camera logic

- (void)setupCaptureSession  {
//	We need the frontal camera
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice: device 
																			   error:nil];
	_videoOutput = [[AVCaptureVideoDataOutput alloc] init];
	_videoOutput.minFrameDuration = CMTimeMake(1, 20);
	_videoOutput.alwaysDiscardsLateVideoFrames = YES; 
	dispatch_queue_t queue;
	queue = dispatch_queue_create("cameraQueue", NULL);
	[_videoOutput setSampleBufferDelegate:self queue:queue];
	dispatch_release(queue);
    
	NSDictionary* videoSettings = [NSDictionary dictionaryWithObjectsAndKeys: 
                                   [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange],
                                   (id)kCVPixelBufferPixelFormatTypeKey, nil];     
	[_videoOutput setVideoSettings:videoSettings]; 
	self.captureSession = [[[AVCaptureSession alloc] init] autorelease];
    
//    NOTE: If you change preset quality - change camera size in Notifications.h
	self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
    
	[self.captureSession addInput:captureInput];
	[self.captureSession addOutput:_videoOutput];	
    
//    Show camera overlay direct to view
    if (!self.previewLayer) {
        self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    }
    self.previewLayer.frame = self.view.bounds;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer: self.previewLayer];
    
    if (DEBUG_IS_ON) {
        _fpsDebugLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 40, 20, 40, 20)];
        _fpsDebugLabel.font = [UIFont systemFontOfSize:16];
        _fpsDebugLabel.textColor = [UIColor redColor];
        _fpsDebugLabel.backgroundColor = [UIColor clearColor];
        [self.view addSubview:_fpsDebugLabel];
    }
    
	[self.captureSession startRunning];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput 
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
	   fromConnection:(AVCaptureConnection *)connection { 
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    {
     
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CGRect videoRect = CGRectMake(0.0f, 0.0f, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
//        AVCaptureVideoOrientation videoOrientation = [[[_videoOutput connections] objectAtIndex:0] videoOrientation];
        AVCaptureVideoOrientation videoOrientation = AVCaptureVideoOrientationPortrait;
        
        // For grayscale mode, the luminance channel of the YUV data is used
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        void *baseaddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        
        cv::Mat *mat = new cv::Mat(videoRect.size.height, videoRect.size.width, CV_8UC1, baseaddress, 0);
        cv::transpose(*mat, *mat);
        cv::flip(*mat, *mat, 1);
        IplImage capturedImage = *mat;
        [self.mainController processFrame:&capturedImage videoRect:videoRect videoOrientation:videoOrientation];
        delete mat;
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0); 
        
        // FPS calculation
        if (DEBUG_IS_ON) {
            static CMTimeValue _lastFrameTimestamp = 0;
            CMTime presentationTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
            
            if (_lastFrameTimestamp == 0) {
                _lastFrameTimestamp = presentationTime.value;
            }
            else {
                float frameTime = (float)(presentationTime.value - _lastFrameTimestamp) / presentationTime.timescale;
                float fps = 1.0f / frameTime;
                _lastFrameTimestamp = presentationTime.value;
                NSLog(@"FPS: %f", fps);
                [_fpsDebugLabel performSelectorOnMainThread:@selector(setText:)
                                                 withObject:[NSString stringWithFormat:@"%f", fps]
                                              waitUntilDone:NO];
            }
        }
    }		
	[pool drain];
}

- (UIImage*) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer // Create a CGImageRef from sample buffer data
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer); 
    CVPixelBufferLockBaseAddress(imageBuffer,0);        // Lock the image buffer 
    
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);   // Get information of the image 
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
    size_t width = CVPixelBufferGetWidth(imageBuffer); 
    size_t height = CVPixelBufferGetHeight(imageBuffer); 
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
    
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst); 
    CGImageRef newImageCG = CGBitmapContextCreateImage(newContext); 
    CGContextRelease(newContext); 
    
    CGColorSpaceRelease(colorSpace); 
    CVPixelBufferUnlockBaseAddress(imageBuffer,0); 

    UIImage *result = [UIImage imageWithCGImage:newImageCG];
    CGImageRelease(newImageCG);
    
    
    return result;
}

- (void)stopCapture {
    [self.captureSession stopRunning];
    AVCaptureInput* input = [self.captureSession.inputs objectAtIndex:0];
    [self.captureSession removeInput:input];
    AVCaptureVideoDataOutput* output = [self.captureSession.outputs objectAtIndex:0];
    [self.captureSession removeOutput:output];
    [self.previewLayer removeFromSuperlayer];
    [_videoOutput release];
    
    if (DEBUG_IS_ON) {
        [_fpsDebugLabel removeFromSuperview];
        RELEASE_AND_NULIFY(_fpsDebugLabel);
    }
    
    self.previewLayer = nil;
    self.captureSession = nil;
}

@end
