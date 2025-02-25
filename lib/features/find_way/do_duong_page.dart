import 'package:dart_ncnn_yolov8/dart_ncnn_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nguoi_khuyet_tat/providers/blind_camera_controller.dart';
import 'package:nguoi_khuyet_tat/providers/object_detection/object_detection_controller.dart';

import '../../providers/ncnn_yolo_options.dart';

class DoDuongPage extends HookConsumerWidget {
  const DoDuongPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewImage = ref.watch(ObjectDetectionController.previewImage);

    void showBackDialog() {
      ref.read(blindCameraController).stopImageStream();
      Navigator.pop(context);
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        showBackDialog();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 28, color: Colors.white),
            onPressed: showBackDialog,
          ),
          backgroundColor: Colors.black.withOpacity(0.5),
          elevation: 0,
          centerTitle: true,
        ),
        body: Stack(
          children: [
            // Hiển thị camera
            Positioned.fill(
              child: Builder(
                builder: (_) {
                  if (previewImage == null) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  return Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: previewImage.width.toDouble(),
                            height: previewImage.height.toDouble(),
                            child: CustomPaint(
                              painter: YoloResultPainter(
                                image: previewImage,
                                results: ref.watch(objectDetectController),
                                labels: labels,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Nút căn chỉnh khoảng cách
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Thêm chức năng căn chỉnh khoảng cách tại đây
                },
                icon: const Icon(Icons.straighten, size: 28),
                label: const Text(
                  "Căn chỉnh khoảng cách",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        resizeToAvoidBottomInset: true,
        extendBodyBehindAppBar: true,
      ),
    );
  }
}
