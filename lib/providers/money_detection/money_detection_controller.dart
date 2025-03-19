import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:dart_ncnn_yolov8/dart_ncnn_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nguoi_khuyet_tat/providers/money_camera_controller.dart';
import '../ncnn_yolo_options.dart';

final moneyDetectController =
    StateNotifierProvider<MoneyDetectionController, List<YoloResult>>(
  MoneyDetectionController.new,
);

class MoneyDetectionController extends StateNotifier<List<YoloResult>> {
  MoneyDetectionController(this.ref) : super([]);

  final Ref ref;
  late FlutterTts flutterTts;
  bool isSpeaking = false;
  final nguoiKhuyetTatSDK = NguoiKhuyetTatSdk();

  static final previewImage = StateProvider<ui.Image?>(
    (_) => null,
  );

  Future<void> initialize() async {
    await nguoiKhuyetTatSDK.load(
        isBlind: true,
        isDeaf: false,
        objectModel: "",
        objectParam: "",
        faceModel: "",
        faceParam: "",
        lightModel: "",
        lightParam: "",
        deafModelV2: '',
        deafParamv2: '',
        emotionModel: "",
        emotionParam: "",
        faceRegModel: "",
        faceRegParam: "",
        faceDeafModel: "",
        faceDeafParam: "",
        deafModel: "",
        deafParam: "",
        moneyModel: 'assets/yolo/money_detection.bin',
        moneyParam: 'assets/yolo/money_detection.param',
        doorModel: "",
        doorParam: "");

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

  Future<void> detectMoney(CameraImage cameraImage) async {
    final completer = Completer<void>();
    switch (cameraImage.format.group) {
      case ImageFormatGroup.unknown:
      case ImageFormatGroup.jpeg:
        log('not support format');
        return;
      case ImageFormatGroup.yuv420:
        state = nguoiKhuyetTatSDK
            .detectMoneyYUV420(
              y: cameraImage.planes[0].bytes,
              u: cameraImage.planes[1].bytes,
              v: cameraImage.planes[2].bytes,
              height: cameraImage.height,
              deviceOrientationType:
                  ref.read(moneyCameraController).deviceOrientationType,
              sensorOrientation:
                  ref.read(moneyCameraController).sensorOrientation,
              onDecodeImage: (image) {
                ref.read(previewImage.notifier).state = image;
                completer.complete();
              },
            )
            .result;
        String flash = nguoiKhuyetTatSDK.detectLightYUV420(
          y: cameraImage.planes[0].bytes,
          u: cameraImage.planes[1].bytes,
          v: cameraImage.planes[2].bytes,
          height: cameraImage.height,
          deviceOrientationType:
              ref.read(moneyCameraController).deviceOrientationType,
          sensorOrientation: ref.read(moneyCameraController).sensorOrientation,
        );
        if (flash == 'bright') {
          ref.read(moneyCameraController).toggleFlash('bright');
        } else {
          ref.read(moneyCameraController).toggleFlash('dark');
        }

        if (state.isNotEmpty) {
          YoloResult obj = state.first;
          print("detect money ${obj.toString()}");
          String name = labels[obj.label];
          _speak(name); // Gọi đọc tên đối tượng
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
