#include "scrfd_deaf.h"

#include <string.h>
#include <opencv2/core/core.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include "cpu.h"

static inline float intersection_area(const Object &a, const Object &b) {
    cv::Rect_<float> inter = a.rect & b.rect;
    return inter.area();
}

static void qsort_descent_inplace(std::vector <Object> &faceobjects, int left, int right) {
    int i = left;
    int j = right;
    float p = faceobjects[(left + right) / 2].prob;

    while (i <= j) {
        while (faceobjects[i].prob > p)
            i++;

        while (faceobjects[j].prob < p)
            j--;

        if (i <= j) {
            // swap
            std::swap(faceobjects[i], faceobjects[j]);

            i++;
            j--;
        }
    }

//     #pragma omp parallel sections
    {
//         #pragma omp section
        {
            if (left < j) qsort_descent_inplace(faceobjects, left, j);
        }
//         #pragma omp section
        {
            if (i < right) qsort_descent_inplace(faceobjects, i, right);
        }
    }
}

static void qsort_descent_inplace(std::vector <Object> &faceobjects) {
    if (faceobjects.empty())
        return;

    qsort_descent_inplace(faceobjects, 0, faceobjects.size() - 1);
}

static void nms_sorted_bboxes(const std::vector <Object> &faceobjects, std::vector<int> &picked,
                              float nms_threshold) {
    picked.clear();

    const int n = faceobjects.size();

    std::vector<float> areas(n);
    for (int i = 0; i < n; i++) {
        areas[i] = faceobjects[i].rect.area();
    }

    for (int i = 0; i < n; i++) {
        const Object &a = faceobjects[i];

        int keep = 1;
        for (int j = 0; j < (int) picked.size(); j++) {
            const Object &b = faceobjects[picked[j]];

            // intersection over union
            float inter_area = intersection_area(a, b);
            float union_area = areas[i] + areas[picked[j]] - inter_area;
            //             float IoU = inter_area / union_area
            if (inter_area / union_area > nms_threshold)
                keep = 0;
        }

        if (keep)
            picked.push_back(i);
    }
}

// insightface/detection/scrfd_deaf/mmdet/core/anchor/anchor_generator.py gen_single_level_base_anchors()
static ncnn::Mat generate_anchors(int base_size, const ncnn::Mat &ratios, const ncnn::Mat &scales) {
    int num_ratio = ratios.w;
    int num_scale = scales.w;

    ncnn::Mat anchors;
    anchors.create(4, num_ratio * num_scale);

    const float cx = 0;
    const float cy = 0;

    for (int i = 0; i < num_ratio; i++) {
        float ar = ratios[i];

        int r_w = round(base_size / sqrt(ar));
        int r_h = round(r_w * ar); //round(base_size * sqrt(ar));

        for (int j = 0; j < num_scale; j++) {
            float scale = scales[j];

            float rs_w = r_w * scale;
            float rs_h = r_h * scale;

            float *anchor = anchors.row(i * num_scale + j);

            anchor[0] = cx - rs_w * 0.5f;
            anchor[1] = cy - rs_h * 0.5f;
            anchor[2] = cx + rs_w * 0.5f;
            anchor[3] = cy + rs_h * 0.5f;
        }
    }

    return anchors;
}

