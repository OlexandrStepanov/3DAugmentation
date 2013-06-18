//
//  isgl3DAugmentedView.m
//  3DAugmentation
//
//  Created by Alexandr Stepanov on 27.02.12.
//  Copyright (c) 2012 Home,sweet home. All rights reserved.
//

#import "isgl3DAugmentedView.h"
#include "CameraIntrinsicMatrix.h"
#include "Notifications.h"
#include "LowPassMatrixFilter.h"


@implementation isgl3DAugmentedView

- (void)dealloc {
    [_modelLock release];
    free(_lastModelViewMatrix);
    [_filter release];
    
    [super dealloc];
}

- (id) init {
    if ((self = [super init])) {
        _modelLock = [[NSLock alloc] init];
        _lastModelViewMatrix = malloc(sizeof(GLfloat)*16);
        _filter = [[LowPassMatrixFilter alloc] initWithSampleRate:30.0 cutoffFrequency:5.0];
        
        //        Prepare camera
        self.camera.isTargetCamera = NO;
        [self setProjectionMatrix];
        
        [self.camera setTransformation:im4CreateIdentity()];
        [self.camera setViewMatrix:im4CreateIdentity()];
    }
    
    return self;
}

- (void)setProjectionMatrix {
    GLfloat matrix[16];
    
    // Camera parameters
    double f_x = cameraMatrix[0]; // Focal length in x axis
    double f_y = cameraMatrix[4]; // Focal length in y axis (usually the same?)
    double c_x = cameraMatrix[2]; // Camera primary point x
    double c_y = cameraMatrix[5]; // Camera primary point y
    
    double screen_width = CAMERA_WIDTH; // In pixels
    double screen_height = CAMERA_HEIGHT; // In pixels
    
    double near = 0.1;  // Near clipping distance
    double far = 1000;  // Far clipping distance
    
    matrix[0] = 2.0 * f_x / screen_width;
	matrix[1] = 0.0;
	matrix[2] = 0.0;
	matrix[3] = 0.0;
    
	matrix[4] = 0.0;
	matrix[5] = 2.0 * f_y / screen_height;
	matrix[6] = 0.0;
	matrix[7] = 0.0;
	
	matrix[8] = 2.0 * c_x / screen_width - 1.0;
	matrix[9] = 2.0 * c_y / screen_height - 1.0;	
	matrix[10] = -( far+near ) / ( far - near );
	matrix[11] = -1.0;
    
	matrix[12] = 0.0;
	matrix[13] = 0.0;
	matrix[14] = -2.0 * far * near / ( far - near );		
	matrix[15] = 0.0;
    
    
    self.camera.projectionMatrix = im4Create(matrix[0], matrix[1], matrix[2], matrix[3], matrix[4], matrix[5], matrix[6], matrix[7], matrix[8], matrix[9], matrix[10], matrix[11], matrix[12], matrix[13], matrix[14], matrix[15]);
}

- (void)setModelViewMatrix:(GLfloat*)matrix forceSet:(BOOL)forceSet {
    //    ARLog(@"In CubeView setModelViewMatrix:");
    [_modelLock lock];
        memcpy(_lastModelViewMatrix, matrix, sizeof(GLfloat)*16);
        if (forceSet)
            [_filter setMatrix:matrix];
    [_modelLock unlock];
}

- (void)updateModelViewMatrix {
    [_filter addMatrix:_lastModelViewMatrix];
}

@end
