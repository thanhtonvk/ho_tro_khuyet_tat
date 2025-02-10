# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(nguoi_khuyet_tat_sdk_library VERSION 0.0.1 LANGUAGES CXX)

get_filename_component(PROJECT_FOLDER ${CMAKE_CURRENT_SOURCE_DIR} DIRECTORY)
if (CMAKE_SYSTEM_NAME STREQUAL "Android")
    set(ncnn_DIR ${PROJECT_FOLDER}/android/src/main/cpp/ncnn-20230517-android-vulkan/${ANDROID_ABI}/lib/cmake/ncnn)
    set(OpenCV_DIR ${PROJECT_FOLDER}/android/src/main/cpp/opencv-mobile-4.6.0-android/sdk/native/jni)
else ()
    message(FATAL_ERROR "system not support: ${CMAKE_SYSTEM_NAME}")
endif ()

find_package(OpenCV 4 REQUIRED)

find_package(ncnn REQUIRED)

include_directories(
        ${PROJECT_FOLDER}/src
        ${OpenCV_INCLUDE_DIRS}
)
add_library(nguoi_khuyet_tat_sdk SHARED
        "scrfd_deaf.cpp"
        "nguoi_khuyet_tat_sdk.cpp"
        "deaf_detection.cpp"
        "emotion_recognition.cpp"
        "light_traffic.cpp"
        "money_detection.cpp"
        "object_detection.cpp"
        "scrfd.cpp"
        "face_emb.cpp"
)


set_target_properties(nguoi_khuyet_tat_sdk PROPERTIES
        PUBLIC_HEADER nguoi_khuyet_tat_sdk.h
        OUTPUT_NAME "nguoi_khuyet_tat_sdk"
)

target_link_libraries(nguoi_khuyet_tat_sdk
        ncnn
        ${OpenCV_LIBS}
)

target_compile_definitions(nguoi_khuyet_tat_sdk PUBLIC DART_SHARED_LIB)
