#pragma once

#include <opencv2/core/core.hpp>

#include <net.h>
#include "object_detection.h"


class MoneyDetection {
public:
    MoneyDetection();

    int load(int target_size, const float *norm_vals,const char *model_path,
             const char *param_path);

    int detect(const unsigned char *pixels, int pixelType, std::vector <Object> &objects, int width,
               int height, float prob_threshold = 0.8f, float nms_threshold = 0.4f);

private:

    ncnn::Net yolo;

    int target_size;
    float norm_vals[3];
    ncnn::UnlockedPoolAllocator blob_pool_allocator;
    ncnn::PoolAllocator workspace_pool_allocator;
};