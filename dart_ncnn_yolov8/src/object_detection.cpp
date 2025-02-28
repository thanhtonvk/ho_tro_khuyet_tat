#include "object_detection.h"

#include <opencv2/core/core.hpp>
#include <opencv2/imgproc/imgproc.hpp>

#include "cpu.h"

static const unsigned char colors[19][3] = {
        {54,  67,  244},
        {99,  30,  233},
        {176, 39,  156},
        {183, 58,  103},
        {181, 81,  63},
        {243, 150, 33},
        {244, 169, 3},
        {212, 188, 0},
        {136, 150, 0},
        {80,  175, 76},
        {74,  195, 139},
        {57,  220, 205},
        {59,  235, 255},
        {7,   193, 255},
        {0,   152, 255},
        {34,  87,  255},
        {72,  85,  121},
        {158, 158, 158},
        {139, 125, 96}
};
static double knownWidths[] = {
        0.5, 1.7, 1.8, 2.0, 35.0, 2.5, 3.0, 2.5, 3.0, 0.3,
        0.4, 0.75, 0.25, 1.5, 0.3, 0.25, 0.4, 1.8, 1.2, 2.0,
        4.0, 1.5, 1.5, 2.5, 0.3, 0.5, 0.4, 0.2, 0.4, 0.2,
        1.5, 1.5, 0.3, 0.5, 0.7, 0.3, 0.8, 1.5,
        0.4, 0.3, 0.1, 0.1, 0.2, 0.3, 0.3, 0.3, 0.2, 0.2,
        0.4, 0.4, 0.4, 0.4, 0.6, 0.4, 0.4, 0.4, 0.5, 1.5,
        0.4, 2.0, 1.0, 0.5, 1.5, 0.3, 0.1, 0.2, 0.2, 0.1,
        0.5, 0.6, 0.6, 0.4, 0.5, 0.2, 0.2, 0.3, 0.2, 0.2,
        0.4, 0.2
};

static double knownDistances[] = {
        2.0, 5.0, 10.0, 5.0, 100.0, 10.0, 15.0, 10.0, 20.0, 10.0,
        2.0, 10.0, 2.0, 5.0, 2.0, 1.5, 2.0, 5.0, 2.0, 5.0,
        15.0, 5.0, 5.0, 10.0, 2.0, 2.0, 1.5, 1.0, 1.5, 1.5,
        5.0, 5.0, 2.0, 5.0, 5.0, 2.0, 5.0, 5.0,
        2.0, 2.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 2.0,
        2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 5.0,
        2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 1.5, 1.5, 1.5, 1.5,
        2.0, 2.0, 2.0, 2.0, 2.0, 1.5, 1.5, 1.5, 1.5, 1.5,
        2.0, 1.5
};

double calculateFocalLength(double knownDistance, double knownWidth, int widthInImage) {
    return (widthInImage * knownDistance) / knownWidth;
}


double calculateDistance(double knownWidth, double focalLength, int widthInImage) {
    return (knownWidth * focalLength) / widthInImage;
}

static float fast_exp(float x) {
    union {
        uint32_t i;
        float f;
    } v{};
    v.i = (1 << 23) * (1.4426950409 * x + 126.93490512f);
    return v.f;
}

static float sigmoid(float x) {
    return 1.0f / (1.0f + fast_exp(-x));
}

static float intersection_area(const Object &a, const Object &b) {
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
        areas[i] = faceobjects[i].rect.width * faceobjects[i].rect.height;
    }

    for (int i = 0; i < n; i++) {
        const Object &a = faceobjects[i];

        int keep = 1;
        for (int j = 0; j < (int) picked.size(); j++) {
            const Object &b = faceobjects[picked[j]];

            // intersection over union
            float inter_area = intersection_area(a, b);
            float union_area = areas[i] + areas[picked[j]] - inter_area;
            // float IoU = inter_area / union_area
            if (inter_area / union_area > nms_threshold)
                keep = 0;
        }

        if (keep)
            picked.push_back(i);
    }
}

static void
generate_grids_and_stride(const int target_w, const int target_h, std::vector<int> &strides,
                          std::vector <GridAndStride> &grid_strides) {
    for (int i = 0; i < (int) strides.size(); i++) {
        int stride = strides[i];
        int num_grid_w = target_w / stride;
        int num_grid_h = target_h / stride;
        for (int g1 = 0; g1 < num_grid_h; g1++) {
            for (int g0 = 0; g0 < num_grid_w; g0++) {
                GridAndStride gs;
                gs.grid0 = g0;
                gs.grid1 = g1;
                gs.stride = stride;
                grid_strides.push_back(gs);
            }
        }
    }
}

