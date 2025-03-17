import 'package:dart_ncnn_yolov8/dart_ncnn_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nguoi_khuyet_tat/providers/blind_camera_controller.dart';
import 'package:nguoi_khuyet_tat/providers/find_way_camera_controller.dart';
import 'package:nguoi_khuyet_tat/providers/object_detection/any_object_detection_controller.dart';
import 'package:nguoi_khuyet_tat/providers/object_detection/object_detection_controller.dart';

import '../../providers/ncnn_yolo_options.dart';

class AnyObjectPage extends HookConsumerWidget {
  const AnyObjectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewImage = ref.watch(AnyObjectDetectionController.previewImage);

    void showBackDialog() {
      ref.read(findWayCameraController).stopImageStream();
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
                              painter: ObjectResultPainter(
                                image: previewImage,
                                results: ref.watch(anyObjectDetectionController),
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
          ],
        ),
        resizeToAvoidBottomInset: true,
        extendBodyBehindAppBar: true,
      ),
    );
  }
}
