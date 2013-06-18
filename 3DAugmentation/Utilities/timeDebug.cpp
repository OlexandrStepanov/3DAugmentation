//
//  timeDebug.c
//  ARWorld
//
//  Created by Alina Okhremenko on 16.10.11.
//  Copyright 2011 Home,sweet home. All rights reserved.
//

#include <stdio.h>
#include <time.h>

extern "C" {

void startTimer(clock_t *_mainT) {
    *_mainT = clock();
}

void printTimerWithPrefix(char *preffix, clock_t _mainT) {
    clock_t t2=clock();
    printf("Seconds for %s: %0.5f\n", preffix, (double)(t2-_mainT)/CLOCKS_PER_SEC);
}
    
}
