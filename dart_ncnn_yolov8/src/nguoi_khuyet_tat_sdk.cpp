#include <string>
#include <vector>

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
              "," + std::to_string(faceObject.rect.height) + "\n";

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
    if (bgr.empty()) {
        fprintf(stderr, "cv::imread %s failed\n", image_path);
    }
    {
        ncnn::MutexLockGuard g(lock);
        if (faceRecognition && faceDetection) {
            cv::Mat rgb;
            cv::cvtColor(bgr, rgb, cv::COLOR_BGR2RGB);
            faceDetection->detect(rgb, faceObjects);
            if (!faceObjects.empty()) {
                faceRecognition->getEmbeding(rgb, faceObjects[0].landmark, embedding, faceAligned);
            }
        }
    }
    return parseVector(embedding);
}

FFI_PLUGIN_EXPORT char *
getFaceObjectWithPixels(const unsigned char *pixels, int width, int height) {
    cv::Mat rgb = convertToMat(pixels, width, height, 3);
    if (rgb.empty()) {
        fprintf(stderr, "cv::imread %s failed\n", image_path);
    }
    {
        ncnn::MutexLockGuard g(lock);
        if (faceDetection) {
            faceObjects.clear();
            faceDetection->detect(rgb, faceObjects);
        }
    }
    return parseResultsFaceObjects(faceObjects);
}

FFI_PLUGIN_EXPORT char *getEmbeddingWithPixels(const unsigned char *pixels, int width, int height) {
    cv::Mat rgb = convertToMat(pixels, width, height, 3);
    if (rgb.empty()) {
        fprintf(stderr, "cv::imread %s failed\n", image_path);
    }
    {
        ncnn::MutexLockGuard g(lock);
        if (faceRecognition) {
            if (!faceObjects.empty()) {
                faceRecognition->getEmbeding(rgb, faceObjects[0].landmark, embedding, faceAligned);
            }
        }
    }
    return parseVector(embedding);
}

FFI_PLUGIN_EXPORT char *detectMoney(const unsigned char *pixels, int width, int height) {
    cv::Mat rgb = convertToMat(pixels, width, height, 3);
    if (rgb.empty()) {
        fprintf(stderr, "cv::imread %s failed\n", image_path);
    }
    {
        ncnn::MutexLockGuard g(lock);
        if (moneyDetection) {
            moneyDetection->detect(rgb, moneyObjects);
        }
    }
    return parseResultsObjects(moneyObjects);
}

void MyNdkCamera::on_image_render(cv::Mat &rgb) const {
    {
        ncnn::MutexLockGuard g(lock);
        image = rgb.clone();
        if (g_yolov11) {
            moneyObjects.clear();
            g_yolov11->detect(rgb, moneyObjects);
        }
        if (g_yolo && indoorDetection) {

            indoorObjects.clear();
            indoorDetection->detect(rgb, indoorObjects);

            objects.clear();
            g_yolo->detect(rgb, objects);
            for (Object obj: objects) {
                if (obj.label == 9) {
                    cv::Mat roi = rgb(obj.rect);
                    g_lightTraffic->predict(roi, resultLightTraffic);
                    break;
                }
            }

        }
        if (g_scrfd) {
            faceObjects.clear();
            g_scrfd->detect(rgb, faceObjects);
            if (!faceObjects.empty()) {
                g_faceEmb->getEmbeding(rgb, faceObjects[0].landmark, embedding, faceAligned);
            }
        }

        if (!objects.empty()) {
            g_yolo->draw(rgb, objects);
        }
        if (!moneyObjects.empty()) {
            g_yolov11->draw(rgb, moneyObjects);
        }
        if (!faceObjects.empty()) {
            g_scrfd->draw(rgb, faceObjects);
        }
        if (!indoorObjects.empty()) {
            indoorDetection->draw(rgb, indoorObjects);
        }

        if (g_scrfd_deaf && g_emotion && g_yolo9) {
            scoreEmotions.clear();
            objectsV9.clear();
            g_scrfd_deaf->detect(rgb, faceObjects);
            if (!faceObjects.empty()) {
                g_yolo9->detect(rgb, objectsV9);
                g_emotion->predict(rgb, faceObjects[0], scoreEmotions);
                g_emotion->draw(rgb, faceObjects[0], scoreEmotions);
                g_yolo9->draw(rgb, objectsV9);
            }
        }
    }
}

static MyNdkCamera *g_camera = 0;

extern "C" {
JNIEXPORT jint
JNI_OnLoad(JavaVM * vm , void *reserved ) {
g_camera = new MyNdkCamera;

return JNI_VERSION_1_4;
}

JNIEXPORT void JNI_OnUnload(JavaVM * vm, void * reserved) {
    {
        ncnn::MutexLockGuard g(lock);
        delete g_yolo;
        g_yolo = 0;
        delete g_scrfd;
        g_scrfd = 0;
        delete g_faceEmb;
        g_faceEmb = 0;
        delete g_lightTraffic;
        g_lightTraffic = 0;
        delete g_yolov11;
        g_yolov11 = 0;


        delete g_scrfd_deaf;
        g_scrfd_deaf = 0;

        delete g_emotion;
        g_emotion = 0;

        delete g_yolo9;
        g_yolo9 = 0;

        delete indoorDetection;
        indoorDetection = 0;
    }

    delete g_camera;
    g_camera = 0;
}


}

