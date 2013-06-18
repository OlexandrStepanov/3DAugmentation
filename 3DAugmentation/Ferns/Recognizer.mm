//
//  Recognizer.m
//  ARWorld
//
//  Created by Alexandr Stepanov on 28.09.11.
//  Copyright 2011 Home,sweet home. All rights reserved.
//

#import "Recognizer.h"
#import "ControlWizzard.h"
#import "UIImage+IplImage.h"
#import "Notifications.h"

#define INLIER_POINTS_THRESHOLD 2

#include "timeDebug.h"
#include "highgui.h"
#include "planar_pattern_detector_builder.h"
#include "template_matching_based_tracker.h"
#include "homography06.h"

#include "CameraIntrinsicMatrix.h"

@implementation Recognizer

@synthesize wasInitialized;
@synthesize delegate;
@synthesize lastFrameSize;
@synthesize videoFrame=_videoFrame;
@synthesize trackingThreadPriority;

- (void)dealloc {
    delete detector;
    delete tracker;
    
    [_polygonHomographyLock release];
    
    [super dealloc];
}


- (id)initWithModelName:(NSString*)modelName
{
    if ((self = [super init])) {
        // Initialization code here.
        ARLog(@"Initializing pattern detector with model = %@", modelName);
        self.wasInitialized = YES;

        detector = planar_pattern_detector_builder::just_load([[NSString stringWithFormat:@"%@.detector_data", modelName] 
                                                               cStringUsingEncoding:NSASCIIStringEncoding]);
        if (detector) {
            detector->ransac_threshold = 10.0;  //  Lower threshold - harder to build plane
            detector->ransac_iterations_number = 2000;
            
            if (DEBUG_IS_ON) {
                detector->model_image = cvLoadImage([modelName cStringUsingEncoding:NSASCIIStringEncoding]);
            }
            
            self.wasInitialized = YES;
            ARLog(@"Detector was initialized");
        }
        else {
            ARLog(@"ERROR! Initializing detector with model = %@ failed", modelName);
            self.wasInitialized = NO;
        }
        
        if (self.wasInitialized) {
            
    //      Initialize tracker
            ARLog(@"Initializing tracker with model = %@", modelName);
            tracker = new template_matching_based_tracker();
            string trackerfn = string([modelName cStringUsingEncoding:NSASCIIStringEncoding])
                                + string(".tracker_data");
            if (!tracker->load(trackerfn.c_str())) {
                ARLog(@"ERROR! Initializing tracker with model = %@ failed", modelName);
                self.wasInitialized = NO;
            }
            tracker->initialize();
        }
        
        lastHomography = NULL;
        _polygonHomographyLock = [[NSLock alloc] init];
        
        _framesWithTracking = 0;
        _inlierPointsCount = 0;
        
        self.videoFrame = CGRectMake(0.0, 0.0, detector->modelWidth, detector->modelHeight);
    }
    
    return self;
}

#pragma mark - Method to override

- (BOOL)detectOnImage:(IplImage*)curFrame {
    BOOL funcResult;
    CGPoint *rectPoints = _polygon;
    
    if (!_isTracking) {
        ARLog(@"Start detecting new frame");
        
        if (detector->detect(curFrame)) {
            _inlierPointsCount = detector->number_of_matches;
            assert(_inlierPointsCount>0);
            funcResult = YES;
            
            ARLog(@"Detecting succeed, inlierPointsCount = %d", _inlierPointsCount);
            tracker->initialize(detector->detected_u_corner[0], detector->detected_v_corner[0],
                                detector->detected_u_corner[1], detector->detected_v_corner[1],
                                detector->detected_u_corner[2], detector->detected_v_corner[2],
                                detector->detected_u_corner[3], detector->detected_v_corner[3]);
                
            _framesWithTracking = 0;
            
            [_polygonHomographyLock lock];
            {
                rectPoints[0] = CGPointMake(detector->detected_u_corner[0], detector->detected_v_corner[0]);
                rectPoints[1] = CGPointMake(detector->detected_u_corner[1], detector->detected_v_corner[1]);
                rectPoints[2] = CGPointMake(detector->detected_u_corner[2], detector->detected_v_corner[2]);
                rectPoints[3] = CGPointMake(detector->detected_u_corner[3], detector->detected_v_corner[3]);
                        
                lastHomography = (&detector->H);
                lastTransform = [ControlWizzard convertHomographyToTransform:lastHomography];
            }   
            [_polygonHomographyLock unlock];                  
            _isTracking = YES;
        } 
        else {
            ARLog(@"Detecting failed");
            funcResult = NO;
        }
        
//      Save result of detection
        if (DEBUG_IS_ON) {
            IplImage *debugCVImage = detector->create_image_of_matches();
            if (debugCVImage)
                [self.delegate updateDebugImage:[UIImage UIImageFromIplImage:debugCVImage isGray:NO] isTracking:NO];
        }
    }
    else {
        // Call tracking algorithm
        clock_t timer;
        startTimer(&timer);
        
        ARLog(@"Start tracking object in new frame");
        if (tracker->track(curFrame)) {
            ARLog(@"Tracking succeed");
            _framesWithTracking++;
            
            [_polygonHomographyLock lock];
            
                rectPoints[0] = CGPointMake(tracker->u[0], tracker->u[1]);
                rectPoints[1] = CGPointMake(tracker->u[2], tracker->u[3]);
                rectPoints[2] = CGPointMake(tracker->u[4], tracker->u[5]);
                rectPoints[3] = CGPointMake(tracker->u[6], tracker->u[7]);

                lastHomography = (CvMat*)tracker->he;
            
                CATransform3D newTransform = [ControlWizzard convertHomographyToTransform:lastHomography];
                float changeRate = [ControlWizzard getChangeRateBetweenTransform1:lastTransform and2:newTransform];
                lastTransform = newTransform;
            
            [_polygonHomographyLock unlock];
            
//          cout << "Last homography: " << tracker->f << endl;
                        
            if (DEBUG_IS_ON) {
                [self.delegate updateDebugImage:nil isTracking:YES];
            }
             
            if (_framesWithTracking>=3)
                ARLog(@"DELTA OF TRANSFORMS: %0.5f", changeRate);
            
//            First 5 frames we track without check on threshold
            if (_framesWithTracking<3 || (changeRate < THRESHOLD_TRANSFORM_OBJECT_LOST)) {
                funcResult = YES;
            }
            else {
//                funcResult = YES;
                [self.delegate transformThresholdOverheaded:[NSNumber numberWithFloat:changeRate]];
                ARLog(@"TRANSFORM THRESHOLD OVERHEADED");
                
                funcResult = NO;
                _isTracking = NO;
            }
        }
        else {
            ARLog(@"Tracking failed - object lost");
            _isTracking = NO;
            funcResult = NO;
        }
        
        printTimerWithPrefix((char*)"Tracking", timer);
    }
    
    return funcResult;
}

