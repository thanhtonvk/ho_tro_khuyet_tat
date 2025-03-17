import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:dart_ncnn_yolov8/dart_ncnn_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nguoi_khuyet_tat/providers/money_camera_controller.dart';
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
  bool isSpeaking = false;
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
        faceModel: "",
        faceParam: "",
        lightModel: "",
        lightParam: "",
        emotionModel: "",
        emotionParam: "",
        faceRegModel: "",
        faceRegParam: "",
        faceDeafModel: "",
        faceDeafParam: "",
        deafModel: "",
        deafParam: "",
        moneyModel: '',
        moneyParam: '',
        doorModel: 'assets/yolo/door.bin',
        doorParam: 'assets/yolo/door.param');

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
          print("detect object ${obj.toString()}");
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
        String flash = nguoiKhuyetTatSDK.detectLightYUV420(
          y: cameraImage.planes[0].bytes,
          u: cameraImage.planes[1].bytes,
          v: cameraImage.planes[2].bytes,
          height: cameraImage.height,
          deviceOrientationType:
              ref.read(blindCameraController).deviceOrientationType,
          sensorOrientation: ref.read(blindCameraController).sensorOrientation,
        );
        if (flash == 'bright') {
          ref.read(blindCameraController).toggleFlash('bright');
        } else {
          ref.read(blindCameraController).toggleFlash('dark');
        }
        if (state.isNotEmpty) {
          YoloResult obj = state.first;
          print(obj.toString());
          String name = labels[obj.label];
          double width = cameraImage.height.toDouble();
          double height = cameraImage.width.toDouble();
          int label = obj.label;
          if (obj.label < 83) {
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
            String content = _getContentSpeaking(
                name, centerX, centerY, distance, width, height);
            _speak(content);
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

  String _getContentSpeaking(String name, double centerX, double centerY,
      double distance, double imageWidth, double imageHeight) {
    int gridCols = 3;
    int gridRows = 3;

    int cellWidth = (imageWidth / gridCols).floor(); // 240
    int cellHeight = (imageHeight / gridRows).floor(); // 426

    // 🔹 Giới hạn centerX và centerY trong phạm vi ảnh
    centerX = centerX.clamp(0, imageWidth - 1);
    centerY = centerY.clamp(0, imageHeight - 1);

    int col = (centerX / cellWidth).floor();
    int row = (centerY / cellHeight).floor();

    Map<String, String> directions = {
      "0,0": "trên bên trái",
      "0,1": "trên",
      "0,2": "trên bên phải",
      "1,0": "bên trái",
      "1,1": "giữa",
      "1,2": "bên phải",
      "2,0": "dưới bên trái",
      "2,1": "dưới",
      "2,2": "dưới bên phải",
      "3,0": "dưới bên trái",
      "3,1": "dưới bên phải"
    };

    String positionKey = "$row,$col";
    print(positionKey);
    String position = directions[positionKey] ?? "ngoài vùng xác định";

    String valDistance = distance.toStringAsFixed(2);
    return "$name đang ở $position $valDistance met";
  }
}
