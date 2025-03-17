#include <opencv2/core/core.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/video/background_segm.hpp> // Thêm thư viện xử lý nền
#include <iostream>
#include "any_object_detection.h"

AnyObjectDetection::AnyObjectDetection() {

}

cv::Ptr <cv::BackgroundSubtractorMOG2> fgbg = cv::createBackgroundSubtractorMOG2();

int AnyObjectDetection::detect(const unsigned char *pixels, int pixelType,
                               std::vector <Object> &objects,
                               int width, int height) {
    if (!pixels) {
        std::cerr << "Error: pixels is null!" << std::endl;
        return -1;
    }

    cv::Mat frame(height, width, CV_8UC3, (void *) pixels);
    cv::Mat fgmask, gray;

    // Chuyển ảnh sang grayscale để xử lý tốt hơn
    cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);

    // Làm mịn
    cv::GaussianBlur(gray, gray, cv::Size(5, 5), 0);

    // Áp dụng bộ trừ nền
    fgbg->apply(gray, fgmask);

    // Tìm contours
    std::vector <std::vector<cv::Point>> contours;
    cv::findContours(fgmask, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);

    if (!contours.empty()) {
        auto largest_contour = std::max_element(contours.begin(), contours.end(),
                                                [](const std::vector <cv::Point> &a,
                                                   const std::vector <cv::Point> &b) {
                                                    return cv::contourArea(a) < cv::contourArea(b);
                                                });

        double max_area = cv::contourArea(*largest_contour);
        if (max_area > 2000) { // Chỉ lấy nếu đủ lớn
            cv::Rect bbox = cv::boundingRect(*largest_contour);
            Object obj;
            obj.rect = bbox;
            obj.label = 92;
            obj.prob = 1.0;
            objects.push_back(obj);
        }
    }

    return 0;
}
