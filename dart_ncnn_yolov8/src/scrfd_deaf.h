//
// Created by TonSociu on 13/8/24.
//

#ifndef NGUOIMU_SCRFD_DEAF_H
#define NGUOIMU_SCRFD_DEAF_H
#include <opencv2/core/core.hpp>

#include <net.h>
#include "scrfd.h"

class SCRFD_DEAF
{
public:
    int load();

    int detect(const cv::Mat& rgb, std::vector<FaceObject>& faceobjects, float prob_threshold = 0.5f, float nms_threshold = 0.45f);

    int draw(cv::Mat& rgb, const std::vector<FaceObject>& faceobjects);

private:
    ncnn::Net scrfd_deaf;
    bool has_kps;
};

#endif // SCRFD_H
