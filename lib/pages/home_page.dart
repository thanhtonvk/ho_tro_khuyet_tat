import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nguoi_khuyet_tat/pages/do_duong_page.dart';
import 'package:nguoi_khuyet_tat/providers/blind_camera_controller.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../features/dialog_micro/dialog_micro.dart';
import '../features/learning/learning_screen.dart';
import '../features/read_text/read_text_screen.dart';
import '../providers/face_camera_controller.dart';
import '../utils/app_text_style.dart';
import 'drawer_list_feature.dart';
import 'face_detect_page.dart';

class HomePage extends HookConsumerWidget {
  HomePage({super.key, required this.title});

  final String title;
  late FlutterTts flutterTts;
  SpeechToText speechToText = SpeechToText();
  bool isListening = false;

  Future<void> _initSpeechToText() async {
    await speechToText.initialize();
  }

  Future<void> _setupTTS(String lang) async {
    await flutterTts.setLanguage(lang); // Chọn tiếng Việt
    await flutterTts.setSpeechRate(0.6); // Tốc độ nói
    await flutterTts.setPitch(1.0); // Cao độ
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

    // Xử lý khi nói xong

    return Scaffold(
        drawer: DrawerListFeatureWidget(),
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text("Người khuyết tật"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            // Căn giữa theo chiều dọc
            crossAxisAlignment: CrossAxisAlignment.center,
            // Căn giữa theo chiều ngang
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Hãy ra lệnh",
                  style: AppTextStyle.appBarTitle,
                  textAlign: TextAlign.center, // Đảm bảo text được căn giữa
                ),
              ),
              const SizedBox(height: 20),
              IconButton(
                onPressed: () {
                  if (isListening) {
                    _stopListening();
                  } else {
                    _speak('Bạn hãy ra lệnh');
                    flutterTts.setCompletionHandler(() async {
                      _listenToSpeech(context, ref);
                    });
                  }
                },
                icon: Image.asset('assets/images/ic_mic.png'),
              ),
            ],
          ),
        ));
  }

  void _listenToSpeech(BuildContext context, WidgetRef ref) async {
    isListening = true;
    await speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          String content = result.recognizedWords;
          print('result speech: ${result.recognizedWords}');
          content = removeDiacritics(content.trim().toLowerCase());
          if (content.contains("do duong")) {
            _speak('Mở chức năng dò đường');
            flutterTts.setCompletionHandler(() async {
              ref.read(blindCameraController).startImageStream(0);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DoDuongPage(),
                ),
              );
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
                    builder: (context) => const ReadTextScreen(),
                  ));
            });
          } else if (content.contains("dinh vi") ||
              content.contains("vi tri")) {
            _speak("Đã gửi vị trí");
          } else if (content.contains("thi")) {
            _speak("Mở chức năng thi online");
            flutterTts.setCompletionHandler(() async {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const LearningScreen(title: "Thi online"),
                  ));
            });
          } else if (content.contains("hoc")) {
            _speak("Mở chức năng học tập");
            flutterTts.setCompletionHandler(() async {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const LearningScreen(title: "Học tập"),
                  ));
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

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
