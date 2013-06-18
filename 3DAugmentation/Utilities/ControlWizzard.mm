//
//  ControlWizzard.m
//  ArtAndAR
//
//  Created by Alexandr Stepanov on 20.12.11.
//  Copyright (c) 2011 Home,sweet home. All rights reserved.
//

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>


#import "ControlWizzard.h"
#import "AppDelegate.h"
#import "Notifications.h"

@implementation ControlWizzard

float getDistanceBetweenPoints(CGPoint first, CGPoint second) {
    return sqrtf((first.x-second.x)*(first.x-second.x) + (first.y-second.y)*(first.y-second.y));
}

+ (UIAlertView*)alertWithTitle:(NSString *)title
					   message:(NSString *)message 
					  delegate:(id)delegate 
			 cancelButtonTitle:(NSString *)cancelButtonTitle 
			  otherButtonTitle:(NSString *)otherButtonTitle {
	
	UIAlertView *alert;
	if (otherButtonTitle)
		alert = [[[UIAlertView alloc] initWithTitle:title
											message:message
										   delegate:delegate 
								  cancelButtonTitle:cancelButtonTitle
								  otherButtonTitles:otherButtonTitle, nil] autorelease];
	else
        alert = [[[UIAlertView alloc] initWithTitle:title
                                            message:message
                                           delegate:delegate 
                                  cancelButtonTitle:cancelButtonTitle
                                  otherButtonTitles:nil] autorelease];
    
    
	
	[alert show];
	return alert;
}

+ (NSString*)CATransform3DToNSString:(CATransform3D)transform {
    return CATransform3DIsIdentity(transform)
    ? @"CATransform3DIdentity"
    : [NSString stringWithFormat:@"[%.4f %.4f %.4f %.4f;\n %.4f %.4f %.4f %.4f;\n %.4f %.4f %.4f %.4f;\n %.4f %.4f %.4f %.4f]",
       transform.m11, transform.m12, transform.m13, transform.m14, 
       transform.m21, transform.m22, transform.m23, transform.m24, 
       transform.m31, transform.m32, transform.m33, transform.m34, 
       transform.m41, transform.m42, transform.m43, transform.m44];
}

+ (CATransform3D)CATransform3DNormalized:(CATransform3D)transform {
    CATransform3D result;
    
    double normalizer = 1.0/transform.m44;
    
    result.m11 = (float)(transform.m11*normalizer);
    result.m12 = (float)(transform.m12*normalizer);
    result.m13 = (float)(transform.m13*normalizer);
    result.m14 = (float)(transform.m14*normalizer);
    
    result.m21 = (float)(transform.m21*normalizer);
    result.m22 = (float)(transform.m22*normalizer);
    result.m23 = (float)(transform.m23*normalizer);
    result.m24 = (float)(transform.m24*normalizer);
    
    result.m31 = (float)(transform.m31*normalizer);
    result.m32 = (float)(transform.m32*normalizer);
    result.m33 = (float)(transform.m33*normalizer);
    result.m34 = (float)(transform.m34*normalizer);
    
    result.m41 = (float)(transform.m41*normalizer);
    result.m42 = (float)(transform.m42*normalizer);
    result.m43 = (float)(transform.m43*normalizer);
    result.m44 = 1.0;
    
    return result;
}

+ (CATransform3D)convertHomographyToTransform:(CvMat*)homography {
    CATransform3D result;
    
    result.m11 = homography->data.fl[0];
    result.m21 = homography->data.fl[1];
    result.m31 = 0.0;
    result.m41 = homography->data.fl[2];
    
    result.m12 = homography->data.fl[3];
    result.m22 = homography->data.fl[4];
    result.m32 = 0.0;
    result.m42 = homography->data.fl[5];
    
    result.m13 = 0.0;
    result.m23 = 0.0;
    result.m33 = 0.0;
    result.m43 = 0.0;
    
    result.m14 = homography->data.fl[6];
    result.m24 = homography->data.fl[7];
    result.m34 = 0.0;
    result.m44 = homography->data.fl[8];
    
    //    Normalize, so m44 = 1.0
    result = [ControlWizzard CATransform3DNormalized:result];
    result.m33 = 1.0;
    
    return result;
}

+ (CGSize)windowBoundsSize {
    AppDelegate *appDelegate = APPDELEGATE;
    CGSize windowBoundsSize = appDelegate.window.bounds.size;
    
    return windowBoundsSize;
}


+ (float)getSquareOfTriangleWith1stPoint:(CGPoint)first
                                  second:(CGPoint)second
                                   third:(CGPoint)third {
    float result = 0.5 * fabsf((second.x - first.x)*(third.y - first.y) - (third.x - first.x)*(second.y - first.y));
    return result;
}

+ (float)getChangeRateBetweenTransform1:(CATransform3D)transform1 and2:(CATransform3D)transform2 {
    
    return sqrtf((transform1.m11 - transform2.m11)*(transform1.m11 - transform2.m11) +
                 (transform1.m12 - transform2.m12)*(transform1.m12 - transform2.m12) +
                 (transform1.m14 - transform2.m14)*(transform1.m14 - transform2.m14) +
                 (transform1.m21 - transform2.m21)*(transform1.m21 - transform2.m21) +
                 (transform1.m22 - transform2.m22)*(transform1.m22 - transform2.m22) +
                 (transform1.m24 - transform2.m24)*(transform1.m24 - transform2.m24));
}

+ (BOOL)isiPad {
    if ([[UIDevice currentDevice] respondsToSelector: @selector(userInterfaceIdiom)])
        return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
//  else
    return NO;
}

+ (NSString*)xibForCurrentDevice:(NSString*)name {
    return [NSString stringWithFormat:@"%@-%@", name, (IS_IPAD ? @"iPad" : @"iPhone")];
}

@end
