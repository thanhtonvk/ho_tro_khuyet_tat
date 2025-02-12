//
// Created by TonSociu on 13/8/24.
//

#ifndef NGUOIMU_SCRFD_DEAF_H
#define NGUOIMU_SCRFD_DEAF_H

#include <opencv2/core/core.hpp>

#include <net.h>
#include "scrfd.h"

class SCRFD_DEAF {
public:
    int load(const char *model_path,
             const char *param_path);


    int
    detect(const unsigned char *pixels, int pixelType, std::vector <FaceObject> &faceobjects,
           int width, int height, float prob_threshold = 0.5f,
           float nms_threshold = 0.45f);

private:
    ncnn::Net scrfd_deaf;
    bool has_kps;
};

#endif // SCRFD_H
