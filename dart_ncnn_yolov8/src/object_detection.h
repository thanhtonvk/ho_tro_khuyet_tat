#ifndef YOLO_H
#define YOLO_H

#include <opencv2/core/core.hpp>

#include <net.h>

struct Object {
    cv::Rect_<float> rect;
    int label;
    float prob;
};
struct GridAndStride {
    int grid0;
    int grid1;
    int stride;
};

class ObjectDetection {
public:
    ObjectDetection();

    int
    load(int _target_size, const float *_mean_vals, const float *_norm_vals, const char *model_path,
         const char *param_path);

    int detect(const unsigned char *pixels, int pixelType, std::vector <Object> &objects, int width,
               int height);

private:
    ncnn::Net yolo;
    int target_size;
    float mean_vals[3];
    float norm_vals[3];
    ncnn::UnlockedPoolAllocator blob_pool_allocator;
    ncnn::PoolAllocator workspace_pool_allocator;
};

#endif // NANODET_H
