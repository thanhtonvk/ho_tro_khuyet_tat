//
// Created by thanh on 8/24/2024.
//

#ifndef NGUOIMU_LIGHT_TRAFFIC_H
#define NGUOIMU_LIGHT_TRAFFIC_H

#include <opencv2/core/core.hpp>
#include <net.h>

class LightTraffic {
public:
    LightTraffic();

    int load(const char *model_path,
             const char *param_path);

    int predict(const unsigned char *pixels, int pixelType, int width, int height,
                std::vector<float> &result);

private:
    ncnn::Net model;
};

#endif //NGUOIMU_LIGHT_TRAFFIC_H
