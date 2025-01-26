#include <string>
#include <vector>
#include "nguoi_khuyet_tat_sdk.h"
#include "deaf_detection.h"
#include "emotion_recognition.h"
#include "face_emb.h"
#include "light_traffic.h"
#include "money_detection.h"
#include "object_detection.h"
#include "scrfd.h"
#include "scrfd_deaf.h"

#include <opencv2/core/core.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <iostream>
#include <android/bitmap.h>
#include <opencv2/opencv.hpp>
#include <opencv2/highgui/highgui.hpp>

using namespace cv;
static ObjectDetection *objectDetection = 0;
static SCRFD *faceDetection = 0;
static LightTraffic *lightTraffic = 0;
static EmotionRecognition *emotionRecognition = 0;
static FaceEmb *faceRecognition = 0;
static SCRFD_DEAF *faceDeafDetection = 0;
static DeafDetection *deafDetection = 0;
static MoneyDetection *moneyDetection = 0;
static ncnn::Mutex lock;


static std::vector <Object> objects;
static std::vector <FaceObject> faceObjects;
static std::vector <Object> moneyObjects;
static std::vector <Object> deafObjects;


static std::vector<float> embedding;
static cv::Mat faceAligned;
static std::vector<float> resultLightTraffic;

static std::vector<float> scoreEmotions;
static std::vector<float> scoreDeafs;

cv::Mat convertToMat(unsigned char *pixels, int width, int height, int channels) {
    int type = (channels == 1) ? CV_8UC1 : CV_8UC3;
    cv::Mat image(height, width, type, pixels);
    return image.clone();
}

char *parseResultsObjects(std::vector <Object> &objects) {
    if (objects.size() == 0) {
        NCNN_LOGE("No object detected");
        return (char *) "";
    }

    std::string result = "";
    for (int i = 0; i < (int) objects.size(); i++) {
        Object obj = objects[i];
        result += std::to_string(obj.rect.x) + "," + std::to_string(obj.rect.y) + "," +
                  std::to_string(obj.rect.width) +
                  "," + std::to_string(obj.rect.height) + "," + std::to_string(obj.label) + "," +
                  std::to_string(obj.prob) + "\n";
    }

    char *result_c = new char[result.length() + 1];
    strcpy(result_c, result.c_str());
    return result_c;
}

char *parseResultsFaceObjects(std::vector <FaceObject> &faceObjects) {
    if (faceObjects.size() == 0) {
        NCNN_LOGE("No face detected");
        return (char *) "";
    }

    std::string result = "";
    FaceObject faceObject = faceObjects[i];
    result += std::to_string(faceObject.rect.x) + "," + std::to_string(faceObject.rect.y) + "," +
              std::to_string(faceObject.rect.width) +
              "," + std::to_string(faceObject.rect.height) + "," + std::to_string(faceObject.prob) +
              "\n";

    char *result_c = new char[result.length() + 1];
    strcpy(result_c, result.c_str());
    return result_c;
}

char *parseVector(std::vector<float> embedding) {
    if (embedding.empty()) {
        NCNN_LOGE("No embedding");
        return (char *) "";
    }
    std::string result = "";
    for (int i = 0; i < (int) embedding.size(); i++) {
        result += std::to_string(embedding[i]) + ",";
    }
    char *result_c = new char[result.length() + 1];
    strcpy(result_c, result.c_str());
    return result_c;
}

FFI_PLUGIN_EXPORT void
yuv420sp2rgb(const unsigned char *yuv420sp, int width, int height, unsigned char *rgb) {
    ncnn::yuv420sp2rgb(yuv420sp, width, height, rgb);
    return;
}

FFI_PLUGIN_EXPORT void
rgb2rgba(const unsigned char *rgb, int width, int height, unsigned char *rgba) {
    ncnn::Mat m = ncnn::Mat::from_pixels(rgb, ncnn::Mat::PIXEL_RGB2BGRA, width, height);
    m.to_pixels(rgba, ncnn::Mat::PIXEL_RGBA);
    return;
}

FFI_PLUGIN_EXPORT void
kannaRotate(const unsigned char *src, int channel, int srcw, int srch, unsigned char *dst,
            int dsw, int dsh, int type) {
    switch (channel) {
        case 1:
            ncnn::kanna_rotate_c1(src, srcw, srch, dst, dsw, dsh, type);
            break;
        case 2:
            ncnn::kanna_rotate_c2(src, srcw, srch, dst, dsw, dsh, type);
            break;
        case 3:
            ncnn::kanna_rotate_c3(src, srcw, srch, dst, dsw, dsh, type);
            break;
        case 4:
            ncnn::kanna_rotate_c4(src, srcw, srch, dst, dsw, dsh, type);
            break;
    }
    return;
}

