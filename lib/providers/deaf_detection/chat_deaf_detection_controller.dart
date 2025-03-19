import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:dart_ncnn_yolov8/dart_ncnn_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nguoi_khuyet_tat/providers/chatCameraController.dart';
import 'package:nguoi_khuyet_tat/providers/ncnn_yolo_options.dart';
import 'package:nguoi_khuyet_tat/utils/common.dart';

final labelsChatDeafProvider =
    StateProvider<List<String>>((ref) => labelsDeafVI);
final languageProvider = StateProvider<String>((ref) => 'vi');

final chatDeafDetectionController =
    StateNotifierProvider<ChatDeafDetectionController, List<YoloResult>>(
  (ref) => ChatDeafDetectionController(ref),
);

class ChatDeafDetectionController extends StateNotifier<List<YoloResult>> {
  ChatDeafDetectionController(this.ref) : super([]);

  final Ref ref;
  late FlutterTts flutterTts;
  bool isSpeaking = false;
  final nguoiKhuyetTatSDK = NguoiKhuyetTatSdk();
  final database = FirebaseDatabase.instance.ref();

  static final previewImage = StateProvider<ui.Image?>((_) => null);

  /// **Khởi tạo Controller**
  Future<void> initializeController() async {
    _initializeTTS();
    await initializeSDK();
  }

  /// **Khởi tạo TTS**
  void _initializeTTS() {
    flutterTts = FlutterTts();
    _setupTTS('vi-VN');

    flutterTts.setCompletionHandler(() {
      Future.delayed(const Duration(seconds: 2), () => isSpeaking = false);
    });
  }

  /// **Cấu hình TTS**
  Future<void> _setupTTS(String lang) async {
    await flutterTts.setLanguage(lang);
    await flutterTts.setSpeechRate(0.6);
    await flutterTts.setPitch(1.0);
  }

  /// **Khởi tạo SDK**
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
      deafModelV2: 'assets/yolo/cu_chi_tuyen_quang2.bin',
      deafParamv2: 'assets/yolo/cu_chi_tuyen_quang2.param',
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

  /// **Phát âm thanh và gửi tin nhắn**
  Future<void> _speak(String text, String language) async {
    print(isSpeaking);
    if (text.isNotEmpty && !isSpeaking) {
      isSpeaking = true;
      await flutterTts.setLanguage(language);
      await flutterTts.speak(text);
      sendMessage(text);
    }
  }

  /// **Gửi tin nhắn lên Firebase**
  Future<void> sendMessage(String message) async {
    if (message.trim().isNotEmpty) {
      String? messageId = database
          .child("chat_rooms/${Common.roomId.value}/messages")
          .push()
          .key;
      if (messageId != null) {
        await database
            .child("chat_rooms/${Common.roomId.value}/messages/$messageId")
            .set({
          "sender": Common.userId.value,
          "text": message,
          "timestamp": ServerValue.timestamp,
        });
      }
    }
  }

  /// **Nhận diện từ Camera**
  Future<void> detectDeaf(CameraImage cameraImage) async {
    final completer = Completer<void>();

    if (cameraImage.format.group != ImageFormatGroup.yuv420) {
      log('Unsupported format');
      return;
    }

    state = nguoiKhuyetTatSDK
        .detectDeafYUV420(
          y: cameraImage.planes[0].bytes,
          u: cameraImage.planes[1].bytes,
          v: cameraImage.planes[2].bytes,
          height: cameraImage.height,
          deviceOrientationType:
              ref.read(chatCameraController).deviceOrientationType,
          sensorOrientation: ref.read(chatCameraController).sensorOrientation,
          onDecodeImage: (image) {
            ref.read(previewImage.notifier).state = image;
            completer.complete();
          },
        )
        .result;

    final lang = ref.read(languageProvider);
    final labels = ref.read(labelsChatDeafProvider);

    for (YoloResult result in state) {
      if (result.label < 19) {
        String detectedText = labels[result.label];
        _speak(detectedText, lang);
        Common.noiDung.value = detectedText;
        return completer.future;
      }
    }

    Common.noiDung.value = "";
    return completer.future;
  }
}
