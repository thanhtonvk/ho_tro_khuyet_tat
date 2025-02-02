import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:dart_ncnn_yolov8/dart_ncnn_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import '../my_camera_controller.dart';

final faceDetectController =
    StateNotifierProvider<FaceRecognitionController, List<double>>(
  FaceRecognitionController.new,
);

class FaceRecognitionController extends StateNotifier<List<double>> {
  FaceRecognitionController(this.ref) : super([]);

  final Ref ref;

  final nguoiKhuyetTatSDK = NguoiKhuyetTatSdk();

  static final previewImage = StateProvider<ui.Image?>(
    (_) => null,
  );

  Future<void> initialize() async {
    await nguoiKhuyetTatSDK.load(isBlind: true, isDeaf: false);
  }

  Future<void> getEmbeddingFromPath(XFile file) async {
    state = nguoiKhuyetTatSDK.getEmbeddingFromPath(file.path);
    log(state.toString());

    final decodedImage = await decodeImageFromList(
      File(
        file.path,
      ).readAsBytesSync(),
    );
    ref.read(previewImage.notifier).state = decodedImage;
  }

  Future<void> getEmbeddingFromImage(CameraImage cameraImage) async {
    final completer = Completer<void>();
    switch (cameraImage.format.group) {
      case ImageFormatGroup.unknown:
      case ImageFormatGroup.jpeg:
        log('not support format');
        return;
      case ImageFormatGroup.yuv420:
        state = nguoiKhuyetTatSDK.getEmbeddingYUV420(
          y: cameraImage.planes[0].bytes,
          u: cameraImage.planes[1].bytes,
          v: cameraImage.planes[2].bytes,
          height: cameraImage.height,
          deviceOrientationType:
              ref.read(myCameraController).deviceOrientationType,
          sensorOrientation: ref.read(myCameraController).sensorOrientation,
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
