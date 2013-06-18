//
//  highgui.h
//  ARWorld
//
//  Created by Alexandr Stepanov on 26.09.11.
//  Copyright 2011 Home,sweet home. All rights reserved.
//

#ifndef ARWorld_highgui_h
#define ARWorld_highgui_h

#include "opencv2/core/core_c.h"
#include "opencv2/core/core.hpp"

enum
{
    /* 8bit, color or not */
	CV_LOAD_IMAGE_UNCHANGED  =-1,
    /* 8bit, gray */
	CV_LOAD_IMAGE_GRAYSCALE  =0,
    /* ?, color */
	CV_LOAD_IMAGE_COLOR      =1,
    /* any depth, ? */
	CV_LOAD_IMAGE_ANYDEPTH   =2,
    /* ?, any color */
	CV_LOAD_IMAGE_ANYCOLOR   =4
};


CVAPI(int) cvSaveImage(const char * filename, IplImage * image);
CVAPI(IplImage*) cvLoadImage(const char * filename, int code CV_DEFAULT(CV_LOAD_IMAGE_COLOR));
CVAPI(IplImage*) cvRotateImageFromCamera(IplImage* image);
CVAPI(void) BGRAToGreyConversion(IplImage *src, IplImage *dest);

#endif
