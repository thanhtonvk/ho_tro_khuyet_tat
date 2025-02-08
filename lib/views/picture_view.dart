import 'package:dart_ncnn_yolov8/dart_ncnn_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nguoi_khuyet_tat/providers/blind_camera_controller.dart';
import 'package:nguoi_khuyet_tat/providers/object_detection/object_detection_controller.dart';
import '../providers/ncnn_yolo_options.dart';

class DisplayPictureScreen extends HookConsumerWidget {
  const DisplayPictureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewImage = ref.watch(ObjectDetectionController.previewImage);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            ref.read(blindCameraController).stopImageStream();
            Navigator.pop(context);
          },
        ),
      ),
      body: Builder(
        builder: (_) {
          if (previewImage == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return FittedBox(
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
            )
          );
        },
      )
    );
  }
}
