import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Common {
  static ValueNotifier<String> noiDung = ValueNotifier<String>("");

  static List<double> xywhToCenter(double x, double y, double w, double h) {
    double centerX = x + w / 2;
    double centerY = y + h / 2;
    return [centerX, centerY];
  }

  static double cosineSimilarity(List<double> vectorA, List<double> vectorB) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < vectorA.length; i++) {
      dotProduct += vectorA[i] * vectorB[i];
      normA += vectorA[i] * vectorA[i];
      normB += vectorB[i] * vectorB[i];
    }

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  static Uint8List resizeImage(Uint8List imageData, {int maxWidth = 240}) {
    // Decode ảnh từ Uint8List
    final img.Image? image = img.decodeImage(imageData);
    if (image == null) return imageData;

    // Tính toán chiều cao mới theo tỷ lệ
    double aspectRatio = image.height / image.width;
    int newHeight = (maxWidth * aspectRatio).round();

    // Resize ảnh giữ nguyên tỷ lệ
    final img.Image resized =
        img.copyResize(image, width: maxWidth, height: newHeight);

    // Chuyển về Uint8List để sử dụng trong Flutter
    return Uint8List.fromList(
        img.encodeJpg(resized, quality: 25)); // Giảm chất lượng để tối ưu
  }

  static Future<String> saveImageToLocal(
      Uint8List imageBytes, String fileName) async {
    Directory dir = await getApplicationDocumentsDirectory();
    String path = "${dir.path}/$fileName.jpg";
    File file = File(path);
    await file.writeAsBytes(imageBytes);
    return path; // Trả về đường dẫn file
  }
}
