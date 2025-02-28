#if _WIN32
#include <windows.h>
#else

#include <pthread.h>
#include <unistd.h>

#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

// YOLO
FFI_PLUGIN_EXPORT void
yuv420sp2rgb(const unsigned char *yuv420sp, int width, int height, unsigned char *rgb);

FFI_PLUGIN_EXPORT void
rgb2rgba(const unsigned char *rgb, int width, int height, unsigned char *rgba);

FFI_PLUGIN_EXPORT void
kannaRotate(const unsigned char *src, int channel, int srcw, int srch, unsigned char *dst,
            int dsw, int dsh, int type);

FFI_PLUGIN_EXPORT void
load(int deaf, int blind, char *object_detection_model, char *object_detection_param,
     char *face_detection_model, char *face_detection_param,
     char *light_traffic_model, char *light_traffic_param,
     char *emotion_model, char *emotion_param,
     char *face_reg_model, char *face_reg_param,
     char *face_deaf_model, char *face_deaf_param,
     char *deaf_model, char *deaf_param,
     char *money_model, char *model_param);

FFI_PLUGIN_EXPORT void unLoad();

FFI_PLUGIN_EXPORT char *getEmbeddingFromPath(const char *image_path);

FFI_PLUGIN_EXPORT char *
detectFaceObjectWithPixels(const unsigned char *pixels, int pixelType, int width, int height);

FFI_PLUGIN_EXPORT char *
getEmbeddingWithPixels(const unsigned char *pixels, int pixelType, int width, int height);

FFI_PLUGIN_EXPORT char *
detectMoney(const unsigned char *pixels, int pixelType, int width, int height);

FFI_PLUGIN_EXPORT char *
detectObject(const unsigned char *pixels, int pixelType, int width, int height);

FFI_PLUGIN_EXPORT char *
predictLightTraffic(const unsigned char *pixels, int pixelType, int width, int height);

FFI_PLUGIN_EXPORT char *
predictDeaf(const unsigned char *pixels, int pixelType, int width, int height);

FFI_PLUGIN_EXPORT char *
lightDetection(const unsigned char *pixels, int pixelType, int width, int height);


#ifdef __cplusplus
}
#endif