static void
generate_proposals(const ncnn::Mat &anchors, int feat_stride, const ncnn::Mat &score_blob,
                   const ncnn::Mat &bbox_blob, const ncnn::Mat &kps_blob, float prob_threshold,
                   std::vector <Object> &faceobjects) {
    int w = score_blob.w;
    int h = score_blob.h;

    // generate face proposal from bbox deltas and shifted anchors
    const int num_anchors = anchors.h;

    for (int q = 0; q < num_anchors; q++) {
        const float *anchor = anchors.row(q);

        const ncnn::Mat score = score_blob.channel(q);
        const ncnn::Mat bbox = bbox_blob.channel_range(q * 4, 4);

        // shifted anchor
        float anchor_y = anchor[1];

        float anchor_w = anchor[2] - anchor[0];
        float anchor_h = anchor[3] - anchor[1];

        for (int i = 0; i < h; i++) {
            float anchor_x = anchor[0];

            for (int j = 0; j < w; j++) {
                int index = i * w + j;

                float prob = score[index];

                if (prob >= prob_threshold) {
                    // insightface/detection/scrfd_deaf/mmdet/models/dense_heads/scrfd_deaf_head.py _get_bboxes_single()
                    float dx = bbox.channel(0)[index] * feat_stride;
                    float dy = bbox.channel(1)[index] * feat_stride;
                    float dw = bbox.channel(2)[index] * feat_stride;
                    float dh = bbox.channel(3)[index] * feat_stride;

                    // insightface/detection/scrfd_deaf/mmdet/core/bbox/transforms.py distance2bbox()
                    float cx = anchor_x + anchor_w * 0.5f;
                    float cy = anchor_y + anchor_h * 0.5f;

                    float x0 = cx - dx;
                    float y0 = cy - dy;
                    float x1 = cx + dw;
                    float y1 = cy + dh;

                    Object obj;
                    obj.rect.x = x0;
                    obj.rect.y = y0;
                    obj.rect.width = x1 - x0 + 1;
                    obj.rect.height = y1 - y0 + 1;
                    obj.prob = prob;
                    obj.label = 20;
                    faceobjects.push_back(obj);
                }

                anchor_x += feat_stride;
            }

            anchor_y += feat_stride;
        }
    }
}

int SCRFD_DEAF::load(const char *model_path,
                     const char *param_path) {
    scrfd_deaf.clear();
    ncnn::set_cpu_powersave(2);
    ncnn::set_omp_num_threads(ncnn::get_big_cpu_count());

    scrfd_deaf.opt = ncnn::Option();

#if NCNN_VULKAN
    scrfd_deaf.opt.use_vulkan_compute = false;
#endif

    scrfd_deaf.opt.num_threads = ncnn::get_big_cpu_count();

//    char parampath[256];
//    char modelpath[256];
//    sprintf(parampath, "assets/yolo/scrfd_deaf_2.5g_kps-opt2.param");
//    sprintf(modelpath, "assets/yolo/scrfd_deaf_2.5g_kps-opt2.bin");

    scrfd_deaf.load_param(param_path);
    scrfd_deaf.load_model(model_path);

    return 0;
}


