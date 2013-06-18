//
//  template_tracker_colored.cpp
//  FernsDemo
//
//  Created by Alexandr Stepanov on 27.11.11.
//  Copyright 2011 Home,sweet home. All rights reserved.
//

#include "template_matching_based_tracker.h"
#include "template_tracker_colored.h"
#include <iostream>
#include <fstream>

#include "homography.h"
#include "math.h"
#include "mcv.h"

#define MINIMUM_SHADOW_PART 0.5

using namespace std;



bool template_tracker_colored::load(const char * filename)
{
    ifstream f(filename);
    
    if (!f.good()) 
        return false;
    
    cout << "Loading (COLORED) " << filename << "..." << endl;
    
    U0 = cvCreateMat(8, 1, CV_32F);
    u0 = U0->data.fl;
    for(int i = 0; i < 8; i++)
        f >> u0[i];
    
//    Read width and height from 3rd corner
    modelWidth = u0[4];
    modelHeight = u0[5];
    
    f >> nx >> ny;
    m = new int[2 * nx * ny];
    for(int i = 0; i < nx * ny; i++)
        f >> m[2 * i] >> m[2 * i + 1];
    
    U = cvCreateMat(8, 1, CV_32F);
    u = U->data.fl;
    
    I0 = cvCreateMat(3 * nx * ny, 1, CV_32F);
    i0 = I0->data.fl;
    
    for(int i = 0; i < 3 * nx * ny; i++)
        f >> i0[i];
    
    I1 = cvCreateMat(3 * nx * ny, 1, CV_32F);
    i1 = I1->data.fl;
    DI = cvCreateMat(3 * nx * ny, 1, CV_32F);
    DU = cvCreateMat(8, 1, CV_32F);
    du = DU->data.fl;
    
    f >> number_of_levels;
    
    As = new CvMat*[number_of_levels];
    for(int i = 0; i < number_of_levels; i++) {
        As[i] = cvCreateMat(8, 3 * nx * ny, CV_32F);
        for(int j = 0; j < 8; j++)
            for(int k = 0; k < 3 * nx * ny; k++) {
                float v;
                f >> v;
                cvmSet(As[i], j, k, v);
            }
    }
    
    if (!f.good()) 
        return false;
    
    cout << "Done." << endl;
    return true;
}

void template_tracker_colored::save(const char * filename)
{
    ofstream f(filename);
    
    for(int i = 0; i < 8; i++)
        f << u0[i] << " ";
    f << endl;
    f << nx << " " << ny << endl;
    for(int i = 0; i < nx * ny; i++)
        f << m[2 * i] << " " << m[2 * i + 1] << endl;
    for(int i = 0; i < 3 * nx * ny; i++)
        f << i0[i] << " ";
    f << endl;
    f << number_of_levels << endl;
    for(int i = 0; i < number_of_levels; i++) {
        for(int j = 0; j < 8; j++) {
            for(int k = 0; k < 3 * nx * ny; k++)
                f << cvmGet(As[i], j, k) << " ";
            f << endl;
        }
    }
    f.close();
}

void template_tracker_colored::add_random_shadow(IplImage *image) {
//    We create shadow with size of image.
//    Then we generate the shadow amount (in percents), center and rotation
    IplImage *whiteMask = cvCreateImage(cvSize(image->width, image->height),
                                        IPL_DEPTH_8U, 1);
    cvFillImage(whiteMask, 255.0001);
    IplImage *shadowMask = cvCreateImage(cvSize(image->width, image->height),
                                         IPL_DEPTH_8U, 1);
    CvPoint translate;
    translate.x = randomGenerator->uniform(-MINIMUM_SHADOW_PART, MINIMUM_SHADOW_PART) * image->width;
    translate.y = randomGenerator->uniform(-MINIMUM_SHADOW_PART, MINIMUM_SHADOW_PART) * image->height;
    float rotation = randomGenerator->uniform(0.0, 360.0);
    CvMat* affineMatrix = cvCreateMat(2, 3, CV_32FC1);
    cv2DRotationMatrix(cvPoint2D32f(shadowMask->width/2.0, shadowMask->height/2.0), rotation , 1.0 , affineMatrix);
//    Add translation
    CV_MAT_ELEM(*affineMatrix, float, 0, 2) = translate.x;
    CV_MAT_ELEM(*affineMatrix, float, 1, 2) = translate.y;
    
    cvWarpAffine(whiteMask, shadowMask, affineMatrix);
    
#pragma warning Remove below after debug
    mcvSaveImage("shadowMask.bmp", shadowMask);
    
    float shadowRate = randomGenerator->uniform(0.1, 0.7);
    
//    Now walk throw shadowMask and aply shadow to image if there mask
    CvMat *mat = cvCreateMat( shadowMask->height, shadowMask->width, CV_8U );
    cvConvert( shadowMask, mat );
    
    for(int y = 0; y < image->height; y++ )
        for (int x = 0; x < image->width; x++ ) {
            uchar temp = CV_MAT_ELEM(*mat, uchar, y, x);
            if (temp > 0) {
                for(int z = 0; z < image->nChannels; z++ ) {
                    uchar oldValue = image->imageData[image->widthStep * y + x * image->nChannels + z];
                    image->imageData[image->widthStep * y + x * image->nChannels + z] = oldValue * (1.0 - shadowRate);
                }
            }
        }
    
#pragma warning Remove below after debug
    mcvSaveImage("imageWithShadowApplied.bmp", image);
    
    cvReleaseMat(&mat);
    cvReleaseMat(&affineMatrix);
    cvReleaseImage(&whiteMask);
    cvReleaseImage(&shadowMask);
}

