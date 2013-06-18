//
//  CubeView.m
//  3DAugmentation
//
//  Created by Alexandr Stepanov on 27.02.12.
//  Copyright (c) 2012 Home,sweet home. All rights reserved.
//

#import "CubeView.h"
#import "LowPassMatrixFilter.h"

@interface CubeView(Private)
    - (void)setProjectionMatrix;
@end

@implementation CubeView

- (id) init {
	
	if ((self = [super init])) {
        
		// Create an Isgl3dMultiMaterialCube with random colors.
		_cube = [Isgl3dMultiMaterialCube cubeWithDimensionsAndRandomColors:1 height:1 depth:1 nSegmentWidth:2 nSegmentHeight:2 nSegmentDepth:2];
		// Add the cube to the scene.
		[self.scene addChild:_cube];
        [self.scene setTransformation:im4CreateIdentity()];
        
		// Schedule updates
		[self schedule:@selector(tick:)];
        
//        _cube.position = iv3(0.f, 0.f, 0.5f);
        _currentRotation = 0.0;
        
	}
	return self;
}

- (void) dealloc {
	[_cube release];
    
	[super dealloc];
}

- (void) tick:(float)dt {	
    [_modelLock lock];
    {
        [self updateModelViewMatrix];
        
        [_cube setTransformationFromOpenGLMatrix:[_filter getCurrentMatrix]];
        [_cube translateByValues:0.0 y:0.0 z:0.5];
        
//        [self.camera setViewMatrix:im4CreateFromOpenGL([_filter getCurrentMatrix])];
    }
    [_modelLock unlock];
    
    [_cube roll:_currentRotation];
    _currentRotation += 2.0;
}


@end
