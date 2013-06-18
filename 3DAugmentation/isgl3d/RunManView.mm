//
//  RunManView.m
//  3DAugmentation
//
//  Created by Alexandr Stepanov on 27.02.12.
//  Copyright (c) 2012 Home,sweet home. All rights reserved.
//

#import "RunManView.h"
#import "Isgl3dPODImporter.h"
#import "LowPassMatrixFilter.h"

@implementation RunManView

- (id) init {
	
	if ((self = [super init])) {        
		// Enable shadow rendering
		[Isgl3dDirector sharedInstance].shadowRenderingMethod = Isgl3dShadowPlanar;
		[Isgl3dDirector sharedInstance].shadowAlpha = 0.4;
        
		Isgl3dPODImporter * podImporter = [Isgl3dPODImporter podImporterWithFile:@"man.pod"];
		
		// Modify texture files
		[podImporter modifyTexture:@"body.bmp" withTexture:@"Body.pvr"];
		[podImporter modifyTexture:@"legs.bmp" withTexture:@"Legs.pvr"];
		[podImporter modifyTexture:@"belt.bmp" withTexture:@"Belt.pvr"];
        
		// Create skeleton node	
		Isgl3dSkeletonNode * skeleton = [self.scene createSkeletonNode];
        _skeleton = [skeleton retain];
		
		// Add meshes to skeleton
		[podImporter addMeshesToScene:skeleton];
		[skeleton setAlphaWithChildren:1.0];
		[podImporter addBonesToSkeleton:skeleton];
		[skeleton enableShadowCastingWithChildren:YES];
        
		// Add animation controller
		_animationController = [[Isgl3dAnimationController alloc] initWithSkeleton:skeleton andNumberOfFrames:[podImporter numberOfFrames]];
		[_animationController start];
            
		// Schedule updates
		[self schedule:@selector(tick:)];
        
        [self.scene setTransformation:im4CreateIdentity()];
	}
	
	return self;
}

- (void) dealloc {
	[_animationController release];
    [_skeleton release];
    
	[super dealloc];
}


- (void) tick:(float)dt {
    [_modelLock lock];
    {
        [self updateModelViewMatrix];
        
        [_skeleton setTransformationFromOpenGLMatrix:[_filter getCurrentMatrix]];
        [_skeleton setScale:0.01f];
        [_skeleton pitch:90.0];
    }
    [_modelLock unlock];
}


@end
