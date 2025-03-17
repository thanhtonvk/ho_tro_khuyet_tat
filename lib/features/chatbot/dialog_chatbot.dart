
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nguoi_khuyet_tat/utils/app_text_style.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DialogChatBot extends StatefulWidget {
  const DialogChatBot({super.key});

  @override
  _DialogChatBotState createState() => _DialogChatBotState();
}

class _DialogChatBotState extends State<DialogChatBot> {
  SpeechToText speechToText = SpeechToText();
  bool isListening = false;
  late FlutterTts flutterTts;
  bool isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initSpeechToText();
    flutterTts = FlutterTts();
    _setupTTS('vi-VN');
  }

  Future<void> _initSpeechToText() async {
    await speechToText.initialize();
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  Future<void> _setupTTS(String lang) async {
    await flutterTts.setLanguage(lang); // Chọn tiếng Việt
    await flutterTts.setSpeechRate(0.6); // Tốc độ nói
    await flutterTts.setPitch(1.0); // Cao độ
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Bạn hãy hỏi câu hỏi",
              style: AppTextStyle.appBarTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                if (isListening) {
                  _stopListening();
                } else {
                  _listenToSpeech();
                }
              },
              child: CircleAvatar(
                radius: 40,
                backgroundColor:
                    isListening ? Colors.redAccent : Colors.blueAccent,
                child: isListening
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.mic, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Đóng', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  void _listenToSpeech() async {
    flutterTts.stop();
    setState(() => isListening = true);
    await speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          _stopListening();
          print(result.recognizedWords);
          chatWithGPT(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 10),
      localeId: 'vi-VN',
    );
  }

  Future<void> chatWithGPT(String userInput) async {
    const String apiKey =
        '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';
    const String apiUrl = "https://api.openai.com/v1/chat/completions";

    List<Map<String, String>> messages = [
      {
        "role": "system",
        "content":
            "Bạn là một trợ lý ảo thông minh và thân thiện, có thể trả lời các câu hỏi và hỗ trợ người dùng một cách chuyên nghiệp. Chỉ trả về văn bản thuần túy, không sử dụng định dạng Markdown."
      },
      {"role": "user", "content": userInput}
    ];

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": messages,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        final botMessage = responseData['choices'][0]['message']['content'];
        String result  = cleanMarkdown(botMessage);
        print(result);
        _speak(result);
      } else {
        _speak("Lỗi từ server!");
      }
    } catch (e) {
      _speak("Lỗi kết nối!");
    }
  }

  void _stopListening() async {
    setState(() => isListening = false);
    await speechToText.stop();
  }
  String cleanMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'[*_`~\[\](){}-]'), '') // Xóa ký tự markdown
        .replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '') // Xóa ảnh
        .replaceAll(RegExp(r'\[(.*?)\]\(.*?\)'), r'$1') // Xóa link
        .replaceAll(RegExp(r'```.*?```', dotAll: true), '') // Xóa block code
        .replaceAll(RegExp(r'`(.*?)`'), r'$1') // Xóa inline code
        .trim();
  }

}
