import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'face_result.freezed.dart';

@freezed
class FaceResult with _$FaceResult {
  const factory FaceResult({
    @Default(0) double x,
    @Default(0) double y,
    @Default(0) double width,
    @Default(0) double height,
    @Default(0) double prob,
  }) = _FaceResult;

  static List<FaceResult> create(String response) => response
      .split('\n')
      .where(
        (element) => element.isNotEmpty,
  )
      .map(
        (e) {
      final values = e.split(',');
      return FaceResult(
        x: double.parse(values[0]),
        y: double.parse(values[1]),
        width: double.parse(values[2]),
        height: double.parse(values[3]),
        prob: double.parse(values[4]),
      );
    },
  ).toList();
}
