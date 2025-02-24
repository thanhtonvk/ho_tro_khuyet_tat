import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nguoi_khuyet_tat/features/learning/learning_screen.dart';
import 'package:nguoi_khuyet_tat/features/read_text/read_text_screen.dart';
import 'package:nguoi_khuyet_tat/pages/face_detect_page.dart';
import 'package:nguoi_khuyet_tat/pages/giao_tiep_tu_page.dart';
import 'package:nguoi_khuyet_tat/providers/deaf_detection/deaf_detection_controller.dart';
import 'package:nguoi_khuyet_tat/providers/face_camera_controller.dart';
import 'package:nguoi_khuyet_tat/providers/giao_tiep_cau_camera_controller.dart';
import 'package:nguoi_khuyet_tat/providers/giao_tiep_tu_camera_controller.dart';

import '../features/dialog_micro/dialog_micro.dart';
import '../providers/blind_camera_controller.dart';
import 'do_duong_page.dart';
import 'giao_tiep_cau_page.dart';

class DrawerListFeatureWidget extends HookConsumerWidget {
  DrawerListFeatureWidget({super.key});

  late FlutterTts flutterTts;

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
    flutterTts = FlutterTts();
    _setupTTS('vi-VN');
    return Drawer(
      child: DrawerHeader(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Nguời khuyết tật",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                  width: double.infinity,
                  child: DrawerItemButton(
                    onPressed: () {
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
                    },
                    title: "Dò đường",
                    imagePath: "assets/images/ic_map.png",
                    icon: Icons.map,
                  )),
              SizedBox(
                width: double.infinity,
                child: DrawerItemButton(
                  onPressed: () {
                    _speak("Mở chức năng nhận diện người thân");
                    flutterTts.setCompletionHandler(() async {
                      ref.read(faceCameraController).startImageStream(0);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const FaceDetectPage()));
                    });
                  },
                  title: "Nhận diện người thân",
                  imagePath: "assets/images/ic_person.png",
                  icon: Icons.person,
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: DrawerItemButton(
                  onPressed: () {
                    _speak("Hãy đọc số điện thoại");
                    flutterTts.setCompletionHandler(() async {
                      showDialog(
                          context: context,
                          builder: (context) =>
                              const DialogMicro(isCallContact: false));
                    });
                  },
                  title: "Quay số",
                  imagePath: "assets/images/ic_keyboard.png",
                  icon: Icons.keyboard,
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: DrawerItemButton(
                      onPressed: () {
                        _speak("Hãy đọc tên trong danh bạ");
                        flutterTts.setCompletionHandler(() async {
                          showDialog(
                              context: context,
                              builder: (context) =>
                                  const DialogMicro(isCallContact: true));
                        });
                      },
                      title: "Gọi trong danh bạ",
                      imagePath: "assets/images/ic_contact.png",
                      icon: Icons.contact_emergency,
                    )),
              ),
              SizedBox(
                  width: double.infinity,
                  child: DrawerItemButton(
                    onPressed: () {
                      _speak("Mở chức năng đọc chữ");
                      flutterTts.setCompletionHandler(() async {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ReadTextScreen(),
                            ));
                      });
                    },
                    title: "Đọc chữ",
                    imagePath: "assets/images/ic_voice.png",
                    icon: Icons.volume_up,
                  )),
              SizedBox(
                  width: double.infinity,
                  child: DrawerItemButton(
                    onPressed: () {
                      _speak("Đã gửi vị trí");
                    },
                    title: "Định vị",
                    imagePath: "assets/images/ic_map.png",
                    icon: Icons.location_on,
                  )),
              SizedBox(
                  width: double.infinity,
                  child: DrawerItemButton(
                    onPressed: () {
                      _speak("Mở chức năng học tập");
                      flutterTts.setCompletionHandler(() async {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const LearningScreen(title: "Học tập"),
                            ));
                      });
                    },
                    title: "Học tập",
                    imagePath: "assets/images/ic_ranking.png",
                    icon: Icons.school,
                  )),
              SizedBox(
                width: double.infinity,
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: DrawerItemButton(
                      onPressed: () {
                        _speak("Mở chức năng thi online");
                        flutterTts.setCompletionHandler(() async {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const LearningScreen(title: "Thi online"),
                              ));
                        });
                      },
                      title: "Thi online",
                      imagePath: "assets/images/ic_ranking.png",
                      icon: Icons.school,
                    )),
              ),
              SizedBox(
                width: double.infinity,
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: DrawerItemButton(
                      onPressed: () {
                        _speak("Giao tiếp từ");
                        flutterTts.setCompletionHandler(() async {
                          ref
                              .read(giaoTiepTuCameraController)
                              .startImageStream(1);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const GiaoTiepTuPage(),
                              ));
                        });
                      },
                      title: "Giao tiếp từ",
                      imagePath: "assets/images/word.png",
                      icon: Icons.accessibility,
                    )),
              ),
              SizedBox(
                width: double.infinity,
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: DrawerItemButton(
                      onPressed: () {
                        _speak("Giao tiếp câu");
                        flutterTts.setCompletionHandler(() async {
                          ref
                              .read(giaoTiepCauCameraController)
                              .startImageStream(1);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const GiaoTiepCauPage(),
                              ));
                        });
                      },
                      title: "Giao tiếp câu",
                      imagePath: "assets/images/write.png",
                      icon: Icons.settings_accessibility_rounded,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DrawerItemButton extends StatelessWidget {
  const DrawerItemButton(
      {super.key,
      required this.onPressed,
      required this.title,
      required this.imagePath,
      required this.icon});

  final VoidCallback onPressed;
  final String title;
  final String imagePath;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: onPressed,
        child: TextButton(
            onPressed: () {
              onPressed();
            },
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: const Color(0xFF5C5C5C),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style:
                        const TextStyle(fontSize: 14, color: Color(0xFF5C5C5C)),
                  ),
                ],
              ),
            )));
  }
}
