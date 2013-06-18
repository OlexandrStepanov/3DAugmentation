//
//  highgui.c
//  ARWorld
//
//  Created by Alexandr Stepanov on 26.09.11.
//  Copyright 2011 Home,sweet home. All rights reserved.
//

#include <cv.h>

#include "highgui.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UIImage+IplImage.h"

int cvSaveImage(const char * filename, IplImage * image) {
    
    return 0;
}

IplImage *cvLoadImage(const char * filename, int code CV_DEFAULT(CV_LOAD_IMAGE_COLOR)) {
    
    NSString *filePathNS = [[NSString alloc] initWithCString:filename encoding:NSASCIIStringEncoding];
    NSData *imageData = [[NSData alloc] initWithContentsOfFile:filePathNS];
    
    IplImage * result = [UIImage CreateIplImageFromUIImage:[UIImage imageWithData:imageData] isGray:!code];
    
    [filePathNS release];
    [imageData release];
    
    return result;
}

IplImage* cvRotateImageFromCamera(IplImage* image) {
    IplImage* result = cvCreateImage(cvSize(image->height, image->width), image->depth, image->nChannels);
    
//    This is 90 CW rotate performing by simple swaping pixels
    for (int i=0; i<image->height; i++) 
        for (int j=0; j<image->width; j++) {
            int imageIndex = i*image->width + j;
            int resultIndex = (image->height-1-i) + j*image->height;
            
            for (int k=0; k<image->nChannels; k++)
                result->imageData[image->nChannels*resultIndex + k] = image->imageData[image->nChannels*imageIndex + k];
        }
    
    return result;
}

static inline void neon_asm_convert(uint8_t * __restrict dest, uint8_t * __restrict src, int numPixels)
{
    __asm__ volatile("lsr %2, %2, #3 \n"
                     "# build the three constants: \n"
                     "mov r4, #28 \n" // Blue channel multiplier
                     "mov r5, #151 \n" // Green channel multiplier
                     "mov r6, #77 \n" // Red channel multiplier
                     "vdup.8 d4, r4 \n"
                     "vdup.8 d5, r5 \n"
                     "vdup.8 d6, r6 \n"
                     "0: \n"
                     "# load 8 pixels: \n"
                     "vld4.8 {d0-d3}, [%1]! \n"
                     "# do the weight average: \n"
                     "vmull.u8 q7, d0, d4 \n"
                     "vmlal.u8 q7, d1, d5 \n"
                     "vmlal.u8 q7, d2, d6 \n"
                     "# shift and store: \n"
                     "vshrn.u16 d7, q7, #8 \n" // Divide q3 by 256 and store in the d7
                     "vst1.8 {d7}, [%0]! \n"
                     "subs %2, %2, #1 \n" // Decrement iteration count
                     "bne 0b \n" // Repeat unil iteration count is not zero
                     :
                     : "r"(dest), "r"(src), "r"(numPixels)
                     : "r4", "r5", "r6"
                     );
}

CVAPI(void) BGRAToGreyConversion(IplImage *src, IplImage *dest) {
    int numPixels = src->width * src->height;
    neon_asm_convert((uint8_t*)dest->imageData, (uint8_t*)src->imageData, numPixels);
}
