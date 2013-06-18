//
//  CubeView.h
//  3DAugmentation
//
//  Created by Alexandr Stepanov on 27.02.12.
//  Copyright (c) 2012 Home,sweet home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "isgl3DAugmentedView.h"

@interface CubeView : isgl3DAugmentedView {
	Isgl3dMultiMaterialCube * _cube;
    GLfloat                   _currentRotation;
}

@end