FFI_PLUGIN_EXPORT void
load(int deaf, int blind) {
    {
        ncnn::MutexLockGuard g(lock);
        delete objectDetection;
        delete faceDetection;
        delete lightTraffic;
        delete emotionRecognition;
        delete faceRecognition;
        delete faceDeafDetection;
        delete deafDetection;
        delete moneyDetection;
        objectDetection = 0;
        faceDetection = 0;
        lightTraffic = 0;
        emotionRecognition = 0;
        faceRecognition = 0;
        faceDeafDetection = 0;
        deafDetection = 0;
        moneyDetection = 0;

        const float mean_vals[][3] =
                {
                        {103.53f, 116.28f, 123.675f},
                        {103.53f, 116.28f, 123.675f},
                };

        const float norm_vals[][3] =
                {
                        {1 / 255.f, 1 / 255.f, 1 / 255.f},
                        {1 / 255.f, 1 / 255.f, 1 / 255.f},
                };

        if (deaf > 0) {
            if (!faceDeafDetection)
                faceDeafDetection = new SCRFD_DEAF;
            faceDeafDetection->load();

            if (!emotionRecognition)
                emotionRecognition = new EmotionRecognition;
            emotionRecognition->load();

            if (!deafDetection)
                deafDetection = new DeafDetection;
            deafDetection->load(320, norm_vals[0]);
        } else {

            if (!lightTraffic) {
                lightTraffic = new LightTraffic;
            }
            lightTraffic->load();

            if (!objectDetection) {
                objectDetection = new ObjectDetection;
            }
            objectDetection->load(640, mean_vals[0],
                                  norm_vals[0]);

            if (!faceDetection)
                faceDetection = new SCRFD;
            faceDetection->load();
            if (!faceRecognition)
                faceRecognition = new FaceEmb;
            faceRecognition->load();


            moneyDetection = new MoneyDetection;
            moneyDetection->load(320, norm_vals[0]);

        }
    }
}

FFI_PLUGIN_EXPORT void unLoad() {
    {

        ncnn::MutexLockGuard g(lock);
        delete objectDetection;
        delete faceDetection;
        delete lightTraffic;
        delete emotionRecognition;
        delete faceRecognition;
        delete faceDeafDetection;
        delete deafDetection;
        delete moneyDetection;
        objectDetection = 0;
        faceDetection = 0;
        lightTraffic = 0;
        emotionRecognition = 0;
        faceRecognition = 0;
        faceDeafDetection = 0;
        deafDetection = 0;
        moneyDetection = 0;
    }
}


FFI_PLUGIN_EXPORT char *getEmbeddingFromPath(const char *image_path) {
    cv::Mat bgr = cv::imread(image_path, 1);
    ncnn::MutexLockGuard g(lock);
    if (faceRecognition && faceDetection) {
        faceObjects.clear();
        embedding.clear();
        cv::Mat rgb;
        cv::cvtColor(bgr, rgb, cv::COLOR_BGR2RGB);
        faceDetection->detect(rgb, faceObjects);
        if (!faceObjects.empty()) {
            faceRecognition->getEmbeding(rgb, faceObjects[0].landmark, embedding, faceAligned);
        }
    }

    return parseVector(embedding);
}

FFI_PLUGIN_EXPORT char *
detectFaceObjectWithPixels(const unsigned char *pixels, int width, int height) {
    cv::Mat rgb = convertToMat(pixels, width, height, 3);
    ncnn::MutexLockGuard g(lock);
    if (faceDetection) {
        faceObjects.clear();
        faceDetection->detect(rgb, faceObjects);
    }

    return parseResultsFaceObjects(faceObjects);
}

FFI_PLUGIN_EXPORT char *getEmbeddingWithPixels(const unsigned char *pixels, int width, int height) {
    cv::Mat rgb = convertToMat(pixels, width, height, 3);
    ncnn::MutexLockGuard g(lock);
    if (faceRecognition) {
        if (!faceObjects.empty()) {
            embedding.clear();
            faceRecognition->getEmbeding(rgb, faceObjects[0].landmark, embedding, faceAligned);
        }
    }

    return parseVector(embedding);
}

FFI_PLUGIN_EXPORT char *detectMoney(const unsigned char *pixels, int width, int height) {
    cv::Mat rgb = convertToMat(pixels, width, height, 3);
    ncnn::MutexLockGuard g(lock);
    if (moneyDetection) {
        moneyObjects.clear();
        moneyDetection->detect(rgb, moneyObjects);
    }
    return parseResultsObjects(moneyObjects);
}

FFI_PLUGIN_EXPORT char *detectObject(const unsigned char *pixels, int width, int height) {
    cv::Mat rgb = convertToMat(pixels, width, height, 3);
    ncnn::MutexLockGuard g(lock);
    if (objectDetection) {
        objects.clear();
        objectDetection->detect(rgb, objects);
    }
    return parseResultsObjects(objects);
}

FFI_PLUGIN_EXPORT char *predictLightTraffic(const unsigned char *pixels, int width, int height) {
    cv::Mat rgb = convertToMat(pixels, width, height, 3);
    ncnn::MutexLockGuard g(lock);
    if (lightTraffic) {
        resultLightTraffic.clear();
        for (Object obj: objects) {
            cv::Mat imageLightTraffic = rgb(obj.rect);
            lightTraffic->predict(imageLightTraffic, resultLightTraffic);
            break;
        }
    }
    return parseVector(resultLightTraffic);
}

FFI_PLUGIN_EXPORT char *predictDeaf(const unsigned char *pixels, int width, int height) {
    cv::Mat rgb = convertToMat(pixels, width, height, 3);
    ncnn::MutexLockGuard g(lock);
    if (deafDetection) {
        deafObjects.clear();
        deafDetection->predict(rgb, deafObjects);
    }
    return parseResultsObjects(objects);
}

FFI_PLUGIN_EXPORT char *predictEmotion(const unsigned char *pixels, int width, int height) {
    cv::Mat rgb = convertToMat(pixels, width, height, 3);
    ncnn::MutexLockGuard g(lock);
    if (faceDeafDetection && emotionRecognition) {
        faceObjects.clear();
        scoreEmotions.clear();
        faceDeafDetection->detect(rgb, faceObjects);
        if (!faceObjects.empty()) {
            emotionRecognition->predict(rgb, faceObjects, scoreEmotions);
        }
    }
    return parseVector(scoreEmotions);
}