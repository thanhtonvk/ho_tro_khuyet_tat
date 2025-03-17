import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nguoi_khuyet_tat/utils/app_text_style.dart';
import 'package:speech_to_text/speech_to_text.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key, required this.title});

  final String title;

  @override
  _LearningScreenState createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  int currentQuestionIndex = 1;
  Map<int, Map<String, dynamic>> questions = {};
  bool isRetried = false;
  bool isReading = false;
  bool isListening = false;
  int countCorrectAnswer = 0;
  final int MAX_QUESTIONS = 5;
  final flutterTts = FlutterTts();
  SpeechToText speechToText = SpeechToText();

  @override
  void initState() {
    super.initState();
    _generateQuestionsAndSetState(
        MAX_QUESTIONS); // Generate questions and rebuild UI
    _initSpeechToText();
  }

  Future<void> _initSpeechToText() async {
    await speechToText.initialize();
  }

  @override
  void dispose() {
    super.dispose();
    _stopReading();
    _stopListening();
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
          title: Text(
            widget.title,
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
    if (int.tryParse(answer) == questions[currentQuestionIndex]!['result']) {
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
      showDialogResult();
    }
  }

  Map<int, Map<String, dynamic>> generateQuestions(int totalQuestions) {
    final Random random = Random();
    final Map<int, Map<String, dynamic>> questionMap = {};
    final List<String> subjects = [
      'Toán',
      'Lý',
      'Hóa',
      'Sinh',
      'Sử',
      'Địa',
      'Văn'
    ];

    for (int i = 1; i <= totalQuestions; i++) {
      String subject = subjects[random.nextInt(subjects.length)];
      String question = '';
      Map<String, dynamic> options = {};
      String correctOption = '';

      switch (subject) {
        case 'Toán':
          int num1 = random.nextInt(20) + 1;
          int num2 = random.nextInt(20) + 1;
          int result = num1 + num2;
          List<int> choices = [result];
          while (choices.length < 4) {
            int fakeAnswer = result + random.nextInt(10) - 5;
            if (fakeAnswer != result &&
                !choices.contains(fakeAnswer) &&
                fakeAnswer > 0) {
              choices.add(fakeAnswer);
            }
          }
          choices.shuffle();
          correctOption = String.fromCharCode(65 + choices.indexOf(result));
          options = {
            'A': choices[0],
            'B': choices[1],
            'C': choices[2],
            'D': choices[3],
          };
          question = '$num1 + $num2 = ?';
          break;

        case 'Lý':
          question = 'Đơn vị của lực trong hệ SI là gì?';
          options = {'A': 'Newton', 'B': 'Joule', 'C': 'Watt', 'D': 'Pascal'};
          correctOption = 'A';
          break;

        case 'Hóa':
          question = 'Nguyên tố nào có số hiệu nguyên tử là 8?';
          options = {'A': 'Oxi', 'B': 'Cacbon', 'C': 'Hydro', 'D': 'Nitơ'};
          correctOption = 'A';
          break;

        case 'Sinh':
          question = 'Đơn vị cơ bản của sự sống là gì?';
          options = {
            'A': 'Tế bào',
            'B': 'Nguyên tử',
            'C': 'Phân tử',
            'D': 'Mô'
          };
          correctOption = 'A';
          break;

        case 'Sử':
          question =
              'Năm 1945, sự kiện lịch sử quan trọng nào đã diễn ra ở Việt Nam?';
          options = {
            'A': 'Cách mạng tháng Tám',
            'B': 'Chiến tranh Đông Dương',
            'C': 'Hiệp định Paris',
            'D': 'Cách mạng công nghiệp'
          };
          correctOption = 'A';
          break;

        case 'Địa':
          question = 'Châu lục nào lớn nhất trên Trái Đất?';
          options = {
            'A': 'Châu Á',
            'B': 'Châu Âu',
            'C': 'Châu Mỹ',
            'D': 'Châu Phi'
          };
          correctOption = 'A';
          break;

        case 'Văn':
          question = 'Tác giả của truyện "Chí Phèo" là ai?';
          options = {
            'A': 'Nam Cao',
            'B': 'Ngô Tất Tố',
            'C': 'Tô Hoài',
            'D': 'Nguyễn Du'
          };
          correctOption = 'A';
          break;
      }

      questionMap[i] = {
        'subject': subject,
        'question': question,
        'options': options,
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
    await flutterTts.awaitSpeakCompletion(true);
    isReading = true;
  }

  Future<void> _stopReading() async {
    await flutterTts.stop();
    isReading = false;
  }

  void _listenToSpeech() async {
    await speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          if (int.tryParse(result.recognizedWords) != null) {
            print('result speech: ${result.recognizedWords}');
            handleAnswer(result.recognizedWords.trim());
          }
        }
      },
      listenFor: Duration(seconds: 30),
      localeId: 'vi-VN',
    );
  }

  void _stopListening() async {
    await speechToText.stop();
  }

  void showDialogResult() async {
    String text =
        'Bạn đã hoànt hành bài học. Bạn đã trả lời đúng $countCorrectAnswer câu hỏi. Trả lời sai ${MAX_QUESTIONS - countCorrectAnswer} câu hỏi. Điểm ${countCorrectAnswer * 2}';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hoàn thành bài kiểm tra'),
        content: Text(
          text,
        ),
      ),
    );
    await _readText(text);
  }
}
