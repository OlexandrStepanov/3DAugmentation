//
//  ControlWizzard.h
//  ArtAndAR
//
//  Created by Alexandr Stepanov on 20.12.11.
//  Copyright (c) 2011 Home,sweet home. All rights reserved.
//

#define IS_IPAD [ControlWizzard isiPad]

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>


@interface ControlWizzard : NSObject

+ (UIAlertView*)alertWithTitle:(NSString *)title
					   message:(NSString *)message 
					  delegate:(id)delegate 
			 cancelButtonTitle:(NSString *)cancelButtonTitle 
			  otherButtonTitle:(NSString *)otherButtonTitle;

+ (CGSize)windowBoundsSize;

+ (CATransform3D)convertHomographyToTransform:(CvMat*)homography;
+ (NSString*)CATransform3DToNSString:(CATransform3D)transform;
+ (CATransform3D)CATransform3DNormalized:(CATransform3D)transform;

+ (float)getSquareOfTriangleWith1stPoint:(CGPoint)first second:(CGPoint)second third:(CGPoint)third;

+ (float)getChangeRateBetweenTransform1:(CATransform3D)transform1 and2:(CATransform3D)transform2;

+ (BOOL)isiPad;
+ (NSString*)xibForCurrentDevice:(NSString*)name;


@end