IplImage * template_tracker_colored::compute_gradient(IplImage * colorImage)
{
    IplImage * image = cvCreateImage(cvSize(colorImage->width,colorImage->height), IPL_DEPTH_8U, 1);
    cvCvtColor(colorImage, image, CV_RGB2GRAY);
    
    IplImage * dx = cvCreateImage(cvSize(image->width, image->height),
                                  IPL_DEPTH_16S, 1);
    IplImage * dy = cvCreateImage(cvSize(image->width, image->height),
                                  IPL_DEPTH_16S, 1);
    IplImage * result = cvCreateImage(cvSize(image->width, image->height),
                                      IPL_DEPTH_16S, 1);
    cvSobel(image, dx, 1, 0, 3);
    cvSobel(image, dy, 0, 1, 3);
    cvMul(dx, dx, dx);
    cvMul(dy, dy, dy);
    cvAdd(dx, dy, result);
    
    cvReleaseImage(&dx);
    cvReleaseImage(&dy);
    cvReleaseImage(&image);
    
    return result;
}

bool template_tracker_colored::normalize(CvMat * V)
{
//    Here we should normalize 3 vectors separately - for R, G and B
    
    float sum[3];sum[0] = 0.0;sum[1] = 0.0;sum[2] = 0.0;
    float sum2[3];sum2[0] = 0.0;sum2[1] = 0.0;sum2[2] = 0.0;
    
    float * v = V->data.fl;
    
    for(int i = 0; i < V->rows; i+=3) {
        sum[0] += v[i];
        sum[1] += v[i+1];
        sum[2] += v[i+2];
        
        sum2[0] += v[i] * v[i];
        sum2[1] += v[i+1] * v[i+1];
        sum2[2] += v[i+2] * v[i+2];
    }
    
    // Not enough contrast,  better not put this sample into the training set:
    if (sum[0] < (V->rows/3 * 10) && sum[1] < (V->rows/3 * 10) && sum[2] < (V->rows/3 * 10))
        return false;
    
    float mean[3];
    mean[0] = sum[0] / (V->rows/3);
    mean[1] = sum[0] / (V->rows/3);
    mean[2] = sum[0] / (V->rows/3);
    
    float inv_sigma[3];
    inv_sigma[0] = 1.0 / sqrt(sum2[0] / (V->rows/3) - mean[0] * mean[0]);
    inv_sigma[1] = 1.0 / sqrt(sum2[1] / (V->rows/3) - mean[1] * mean[1]);
    inv_sigma[2] = 1.0 / sqrt(sum2[2] / (V->rows/3) - mean[2] * mean[2]);
    
    // Not enough contrast,  better not put this sample into the training set:
    if (!isfinite(inv_sigma[0]) || !isfinite(inv_sigma[1]) || !isfinite(inv_sigma[2]))
        return false;
    
    for(int i = 0; i < V->rows; i+=3) {
        v[i] = inv_sigma[0] * (v[i] - mean[0]);
        v[i+1] = inv_sigma[1] * (v[i+1] - mean[1]);
        v[i+2] = inv_sigma[2] * (v[i+2] - mean[2]);
    }
    
    return true;
}

