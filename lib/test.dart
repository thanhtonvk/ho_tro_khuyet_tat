import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> chatWithGPT(String userInput) async {
  const String apiKey  = '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';
  const String apiUrl = "https://api.openai.com/v1/chat/completions";

  List<Map<String, String>> messages = [
    {"role": "system", "content": "Bạn là một trợ lý ảo thông minh, có thể trả lời các câu hỏi và hỗ trợ người dùng một cách chuyên nghiệp. Chỉ trả về văn bản thuần túy, không sử dụng định dạng Markdown."},
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
      final responseData = jsonDecode(response.body);
      final botMessage = responseData['choices'][0]['message']['content'];
      print("Bot: $botMessage");
    } else {
      print("Bot: Lỗi từ server!");
    }
  } catch (e) {
    print("Bot: Lỗi kết nối!");
  }
}

void main() {
  stdout.write("Bạn: ");
  String? userInput = stdin.readLineSync();
  if (userInput != null && userInput.isNotEmpty) {
    chatWithGPT(userInput);
  }
}