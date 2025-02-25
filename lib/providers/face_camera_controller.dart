import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_ncnn_yolov8/dart_ncnn_flutter.dart';
import 'package:nguoi_khuyet_tat/providers/face_detection/face_detect_controller.dart';

final faceCameraController = Provider(
  FaceCameraController.new,
);

class FaceCameraController {
  FaceCameraController(this.ref);

  final Ref ref;

  CameraController? _cameraController;

  KannaRotateDeviceOrientationType get deviceOrientationType =>
      _cameraController?.value.deviceOrientation.kannaRotateType ??
      KannaRotateDeviceOrientationType.portraitUp;

  int get sensorOrientation =>
      _cameraController?.description.sensorOrientation ?? 90;

  bool _isProcessing = false;

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
  Future<void> startImageStream(int cameraIndex) async {
    await ref.read(faceDetectController.notifier).initialize();

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
        await ref.read(faceDetectController.notifier).detectFace(image);

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
