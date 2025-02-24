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
#include <sstream> // Để sử dụng std::ostringstream

void logScores(const std::vector<float> &scores) {
    std::ostringstream oss;
    oss << "Scores: ";
    for (size_t i = 0; i < scores.size(); ++i) {
        oss << scores[i];
        if (i < scores.size() - 1) {
            oss << ", ";
        }
    }
    NCNN_LOGE("%s", oss.str().c_str());
}

int getMaxIndex(const std::vector<float> &scores) {
    if (scores.empty()) return -1;

    int maxIndex = 0;
    float maxValue = scores[0];

    for (int i = 1; i < scores.size(); i++) {
        if (scores[i] > maxValue) {
            maxValue = scores[i];
            maxIndex = i;
        }
    }

    return maxIndex;
}

cv::Mat convertToMat(const unsigned char *pixels, int width, int height, int channels) {
    int type = (channels == 1) ? CV_8UC1 : CV_8UC3;
    return cv::Mat(height, width, type, const_cast<unsigned char *>(pixels)).clone();
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
    FaceObject faceObject = faceObjects[0];
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
load(int deaf, int blind,
     char *object_detection_model, char *object_detection_param,
     char *face_detection_model, char *face_detection_param,
     char *light_traffic_model, char *light_traffic_param,
     char *emotion_model, char *emotion_param,
     char *face_reg_model, char *face_reg_param,
     char *face_deaf_model, char *face_deaf_param,
     char *deaf_model, char *deaf_param,
     char *money_model, char *money_param
) {
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
            if (!faceDetection)
                faceDetection = new SCRFD();
            faceDetection->load(face_detection_model, face_detection_param);

            if (!emotionRecognition)
                emotionRecognition = new EmotionRecognition();
            emotionRecognition->load(emotion_model, emotion_param);

            if (!deafDetection)
                deafDetection = new DeafDetection();
            deafDetection->load(320, norm_vals[0], deaf_model, deaf_param);
        } else {

            if (!lightTraffic) {
                lightTraffic = new LightTraffic();
            }

            lightTraffic->load(light_traffic_model, light_traffic_param);

            if (!objectDetection) {
                objectDetection = new ObjectDetection();
            }
            objectDetection->load(640, mean_vals[0],
                                  norm_vals[0], object_detection_model, object_detection_param);

            if (!faceDetection)
                faceDetection = new SCRFD();
            faceDetection->load(face_detection_model, face_detection_param);
            if (!faceRecognition)
                faceRecognition = new FaceEmb();
            faceRecognition->load(face_reg_model, face_reg_param);
            if (!moneyDetection)
                moneyDetection = new MoneyDetection();
            moneyDetection->load(320, norm_vals[0], money_model, money_param);

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
        int width = rgb.cols;
        int height = rgb.rows;
        faceDetection->detect(rgb.data, ncnn::Mat::PIXEL_RGB, faceObjects, width, height);
        if (!faceObjects.empty()) {
            faceRecognition->getEmbedding(rgb.data, ncnn::Mat::PIXEL_RGB, width, height,
                                          faceObjects[0].landmark, embedding, faceAligned);
        }
    }

    return parseVector(embedding);
}

FFI_PLUGIN_EXPORT char *
detectFaceObjectWithPixels(const unsigned char *pixels, int pixelType, int width, int height) {
//    cv::Mat rgb = cv::Mat(height, width, CV_8UC1, *pixels);
    ncnn::MutexLockGuard g(lock);
    if (faceDetection) {
        faceObjects.clear();
        faceDetection->detect(pixels, pixelType, faceObjects, width, height);
        if (!faceObjects.empty()) {
            NCNN_LOGE("rect.x: %f", faceObjects[0].rect.x);
            NCNN_LOGE("rect.y: %f", faceObjects[0].rect.y);
        }

    }

    return parseResultsFaceObjects(faceObjects);
}