void template_tracker_colored::learn(IplImage * image,
                                            int number_of_levels, int max_motion, int nx, int ny,
                                            int xUL, int yUL,
                                            int xBR, int yBR,
                                            int bx, int by,
                                            int Ns)
{
    if (image->nChannels != 3) {
        cout << "ERROR: in template_matching_based_tracker::learn image should be RGB" << endl;
        return;
    }
    
    IplImage *imageGray = cvCreateImage(cvGetSize(image), image->depth, 1);
    cvCvtColor(image, imageGray, CV_RGB2GRAY);
    
    this->number_of_levels = number_of_levels;
    this->nx = nx;
    this->ny = ny;
    
    m = new int[2 * nx * ny];
    U0 = cvCreateMat(8, 1, CV_32F);
    u0 = U0->data.fl;
    u0[0] = xUL; u0[1] = yUL;
    u0[2] = xBR; u0[3] = yUL;
    u0[4] = xBR; u0[5] = yBR;
    u0[6] = xUL; u0[7] = yBR;
    
    find_2d_points(imageGray, bx, by);
    
    U = cvCreateMat(8, 1, CV_32F);
    u = U->data.fl;
    
    I0 = cvCreateMat(nx * ny * 3, 1, CV_32F);
    i0 = I0->data.fl;
    
    for(int i = 0; i < nx * ny; i++) {
        i0[3*i] = mcvRow(image, m[2 * i + 1], unsigned char)[ 3 * m[2 * i] ];
        i0[3*i + 1] = mcvRow(image, m[2 * i + 1], unsigned char)[ 3 * m[2 * i] + 1];
        i0[3*i + 2] = mcvRow(image, m[2 * i + 1], unsigned char)[ 3 * m[2 * i] + 2];
    }
    bool ok = normalize(I0);
    if (!ok) {
        cerr << "> in template_tracker_colored::learn :" << endl;
        cerr << "> Template matching: image has not enough contrast." << endl;
        return ;
    }
    
    I1 = cvCreateMat(3 * nx * ny, 1, CV_32F);
    i1 = I1->data.fl;
    DI = cvCreateMat(3 * nx * ny, 1, CV_32F);
    DU = cvCreateMat(8, 1, CV_32F);
    du = DU->data.fl;
    
    cvReleaseImage(&imageGray);
    
    compute_As_matrices(image, max_motion, Ns);
}

void template_tracker_colored::compute_As_matrices(IplImage * image, int max_motion, int Ns)
{
    As = new CvMat*[number_of_levels];
    
    int mCount_3 = 3 * nx * ny;
    
    CvMat * Y = cvCreateMat(8, Ns, CV_32F);
    CvMat * H = cvCreateMat(mCount_3, Ns, CV_32F);
    CvMat * HHt = cvCreateMat(mCount_3, mCount_3, CV_32F);
    CvMat * HHt_inv = cvCreateMat(mCount_3, mCount_3, CV_32F);
    CvMat * Ht_HHt_inv = cvCreateMat(Ns, mCount_3, CV_32F);
    
    IplImage *shadowImage = cvCreateImage(cvSize(image->width, image->height), image->depth, image->nChannels);
    
    for(int level = 0; level < number_of_levels; level++) {
        
        float k = exp(1. / (number_of_levels - 1) * log(3.0 / max_motion));
        int amp = int(pow(k, float(level)) * max_motion + 1e-3);
        
        cout << "Amplitude: " << amp << endl;
        
        int n = 0;
        while(n < Ns) {
            cout << "Level: " << level << " (" << n << "/" << Ns << " samples done)" << char(13) << flush;
            
            float u1[8];
            
            for(int i = 0; i < 4; i++)
                move(u0[2 * i], u0[2 * i + 1], u1[2 * i], u1[2 * i + 1], amp);
            
            for(int i = 0; i < 8; i++)
                cvmSet(Y, i, n, u1[i] - u0[i]);
            
            he->estimate(
                         u0[0], u0[1], u1[0], u1[1],
                         u0[2], u0[3], u1[2], u1[3],
                         u0[4], u0[5], u1[4], u1[5],
                         u0[6], u0[7], u1[6], u1[7]);
            
//            Now decide - should we add shadow or not
            IplImage *imageToUse = image;
//            float randomTemp = randomGenerator->uniform(0.0, 1.0);
//            if (randomTemp < imagesInLearnShadowPercentage) {
//                cvCopy(image, shadowImage);
//                add_random_shadow(shadowImage);
//                imageToUse = shadowImage;
//            }
            
            for(int i = 0; i < nx * ny; i++) {
                int x1, y1;
                
                he->transform_point(m[2 * i], m[2 * i + 1], &x1, &y1);
                i1[3*i] = mcvRow(imageToUse, y1, unsigned char)[3 * x1];
                i1[3*i + 1] = mcvRow(imageToUse, y1, unsigned char)[3 * x1 + 1];
                i1[3*i + 2] = mcvRow(imageToUse, y1, unsigned char)[3 * x1 + 2];
            }
            
            add_noise(I1);
            bool ok = normalize(I1);
            if (ok) {
                for(int i = 0; i < mCount_3; i++)
                    cvmSet(H, i, n, i1[i] - i0[i]);
                n++;
            }
        }
        
        cout << "Level: " << level << "                                        " << endl;
        cout << " - " << n << " training samples generated." << endl;
        
        As[level] = cvCreateMat(8, mCount_3, CV_32F);
        
        cout << " - computing HHt..." << flush;
        cvGEMM(H, H, 1.0, 0, 0.0, HHt, CV_GEMM_B_T);
        cout << "done." << endl;
        
        cout << " - inverting HHt..." << flush;
        if (cvInvert(HHt, HHt_inv, CV_SVD_SYM) == 0) {
            cerr << "> In template_matching_based_tracker::compute_As_matrices :" << endl;
            cerr << " Can't compute HHt matrix inverse!" << endl;
            cerr << " damn!" << endl;
            exit(-1);
        }
        cout << "done." << endl;
        
        cout << " - computing H(HHt)^-1..." << flush;
        cvGEMM(H, HHt_inv, 1.0, 0, 0.0, Ht_HHt_inv, CV_GEMM_A_T);
        cout << "done." << endl;
        
        cout << " - computing YH(HHt)^-1..." << flush;
        cvMatMul(Y, Ht_HHt_inv, As[level]);
        cout << "done." << endl;
    }
    
    cvReleaseImage(&shadowImage);
    cvReleaseMat(&Y);
    cvReleaseMat(&H);
    cvReleaseMat(&HHt);
    cvReleaseMat(&HHt_inv);
    cvReleaseMat(&Ht_HHt_inv);
}

