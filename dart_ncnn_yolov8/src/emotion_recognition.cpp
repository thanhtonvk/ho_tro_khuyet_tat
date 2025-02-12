//
// Created by thanh on 9/14/2024.
//

#include "emotion_recognition.h"
#include <string.h>
#include <opencv2/core/core.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include "cpu.h"
#include <opencv2/opencv.hpp>


cv::Rect resizeImage(FaceObject faceobject) {
    // Get the original coordinates
    int left = faceobject.rect.x;
    int top = faceobject.rect.y;
    int w = faceobject.rect.width;
    int h = faceobject.rect.height;
    int maxSize = std::max(w, h);

    // Tính lại tọa độ sao cho hình vuông nằm giữa hình chữ nhật
    int newLeft = left - (maxSize - w) / 2;
    int newTop = top - (maxSize - h) / 2;

    // Đảm bảo tọa độ không vượt quá biên của hình ảnh
    newLeft = std::max(0, newLeft);
    newTop = std::max(0, newTop);


    return {newLeft, newTop, maxSize, maxSize};
}

EmotionRecognition::EmotionRecognition() {

}

int EmotionRecognition::load(const char *model_path,
                             const char *param_path) {
    model.clear();
    ncnn::set_cpu_powersave(2);
    ncnn::set_omp_num_threads(ncnn::get_big_cpu_count());
    model.opt = ncnn::Option();
    model.opt.num_threads = ncnn::get_big_cpu_count();
//    char parampath[256];
//    char modelpath[256];
//    sprintf(parampath, "assets/yolo/model.param");
//    sprintf(modelpath, "assets/yolo/model.bin");
    model.load_param(param_path);
    model.load_model(model_path);

    return 0;
}

int EmotionRecognition::predict(const unsigned char *pixels, int pixelType, int width, int height,
                                FaceObject &faceobject,
                                std::vector<float> &result) {

    cv::Rect newRect = resizeImage(faceobject);
    if (newRect.x >= 0 && newRect.y >= 0 &&
        newRect.width > 0 && newRect.height > 0 &&
        newRect.x + newRect.width <= src.cols &&
        newRect.y + newRect.height <= src.rows) {
        cv::Mat src(height, width, (channels == 3) ? CV_8UC3 : CV_8UC1, (void *) pixels)
        cv::Mat croppedImage = src(newRect);
        ncnn::Mat in_net = ncnn::Mat::from_pixels_resize(croppedImage.data,
                                                         pixelType, croppedImage.cols,
                                                         croppedImage.rows,
                                                         128, 128);
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
    }

    return 0;
}