#include <string.h>
#include <opencv2/core/core.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include "cpu.h"
#include <opencv2/opencv.hpp>
#include "light_traffic.h"

LightTraffic::LightTraffic() {
}

int LightTraffic::load() {

    model.clear();

    ncnn::set_cpu_powersave(2);
    ncnn::set_omp_num_threads(ncnn::get_big_cpu_count());

    model.opt = ncnn::Option();


    model.opt.num_threads = ncnn::get_big_cpu_count();

    char parampath[256];
    char modelpath[256];
    sprintf(parampath, "assets/yolo/lighttraffic.ncnn.param");
    sprintf(modelpath, "assets/yolo/lighttraffic.ncnn.bin");

    model.load_param(parampath);
    model.load_model(modelpath);

    return 0;
}

int LightTraffic::predict(cv::Mat src, std::vector<float> &result) {
    result.clear();
    ncnn::Mat in_net = ncnn::Mat::from_pixels_resize(src.clone().data,
                                                     ncnn::Mat::PIXEL_RGB, src.cols,
                                                     src.rows,
                                                     224, 224);
    float norm[3] = {1 / 127.5f, 1 / 127.5f, 1 / 127.5f};
    float mean[3] = {127.5f, 127.5f, 127.5f};
    in_net.substract_mean_normalize(mean, norm);
    ncnn::Extractor extractor = model.create_extractor();
    extractor.input("in0", in_net);
    ncnn::Mat outBlob;
    extractor.extract("out0", outBlob);
    for (int i = 0; i < outBlob.w; i++) {
        float test = outBlob.row(0)[i];
        result.push_back(test);
    }
    return 0;
}

