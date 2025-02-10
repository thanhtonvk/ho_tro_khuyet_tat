import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:dart_ncnn_yolov8/dart_ncnn_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../blind_camera_controller.dart';

final emotionRecognitionController =
    StateNotifierProvider<EmotionRecognitionController, List<double>>(
  EmotionRecognitionController.new,
);

class EmotionRecognitionController extends StateNotifier<List<double>> {
  EmotionRecognitionController(this.ref) : super([]);

  final Ref ref;

  final nguoiKhuyetTatSDK = NguoiKhuyetTatSdk();

  static final previewImage = StateProvider<ui.Image?>(
    (_) => null,
  );

  Future<void> initialize() async {
    await nguoiKhuyetTatSDK.load(isBlind: false, isDeaf: true, objectModel: 'assets/yolo/yolov8n.bin', objectParam: 'assets/yolo/yolov8n.param');
  }

  Future<void> predictEmotion(CameraImage cameraImage) async {
    final completer = Completer<void>();
    switch (cameraImage.format.group) {
      case ImageFormatGroup.unknown:
      case ImageFormatGroup.jpeg:
        log('not support format');
        return;
      case ImageFormatGroup.yuv420:
        state = nguoiKhuyetTatSDK.predictEmotionYUV420(
          y: cameraImage.planes[0].bytes,
          u: cameraImage.planes[1].bytes,
          v: cameraImage.planes[2].bytes,
          height: cameraImage.height,
          deviceOrientationType:
              ref.read(blindCameraController).deviceOrientationType,
          sensorOrientation: ref.read(blindCameraController).sensorOrientation,
          onDecodeImage: (image) {
            ref.read(previewImage.notifier).state = image;
            completer.complete();
          },
        );
        break;
      case ImageFormatGroup.nv21:
        break;
      case ImageFormatGroup.bgra8888:
        break;
    }
    return completer.future;
  }
}
