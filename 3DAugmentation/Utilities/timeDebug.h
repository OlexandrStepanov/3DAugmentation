//
//  timeDebug.h
//  ARWorld
//
//  Created by Alina Okhremenko on 16.10.11.
//  Copyright 2011 Home,sweet home. All rights reserved.
//

#ifndef ARWorld_timeDebug_h
#define ARWorld_timeDebug_h

CVAPI(void) startTimer(clock_t *_mainT);
CVAPI(void) printTimerWithPrefix(char *preffix, clock_t _mainT);


#endif