static void generate_proposals(std::vector <GridAndStride> grid_strides, const ncnn::Mat &pred,
                               float prob_threshold, std::vector <Object> &objects) {
    const int num_points = grid_strides.size();
    const int num_class = 80;
    const int reg_max_1 = 16;

    for (int i = 0; i < num_points; i++) {
        const float *scores = pred.row(i) + 4 * reg_max_1;

        // find label with max score
        int label = -1;
        float score = -FLT_MAX;
        for (int k = 0; k < num_class; k++) {
            float confidence = scores[k];
            if (confidence > score) {
                label = k;
                score = confidence;
            }
        }
        float box_prob = sigmoid(score);
        if (box_prob >= 0.3) {
            ncnn::Mat bbox_pred(reg_max_1, 4, (void *) pred.row(i));
            {
                ncnn::Layer *softmax = ncnn::create_layer("Softmax");

                ncnn::ParamDict pd;
                pd.set(0, 1); // axis
                pd.set(1, 1);
                softmax->load_param(pd);

                ncnn::Option opt;
                opt.num_threads = 1;
                opt.use_packing_layout = false;

                softmax->create_pipeline(opt);

                softmax->forward_inplace(bbox_pred, opt);

                softmax->destroy_pipeline(opt);

                delete softmax;
            }

            float pred_ltrb[4];
            for (int k = 0; k < 4; k++) {
                float dis = 0.f;
                const float *dis_after_sm = bbox_pred.row(k);
                for (int l = 0; l < reg_max_1; l++) {
                    dis += l * dis_after_sm[l];
                }

                pred_ltrb[k] = dis * grid_strides[i].stride;
            }

            float pb_cx = (grid_strides[i].grid0 + 0.5f) * grid_strides[i].stride;
            float pb_cy = (grid_strides[i].grid1 + 0.5f) * grid_strides[i].stride;

            float x0 = pb_cx - pred_ltrb[0];
            float y0 = pb_cy - pred_ltrb[1];
            float x1 = pb_cx + pred_ltrb[2];
            float y1 = pb_cy + pred_ltrb[3];

            Object obj;
            obj.rect.x = x0;
            obj.rect.y = y0;
            obj.rect.width = x1 - x0;
            obj.rect.height = y1 - y0;
            obj.label = label;
            obj.prob = box_prob;

            objects.push_back(obj);
        }
    }
}

ObjectDetection::ObjectDetection() {
    blob_pool_allocator.set_size_compare_ratio(0.f);
    workspace_pool_allocator.set_size_compare_ratio(0.f);
}


int ObjectDetection::load(int _target_size, const float *_mean_vals, const float *_norm_vals,
                          const char *model_path,
                          const char *param_path) {
    yolo.clear();
    blob_pool_allocator.clear();
    workspace_pool_allocator.clear();

    ncnn::set_cpu_powersave(2);
    ncnn::set_omp_num_threads(ncnn::get_big_cpu_count());

    yolo.opt = ncnn::Option();

#if NCNN_VULKAN
    yolo.opt.use_vulkan_compute = false;
#endif

    yolo.opt.num_threads = ncnn::get_big_cpu_count();
    yolo.opt.blob_allocator = &blob_pool_allocator;
    yolo.opt.workspace_allocator = &workspace_pool_allocator;

    yolo.load_param(param_path);
    yolo.load_model(model_path);

    target_size = _target_size;
    mean_vals[0] = _mean_vals[0];
    mean_vals[1] = _mean_vals[1];
    mean_vals[2] = _mean_vals[2];
    norm_vals[0] = _norm_vals[0];
    norm_vals[1] = _norm_vals[1];
    norm_vals[2] = _norm_vals[2];

    return 0;
}

int
ObjectDetection::detect(const unsigned char *pixels, int pixelType, std::vector <Object> &objects,
                        int width,
                        int height) {

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

    ncnn::Mat in = ncnn::Mat::from_pixels_resize(pixels, pixelType, width, height,
                                                 w, h);

    // pad to target_size rectangle
    int wpad = (w + 31) / 32 * 32 - w;
    int hpad = (h + 31) / 32 * 32 - h;
    ncnn::Mat in_pad;
    ncnn::copy_make_border(in, in_pad, hpad / 2, hpad - hpad / 2, wpad / 2, wpad - wpad / 2,
                           ncnn::BORDER_CONSTANT, 0.f);

    in_pad.substract_mean_normalize(0, norm_vals);

    ncnn::Extractor ex = yolo.create_extractor();

    ex.input("images", in_pad);

    std::vector <Object> proposals;

    ncnn::Mat out;
    ex.extract("output", out);

    std::vector<int> strides = {8, 16, 32}; // might have stride=64
    std::vector <GridAndStride> grid_strides;
    generate_grids_and_stride(in_pad.w, in_pad.h, strides, grid_strides);
    generate_proposals(grid_strides, out, 0.3, proposals);

    // sort all proposals by score from highest to lowest
    qsort_descent_inplace(proposals);

    // apply nms with nms_threshold
    std::vector<int> picked;
    nms_sorted_bboxes(proposals, picked, 0.3);

    int count = picked.size();

    objects.resize(count);
    for (int i = 0; i < count; i++) {
        objects[i] = proposals[picked[i]];

        // adjust offset to original unpadded
        float x0 = (objects[i].rect.x - (wpad / 2)) / scale;
        float y0 = (objects[i].rect.y - (hpad / 2)) / scale;
        float x1 = (objects[i].rect.x + objects[i].rect.width - (wpad / 2)) / scale;
        float y1 = (objects[i].rect.y + objects[i].rect.height - (hpad / 2)) / scale;

        // clip
        x0 = std::max(std::min(x0, (float) (width - 1)), 0.f);
        y0 = std::max(std::min(y0, (float) (height - 1)), 0.f);
        x1 = std::max(std::min(x1, (float) (width - 1)), 0.f);
        y1 = std::max(std::min(y1, (float) (height - 1)), 0.f);
        objects[i].rect.x = x0;
        objects[i].rect.y = y0;
        objects[i].rect.width = x1 - x0;
        objects[i].rect.height = y1 - y0;
    }
    struct {
        bool operator()(const Object &a, const Object &b) const {
            return a.rect.area() > b.rect.area();
        }
    } objects_area_greater;
    std::sort(objects.begin(), objects.end(), objects_area_greater);

    return 0;
}