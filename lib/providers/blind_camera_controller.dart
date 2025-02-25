import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_ncnn_yolov8/dart_ncnn_flutter.dart';
import 'package:nguoi_khuyet_tat/providers/face_detection/face_detect_controller.dart';
import 'package:nguoi_khuyet_tat/providers/face_recognition/face_recognition_controller.dart';
import 'package:nguoi_khuyet_tat/providers/object_detection/object_detection_controller.dart';

final blindCameraController = Provider(BlindCameraController.new);

class BlindCameraController {
  BlindCameraController(this.ref);

  final Ref ref;
  CameraController? _cameraController;
  bool _isProcessing = false;

  KannaRotateDeviceOrientationType get deviceOrientationType =>
      _cameraController?.value.deviceOrientation.kannaRotateType ??
      KannaRotateDeviceOrientationType.portraitUp;

  int get sensorOrientation =>
      _cameraController?.description.sensorOrientation ?? 90;

  Future<void> startImageStream(int cameraIndex) async {
    await ref.read(objectDetectController.notifier).initialize();
    await _initializeCameraController(cameraIndex);

    await _cameraController!.startImageStream((image) async {
      if (_isProcessing) return;
      _isProcessing = true;

      try {
        await ref.read(objectDetectController.notifier).detectObject(image);
      } finally {
        _isProcessing = false;
      }
    });
  }

  Future<void> stopImageStream() async {
    if (_cameraController != null) {
      await _cameraController?.stopImageStream();
      await _cameraController?.dispose();
      _cameraController = null;
    }
  }

  int _darkFrameCount = 0;
  int _brightFrameCount = 0;
  bool _isFlashOn = false; // Trạng thái đèn flash
  Timer? _flashTimer; // Để tránh bật/tắt flash liên tục

  Future<void> toggleFlash(String flash) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    // Nếu mô hình nhận diện "bright", tăng số khung hình sáng
    if (flash == 'bright') {
      _brightFrameCount++;
      _darkFrameCount = 0; // Reset dark frame count
    } else {
      _darkFrameCount++;
      _brightFrameCount = 0; // Reset bright frame count
    }

    // Chỉ thay đổi trạng thái flash nếu có ít nhất 5 khung hình liên tiếp giống nhau
    if (_brightFrameCount >= 5 && _isFlashOn) {
      _scheduleFlashChange(false);
    } else if (_darkFrameCount >= 5 && !_isFlashOn) {
      _scheduleFlashChange(true);
    }
  }

  void _scheduleFlashChange(bool turnOn) {
    if (_flashTimer?.isActive ?? false) return; // Nếu đang đợi, không làm gì cả

    _flashTimer = Timer(const Duration(seconds: 3), () async {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        _isFlashOn = turnOn;
        await _cameraController!
            .setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
      }
    });
  }

  Future<void> _initializeCameraController(int cameraIndex) async {
    if (_cameraController?.value.isInitialized ?? false) return;

    final camera = (await availableCameras())[cameraIndex];
    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _cameraController!.initialize();
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
