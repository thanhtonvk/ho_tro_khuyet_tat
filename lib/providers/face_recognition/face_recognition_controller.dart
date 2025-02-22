import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:dart_ncnn_yolov8/dart_ncnn_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

import '../blind_camera_controller.dart';

final faceRecognitionController =
    StateNotifierProvider<FaceRecognitionController, List<double>>(
  FaceRecognitionController.new,
);

class FaceRecognitionController extends StateNotifier<List<double>> {
  FaceRecognitionController(this.ref) : super([]);

  final Ref ref;

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
  }

  Future<List<double>> getEmbeddingFromPath(XFile file) async {
    state = nguoiKhuyetTatSDK.getEmbeddingFromPath(file.path);
    log(state.toString());

    final decodedImage = await decodeImageFromList(
      File(
        file.path,
      ).readAsBytesSync(),
    );
    ref.read(previewImage.notifier).state = decodedImage;
    return state;
  }

  Future<void> getEmbeddingFromImage(CameraImage cameraImage) async {
    final completer = Completer<void>();
    switch (cameraImage.format.group) {
      case ImageFormatGroup.unknown:
      case ImageFormatGroup.jpeg:
        log('not support format');
        return;
      case ImageFormatGroup.yuv420:
        state = nguoiKhuyetTatSDK.getEmbeddingYUV420(
          y: cameraImage.planes[0].bytes,
          u: cameraImage.planes[1].bytes,
          v: cameraImage.planes[2].bytes,
          height: cameraImage.height,
          deviceOrientationType:
              ref.read(blindCameraController).deviceOrientationType,
          sensorOrientation: ref.read(blindCameraController).sensorOrientation,
          onDecodeImage: (image) {
            ref.read(previewImage.notifier).state = image;
            completer.complete();
          },
        );
        break;
      case ImageFormatGroup.nv21:
        break;
      case ImageFormatGroup.bgra8888:
        break;
    }
    return completer.future;
  }
}