jobject mat_to_bitmap(JNIEnv *env, Mat &src, bool needPremultiplyAlpha) {
    jclass java_bitmap_class = env->FindClass("android/graphics/Bitmap");
    jclass bmpCfgCls = env->FindClass("android/graphics/Bitmap$Config");
    jmethodID bmpClsValueOfMid = env->GetStaticMethodID(bmpCfgCls, "valueOf",
                                                        "(Ljava/lang/String;)Landroid/graphics/Bitmap$Config;");
    jobject jBmpCfg = env->CallStaticObjectMethod(bmpCfgCls, bmpClsValueOfMid,
                                                  env->NewStringUTF("ARGB_8888"));

    jmethodID mid = env->GetStaticMethodID(java_bitmap_class,
                                           "createBitmap",
                                           "(IILandroid/graphics/Bitmap$Config;)Landroid/graphics/Bitmap;");

    jobject bitmap = env->CallStaticObjectMethod(java_bitmap_class,
                                                 mid, src.cols, src.rows,
                                                 jBmpCfg);

    AndroidBitmapInfo info;
    void *pixels = nullptr;


    // Validate
    if (AndroidBitmap_getInfo(env, bitmap, &info) < 0) {
        std::runtime_error("Failed to get Bitmap info.");
    }
    if (src.type() != CV_8UC1 && src.type() != CV_8UC3 && src.type() != CV_8UC4) {
        std::runtime_error("Unsupported cv::Mat type.");
    }
    if (AndroidBitmap_lockPixels(env, bitmap, &pixels) < 0) {
        std::runtime_error("Failed to lock Bitmap pixels.");
    }
    if (!pixels) {
        std::runtime_error("Bitmap pixels are null.");
    }

    // Convert cv::Mat to the Bitmap format
    if (info.format == ANDROID_BITMAP_FORMAT_RGBA_8888) {
        Mat tmp(info.height, info.width, CV_8UC4, pixels);
        if (src.type() == CV_8UC1) {
            cvtColor(src, tmp, COLOR_GRAY2RGBA);
        } else if (src.type() == CV_8UC3) {
            cvtColor(src, tmp, COLOR_RGB2RGBA);
        } else if (src.type() == CV_8UC4) {
            if (needPremultiplyAlpha) {
                cvtColor(src, tmp, COLOR_RGBA2mRGBA);
            } else {
                src.copyTo(tmp);
            }
        }
    } else if (info.format == ANDROID_BITMAP_FORMAT_RGB_565) {
        Mat tmp(info.height, info.width, CV_8UC2, pixels);
        if (src.type() == CV_8UC1) {
            cvtColor(src, tmp, COLOR_GRAY2BGR565);
        } else if (src.type() == CV_8UC3) {
            cvtColor(src, tmp, COLOR_RGB2BGR565);
        } else if (src.type() == CV_8UC4) {
            cvtColor(src, tmp, COLOR_RGBA2BGR565);
        }
    }

    AndroidBitmap_unlockPixels(env, bitmap);
    return bitmap;
}

extern "C"
JNIEXPORT jobject

JNICALL
Java_com_tondz_nguoimu_NguoiMuSDK_getFaceAlign(JNIEnv *env, jobject thiz) {
    jobject bitmap = mat_to_bitmap(env, faceAligned, false);
    return bitmap;
}

extern "C"
JNIEXPORT jstring

JNICALL
Java_com_tondz_nguoimu_NguoiMuSDK_getEmbeddingFromPath(JNIEnv *env, jobject thiz, jstring path) {
    std::vector<float> result;
    jboolean isCopy;
    const char *convertedValue = (env)->GetStringUTFChars(path, &isCopy);
    std::string strPath = convertedValue;
    static std::vector <FaceObject> faceObjects1;
    static std::vector<float> embedding1;
    static cv::Mat faceAligned1;


    cv::Mat bgr = imread(strPath, IMREAD_COLOR);
    cv::Mat rgb;
    cv::cvtColor(bgr, rgb, cv::COLOR_BGR2RGB);
    g_scrfd->detect(rgb, faceObjects1);
    __android_log_print(ANDROID_LOG_DEBUG, "LOGFACE", "len face %f", faceObjects1[0].rect.width);
    if (faceObjects1.size() > 0) {
        g_faceEmb->getEmbeding(bgr, faceObjects1[0].landmark, embedding1, faceAligned1);
        __android_log_print(ANDROID_LOG_DEBUG, "LOGFACE", "len embedding %zu", embedding1.size());
        std::ostringstream oss;

        // Convert each element to string and add it to the stream
        for (size_t i = 0; i < embedding1.size(); ++i) {
            if (i != 0) {
                oss << ",";  // Add a separator between elements
            }
            oss << embedding1[i];
        }

        // Convert the stream to a string
        std::string embeddingStr = oss.str();
        return env->NewStringUTF(embeddingStr.c_str());
    }
    return env->NewStringUTF("");
}

