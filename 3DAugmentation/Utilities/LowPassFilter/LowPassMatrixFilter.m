//
//  LowPassMatrixFilter.m
//  3DAugmentation
//
//  Created by Alexandr Stepanov on 29.02.12.
//  Copyright (c) 2012 Home,sweet home. All rights reserved.
//

#import "LowPassMatrixFilter.h"

@implementation LowPassMatrixFilter

- (void)dealloc {
    [super dealloc];
}

-(id)initWithSampleRate:(double)rate cutoffFrequency:(double)freq {
    self = [super init];
	if(self != nil)
	{
		double dt = 1.0 / rate;
		double RC = 1.0 / freq;
		filterConstant = dt / (dt + RC);
        
        for (int i=0; i<16; i++) {
            curMatrix[i] = 0.0;
        }
	}
	return self;
}

- (GLfloat*)getCurrentMatrix {
    return curMatrix;
}

-(void)addMatrix:(GLfloat*)matrix {
    double alpha = filterConstant;
	
    for (int i=0; i<16; i++) {
        curMatrix[i] = matrix[i] * alpha + curMatrix[i] * (1.0 - alpha);
    }
}

- (void)setMatrix:(GLfloat*)matrix {
    memcpy(curMatrix, matrix, sizeof(GLfloat)*16);
}


@end
