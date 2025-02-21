import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nguoi_khuyet_tat/utils/app_text_style.dart';
import 'package:speech_to_text/speech_to_text.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  _LearningScreenState createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  int currentQuestionIndex = 1;
  Map<int, Map<String, dynamic>> questions = {};
  bool isRetried = false;
  bool isReading = false;
  bool isListening = false;
  final flutterTts = FlutterTts();
  SpeechToText speechToText = SpeechToText();

  @override
  void initState() {
    super.initState();
    _generateQuestionsAndSetState(10); // Generate questions and rebuild UI
    _initSpeechToText();
  }

  Future<void> _initSpeechToText() async {
    await speechToText.initialize();
  }

  @override
  void dispose() {
    super.dispose();
    _stopReading();
  }

  void _generateQuestionsAndSetState(int totalQuestions) {
    setState(() {
      questions = generateQuestions(totalQuestions);
      _readQuestion();
      print(questions);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty || !questions.containsKey(currentQuestionIndex)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Học tập",
            style: AppTextStyle.appBarTitle,
          ),
        ),
        body: Center(
          child: Text(
            "No questions available",
            style:
                AppTextStyle.learningQuestionText.copyWith(color: Colors.black),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Học tập",
          style: AppTextStyle.appBarTitle,
        ),
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: [
              Flexible(
                flex: 1,
                child: Column(
                  children: [
                    // question
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        margin: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFFF9790),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            questions[currentQuestionIndex]!['question']
                                .toString(),
                            style: AppTextStyle.learningQuestionText,
                          ),
                        ),
                      ),
                    ),
                    // answer
                    Row(
                      children: [
                        SizedBox(width: 16),
                        Flexible(
                          flex: 1,
                          child: AspectRatio(
                            aspectRatio: 1 / 1,
                            child: ElevatedButton(
                              onPressed: () {
                                handleAnswer(
                                    questions[currentQuestionIndex]!['options']
                                            ['A']
                                        .toString());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF4ECB71),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  questions[currentQuestionIndex]!['options']
                                          ['A']
                                      .toString(),
                                  style: AppTextStyle.learningAnswerText,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          flex: 1,
                          child: AspectRatio(
                            aspectRatio: 1 / 1,
                            child: ElevatedButton(
                              onPressed: () {
                                handleAnswer(
                                    questions[currentQuestionIndex]!['options']
                                            ['B']
                                        .toString());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF85B6FF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  questions[currentQuestionIndex]!['options']
                                          ['B']
                                      .toString(),
                                  style: AppTextStyle.learningAnswerText,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(width: 16),
                        Flexible(
                          flex: 1,
                          child: AspectRatio(
                            aspectRatio: 1 / 1,
                            child: ElevatedButton(
                              onPressed: () {
                                handleAnswer(
                                    questions[currentQuestionIndex]!['options']
                                            ['C']
                                        .toString());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFD99BFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  questions[currentQuestionIndex]!['options']
                                          ['C']
                                      .toString(),
                                  style: AppTextStyle.learningAnswerText,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          flex: 1,
                          child: AspectRatio(
                            aspectRatio: 1 / 1,
                            child: ElevatedButton(
                              onPressed: () {
                                handleAnswer(
                                    questions[currentQuestionIndex]!['options']
                                            ['D']
                                        .toString());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFFD233),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  questions[currentQuestionIndex]!['options']
                                          ['D']
                                      .toString(),
                                  style: AppTextStyle.learningAnswerText,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                      ],
                    )
                  ],
                ),
              ),
              Row(
                children: [
                  SizedBox(width: 16),
                  IconButton(
                    onPressed: () {
                      _readQuestion();
                    },
                    icon: const Icon(Icons.refresh),
                    iconSize: 100,
                  ),
                  Flexible(flex: 1, child: Container()),
                  IconButton(
                    onPressed: () {
                      if (isListening) {
                        isListening = false;
                        _stopListening();
                      } else {
                        isListening = true;
                        _listenToSpeech();
                      }
                    },
                    icon: const Icon(Icons.mic),
                    iconSize: 100,
                  ),
                  SizedBox(width: 16),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> handleAnswer(String answer) async {
    if (answer == questions[currentQuestionIndex]!['answer']) {
      isRetried = false;
      if (isReading) {
        await _stopReading();
      }
      await _readText('Chúc mừng bạn đã trả lời đúng.');
      print('correct');
      nextQuestion();
    } else {
      if (!isRetried) {
        isRetried = true;
        if (isReading) {
          await _stopReading();
        }
        await _readText('Câu trả lời chưa chính xác. Bạn hãy chọn lại.');
        return;
      } else {
        if (isReading) {
          await _stopReading();
        }
        await _readText(
            'Câu trả lời chưa chính xác. Đáp án đúng là ${questions[currentQuestionIndex]!['answer']}');
        nextQuestion();
      }
      print('incorrect');
    }
  }

  void nextQuestion() {
    if (currentQuestionIndex < questions.length) {
      setState(() {
        currentQuestionIndex++;
        _readQuestion();
      });
    } else {
      //show dialog
    }
  }

  Map<int, Map<String, dynamic>> generateQuestions(int totalQuestions) {
    final Random random = Random();
    final Map<int, Map<String, dynamic>> questionMap = {};
    final Set<int> usedResults = {};

    for (int i = 1; i <= totalQuestions; i++) {
      int num1, num2, result;

      do {
        num1 = random.nextInt(20) + 1;
        num2 = random.nextInt(20) + 1;
        result = num1 + num2;
      } while (usedResults.contains(result));

      usedResults.add(result);

      // Tạo đáp án ngẫu nhiên
      List<int> options = [result];
      while (options.length < 4) {
        int fakeAnswer = result + random.nextInt(10);
        if (fakeAnswer != result &&
            fakeAnswer > 0 &&
            !options.contains(fakeAnswer)) {
          options.add(fakeAnswer);
        }
      }

      // Trộn đáp án
      options.shuffle();

      // Xác định đáp án đúng
      String correctOption =
          String.fromCharCode(65 + options.indexOf(result)); // A, B, C, D

      // Thêm câu hỏi vào map
      questionMap[i] = {
        'question': '$num1 + $num2',
        'options': {
          'A': options[0],
          'B': options[1],
          'C': options[2],
          'D': options[3],
        },
        'result': result,
        'answer': correctOption
      };
    }
    return questionMap;
  }

  void _readQuestion() async {
    final text =
        'Câu hỏi số ${currentQuestionIndex} ${questions[currentQuestionIndex]!['question']} đáp án 1 ${questions[currentQuestionIndex]!['options']['A']} đáp án 2 ${questions[currentQuestionIndex]!['options']['B']} đáp án 3 ${questions[currentQuestionIndex]!['options']['C']} đáp án 4 ${questions[currentQuestionIndex]!['options']['D']}';
    await _readText(text);
  }

  Future<void> _readText(String text) async {
    await flutterTts.setLanguage("vi-VN");
    await flutterTts.setSpeechRate(0.35);
    await flutterTts.setVolume(1);
    await flutterTts.speak(text);
    isReading = true;
  }

  Future<void> _stopReading() async {
    await flutterTts.stop();
    isReading = false;
  }

  void _listenToSpeech() async {
    await speechToText.listen(onResult: (result) {
      print('result speech: $result');
    },
    listenFor: Duration(seconds: 30)
    );
  }

  void _stopListening() async {
    await speechToText.stop();
  }
}
