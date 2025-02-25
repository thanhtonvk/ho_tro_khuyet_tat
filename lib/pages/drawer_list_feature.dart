import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nguoi_khuyet_tat/features/learning/learning_screen.dart';
import 'package:nguoi_khuyet_tat/features/person_normal/person_normal_screen.dart';
import 'package:nguoi_khuyet_tat/features/read_text/read_text_screen.dart';
import 'package:nguoi_khuyet_tat/providers/face_camera_controller.dart';
import 'package:nguoi_khuyet_tat/providers/giao_tiep_cau_camera_controller.dart';
import 'package:nguoi_khuyet_tat/providers/giao_tiep_tu_camera_controller.dart';
import '../features/deaf/giao_tiep_cau_page.dart';
import '../features/deaf/giao_tiep_tu_page.dart';
import '../features/dialog_micro/dialog_micro.dart';
import '../features/face/face_detect_page.dart';
import '../features/find_way/do_duong_page.dart';
import '../providers/blind_camera_controller.dart';

class DrawerListFeatureWidget extends HookConsumerWidget {
  DrawerListFeatureWidget({super.key});

  late FlutterTts flutterTts;

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
    flutterTts = FlutterTts();
    _setupTTS('vi-VN');

    return Drawer(
      child: Column(
        children: [
          // Header với nền gradient + ảnh logo
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.blue.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage("assets/images/ic_person.png"),
                ),
                SizedBox(height: 10),
                Text(
                  "Ứng dụng hỗ trợ",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Danh sách tính năng
          Expanded(
            child: ListView(
              children: [
                DrawerItem(
                  title: "Dò đường",
                  icon: Icons.map,
                  onTap: () {
                    _speak("Mở chức năng dò đường");
                    flutterTts.setCompletionHandler(() {
                      ref.read(blindCameraController).startImageStream(0);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DoDuongPage()));
                    });
                  },
                ),
                DrawerItem(
                  title: "Nhận diện người thân",
                  icon: Icons.person,
                  onTap: () {
                    _speak("Mở chức năng nhận diện người thân");
                    flutterTts.setCompletionHandler(() {
                      ref.read(faceCameraController).startImageStream(0);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const FaceDetectPage()));
                    });
                  },
                ),
                DrawerItem(
                  title: "Quay số",
                  icon: Icons.dialpad,
                  onTap: () {
                    _speak("Hãy đọc số điện thoại");
                    flutterTts.setCompletionHandler(() {
                      showDialog(context: context, builder: (_) => const DialogMicro(isCallContact: false));
                    });
                  },
                ),
                DrawerItem(
                  title: "Gọi trong danh bạ",
                  icon: Icons.contacts,
                  onTap: () {
                    _speak("Hãy đọc tên trong danh bạ");
                    flutterTts.setCompletionHandler(() {
                      showDialog(context: context, builder: (_) => const DialogMicro(isCallContact: true));
                    });
                  },
                ),
                DrawerItem(
                  title: "Đọc chữ",
                  icon: Icons.volume_up,
                  onTap: () {
                    _speak("Mở chức năng đọc chữ");
                    flutterTts.setCompletionHandler(() {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ReadTextScreen()));
                    });
                  },
                ),
                DrawerItem(
                  title: "Định vị",
                  icon: Icons.location_on,
                  onTap: () => _speak("Đã gửi vị trí"),
                ),
                DrawerItem(
                  title: "Học tập",
                  icon: Icons.school,
                  onTap: () {
                    _speak("Mở chức năng học tập");
                    flutterTts.setCompletionHandler(() {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LearningScreen(title: "Học tập")));
                    });
                  },
                ),
                DrawerItem(
                  title: "Thi online",
                  icon: Icons.assessment,
                  onTap: () {
                    _speak("Mở chức năng thi online");
                    flutterTts.setCompletionHandler(() {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LearningScreen(title: "Thi online")));
                    });
                  },
                ),
                DrawerItem(
                  title: "Giao tiếp từ",
                  icon: Icons.translate,
                  onTap: () {
                    _speak("Giao tiếp từ");
                    flutterTts.setCompletionHandler(() {
                      ref.read(giaoTiepTuCameraController).startImageStream(1);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const GiaoTiepTuPage()));
                    });
                  },
                ),
                DrawerItem(
                  title: "Giao tiếp câu",
                  icon: Icons.textsms,
                  onTap: () {
                    _speak("Giao tiếp câu");
                    flutterTts.setCompletionHandler(() {
                      ref.read(giaoTiepCauCameraController).startImageStream(1);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const GiaoTiepCauPage()));
                    });
                  },
                ),
                DrawerItem(
                  title: "Người bình thường ",
                  icon: Icons.textsms,
                  onTap: () {
                    _speak("Người bình thường");
                    flutterTts.setCompletionHandler(() {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonNormalScreen()));
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget cải tiến cho từng mục trong Drawer
class DrawerItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const DrawerItem({super.key, required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
    );
  }
}
