//
//  Islg3dResponseDelegate.h
//  isgl3d
//
//  Created by Alexandr Stepanov on 03.03.12.
//  Copyright (c) 2012 Home,sweet home. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol Islg3dCollisionDelegate <NSObject>

- (void)object:(id)obj1 colidesObject:(id)obj2;

@end
