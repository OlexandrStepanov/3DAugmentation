//
//  LowPassMatrixFilter.h
//  3DAugmentation
//
//  Created by Alexandr Stepanov on 29.02.12.
//  Copyright (c) 2012 Home,sweet home. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LowPassMatrixFilter : NSObject {
	double filterConstant;
	GLfloat lastMatrix[16];
    GLfloat curMatrix[16];
    
}


-(id)initWithSampleRate:(double)rate cutoffFrequency:(double)freq;

- (GLfloat*)getCurrentMatrix;
- (void)addMatrix:(GLfloat*)matrix;
- (void)setMatrix:(GLfloat*)matrix;


@end
