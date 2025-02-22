import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/face_data.dart';
import '../utils/common.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'face_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE faces(id INTEGER PRIMARY KEY AUTOINCREMENT, cameraImage TEXT, embedding TEXT, name TEXT)',
        );
      },
    );
  }

  // Thêm dữ liệu
  Future<int> insertFace(FaceData face) async {
    final db = await database;
    return await db.insert('faces', face.toMap());
  }

  // Lấy danh sách
  Future<List<FaceData>> getAllFaces() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('faces');
    return List.generate(maps.length, (i) => FaceData.fromMap(maps[i]));
  }

  // Xóa dữ liệu
  Future<int> deleteFace(int id) async {
    final db = await database;
    return await db.delete('faces', where: 'id = ?', whereArgs: [id]);
  }

  Future<FaceData?> searchFace(List<double> inputEmbedding) async {
    final List<FaceData> faces = await getAllFaces();

    double maxSimilarity = -1;
    FaceData? bestMatch;

    for (var face in faces) {
      double similarity =
          Common.cosineSimilarity(inputEmbedding, face.embedding);
      if (similarity > maxSimilarity && similarity > 0.5) {
        maxSimilarity = similarity;
        bestMatch = face;
      }
    }

    return bestMatch;
  }
}
