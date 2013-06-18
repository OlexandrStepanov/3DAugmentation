//
//  Defines.h
//  FaceAugmentation
//
//  Created by Alexandr Stepanov on 13.01.12.
//  Copyright (c) 2012 Home,sweet home. All rights reserved.
//

#ifndef FaceAugmentation_Notifications_h
#define FaceAugmentation_Notifications_h

#define RELEASE_AND_NULIFY(_arg) {[_arg release];_arg=nil;}
#define DOCUMENTS_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]
#define APPDELEGATE [[UIApplication sharedApplication] delegate]

#define kRecognizerWasInitialized @"kRecognizerWasInitialized"
#define kModelWasFoundInFrame @"kModelWasFoundInFrame"

#define kDebugInformationTranslationVector @"kDebugInformationTranslationVector"

#define RECOGNITION_THREAD_PRIORITY 0.8
#define TRACKING_THREAD_PRIORITY 0.6
#define RECOGNITION_TIMER_INTERVAL 0.3
#define INIT_RECOGNIZER_THREAD_PRIORITY 0.7

#define THRESHOLD_TRANSFORM_OBJECT_LOST 0.2

#define MODEL_NAME @"monaLisaTalk.jpg"
#define TRACKING_FRAME_INCREASE_PERCENTAGE 0.3

#define IMAGE_MOVE_SPEED 0.3

#define CAMERA_WIDTH 480
#define CAMERA_HEIGHT 640

#endif
