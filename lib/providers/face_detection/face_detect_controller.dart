import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:dart_ncnn_yolov8/dart_ncnn_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nguoi_khuyet_tat/providers/face_camera_controller.dart';
import 'package:nguoi_khuyet_tat/services/data_helper.dart';
import 'package:nguoi_khuyet_tat/viewmodels/face_view_model.dart';

import '../blind_camera_controller.dart';

final faceDetectController =
    StateNotifierProvider<FaceDetectController, List<FaceResult>>(
  FaceDetectController.new,
);

class FaceDetectController extends StateNotifier<List<FaceResult>> {
  FaceDetectController(this.ref) : super([]);
  late FlutterTts flutterTts;
  final Ref ref;
  bool isSpeaking = false;
  final nguoiKhuyetTatSDK = NguoiKhuyetTatSdk();
  FaceViewModel faceViewModel = FaceViewModel();

  static final previewImage = StateProvider<ui.Image?>(
    (_) => null,
  );

  Future<void> initialize() async {
    await nguoiKhuyetTatSDK.load(
        isBlind: true,
        isDeaf: false,
        objectModel: 'assets/yolo/yolov8n.bin',
        objectParam: 'assets/yolo/yolov8n.param',
        faceModel: 'assets/yolo/scrfd_2.5g_kps-opt2.bin',
        faceParam: 'assets/yolo/scrfd_2.5g_kps-opt2.param',
        lightModel: 'assets/yolo/lighttraffic.ncnn.bin',
        lightParam: 'assets/yolo/lighttraffic.ncnn.param',
        emotionModel: 'assets/yolo/model.bin',
        emotionParam: 'assets/yolo/model.param',
        faceRegModel: 'assets/yolo/w600k_mbf.bin',
        faceRegParam: 'assets/yolo/w600k_mbf.param',
        faceDeafModel: 'assets/yolo/scrfd_2.5g_kps-opt2.bin',
        faceDeafParam: 'assets/yolo/scrfd_2.5g_kps-opt2.param',
        deafModel: 'assets/yolo/best_cu_chi_v9.bin',
        deafParam: 'assets/yolo/best_cu_chi_v9.param',
        moneyModel: 'assets/yolo/money_detection.bin',
        moneyParam: 'assets/yolo/money_detection.param');
    flutterTts = FlutterTts();
    _setupTTS('vi-VN');

    // Xử lý khi nói xong
    flutterTts.setCompletionHandler(() async {
      await Future.delayed(const Duration(seconds: 3)); // Đợi 3 giây
      isSpeaking = false; // Cho phép đọc tiếp
    });
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty && !isSpeaking) {
      isSpeaking = true;
      await flutterTts.speak(text);
    }
  }

  Future<void> _setupTTS(String lang) async {
    await flutterTts.setLanguage(lang); // Chọn tiếng Việt
    await flutterTts.setSpeechRate(0.6); // Tốc độ nói
    await flutterTts.setPitch(1.0); // Cao độ
  }

  Future<void> detectFace(CameraImage cameraImage) async {
    final completer = Completer<void>();
    switch (cameraImage.format.group) {
      case ImageFormatGroup.unknown:
      case ImageFormatGroup.jpeg:
        log('not support format');
        return;
      case ImageFormatGroup.yuv420:
        state = nguoiKhuyetTatSDK
            .detectFaceYUV420(
              y: cameraImage.planes[0].bytes,
              u: cameraImage.planes[1].bytes,
              v: cameraImage.planes[2].bytes,
              height: cameraImage.height,
              deviceOrientationType:
                  ref.read(faceCameraController).deviceOrientationType,
              sensorOrientation:
                  ref.read(faceCameraController).sensorOrientation,
              onDecodeImage: (image) {
                ref.read(previewImage.notifier).state = image;
                completer.complete();
              },
            )
            .result;
        var embedding = nguoiKhuyetTatSDK.getEmbeddingYUV420(
            y: cameraImage.planes[0].bytes,
            u: cameraImage.planes[1].bytes,
            v: cameraImage.planes[2].bytes,
            height: cameraImage.height,
            deviceOrientationType:
                ref.read(faceCameraController).deviceOrientationType,
            sensorOrientation:
                ref.read(faceCameraController).sensorOrientation);
        await faceViewModel.searchFace(embedding).then((value) {
          if (value != null) {
            _speak(value.name);
          }
        });
        break;
      case ImageFormatGroup.nv21:
        break;
      case ImageFormatGroup.bgra8888:
        break;
    }

    return completer.future;
  }
}
