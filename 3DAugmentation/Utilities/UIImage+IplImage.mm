//
//  UIImage+IplImage.m
//  PhotoVitrage
//
//  Created by Alexandr Stepanov on 01.08.11.
//  Copyright 2011 Home,sweet home. All rights reserved.
//

#import "UIImage+IplImage.h"


@implementation UIImage(IplImageAdditions)

+ (IplImage *)CreateIplImageFromUIImage:(UIImage *)image isGray:(BOOL)grayFlag {
	CGImageRef imageRef = image.CGImage;
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	IplImage *iplimage = cvCreateImage(cvSize(image.size.width, image.size.height), IPL_DEPTH_8U, 4);
	CGContextRef contextRef = CGBitmapContextCreate(iplimage->imageData, iplimage->width, iplimage->height,
													iplimage->depth, iplimage->widthStep,
													colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault);
	CGContextDrawImage(contextRef, CGRectMake(0, 0, image.size.width, image.size.height), imageRef);
	CGContextRelease(contextRef);
	CGColorSpaceRelease(colorSpace);
	
	IplImage *ret = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, (grayFlag ? 1 : 3));
	cvCvtColor(iplimage, ret, (grayFlag ? CV_RGB2GRAY : CV_RGBA2RGB));
	cvReleaseImage(&iplimage);
	
	return ret;
}

// NOTE You should convert color mode as RGB before passing to this function
+ (UIImage *)UIImageFromIplImage:(IplImage *)image isGray:(BOOL)grayFlag {
//	ARLog(@"IplImage (%d, %d) %d bits by %d channels, %d bytes/row %s", image->width, image->height, image->depth, image->nChannels, image->widthStep, image->channelSeq);
	
	CGColorSpaceRef colorSpace = (grayFlag ? CGColorSpaceCreateDeviceGray() : CGColorSpaceCreateDeviceRGB());
	NSData *data = [[NSData alloc] initWithBytes:image->imageData length:image->imageSize];
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
	CGImageRef imageRef = CGImageCreate(image->width, image->height,
										image->depth, image->depth * image->nChannels, image->widthStep,
										colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault,
										provider, NULL, false, kCGRenderingIntentDefault);
	UIImage *ret = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	CGDataProviderRelease(provider);
	CGColorSpaceRelease(colorSpace);
    [data release];
    
	return ret;
}


@end