FFI_PLUGIN_EXPORT char *
getEmbeddingWithPixels(const unsigned char *pixels, int pixelType, int width, int height) {
//    cv::Mat rgb = cv::Mat(height, width, CV_8UC1, *pixels);
    ncnn::MutexLockGuard g(lock);
    if (faceRecognition) {
        if (!faceObjects.empty()) {
            embedding.clear();
            faceRecognition->getEmbedding(pixels, pixelType, width, height,
                                          faceObjects[0].landmark, embedding, faceAligned);
        }
    }

    return parseVector(embedding);
}

FFI_PLUGIN_EXPORT char *
detectMoney(const unsigned char *pixels, int pixelType, int width, int height) {
    ncnn::MutexLockGuard g(lock);
    if (moneyDetection) {
        moneyObjects.clear();
        moneyDetection->detect(pixels, pixelType, moneyObjects, width, height);
    }
    return parseResultsObjects(moneyObjects);
}

FFI_PLUGIN_EXPORT char *
detectObject(const unsigned char *pixels, int pixelType, int width, int height) {
    ncnn::MutexLockGuard g(lock);
    if (objectDetection && moneyDetection) {
        objects.clear();
        moneyDetection->detect(pixels, pixelType, objects, width, height);
        if (objects.empty()) {
            objectDetection->detect(pixels, pixelType, objects, width, height);
        }

    }
    return parseResultsObjects(objects);
}

FFI_PLUGIN_EXPORT char *
predictLightTraffic(const unsigned char *pixels, int pixelType, int width, int height) {

    ncnn::MutexLockGuard g(lock);
    if (lightTraffic) {
        resultLightTraffic.clear();
        cv::Mat rgb(height, width, CV_8UC3, (void *) pixels);;
        for (Object obj: objects) {
            cv::Mat imageLightTraffic = rgb(obj.rect);
            lightTraffic->predict(imageLightTraffic.data, pixelType, imageLightTraffic.cols,
                                  imageLightTraffic.rows, resultLightTraffic);
            break;
        }
    }
    return parseVector(resultLightTraffic);
}

FFI_PLUGIN_EXPORT char *
predictDeaf(const unsigned char *pixels, int pixelType, int width, int height) {
    ncnn::MutexLockGuard g(lock);
    if (deafDetection && faceDetection && emotionRecognition) {
        deafObjects.clear();
        faceObjects.clear();
        deafDetection->detect(pixels, pixelType, deafObjects, width, height);
        faceDetection->detect(pixels, pixelType, faceObjects, width, height);

        if (!faceObjects.empty()) {
            std::vector <Object> tempObjects;
            tempObjects.resize(faceObjects.size() + deafObjects.size());
            for (int i = 0; i < deafObjects.size(); ++i) {
                tempObjects[i] = deafObjects[i];
            }
            for (int i = 0; i < faceObjects.size(); ++i) {
                int indexObject = i + deafObjects.size();
                FaceObject faceObject = faceObjects[i];
                tempObjects[indexObject].rect = faceObject.rect;
                scoreEmotions.clear();
                emotionRecognition->predict(pixels, pixelType, width, height, faceObject,
                                            scoreEmotions);
                if (!scoreEmotions.empty()) {
                    int idx = getMaxIndex(scoreEmotions);
                    tempObjects[indexObject].prob = scoreEmotions[idx];
                    tempObjects[indexObject].label = idx + 19;
                }
            }
            deafObjects = tempObjects;
        }
    }
    return parseResultsObjects(deafObjects);
}

FFI_PLUGIN_EXPORT char *
lightDetection(const unsigned char *pixels, int pixelType, int width, int height){
    cv::Mat rgb = cv::Mat(height, width, CV_8UC1, *pixels);

    cv::Mat gray;
    if (rgb.channels() == 3) {
        cv::cvtColor(rgb, gray, cv::COLOR_RGB2GRAY); // Chuyển sang ảnh xám
    } else {
        gray = rgb.clone(); // Nếu đã là ảnh xám, giữ nguyên
    }

    double meanBrightness = cv::mean(gray)[0]; // Lấy giá trị trung bình
    return (meanBrightness >= 128) ? "bright" : "dark";
}