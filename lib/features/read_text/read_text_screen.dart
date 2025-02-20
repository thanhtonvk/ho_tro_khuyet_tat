import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:nguoi_khuyet_tat/utils/app_text_style.dart';
import 'package:permission_handler/permission_handler.dart';

class ReadTextScreen extends StatefulWidget {
  const ReadTextScreen({super.key});

  @override
  _ReadTextScreenState createState() => _ReadTextScreenState();
}

class _ReadTextScreenState extends State<ReadTextScreen> {
  bool isPermissionGranted = false;
  bool isLoading = false;
  bool isReading = false;

  late Future<void> _future;
  CameraController? _cameraController;
  final textRecognizer = TextRecognizer();
  List<CameraDescription> _availableCameras = [];
  FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _future = _requestCameraPermission();
  }

  @override
  void dispose() {
    super.dispose();
    textRecognizer.close();
    _stopReading();
    _stopCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      _startCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Đọc chữ",
            style: AppTextStyle.appBarTitle,
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          child: FutureBuilder(
              future: _future,
              builder: (context, snapshot) {
                return isPermissionGranted
                    ? _buildCameraPreview()
                    : _buildPermissionDenied();
              }),
        ));
  }

  Widget _buildCameraPreview() {
    return FutureBuilder<List<CameraDescription>>(
      future: availableCameras(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _getAvailableCameras();
          return Column(children: [
            Flexible(
              flex: 1,
              child: GestureDetector(
                onTap: () {
                  _scanImage();
                },
                child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                        width: _cameraController!.value.previewSize!.height,
                        height: _cameraController!.value.previewSize!.width,
                        child: CameraPreview(_cameraController!))),
              ),
            ),
            ElevatedButton(
              child: const Text("Đổi camera"),
              onPressed: () {
                _toggleCamera();
              },
            )
          ]);
        }
        return Center(child: const Text("No camera available"));
      },
    );
  }

  Widget _buildPermissionDenied() {
    return Center(child: const Text("Permission denied"));
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    isPermissionGranted = status == PermissionStatus.granted;
  }

  void _startCamera() {
    if (_cameraController != null) {
      _cameraSelected(_cameraController!.description);
    }
  }

  void _stopCamera() {
    if (_cameraController != null) {
      _cameraController?.dispose();
    }
  }

  void _initCameraController(List<CameraDescription> cameras) {
    if (_cameraController != null) {
      return;
    }

    // Select the first rear camera.
    CameraDescription? camera;
    for (var i = 0; i < cameras.length; i++) {
      final CameraDescription current = cameras[i];
      if (current.lensDirection == CameraLensDirection.back) {
        camera = current;
        break;
      }
    }

    if (camera != null) {
      _cameraSelected(camera);
    }
  }

  Future<void> _cameraSelected(CameraDescription camera) async {
    _cameraController = CameraController(
      camera,
      ResolutionPreset.max,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    await _cameraController!.setFlashMode(FlashMode.off);

    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _scanImage() async {
    setState(() {
      isLoading = true;
    });
    if (_cameraController == null) return;

    final navigator = Navigator.of(context);

    try {
      final pictureFile = await _cameraController!.takePicture();
      final file = File(pictureFile.path);
      final inputImage = InputImage.fromFile(file);
      final recognizedText = await textRecognizer.processImage(inputImage);

      // Chuyển recognizedText thành danh sách các dòng văn bản có vị trí
      List<Map<String, dynamic>> lines = [];

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          lines.add({
            'text': line.text,
            'y': line.boundingBox.top, // Vị trí theo trục Y (cao -> thấp)
            'x': line.boundingBox.left, // Vị trí theo trục X (trái -> phải)
          });
        }
      }
      // Sắp xếp theo Y trước, nếu cùng Y thì sắp xếp theo X
      lines.sort((a, b) {
        if (a['y'] == b['y']) {
          return a['x'].compareTo(b['x']); // Cùng hàng -> X tăng dần
        }
        return a['y'].compareTo(b['y']); // Y tăng dần (từ trên xuống)
      });
      // Kết hợp lại thành đoạn văn bản đúng thứ tự
      String sortedText = lines.map((line) => line['text']).join(" ");
      print("🔹 Văn bản sau khi sắp xếp:\n$sortedText");
      if (!isReading) {
        _readText(sortedText);
      } else {
        _stopReading();
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred when scanning text'),
        ),
      );
    }
  }

  void _toggleCamera() {
    if (_cameraController == null) return;
    // get current lens direction (front / rear)
    final lensDirection = _cameraController!.description.lensDirection;
    CameraDescription newDescription;
    if (lensDirection == CameraLensDirection.front) {
      newDescription = _availableCameras.firstWhere((description) =>
          description.lensDirection == CameraLensDirection.back);
    } else {
      newDescription = _availableCameras.firstWhere((description) =>
          description.lensDirection == CameraLensDirection.front);
    }

    if (newDescription != null) {
      _cameraSelected(newDescription);
    } else {
      print('Asked camera not available');
    }
  }

  // get available cameras
  Future<void> _getAvailableCameras() async {
    _availableCameras = await availableCameras();
    _initCameraController(_availableCameras);
  }

  void _readText(String text) async {
    await flutterTts.setLanguage("vi-VN");
    final List<dynamic> languages = await flutterTts.getLanguages;
    print("🔹 Đang đọc: $languages");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1);
    await flutterTts.speak(text);
    if (Platform.isIOS) {

    }
    isReading = true;
  }

  void _stopReading() async {
    await flutterTts.stop();
    isReading = false;
  }
}