#pragma mark - 3D Pose Estimation

- (void)buildModelViewMatrixUseOld:(BOOL)useOld {
    clock_t timer;
    startTimer(&timer);
    
    CvMat cvCameraMatrix = cvMat( 3, 3, CV_32FC1, (void*)cameraMatrix );
//    CvMat cvDistMatrix = cvMat(1, 5, CV_32FC1, (void*)distCoeff);
    
    CvMat* objectPoints = cvCreateMat( 4, 3, CV_32FC1 );
    CvMat* imagePoints = cvCreateMat( 4, 2, CV_32FC1 );
    
    if (!_isTracking) {
        int minDimenstion = MIN(detector->modelWidth, detector->modelHeight)*0.5f;
        for (int i=0; i<4; i++) {
            float objectX = (detector->u_corner[i] - detector->modelWidth/2.0f)/minDimenstion;
            float objectY = (detector->v_corner[i] - detector->modelHeight/2.0f)/minDimenstion;
            
            cvmSet(objectPoints, i, 0, objectX);
            cvmSet(objectPoints, i, 1, objectY);
            cvmSet(objectPoints, i, 2, 0.f);
            cvmSet(imagePoints, i, 0, detector->detected_u_corner[i]);
            cvmSet(imagePoints, i, 1, detector->detected_v_corner[i]);
        }
    }
    else {
        int minDimenstion = MIN(tracker->modelWidth, tracker->modelHeight)*0.5f;
        for (int i=0; i<4; i++) {
            float objectX = (tracker->u0[i*2] - tracker->modelWidth/2.0f)/minDimenstion;
            float objectY = (tracker->u0[i*2+1] - tracker->modelHeight/2.0f)/minDimenstion;
            
            cvmSet(objectPoints, i, 0, objectX);
            cvmSet(objectPoints, i, 1, objectY);
            cvmSet(objectPoints, i, 2, 0.f);
            cvmSet(imagePoints, i, 0, tracker->u[i*2]);
            cvmSet(imagePoints, i, 1, tracker->u[i*2+1]);
        }
    }
    
    CvMat* rvec = cvCreateMat(1, 3, CV_32FC1);
    CvMat* tvec = cvCreateMat(1, 3, CV_32FC1);
    CvMat* rotMat = cvCreateMat(3, 3, CV_32FC1);
    
    cvFindExtrinsicCameraParams2(objectPoints, imagePoints, &cvCameraMatrix, NULL,
                                 rvec, tvec);
//    if (DEBUG_IS_ON) {
//        [[NSNotificationCenter defaultCenter] postNotification:
//         [NSNotification notificationWithName:kDebugInformationTranslationVector
//                                       object:nil
//                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
//           [NSNumber numberWithFloat:CV_MAT_ELEM(*tvec, float, 0, 0)], @"x",
//           [NSNumber numberWithFloat:CV_MAT_ELEM(*tvec, float, 0, 1)], @"y", 
//           [NSNumber numberWithFloat:CV_MAT_ELEM(*tvec, float, 0, 2)], @"z", nil]]];
//    }
    
//    Convert it 
    CV_MAT_ELEM(*rvec, float, 0, 1) *= -1.0;
    CV_MAT_ELEM(*rvec, float, 0, 2) *= -1.0;
    
    cvRodrigues2(rvec, rotMat);
    
    GLfloat RTMat[16] = {cvmGet(rotMat, 0, 0), cvmGet(rotMat, 1, 0), cvmGet(rotMat, 2, 0), 0.0f,
                        cvmGet(rotMat, 0, 1), cvmGet(rotMat, 1, 1), cvmGet(rotMat, 2, 1), 0.0f,
                        cvmGet(rotMat, 0, 2), cvmGet(rotMat, 1, 2), cvmGet(rotMat, 2, 2), 0.0f,
                        cvmGet(tvec, 0, 0)  , -cvmGet(tvec, 0, 1), -cvmGet(tvec, 0, 2),    1.0f};
    
//    ARLog(@"ModelView Matrix:");
    for (int i=0; i<16; i++) {
        _modelViewMatrix[i] = RTMat[i];
//        printf("%f, ", _modelViewMatrix[i]);
//        if (i%4 == 3)
//            printf("\n");
    }
    
    cvReleaseMat(&objectPoints);
    cvReleaseMat(&imagePoints);
    cvReleaseMat(&rvec);
    cvReleaseMat(&tvec);
    cvReleaseMat(&rotMat);
    
    printTimerWithPrefix((char*)"ModelView matrix computation", timer);
}

- (GLfloat*)getModelViewMatrix {
    return _modelViewMatrix;
}



@end
