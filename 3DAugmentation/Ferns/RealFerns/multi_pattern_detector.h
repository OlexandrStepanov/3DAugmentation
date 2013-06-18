/*
 Copyright 2012 Alexandr Stepanov,
 All rights reserved.
 */
#ifndef multi_pattern_detector_h
#define multi_pattern_detector_h

#include "planar_pattern_detector.h"

typedef struct pattern_structure {
  fern_based_point_classifier *classifier;
  int modelWidth, modelHeight;
  keypoint * model_points;
  int number_of_model_points;
  
  ~pattern_structure(void) {
    delete classifier;
    delete [] model_points;
  }
  
} pattern_structure;

class multi_pattern_detector: public planar_pattern_detector
{
public:
  //! Empty constructor. call build, load or buildWithCache before use.
  multi_pattern_detector(char ** models_filenames, int modelsCount);
  ~multi_pattern_detector(void);
    
  bool load(const char * filename);
  bool load(ifstream & f);
  
  bool detect(IplImage * input_image);
  
  int recognized_model_number;
    
private:
  int models_count;
  int currentModelNumber;
  pattern_structure ** patterns_structures;
  
  void match_points(void);
  bool estimate_H(void);
};

#endif