int
SCRFD_DEAF::detect(const unsigned char *pixels, int pixelType,
                   std::vector <Object> &faceobjects,
                   int width, int height, float prob_threshold,
                   float nms_threshold) {
    const int target_size = 640;

    // pad to multiple of 32
    int w = width;
    int h = height;
    float scale = 1.f;
    if (w > h) {
        scale = (float) target_size / w;
        w = target_size;
        h = h * scale;
    } else {
        scale = (float) target_size / h;
        h = target_size;
        w = w * scale;
    }

    ncnn::Mat in = ncnn::Mat::from_pixels_resize(pixels, pixelType, width, height, w, h);

    // pad to target_size rectangle
    int wpad = (w + 31) / 32 * 32 - w;
    int hpad = (h + 31) / 32 * 32 - h;
    ncnn::Mat in_pad;
    ncnn::copy_make_border(in, in_pad, hpad / 2, hpad - hpad / 2, wpad / 2, wpad - wpad / 2,
                           ncnn::BORDER_CONSTANT, 0.f);

    const float mean_vals[3] = {127.5f, 127.5f, 127.5f};
    const float norm_vals[3] = {1 / 128.f, 1 / 128.f, 1 / 128.f};
    in_pad.substract_mean_normalize(mean_vals, norm_vals);

    ncnn::Extractor ex = scrfd_deaf.create_extractor();

    ex.input("input.1", in_pad);

    std::vector <Object> faceproposals;

    // stride 8
    {
        ncnn::Mat score_blob, bbox_blob, kps_blob;
        ex.extract("score_8", score_blob);
        ex.extract("bbox_8", bbox_blob);
        ex.extract("kps_8", kps_blob);

        const int base_size = 16;
        const int feat_stride = 8;
        ncnn::Mat ratios(1);
        ratios[0] = 1.f;
        ncnn::Mat scales(2);
        scales[0] = 1.f;
        scales[1] = 2.f;
        ncnn::Mat anchors = generate_anchors(base_size, ratios, scales);

        std::vector <Object> faceobjects8;
        generate_proposals(anchors, feat_stride, score_blob, bbox_blob, kps_blob, prob_threshold,
                           faceobjects8);

        faceproposals.insert(faceproposals.end(), faceobjects8.begin(), faceobjects8.end());
    }

    // stride 16
    {
        ncnn::Mat score_blob, bbox_blob, kps_blob;
        ex.extract("score_16", score_blob);
        ex.extract("bbox_16", bbox_blob);
        ex.extract("kps_16", kps_blob);

        const int base_size = 64;
        const int feat_stride = 16;
        ncnn::Mat ratios(1);
        ratios[0] = 1.f;
        ncnn::Mat scales(2);
        scales[0] = 1.f;
        scales[1] = 2.f;
        ncnn::Mat anchors = generate_anchors(base_size, ratios, scales);

        std::vector <Object> faceobjects16;
        generate_proposals(anchors, feat_stride, score_blob, bbox_blob, kps_blob, prob_threshold,
                           faceobjects16);

        faceproposals.insert(faceproposals.end(), faceobjects16.begin(), faceobjects16.end());
    }

    // stride 32
    {
        ncnn::Mat score_blob, bbox_blob, kps_blob;
        ex.extract("score_32", score_blob);
        ex.extract("bbox_32", bbox_blob);
        ex.extract("kps_32", kps_blob);

        const int base_size = 256;
        const int feat_stride = 32;
        ncnn::Mat ratios(1);
        ratios[0] = 1.f;
        ncnn::Mat scales(2);
        scales[0] = 1.f;
        scales[1] = 2.f;
        ncnn::Mat anchors = generate_anchors(base_size, ratios, scales);

        std::vector <Object> faceobjects32;
        generate_proposals(anchors, feat_stride, score_blob, bbox_blob, kps_blob, prob_threshold,
                           faceobjects32);

        faceproposals.insert(faceproposals.end(), faceobjects32.begin(), faceobjects32.end());
    }

    // sort all proposals by score from highest to lowest
    qsort_descent_inplace(faceproposals);

    // apply nms with nms_threshold
    std::vector<int> picked;
    nms_sorted_bboxes(faceproposals, picked, nms_threshold);

    int face_count = picked.size();

    faceobjects.resize(face_count);
    for (int i = 0; i < face_count; i++) {
        faceobjects[i] = faceproposals[picked[i]];
        // adjust offset to original unpadded
        float x0 = (faceobjects[i].rect.x - (wpad / 2)) / scale;
        float y0 = (faceobjects[i].rect.y - (hpad / 2)) / scale;
        float x1 = (faceobjects[i].rect.x + faceobjects[i].rect.width - (wpad / 2)) / scale;
        float y1 = (faceobjects[i].rect.y + faceobjects[i].rect.height - (hpad / 2)) / scale;

        x0 = std::max(std::min(x0, (float) width - 1), 0.f);
        y0 = std::max(std::min(y0, (float) height - 1), 0.f);
        x1 = std::max(std::min(x1, (float) width - 1), 0.f);
        y1 = std::max(std::min(y1, (float) height - 1), 0.f);

        faceobjects[i].rect.x = x0;
        faceobjects[i].rect.y = y0;
        faceobjects[i].rect.width = x1 - x0;
        faceobjects[i].rect.height = y1 - y0;
        faceobjects[i].label = 20;
    }

    return 0;
}