#pragma once

#include <opencv2/core/core.hpp>

#include <net.h>
#include "object_detection.h"

class AnyObjectDetection {
public:
    AnyObjectDetection();

    int detect(const unsigned char *pixels, int pixelType,
               std::vector <Object> &objects,
               int width, int height);
};
