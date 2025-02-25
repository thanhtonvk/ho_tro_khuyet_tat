import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nguoi_khuyet_tat/providers/blind_camera_controller.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../features/dialog_micro/dialog_micro.dart';
import '../features/face/face_detect_page.dart';
import '../features/find_way/do_duong_page.dart';
import '../features/learning/learning_screen.dart';
import '../features/read_text/read_text_screen.dart';
import '../providers/face_camera_controller.dart';
import '../utils/app_text_style.dart';
import 'drawer_list_feature.dart';

class HomePage extends HookConsumerWidget {
  HomePage({super.key, required this.title});

  final String title;
  late FlutterTts flutterTts;
  SpeechToText speechToText = SpeechToText();
  bool isListening = false;
  String recognizedText = "";

  Future<void> _initSpeechToText() async {
    await speechToText.initialize();
  }

  Future<void> _setupTTS(String lang) async {
    await flutterTts.setLanguage(lang);
    await flutterTts.setSpeechRate(0.6);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await flutterTts.speak(text);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _initSpeechToText();
    flutterTts = FlutterTts();
    _setupTTS('vi-VN');

    return Scaffold(
      drawer: DrawerListFeatureWidget(),
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text(
          "Người khuyết tật",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Hiển thị văn bản nhận diện
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                recognizedText.isEmpty
                    ? "Bạn hãy nói gì đó..."
                    : recognizedText,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            // Danh sách câu lệnh gợi ý
            const Text(
              "Câu lệnh có thể sử dụng:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildCommandList(),
            const Spacer(),
            // Nút micro với hiệu ứng
            GestureDetector(
              onTap: () {
                if (isListening) {
                  _stopListening();
                } else {
                  _speak('Bạn hãy ra lệnh');
                  flutterTts.setCompletionHandler(() async {
                    _listenToSpeech(context, ref);
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isListening ? 90 : 80,
                width: isListening ? 90 : 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isListening ? Colors.redAccent : Colors.blueAccent,
                  boxShadow: [
                    BoxShadow(
                      color: isListening ? Colors.red : Colors.blue,
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.mic,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandList() {
    final commands = [
      {"text": "Dò đường", "icon": Icons.map},
      {"text": "Nhận diện người thân", "icon": Icons.person},
      {"text": "Gọi điện thoại", "icon": Icons.phone},
      {"text": "Đọc chữ", "icon": Icons.menu_book},
      {"text": "Học tập", "icon": Icons.school},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: commands
            .map(
              (cmd) => Chip(
                label: Text(cmd["text"] as String),
                avatar: Icon(cmd["icon"] as IconData),
                backgroundColor: Colors.blueAccent.withOpacity(0.2),
              ),
            )
            .toList(),
      ),
    );
  }

  void _listenToSpeech(BuildContext context, WidgetRef ref) async {
    isListening = true;
    await speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          recognizedText = result.recognizedWords;
          print('result speech: $recognizedText');
          String content =
              removeDiacritics(recognizedText.trim().toLowerCase());

          if (content.contains("do duong")) {
            _speak('Mở chức năng dò đường');
            flutterTts.setCompletionHandler(() async {
              ref.read(blindCameraController).startImageStream(0);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const DoDuongPage()));
            });
          } else if (content.contains("nguoi")) {
            _speak("Mở chức năng nhận diện người thân");
            flutterTts.setCompletionHandler(() async {
              ref.read(faceCameraController).startImageStream(0);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FaceDetectPage()));
            });
          } else if (content.contains("quay so") ||
              content.contains("goi dien")) {
            _speak("Hãy đọc số điện thoại");
            flutterTts.setCompletionHandler(() async {
              showDialog(
                  context: context,
                  builder: (context) =>
                      const DialogMicro(isCallContact: false));
            });
          } else if (content.contains("danh ba")) {
            _speak("Hãy đọc tên trong danh bạ");
            flutterTts.setCompletionHandler(() async {
              showDialog(
                  context: context,
                  builder: (context) => const DialogMicro(isCallContact: true));
            });
          } else if (content.contains("doc")) {
            _speak("Mở chức năng đọc chữ");
            flutterTts.setCompletionHandler(() async {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ReadTextScreen()));
            });
          } else if (content.contains("hoc")) {
            _speak("Mở chức năng học tập");
            flutterTts.setCompletionHandler(() async {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const LearningScreen(title: "Học tập")));
            });
          }
        }
      },
      listenFor: Duration(seconds: 30),
      localeId: 'vi-VN',
    );
  }

  void _stopListening() async {
    isListening = false;
    await speechToText.stop();
  }
}
