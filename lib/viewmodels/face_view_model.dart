import 'dart:typed_data';
import '../models/face_data.dart';
import 'package:flutter/foundation.dart';

import '../services/data_helper.dart';

class FaceViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<FaceData> _faces = [];

  List<FaceData> get faces => _faces;

  Future<void> loadFaces() async {
    _faces = await _dbHelper.getAllFaces();
    notifyListeners();
  }

  Future<void> addFace(
      String name, String image, List<double> embedding) async {
    final face = FaceData(cameraImage: image, embedding: embedding, name: name);
    await _dbHelper.insertFace(face);
    await loadFaces();
  }

  Future<void> removeFace(int id) async {
    await _dbHelper.deleteFace(id);
    await loadFaces();
  }

  Future<FaceData?> searchFace(List<double> embedding) async {
    FaceData? faceData = await _dbHelper.searchFace(embedding);
    return faceData;
  }
}
