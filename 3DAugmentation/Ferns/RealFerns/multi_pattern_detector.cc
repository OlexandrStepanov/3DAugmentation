/*
  Copyright 2012 Alexandr Stepanov,
  All rights reserved.
*/
#include <algorithm>
#include <fstream>
#include <iomanip>

#include "mcv.h"
#include "multi_pattern_detector.h"
#include "buffer_management.h"

multi_pattern_detector::multi_pattern_detector(char ** models_filenames, int modelsCount):
planar_pattern_detector()
{  
  models_count = modelsCount;
  patterns_structures = new pattern_structure*[this->models_count];
  
  for (currentModelNumber=0; currentModelNumber<this->models_count; currentModelNumber++) {
    char *modelFileName = models_filenames[currentModelNumber];
    this->load((const char*)modelFileName);
  }
  
//  NOTE: All models should have the same yape_radius, patch_size and number_of_octaves
  pyramid = new fine_gaussian_pyramid(yape_radius, patch_size, number_of_octaves);
  
  delete image_generator;
  image_generator = 0;
}

multi_pattern_detector::~multi_pattern_detector(void)
{
  for (int i=0; i<models_count; i++)
    delete patterns_structures[i];
  delete [] patterns_structures;
}

#pragma mark Load logic

bool multi_pattern_detector::load(const char * filename)
{
  ifstream f(filename, ios::binary);
  if (!f.is_open()) 
    return false;
  cout << "> [multi_pattern_detector::load] Loading detector file " << filename << " ... " << endl;
  bool result = this->load(f);
  f.close();
  cout << "> [multi_pattern_detector::load] Ok." << endl;
  
  return result;
}

bool multi_pattern_detector::load(ifstream & f)
{
  f >> image_name;
  cout << "> [multi_pattern_detector::load] Image name: " << image_name << endl;

  for(int i = 0; i < 4; i++)
    f >> u_corner[i] >> v_corner[i];

  f >> patch_size >> yape_radius >> number_of_octaves;
  cout << "> [multi_pattern_detector::load] Patch size = " << patch_size
       << ", Yape radius = " << yape_radius
       << ", Number of octaves = " << number_of_octaves
       << "." << endl;

  image_generator->load_transformation_range(f);
  
  f >> mean_recognition_rate;
  cout << "> [multi_pattern_detector::load] Recognition rate: " << mean_recognition_rate << endl;
  
  patterns_structures[currentModelNumber] = new pattern_structure();
  pattern_structure *currentPattern = patterns_structures[currentModelNumber];

  f >> currentPattern->modelWidth 
    >> currentPattern->modelHeight;

  f >> currentPattern->number_of_model_points;
  cout << "> [multi_pattern_detector::load] " << currentPattern->number_of_model_points << " model points." << endl;
  currentPattern->model_points = new keypoint[currentPattern->number_of_model_points];
  for(int i = 0; i < currentPattern->number_of_model_points; i++) {
    f >> currentPattern->model_points[i].u
      >> currentPattern->model_points[i].v 
      >> currentPattern->model_points[i].scale;
    currentPattern->model_points[i].class_index = i;
  }

  currentPattern->classifier = new fern_based_point_classifier(f);

  return true;
}

bool multi_pattern_detector::detect(IplImage * input_image)
{
  bool releaseInputImage = false;
  if (input_image->nChannels != 1 || input_image->depth != IPL_DEPTH_8U) {
      IplImage *colorImage = input_image;
      input_image = cvCreateImage(cvGetSize(colorImage), IPL_DEPTH_8U, 1);
      cvCvtColor(colorImage, input_image, CV_BGR2GRAY);
      releaseInputImage = true;
  }

  pyramid->set_image(input_image);
  detect_points(pyramid);
  
  pattern_is_detected = false;
  
//  now we need go throw models and make matching
  for (currentModelNumber=0; 
       currentModelNumber<models_count && !pattern_is_detected; 
       currentModelNumber++) 
  {
    match_points();

    pattern_is_detected = estimate_H();

    if (pattern_is_detected) {
        for(int i = 0; i < 4; i++)
          H.transform_point(u_corner[i], v_corner[i], detected_u_corner[i], detected_v_corner[i]);

        number_of_matches = 0;
        pattern_structure *cur_pattern = patterns_structures[currentModelNumber];
        for(int i = 0; i < cur_pattern->number_of_model_points; i++)
          if (cur_pattern->model_points[i].class_score > 0) {
            float Hu, Hv;
            H.transform_point(cur_pattern->model_points[i].fr_u(), cur_pattern->model_points[i].fr_v(), Hu, Hv);
              
            float distX, distY;
            distX = (Hu - cur_pattern->model_points[i].potential_correspondent->fr_u());
            distY = (Hv - cur_pattern->model_points[i].potential_correspondent->fr_v());
            float dist2 = distX*distX + distY*distY;
            
            if (dist2 > 10.0 * 10.0)
              cur_pattern->model_points[i].class_score = 0.0;
            else
              number_of_matches++;
        }
//      Also save the recognized model number
      recognized_model_number = currentModelNumber;
    }
  }

  if (releaseInputImage)
    cvReleaseImage(&input_image);
  
  return pattern_is_detected;
}

void multi_pattern_detector::match_points(void)
{
  pattern_structure *cur_pattern = patterns_structures[currentModelNumber];
  
  for(int i = 0; i < cur_pattern->number_of_model_points; i++) {
    cur_pattern->model_points[i].potential_correspondent = 0;
    cur_pattern->model_points[i].class_score = 0;
  }
  
  for(int i = 0; i < number_of_detected_points; i++) {
    keypoint * k = detected_points + i;
    
    cur_pattern->classifier->recognize(pyramid, k);
    
    if (k->class_index >= 0) {
      float true_score = exp(k->class_score);
      
      if (cur_pattern->model_points[k->class_index].class_score < true_score) {
        cur_pattern->model_points[k->class_index].potential_correspondent = k;
        cur_pattern->model_points[k->class_index].class_score = true_score;
      }
    }
  }
}


bool multi_pattern_detector::estimate_H(void)
{
  pattern_structure *cur_pattern = patterns_structures[currentModelNumber];
  
  H_estimator->reset_correspondences(cur_pattern->number_of_model_points);

  for(int i = 0; i < cur_pattern->number_of_model_points; i++)
    if (cur_pattern->model_points[i].class_score > 0)
      H_estimator->add_correspondence(cur_pattern->model_points[i].fr_u(), cur_pattern->model_points[i].fr_v(),
				      cur_pattern->model_points[i].potential_correspondent->fr_u(), cur_pattern->model_points[i].potential_correspondent->fr_v(),
                                      cur_pattern->model_points[i].class_score);

  return H_estimator->ransac(&H, ransac_threshold, ransac_iterations_number, 0.99, true) > 10;
}

