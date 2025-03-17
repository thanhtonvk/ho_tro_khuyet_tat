import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nguoi_khuyet_tat/features/person_normal/person_normal_screen.dart';
import 'package:nguoi_khuyet_tat/providers/giao_tiep_cau_camera_controller.dart';
import 'package:nguoi_khuyet_tat/providers/giao_tiep_tu_camera_controller.dart';
import '../features/chat/room_page.dart';
import '../features/deaf/giao_tiep_cau_page.dart';
import '../features/deaf/giao_tiep_tu_page.dart';

class DrawerListFeatureWidgetDeaf extends HookConsumerWidget {
  DrawerListFeatureWidgetDeaf({super.key});

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
                Icon(
                  Icons.hearing_disabled,
                  // Icon đại diện cho người câm điếc
                  size: 80,
                  color: Colors.black,
                ),
                SizedBox(height: 10),
                Text(
                  "Ứng dụng hỗ trợ giao tiếp",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Danh sách tính năng
          Expanded(
            child: ListView(
              children: [
                DrawerItem(
                  title: "Giao tiếp từ",
                  icon: Icons.translate,
                  onTap: () {
                    _speak("Giao tiếp từ");
                    ref.read(giaoTiepTuCameraController).startImageStream(1);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const GiaoTiepTuPage()));
                  },
                ),
                DrawerItem(
                  title: "Giao tiếp câu",
                  icon: Icons.textsms,
                  onTap: () {
                    _speak("Giao tiếp câu");
                    ref.read(giaoTiepCauCameraController).startImageStream(1);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const GiaoTiepCauPage()));
                  },
                ),
                DrawerItem(
                  title: "Người bình thường ",
                  icon: Icons.people_outline,
                  onTap: () {
                    _speak("Người bình thường");
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PersonNormalScreen()));
                  },
                ),
                DrawerItem(
                  title: "Chat",
                  icon: Icons.message,
                  onTap: () {
                    _speak("Chat");

                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RoomPage()));
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

  const DrawerItem(
      {super.key,
      required this.title,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
    );
  }
}
