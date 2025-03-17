import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nguoi_khuyet_tat/features/chat/room_page.dart';
import 'package:nguoi_khuyet_tat/features/chatbot/dialog_chatbot.dart';
import 'package:nguoi_khuyet_tat/features/find_way/any_object_page.dart';
import 'package:nguoi_khuyet_tat/features/learning/learning_screen.dart';
import 'package:nguoi_khuyet_tat/features/read_text/read_text_screen.dart';
import 'package:nguoi_khuyet_tat/providers/face_camera_controller.dart';
import 'package:nguoi_khuyet_tat/providers/find_way_camera_controller.dart';
import '../features/dialog_micro/dialog_micro.dart';
import '../features/face/face_detect_page.dart';
import '../features/find_way/do_duong_page.dart';
import '../features/find_way/money_page.dart';
import '../providers/blind_camera_controller.dart';
import '../providers/money_camera_controller.dart';

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
                Icon(
                  Icons.visibility_off, // Icon đại diện cho người mù
                  size: 80,
                  color: Colors.white,
                ),
                SizedBox(height: 10),
                Text(
                  "Ứng dụng hỗ trợ khiếm thị",
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
                  title: "Tìm đồ vật",
                  icon: Icons.accessibility_new,
                  onTap: () {
                    _speak("Mở chức năng tìm đồ vật");
                    ref.read(blindCameraController).startImageStream(0);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const DoDuongPage()));
                  },
                ),
                DrawerItem(
                  title: "Dò đường",
                  icon: Icons.map,
                  onTap: () {
                    _speak("Mở chức năng dò đường");
                    ref.read(findWayCameraController).startImageStream(0);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AnyObjectPage()));
                  },
                ),
                DrawerItem(
                  title: "Nhận diện tiền",
                  icon: Icons.map,
                  onTap: () {
                    _speak("Mở chức năng nhận diện tiền");
                    ref.read(moneyCameraController).startImageStream(0);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MoneyPage()));
                  },
                ),
                DrawerItem(
                  title: "Nhận diện người thân",
                  icon: Icons.person,
                  onTap: () {
                    _speak("Mở chức năng nhận diện người thân");
                    ref.read(faceCameraController).startImageStream(0);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => FaceDetectPage()));
                  },
                ),
                DrawerItem(
                  title: "Quay số",
                  icon: Icons.dialpad,
                  onTap: () {
                    _speak("Hãy đọc số điện thoại");
                    showDialog(
                        context: context,
                        builder: (_) =>
                            const DialogMicro(isCallContact: false));
                  },
                ),
                DrawerItem(
                  title: "Gọi trong danh bạ",
                  icon: Icons.contacts,
                  onTap: () {
                    _speak("Hãy đọc tên trong danh bạ");
                    showDialog(
                        context: context,
                        builder: (_) => const DialogMicro(isCallContact: true));
                  },
                ),
                DrawerItem(
                  title: "Đọc chữ",
                  icon: Icons.voice_chat,
                  onTap: () {
                    _speak("Mở chức năng đọc chữ");
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ReadTextScreen()));
                  },
                ),

                DrawerItem(
                  title: "Chatbot",
                  icon: Icons.auto_awesome_mosaic_outlined,
                  onTap: () {
                    _speak("Mở chức năng chatbot");
                    showDialog(
                        context: context,
                        builder: (_) => const DialogChatBot());
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
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const LearningScreen(title: "Học tập")));
                  },
                ),
                DrawerItem(
                  title: "Thi online",
                  icon: Icons.assessment,
                  onTap: () {
                    _speak("Mở chức năng thi online");
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const LearningScreen(title: "Thi online")));
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
