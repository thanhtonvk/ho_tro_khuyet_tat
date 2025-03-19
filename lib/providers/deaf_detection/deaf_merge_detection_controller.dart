import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:dart_ncnn_yolov8/dart_ncnn_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nguoi_khuyet_tat/providers/giao_tiep_cau_camera_controller.dart';
import 'package:nguoi_khuyet_tat/providers/ncnn_yolo_options.dart';
import 'package:nguoi_khuyet_tat/utils/common.dart';

final labelsDeafProvider = StateProvider<List<String>>((ref) => labelsDeafVI);
final languageProvider = StateProvider<String>((ref) => 'vi');
final deafMergeDetectionController =
    StateNotifierProvider<DeafMergeDetectionController, List<YoloResult>>(
  (ref) => DeafMergeDetectionController(ref),
);

class DeafMergeDetectionController extends StateNotifier<List<YoloResult>> {
  DeafMergeDetectionController(this.ref) : super([]);

  final Ref ref;
  late FlutterTts flutterTts;
  bool isSpeaking = false;
  final nguoiKhuyetTatSDK = NguoiKhuyetTatSdk();
  var cauList = [];
  static final previewImage = StateProvider<ui.Image?>(
    (_) => null,
  );

  /// **Gọi từ Widget để khởi tạo**
  Future<void> initializeController() async {
    _initializeTTS();
    await initializeSDK();
  }

  /// **Khởi tạo TTS**
  void _initializeTTS() {
    flutterTts = FlutterTts();
    _setupTTS('vi-VN');

    flutterTts.setCompletionHandler(() {
      Future.delayed(const Duration(seconds: 2), () {
        isSpeaking = false;
      });
    });
  }

  /// **Cấu hình TTS**
  Future<void> _setupTTS(String lang) async {
    await flutterTts.setLanguage(lang);
    await flutterTts.setSpeechRate(0.6);
    await flutterTts.setPitch(1.0);
  }

  Future<void> initializeSDK() async {
    await nguoiKhuyetTatSDK.load(
      isBlind: false,
      isDeaf: true,
      objectModel: '',
      objectParam: '',
      faceModel: 'assets/yolo/scrfd_2.5g_kps-opt2.bin',
      faceParam: 'assets/yolo/scrfd_2.5g_kps-opt2.param',
      emotionModel: "assets/yolo/model.bin",
      emotionParam: "assets/yolo/model.param",
      faceDeafModel: 'assets/yolo/scrfd_2.5g_kps-opt2.bin',
      faceDeafParam: 'assets/yolo/scrfd_2.5g_kps-opt2.param',
      deafModel: 'assets/yolo/cu_chi_tuyen_quang1.bin',
      deafParam: 'assets/yolo/cu_chi_tuyen_quang1.param',
      lightModel: '',
      lightParam: '',
      faceRegModel: '',
      faceRegParam: '',
      moneyModel: '',
      moneyParam: '',
      doorModel: '',
      doorParam: '',
    );
  }

  /// **Phát âm thanh nếu không bị gián đoạn**
  Future<void> _speak(String text, String language) async {
    if (text.isNotEmpty && !isSpeaking) {
      isSpeaking = true;
      await flutterTts.setLanguage(language);
      await flutterTts.speak(text);
    }
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
                  ref.read(giaoTiepCauCameraController).deviceOrientationType,
              sensorOrientation:
                  ref.read(giaoTiepCauCameraController).sensorOrientation,
              onDecodeImage: (image) {
                ref.read(previewImage.notifier).state = image;
                completer.complete();
              },
            )
            .result;
        Timer? resetTimer;
        String lang = ref.read(languageProvider);
        for (YoloResult yoloResult in state) {
          if (yoloResult.label < 19) {
            if (!cauList
                .contains(ref.read(labelsDeafProvider)[yoloResult.label])) {
              Common.noiDung.value +=
                  " ${ref.read(labelsDeafProvider)[yoloResult.label]}";
              cauList.add(ref.read(labelsDeafProvider)[yoloResult.label]);

              // Reset timer mỗi khi có câu mới
              resetTimer?.cancel();
              resetTimer = Timer(const Duration(seconds: 10), () {
                cauList.clear();
                Common.noiDung.value = '';
              });
            }
            break;
          }
        }

// Nếu đủ 3 câu, đọc nội dung, rồi reset sau 2 giây
        if (cauList.length == 3) {
          resetTimer?.cancel(); // Hủy timer 10s vì đã đọc được 3 câu
          _speak(Common.noiDung.value, lang).then((_) {
            Future.delayed(const Duration(seconds: 2), () {
              cauList.clear();
              Common.noiDung.value = '';
            });
          });
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