bool template_tracker_colored::track(IplImage * input_frame)
{
    if (input_frame->nChannels != 3) {
        cout << "ERROR: in template_tracker_colored::track, input_frame should be RGB" << endl;
        return false;
    }
    
    //  Time debugging
    timer = cvGetTickCount();
    
    homography *fs = new homography();
    
    for(int level = 0; level < number_of_levels; level++) {
        for(int iter = 0; iter < 5; iter++) {
            for(int i = 0; i < nx * ny; i++) {
                int x1, y1;
                
                he->transform_point(m[2 * i], m[2 * i + 1], &x1, &y1);
                if (x1 < 0 || y1 < 0 || x1 >= input_frame->width || y1 >= input_frame->height) {
                    delete fs;
                    return false;
                }
                
                i1[3*i] = mcvRow(input_frame, y1, unsigned char)[3*x1];
                i1[3*i+1] = mcvRow(input_frame, y1, unsigned char)[3*x1+1];
                i1[3*i+2] = mcvRow(input_frame, y1, unsigned char)[3*x1+2];
            }
            normalize(I1);
            cvSub(I1, I0, DI);
            
            cvMatMul(As[level], DI, DU);
            fs->estimate(
                         u0[0],  u0[1],  u0[0] - du[0], u0[1] - du[1],
                         u0[2],  u0[3],  u0[2] - du[2], u0[3] - du[3],
                         u0[4],  u0[5],  u0[4] - du[4], u0[5] - du[5],
                         u0[6],  u0[7],  u0[6] - du[6], u0[7] - du[7]);
            
            cvMatMul(he, fs, he);
            
            float norm = 0;
            for(int i = 0; i < 9; i++) norm += he->data.fl[i] * he->data.fl[i];
            norm = sqrtf(norm);
            for(int i = 0; i < 9; i++) he->data.fl[i] /= norm;
        }
    }
    
    he->transform_point(u0[0], u0[1], &(u[0]), &(u[1]));
    he->transform_point(u0[2], u0[3], &(u[2]), &(u[3]));
    he->transform_point(u0[4], u0[5], &(u[4]), &(u[5]));
    he->transform_point(u0[6], u0[7], &(u[6]), &(u[7]));
    
    delete fs;
    
    int64 now = cvGetTickCount();
    this->lastTrackDuration = (now-timer) / cvGetTickFrequency() / 1e6;
    
    return true;
}