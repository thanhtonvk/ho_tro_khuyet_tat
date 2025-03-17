import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nguoi_khuyet_tat/pages/deaf_page.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'blind_page.dart';

class HomePage extends HookConsumerWidget {
  HomePage({super.key});

  final recognizedTextProvider = StateProvider<String>((ref) => "");
  final isListeningProvider = StateProvider<bool>((ref) => false);
  final FlutterTts flutterTts = FlutterTts();
  final SpeechToText speechToText = SpeechToText();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isListening = ref.watch(isListeningProvider);
    useEffect(() {
      _initSpeechToText();
      _setupTTS('vi-VN');
      return null;
    }, []);
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Hỗ trợ người khuyết tật",
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.blueAccent,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Chức năng dành cho người mù
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => BlindPage(
                              title: 'Hỗ trợ người mù',
                            )),
                  );
                },
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.visibility_off, // Icon đại diện cho người mù
                        size: 80,
                        color: Colors.white,
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Dành cho Khiếm thị",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Chức năng dành cho người câm điếc
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DeafPage(
                              title: 'Hỗ trợ người câm điếc',
                            )),
                  );
                },
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.hearing_disabled,
                        // Icon đại diện cho người câm điếc
                        size: 80,
                        color: Colors.white,
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Dành cho Câm điếc",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
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
              const SizedBox(
                height: 50,
              )
            ],
          ),
        ));
  }

  void _listenToSpeech(BuildContext context, WidgetRef ref) async {
    ref.read(isListeningProvider.notifier).state = true;

    await speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          final text = result.recognizedWords;
          ref.read(recognizedTextProvider.notifier).state = text;
          String content = removeDiacritics(text.trim().toLowerCase());

          if (content.contains("khiem thi")) {
            _speak('Mở chức năng khiếm thị');
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => BlindPage(title: "Hỗ trợ người mù")));
          } else if (content.contains("cam diec")) {
            _speak('Mở chức năng câm điếc');
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        DeafPage(title: "Dành cho người câm điếc")));
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
