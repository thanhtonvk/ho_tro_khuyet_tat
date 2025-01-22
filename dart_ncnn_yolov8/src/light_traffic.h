//
// Created by thanh on 8/24/2024.
//

#ifndef NGUOIMU_LIGHT_TRAFFIC_H
#define NGUOIMU_LIGHT_TRAFFIC_H
#include <opencv2/core/core.hpp>
#include <net.h>
class LightTraffic
{
public:
    LightTraffic();
    int load();
    int predict(cv::Mat src, std::vector<float> &result);

private:
    ncnn::Net model;
};
#endif //NGUOIMU_LIGHT_TRAFFIC_H
