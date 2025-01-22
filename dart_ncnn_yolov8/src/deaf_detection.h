#pragma once

#include <opencv2/core/core.hpp>

#include <net.h>
#include "object_detection.h"


class DeafDetection
{
public:
    DeafDetection();

    int load(int target_size, const float* norm_vals, bool use_gpu = false);

    int detect(const cv::Mat& rgb, std::vector<Object>& objects, float prob_threshold = 0.5f, float nms_threshold = 0.2f);


private:

    ncnn::Net yolo;

    int target_size;
    float norm_vals[3];
    ncnn::UnlockedPoolAllocator blob_pool_allocator;
    ncnn::PoolAllocator workspace_pool_allocator;
};
