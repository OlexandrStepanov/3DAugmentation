//
//  Recognizer.h
//  ARWorld
//
//  Created by Alexandr Stepanov on 28.09.11.
//  Copyright 2011 Home,sweet home. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>

#import "RecognizerBase.h"

class planar_pattern_detector;
class template_matching_based_tracker;


@interface Recognizer : RecognizerBase {
    planar_pattern_detector *        detector;
    template_matching_based_tracker *tracker;
    
@public
    CvMat *                         lastHomography;
    CATransform3D                   lastTransform;
    int                             _framesWithTracking;
    int                             _inlierPointsCount;
    
    NSLock *                        _polygonHomographyLock;
    CGPoint                         _polygon[4];
        
    CGRect                          _videoFrame;
    
    GLfloat                         _modelViewMatrix[16];
}

@property (nonatomic) BOOL wasInitialized;
@property (nonatomic) CGRect videoFrame;
@property (atomic) float trackingThreadPriority;


- (id)initWithModelName:(NSString*)modelName;
- (BOOL)detectOnImage:(IplImage*)curFrame;

- (void)buildModelViewMatrixUseOld:(BOOL)useOld;
- (GLfloat*)getModelViewMatrix;

@end
