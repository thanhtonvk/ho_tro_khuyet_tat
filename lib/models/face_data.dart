import 'dart:typed_data';

class FaceData {
  final int? id;
  final String cameraImage;
  final List<double> embedding;
  final String name;

  FaceData({
    this.id,
    required this.cameraImage,
    required this.embedding,
    required this.name,
  });

  // Chuyển đối tượng thành Map để lưu vào SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cameraImage': cameraImage,
      'embedding': embedding.join(','), // Lưu embedding dạng chuỗi
      'name': name,
    };
  }

  // Chuyển từ Map về đối tượng
  factory FaceData.fromMap(Map<String, dynamic> map) {
    return FaceData(
      id: map['id'],
      cameraImage: map['cameraImage'],
      embedding: (map['embedding'] as String)
          .split(',')
          .map((e) => double.tryParse(e) ?? 0.0)
          .toList(),
      name: map['name'],
    );
  }

}
