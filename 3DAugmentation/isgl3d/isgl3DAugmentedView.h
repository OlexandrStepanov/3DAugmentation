//
//  isgl3DAugmentedView.h
//  3DAugmentation
//
//  Created by Alexandr Stepanov on 27.02.12.
//  Copyright (c) 2012 Home,sweet home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "isgl3d.h"

@class LowPassMatrixFilter;
@interface isgl3DAugmentedView : Isgl3dBasic3DView {
    NSLock *                  _modelLock;
    GLfloat             *     _lastModelViewMatrix;
    LowPassMatrixFilter *     _filter;
}

- (void)setProjectionMatrix;
- (void)setModelViewMatrix:(GLfloat*)matrix forceSet:(BOOL)forceSet;

- (void)updateModelViewMatrix;

@end
