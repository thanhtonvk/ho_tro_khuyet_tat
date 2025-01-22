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
static yolov9 *g_yolo9;
static yolov11 *g_yolov11 = 0;
static indoor_detection *indoorDetection = 0;
static ncnn::Mutex lock;


static std::vector<Object> objects;
static std::vector<FaceObject> faceObjects;
static std::vector<Object> moneyObjects;
static std::vector<Object> objectsV9;
static std::vector<Object> indoorObjects;


static std::vector<float> embedding;
static cv::Mat faceAligned;
static std::vector<float> resultLightTraffic;

static std::vector<float> scoreEmotions;
static std::vector<float> scoreDeafs;
static cv::Mat image;

class MyNdkCamera : public NdkCameraWindow {
public:
    virtual void on_image_render(cv::Mat &rgb) const;
};

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
JNI_OnLoad(JavaVM *vm, void *reserved) {
g_camera = new MyNdkCamera;

return JNI_VERSION_1_4;
}

JNIEXPORT void JNI_OnUnload(JavaVM *vm, void *reserved) {
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


extern "C" jboolean
Java_com_tondz_nguoimu_NguoiMuSDK_loadModel(JNIEnv *env, jobject thiz, jobject assetManager,
                                            jint yoloDetect, jint faceDectector,
                                            jint trafficLight, jint isCamDiec, jint money) {
    AAssetManager *mgr = AAssetManager_fromJava(env, assetManager);
    ncnn::MutexLockGuard g(lock);
    const char *modeltype = "n";
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

    int target_size = 640;
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

    if (isCamDiec == 0) {
        if (trafficLight == 1) {
            if (!g_lightTraffic) {
                g_lightTraffic = new LightTraffic;
            }
            g_lightTraffic->load(mgr);
        }
        if (yoloDetect == 1) {
            g_yolo = new Yolo;
            g_yolo->load(mgr, modeltype, target_size, mean_vals[0],
                         norm_vals[0], false);
            indoorDetection = new indoor_detection;
            indoorDetection->load(mgr, 320, norm_vals[0], false);
        }
        if (faceDectector == 1) {
            if (!g_scrfd)
                g_scrfd = new SCRFD;
            g_scrfd->load(mgr, modeltype, false);
            if (!g_faceEmb)
                g_faceEmb = new FaceEmb;
            g_faceEmb->load(mgr);
        }

        if (money == 1) {
            g_yolov11 = new yolov11;
            g_yolov11->load(mgr, 320, norm_vals[0], false);
        }
    }

    if (isCamDiec > 0) {
        if (!g_scrfd_deaf)
            g_scrfd_deaf = new SCRFD_DEAF;
        g_scrfd_deaf->load(mgr, modeltype, false);

        if (!g_emotion)
            g_emotion = new EmotionRecognition;
        g_emotion->load(mgr);

        if (!g_yolo9)
            g_yolo9 = new yolov9;
        g_yolo9->load(mgr, 320, norm_vals[0]);
    }

    return JNI_TRUE;
}
extern "C" jboolean
Java_com_tondz_nguoimu_NguoiMuSDK_openCamera(JNIEnv *env, jobject thiz, jint facing) {
    if (facing < 0 || facing > 1)
        return JNI_FALSE;
    g_camera->open((int) facing);

    return JNI_TRUE;
}

extern "C" jboolean
Java_com_tondz_nguoimu_NguoiMuSDK_closeCamera(JNIEnv *env, jobject thiz) {
    g_camera->close();

    return JNI_TRUE;
}

extern "C" jboolean
Java_com_tondz_nguoimu_NguoiMuSDK_setOutputWindow(JNIEnv *env, jobject thiz, jobject surface) {
    ANativeWindow *win = ANativeWindow_fromSurface(env, surface);
    g_camera->set_window(win);
    return JNI_TRUE;
}

}
extern "C" jobject
Java_com_tondz_nguoimu_NguoiMuSDK_getListResult(JNIEnv *env, jobject thiz) {
    jclass arrayListClass = env->FindClass("java/util/ArrayList");
    jmethodID arrayListConstructor = env->GetMethodID(arrayListClass, "<init>", "()V");
    jobject arrayList = env->NewObject(arrayListClass, arrayListConstructor);

    // Get the add method of ArrayList
    jmethodID arrayListAdd = env->GetMethodID(arrayListClass, "add", "(Ljava/lang/Object;)Z");
    for (const Object &obj: objects) {
        std::ostringstream oss;
        oss << obj.label << " " << obj.rect.x << " " << obj.rect.y << " "
            << obj.rect.width << " " << obj.rect.height;
        std::string objName = oss.str();
        jstring javaString = env->NewStringUTF(objName.c_str());  // Convert to jstring
        env->CallBooleanMethod(arrayList, arrayListAdd, javaString);
        env->DeleteLocalRef(javaString);  // Clean up local reference
    }
    for (const Object &obj: indoorObjects) {
        std::ostringstream oss;
        oss << (obj.label+80) << " " << obj.rect.x << " " << obj.rect.y << " "
            << obj.rect.width << " " << obj.rect.height;
        std::string objName = oss.str();
        jstring javaString = env->NewStringUTF(objName.c_str());  // Convert to jstring
        env->CallBooleanMethod(arrayList, arrayListAdd, javaString);
        env->DeleteLocalRef(javaString);  // Clean up local reference
    }
    indoorObjects.clear();
    objects.clear();
    return arrayList;
}

extern "C"
JNIEXPORT jstring JNICALL
Java_com_tondz_nguoimu_NguoiMuSDK_getEmbedding(JNIEnv *env, jobject thiz) {
    if (embedding.size() > 0) {
        std::ostringstream oss;

        // Convert each element to string and add it to the stream
        for (size_t i = 0; i < embedding.size(); ++i) {
            if (i != 0) {
                oss << ",";  // Add a separator between elements
            }
            oss << embedding[i];
        }

        // Convert the stream to a string
        std::string embeddingStr = oss.str();
        embedding.clear();
        return env->NewStringUTF(embeddingStr.c_str());
    }
    return env->NewStringUTF("");

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
JNIEXPORT jobject JNICALL
Java_com_tondz_nguoimu_NguoiMuSDK_getFaceAlign(JNIEnv *env, jobject thiz) {
    jobject bitmap = mat_to_bitmap(env, faceAligned, false);
    return bitmap;
}
extern "C"
JNIEXPORT jstring JNICALL
Java_com_tondz_nguoimu_NguoiMuSDK_getEmbeddingFromPath(JNIEnv *env, jobject thiz, jstring path) {
    std::vector<float> result;
    jboolean isCopy;
    const char *convertedValue = (env)->GetStringUTFChars(path, &isCopy);
    std::string strPath = convertedValue;
    static std::vector<FaceObject> faceObjects1;
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
JNIEXPORT jobject JNICALL
Java_com_tondz_nguoimu_NguoiMuSDK_getFaceAlignFromPath(JNIEnv *env, jobject thiz, jstring path) {
    std::vector<float> result;
    jboolean isCopy;
    const char *convertedValue = (env)->GetStringUTFChars(path, &isCopy);
    std::string strPath = convertedValue;
    static std::vector<FaceObject> faceObjects1;
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
JNIEXPORT jstring JNICALL
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
JNIEXPORT jstring JNICALL
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
JNIEXPORT jstring JNICALL
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
JNIEXPORT jobject JNICALL
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
JNIEXPORT jobject JNICALL
Java_com_tondz_nguoimu_NguoiMuSDK_getImage(JNIEnv *env, jobject thiz) {
    jobject bitmap = mat_to_bitmap(env, image, false);
    return bitmap;
}