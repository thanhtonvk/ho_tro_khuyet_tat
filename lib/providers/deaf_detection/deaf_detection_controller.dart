import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:dart_ncnn_yolov8/dart_ncnn_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nguoi_khuyet_tat/providers/giao_tiep_tu_camera_controller.dart';
import 'package:nguoi_khuyet_tat/providers/ncnn_yolo_options.dart';
import 'package:nguoi_khuyet_tat/utils/common.dart';

final deafDetectionController =
    StateNotifierProvider<DeafDetectionController, List<YoloResult>>(
  DeafDetectionController.new,
);

class DeafDetectionController extends StateNotifier<List<YoloResult>> {
  DeafDetectionController(this.ref) : super([]);

  final Ref ref;
  late FlutterTts flutterTts;
  bool isSpeaking = false;
  final nguoiKhuyetTatSDK = NguoiKhuyetTatSdk();

  static final previewImage = StateProvider<ui.Image?>(
    (_) => null,
  );

  Future<void> initialize() async {
    await nguoiKhuyetTatSDK.load(
        isBlind: false,
        isDeaf: true,
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
        moneyParam: 'assets/yolo/money_detection.param',
        doorModel: 'assets/yolo/door.bin',
        doorParam: 'assets/yolo/door.param');
    flutterTts = FlutterTts();
    _setupTTS('vi-VN');

    // Xử lý khi nói xong
    flutterTts.setCompletionHandler(() async {
      await Future.delayed(const Duration(seconds: 1)); // Đợi 3 giây
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

  Future<void> detectDeaf(CameraImage cameraImage) async {
    final completer = Completer<void>();
    switch (cameraImage.format.group) {
      case ImageFormatGroup.unknown:
      case ImageFormatGroup.jpeg:
        log('not support format');
        return;
      case ImageFormatGroup.yuv420:
        state = nguoiKhuyetTatSDK
            .detectDeafYUV420(
              y: cameraImage.planes[0].bytes,
              u: cameraImage.planes[1].bytes,
              v: cameraImage.planes[2].bytes,
              height: cameraImage.height,
              deviceOrientationType:
                  ref.read(giaoTiepTuCameraController).deviceOrientationType,
              sensorOrientation:
                  ref.read(giaoTiepTuCameraController).sensorOrientation,
              onDecodeImage: (image) {
                ref.read(previewImage.notifier).state = image;
                completer.complete();
              },
            )
            .result;
        bool isExist = false;
        for (YoloResult yoloResult in state) {
          if (yoloResult.label < 19) {
            _speak(labelsDeaf[yoloResult.label]);
            Common.noiDung.value = labelsDeaf[yoloResult.label];
            isExist = true;
            break;
          }
        }
        if (!isExist) {
          Common.noiDung.value = "";
        }
        break;
      case ImageFormatGroup.nv21:
        break;
      case ImageFormatGroup.bgra8888:
        break;
    }
    return completer.future;
  }
}
