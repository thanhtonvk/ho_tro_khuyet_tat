//
// Created by TonSociu on 13/8/24.
//

#ifndef NGUOIMU_FACE_EMB_H
#define NGUOIMU_FACE_EMB_H

#include <opencv2/core/core.hpp>
#include <net.h>

class FaceEmb {
public:
    FaceEmb();

    int load(const char *model_path, const char *param_path);

    int getEmbedding(const unsigned char *pixels, int pixelType, int width, int height,
                     cv::Point2f landmark[5], std::vector<float> &result, cv::Mat &faceAligned);

private:
    ncnn::Net modelEmb;
};

#endif //NGUOIMU_FACE_EMB_H
