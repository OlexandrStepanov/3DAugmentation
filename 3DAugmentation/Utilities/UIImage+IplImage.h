//
//  UIImage+IplImage.h
//  PhotoVitrage
//
//  Created by Alexandr Stepanov on 01.08.11.
//  Copyright 2011 Home,sweet home. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UIImage(IplImageAdditions)

+ (IplImage *)CreateIplImageFromUIImage:(UIImage *)image isGray:(BOOL)grayFlag;
+ (UIImage *)UIImageFromIplImage:(IplImage *)image isGray:(BOOL)grayFlag;

@end
