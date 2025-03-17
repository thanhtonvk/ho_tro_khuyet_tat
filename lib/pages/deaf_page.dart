import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../features/chat/room_page.dart';
import '../features/deaf/giao_tiep_cau_page.dart';
import '../features/deaf/giao_tiep_tu_page.dart';
import '../features/person_normal/person_normal_screen.dart';
import '../providers/giao_tiep_cau_camera_controller.dart';
import '../providers/giao_tiep_tu_camera_controller.dart';
import 'drawer_list_feature_deaf.dart';

// Tạo state provider để quản lý trạng thái chọn item
final selectedCommandProvider = StateProvider<int?>((ref) => null);

class DeafPage extends HookConsumerWidget {
  DeafPage({super.key, required this.title});

  final String title;
  final FlutterTts flutterTts = FlutterTts();
  final SpeechToText speechToText = SpeechToText();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      drawer: DrawerListFeatureWidgetDeaf(),
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text(
          "Người khuyết tật",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            "Câu lệnh có thể sử dụng:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildCommandList(ref, context),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildCommandList(WidgetRef ref, BuildContext context) {
    final commands = [
      {"text": "Giao tiếp từ", "icon": Icons.map},
      {"text": "Giao tiếp câu", "icon": Icons.accessibility_new},
      {"text": "Giao tiếp thường", "icon": Icons.person},
      {"text": "Chat", "icon": Icons.chat},
    ];

    final selectedIndex = ref.watch(selectedCommandProvider);

    return Center(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: List.generate(commands.length, (index) {
          final isSelected = selectedIndex == index;

          return GestureDetector(
            onTap: () {
              ref.read(selectedCommandProvider.notifier).state = index;
              if (index == 0) {
                ref.read(giaoTiepTuCameraController).startImageStream(1);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const GiaoTiepTuPage()));
              } else if (index == 1) {
                ref.read(giaoTiepCauCameraController).startImageStream(1);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const GiaoTiepCauPage()));
              } else if (index == 2) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PersonNormalScreen()));
              } else if (index == 3) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RoomPage()));
              }
            },
            child: Chip(
              label: Text(commands[index]["text"] as String),
              avatar: Icon(commands[index]["icon"] as IconData),
              backgroundColor: isSelected
                  ? Colors.blueAccent
                  : Colors.blueAccent.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }),
      ),
    );
  }
}
