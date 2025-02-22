import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_ncnn_yolov8/dart_ncnn_flutter.dart';
import 'package:nguoi_khuyet_tat/providers/deaf_detection/deaf_detection_controller.dart';
import 'package:nguoi_khuyet_tat/providers/deaf_detection/deaf_merge_detection_controller.dart';

final giaoTiepCauCameraController = Provider(
  GiaoTiepCauCameraController.new,
);

class GiaoTiepCauCameraController {
  GiaoTiepCauCameraController(this.ref);

  final Ref ref;

  CameraController? _cameraController;

  KannaRotateDeviceOrientationType get deviceOrientationType =>
      _cameraController?.value.deviceOrientation.kannaRotateType ??
          KannaRotateDeviceOrientationType.portraitUp;

  int get sensorOrientation =>
      _cameraController?.description.sensorOrientation ?? 90;

  bool _isProcessing = false;

  Future<void> startImageStream(int cameraIndex) async {
    await ref.read(deafMergeDetectionController.notifier).initialize();

    final camera = (await availableCameras())[cameraIndex];

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    await _cameraController!.startImageStream(
          (image) async {
        if (_isProcessing) {
          return;
        }

        _isProcessing = true;
        await ref.read(deafMergeDetectionController.notifier).detectDeaf(image);

        // await ref.read()
        _isProcessing = false;
      },
    );
  }

  Future<void> stopImageStream() async {
    final cameraValue = _cameraController?.value;
    if (cameraValue != null) {
      if (cameraValue.isInitialized && cameraValue.isStreamingImages) {
        await _cameraController?.stopImageStream();
        await _cameraController?.dispose();
        _cameraController = null;
      }
    }
  }

  Future<CameraController> getCameraController(int cameraIndex) async {
    if (_cameraController == null) {
      final camera = (await availableCameras())[cameraIndex];

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
    }

    return _cameraController!;
  }
}

extension DeviceOrientationExtension on DeviceOrientation {
  KannaRotateDeviceOrientationType get kannaRotateType {
    switch (this) {
      case DeviceOrientation.portraitUp:
        return KannaRotateDeviceOrientationType.portraitUp;
      case DeviceOrientation.portraitDown:
        return KannaRotateDeviceOrientationType.portraitDown;
      case DeviceOrientation.landscapeLeft:
        return KannaRotateDeviceOrientationType.landscapeLeft;
      case DeviceOrientation.landscapeRight:
        return KannaRotateDeviceOrientationType.landscapeRight;
    }
  }
}
