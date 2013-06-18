//
//  template_tracker_colored.h
//  FernsDemo
//
//  Created by Alexandr Stepanov on 27.11.11.
//  Copyright 2011 Home,sweet home. All rights reserved.
//

#ifndef FernsDemo_template_tracker_colored_h
#define FernsDemo_template_tracker_colored_h

#include "template_matching_based_tracker.h"

class template_tracker_colored: public template_matching_based_tracker {
public:
    void learn(IplImage * image,
               int number_of_levels, int max_motion, int nx, int ny,
               int xUL, int yUL,
               int xBR, int yBR,
               int bx, int by,
               int Ns);
    bool track(IplImage * input_frame);
    
    float imagesInLearnShadowPercentage;
    
    template_tracker_colored(): template_matching_based_tracker() {
        imagesInLearnShadowPercentage = 0.2;
    };
    
    void save(const char * filename);
    bool load(const char * filename);
    
    void add_random_shadow(IplImage *image);
    
private:
    bool normalize(CvMat * V);
    void compute_As_matrices(IplImage * image, int max_motion, int Ns);
    IplImage *compute_gradient(IplImage * colorImage);
};



#endif
