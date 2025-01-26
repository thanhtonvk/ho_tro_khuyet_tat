import 'package:dart_ncnn_yolov8/dart_ncnn_flutter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'kanna_rotate/kanna_rotate_result.dart';

part 'face_detect_result.freezed.dart';

@freezed
class FaceDetectResult with _$FaceDetectResult {
  const factory FaceDetectResult({
    @Default(<FaceResult>[]) List<FaceResult> result,
    KannaRotateResult? image,
  }) = _FaceDetectResult;
}
