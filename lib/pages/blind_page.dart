import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nguoi_khuyet_tat/features/find_way/any_object_page.dart';
import 'package:nguoi_khuyet_tat/providers/find_way_camera_controller.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../features/dialog_micro/dialog_micro.dart';
import '../features/face/face_detect_page.dart';
import '../features/find_way/do_duong_page.dart';
import '../features/learning/learning_screen.dart';
import '../features/read_text/read_text_screen.dart';
import '../providers/blind_camera_controller.dart';
import '../providers/face_camera_controller.dart';
import 'drawer_list_feature.dart';

// Tạo state provider để quản lý trạng thái
final recognizedTextProvider = StateProvider<String>((ref) => "");
final isListeningProvider = StateProvider<bool>((ref) => false);

class BlindPage extends HookConsumerWidget {
  BlindPage({super.key, required this.title});

  final String title;
  final FlutterTts flutterTts = FlutterTts();
  final SpeechToText speechToText = SpeechToText();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recognizedText = ref.watch(recognizedTextProvider);
    final isListening = ref.watch(isListeningProvider);

    useEffect(() {
      _initSpeechToText();
      _setupTTS('vi-VN');
      return null;
    }, []);

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
            const Text(
              "Câu lệnh có thể sử dụng:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildCommandList(),
            const SizedBox(
              height: 20,
            ),
            GestureDetector(
              onTap: () {
                _speak(
                    'Nói dò đường để mở chức năng dò đường, Nói tìm đồ vật để mở chức năng tìm đồ vật, nói nhận diện người thân để mở chức năng nhận diện người thân, nói gọi điện thoại để mở chức năng gọi điện thoại, mở đọc chữ để mở chức năng đọc chữ, nói học tập để mở chức năng học tập');
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isListening ? 90 : 80,
                width: isListening ? 90 : 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue,
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.volume_down,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const Spacer(),
            // Nút micro với hiệu ứng
            GestureDetector(
              onTap: () {
                if (isListening) {
                  _stopListening(ref);
                } else {
                  _speak('Bạn hãy ra lệnh');
                  _listenToSpeech(context, ref);
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
      {"text": "Tìm đồ vật", "icon": Icons.accessibility_new},
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
    ref.read(isListeningProvider.notifier).state = true;

    await speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          final text = result.recognizedWords;
          ref.read(recognizedTextProvider.notifier).state = text;
          String content = removeDiacritics(text.trim().toLowerCase());

          if (content.contains("do vat")) {
            _speak('Mở chức năng tìm đồ vật');
            ref.read(blindCameraController).startImageStream(0);
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const DoDuongPage()));
          } else if (content.contains("do duong")) {
            _speak('Mở chức năng dò đường');
            ref.read(findWayCameraController).startImageStream(0);
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AnyObjectPage()));
          } else if (content.contains("nguoi")) {
            _speak("Mở chức năng nhận diện người thân");
            ref.read(faceCameraController).startImageStream(0);
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => FaceDetectPage()));
          } else if (content.contains("quay so") ||
              content.contains("goi dien")) {
            _speak("Hãy đọc số điện thoại");
            showDialog(
                context: context,
                builder: (context) => const DialogMicro(isCallContact: false));
          } else if (content.contains("danh ba")) {
            _speak("Hãy đọc tên trong danh bạ");
            showDialog(
                context: context,
                builder: (context) => const DialogMicro(isCallContact: true));
          } else if (content.contains("doc")) {
            _speak("Mở chức năng đọc chữ");
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ReadTextScreen()));
          } else if (content.contains("hoc")) {
            _speak("Mở chức năng học tập");
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const LearningScreen(title: "Học tập")));
          }
          _stopListening(ref);
        }
      },
      listenFor: const Duration(seconds: 5),
      localeId: 'vi-VN',
    );
  }

  void _stopListening(WidgetRef ref) async {
    ref.read(isListeningProvider.notifier).state = false;
    await speechToText.stop();
  }

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
}