extern "C"
JNIEXPORT jobject

JNICALL
Java_com_tondz_nguoimu_NguoiMuSDK_getFaceAlignFromPath(JNIEnv *env, jobject thiz, jstring path) {
    std::vector<float> result;
    jboolean isCopy;
    const char *convertedValue = (env)->GetStringUTFChars(path, &isCopy);
    std::string strPath = convertedValue;
    static std::vector <FaceObject> faceObjects1;
    static std::vector<float> embedding1;
    static cv::Mat faceAligned1;


    cv::Mat bgr = imread(strPath, IMREAD_COLOR);
    cv::Mat rgb;
    cv::cvtColor(bgr, rgb, cv::COLOR_BGR2RGB);


    g_scrfd->detect(rgb, faceObjects1);
    __android_log_print(ANDROID_LOG_DEBUG, "LOGFACE", "len face %f", faceObjects1[0].rect.width);
    if (faceObjects1.size() > 0) {
        g_faceEmb->getEmbeding(rgb, faceObjects1[0].landmark, embedding1, faceAligned1);
        jobject bitmap = mat_to_bitmap(env, faceAligned1, false);
        return bitmap;
    }
    jobject bitmap = mat_to_bitmap(env, faceAligned1, false);
    return bitmap;
}

extern "C"
JNIEXPORT jstring

JNICALL
Java_com_tondz_nguoimu_NguoiMuSDK_getLightTraffic(JNIEnv *env, jobject thiz) {
    if (resultLightTraffic.size() > 0) {
        std::ostringstream oss;
        // Convert each element to string and add it to the stream
        for (size_t i = 0; i < resultLightTraffic.size(); ++i) {
            if (i != 0) {
                oss << ",";  // Add a separator between elements
            }
            oss << resultLightTraffic[i];
        }

        // Convert the stream to a string
        std::string embeddingStr = oss.str();
        resultLightTraffic.clear();
        return env->NewStringUTF(embeddingStr.c_str());
    }
    return env->NewStringUTF("");
}

extern "C"
JNIEXPORT jstring

JNICALL
Java_com_tondz_nguoimu_NguoiMuSDK_getEmotion(JNIEnv *env, jobject thiz) {
    if (!scoreEmotions.empty()) {
        std::ostringstream oss;

        // Convert each element to string and add it to the stream
        for (size_t i = 0; i < scoreEmotions.size(); ++i) {
            if (i != 0) {
                oss << ",";  // Add a separator between elements
            }
            oss << scoreEmotions[i];
        }
        // Convert the stream to a string
        std::string embeddingStr = oss.str();
        return env->NewStringUTF(embeddingStr.c_str());
    }
    return env->NewStringUTF("");
}

extern "C"
JNIEXPORT jstring

JNICALL
Java_com_tondz_nguoimu_NguoiMuSDK_getDeaf(JNIEnv *env, jobject thiz) {
    if (!objectsV9.empty() && !scoreEmotions.empty()) {
        std::ostringstream oss;

        oss << objectsV9[0].label << " " << objectsV9[0].rect.x << " " << objectsV9[0].rect.y << " "
            << objectsV9[0].rect.width << " " << objectsV9[0].rect.height << "#";

        for (size_t i = 0; i < scoreEmotions.size(); ++i) {
            if (i != 0) {
                oss << ",";  // Add a separator between elements
            }
            oss << scoreEmotions[i];
        }


        std::string embeddingStr = oss.str();
        return env->NewStringUTF(embeddingStr.c_str());
    }
    return env->NewStringUTF("");
}

extern "C"
JNIEXPORT jobject

JNICALL
Java_com_tondz_nguoimu_NguoiMuSDK_getListMoneyResult(JNIEnv *env, jobject thiz) {
    jclass arrayListClass = env->FindClass("java/util/ArrayList");
    jmethodID arrayListConstructor = env->GetMethodID(arrayListClass, "<init>", "()V");
    jobject arrayList = env->NewObject(arrayListClass, arrayListConstructor);

    // Get the add method of ArrayList
    jmethodID arrayListAdd = env->GetMethodID(arrayListClass, "add", "(Ljava/lang/Object;)Z");
    for (const Object &obj: moneyObjects) {
        std::ostringstream oss;
        oss << obj.label << " " << obj.rect.x << " " << obj.rect.y << " "
            << obj.rect.width << " " << obj.rect.height << " " << obj.prob;
        std::string objName = oss.str();
        jstring javaString = env->NewStringUTF(objName.c_str());  // Convert to jstring
        env->CallBooleanMethod(arrayList, arrayListAdd, javaString);
        env->DeleteLocalRef(javaString);  // Clean up local reference
    }
    moneyObjects.clear();
    return arrayList;
}

extern "C"
JNIEXPORT jobject

JNICALL
Java_com_tondz_nguoimu_NguoiMuSDK_getImage(JNIEnv *env, jobject thiz) {
    jobject bitmap = mat_to_bitmap(env, image, false);
    return bitmap;
}