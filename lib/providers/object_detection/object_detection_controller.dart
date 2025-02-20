import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:dart_ncnn_yolov8/dart_ncnn_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nguoi_khuyet_tat/utils/common.dart';

import '../../utils/cal_distance.dart';
import '../blind_camera_controller.dart';
import '../ncnn_yolo_options.dart';

final objectDetectController =
    StateNotifierProvider<ObjectDetectionController, List<YoloResult>>(
  ObjectDetectionController.new,
);

class ObjectDetectionController extends StateNotifier<List<YoloResult>> {
  ObjectDetectionController(this.ref) : super([]);

  final Ref ref;
  late FlutterTts flutterTts;
  bool isSpeaking = false; // Kiểm soát trạng thái nói
  final nguoiKhuyetTatSDK = NguoiKhuyetTatSdk();

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

  Future<void> detectObject(CameraImage cameraImage) async {
    final completer = Completer<void>();
    switch (cameraImage.format.group) {
      case ImageFormatGroup.unknown:
      case ImageFormatGroup.jpeg:
        log('not support format');
        return;
      case ImageFormatGroup.yuv420:
        state = nguoiKhuyetTatSDK
            .detectObjectYUV420(
              y: cameraImage.planes[0].bytes,
              u: cameraImage.planes[1].bytes,
              v: cameraImage.planes[2].bytes,
              height: cameraImage.height,
              deviceOrientationType:
                  ref.read(blindCameraController).deviceOrientationType,
              sensorOrientation:
                  ref.read(blindCameraController).sensorOrientation,
              onDecodeImage: (image) {
                ref.read(previewImage.notifier).state = image;
                completer.complete();
              },
            )
            .result;

        if (state.isNotEmpty) {
          String content = '';
          YoloResult obj = state.first;
          String name = labels[state.first.label];
          double width = cameraImage.width as double;
          double height = cameraImage.height as double;
          int label = obj.label;
          if (obj.label < 80) {
            double focalLength = CalDistance.calculateFocalLength(
                CalDistance.knownDistances[label],
                CalDistance.knownWidths[label],
                CalDistance.widthInImages[label]);
            double distance = CalDistance.calculateDistance(
                CalDistance.knownWidths[label], focalLength, width);
            List<double> position =
                Common.xywhToCenter(obj.x, obj.y, width, height);
            double centerX = position[0];
            double centerY = position[1];
            String speaking = "";

            if (100 < centerX &&
                centerX < 200 &&
                0 < centerY &&
                centerY < 200) {
              speaking = "$name đang ở trên";
            }
            // Right
            if (200 < centerX &&
                centerX < 320 &&
                200 < centerY &&
                centerY < 400) {
              speaking = "$name đang ở bên phải";
            }
            // Bottom
            if (100 < centerX &&
                centerX < 200 &&
                400 < centerY &&
                centerY < 640) {
              speaking = "$name đang ở dưới";
            }
            // Left
            if (0 < centerX &&
                centerX < 100 &&
                200 < centerY &&
                centerY < 400) {
              speaking = "$name đang ở bên trái";
            }
            // Top right
            if (200 < centerX &&
                centerX < 320 &&
                0 < centerY &&
                centerY < 200) {
              speaking = "$name đang ở trên bên phải";
            }
            // Bottom right
            if (200 < centerX &&
                centerX < 320 &&
                400 < centerY &&
                centerY < 640) {
              speaking = "$name đang ở dưới bên phải";
            }
            // Bottom left
            if (0 < centerX &&
                centerX < 100 &&
                400 < centerY &&
                centerY < 640) {
              speaking = "$name đang ở dưới bên trái";
            }
            // Top left
            if (0 < centerX && centerX < 100 && 0 < centerY && centerY < 200) {
              speaking = "$name đang ở trên bên trái";
            }
            // Center
            if (100 < centerX &&
                centerX < 200 &&
                200 < centerY &&
                centerY < 400) {
              speaking = "$name đang ở giữa";
            }
            String valDistance = distance.toStringAsFixed(2);
            speaking += " $valDistance met";
            _speak(speaking);
          } else {
            _speak(name); // Gọi đọc tên đối tượng
          }
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
