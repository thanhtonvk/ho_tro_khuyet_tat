import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nguoi_khuyet_tat/pages/do_duong_page.dart';
import 'package:nguoi_khuyet_tat/pages/giao_tiep_cau_page.dart';
import 'package:nguoi_khuyet_tat/pages/giao_tiep_tu_page.dart';
import 'package:nguoi_khuyet_tat/providers/blind_camera_controller.dart';
import 'package:nguoi_khuyet_tat/providers/giao_tiep_cau_camera_controller.dart';
import 'package:nguoi_khuyet_tat/providers/giao_tiep_tu_camera_controller.dart';

import '../providers/face_camera_controller.dart';
import 'face_detect_page.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text("Người khiếm thị"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildButton(
                icon: Icons.navigation,
                label: "Dò đường",
                onTap: () {
                  ref.read(blindCameraController).startImageStream(1);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DoDuongPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildButton(
                icon: Icons.face,
                label: "Nhận diện khuôn mặt",
                onTap: () {
                  ref.read(faceCameraController).startImageStream(1);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FaceDetectPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildButton(
                icon: Icons.face,
                label: "Giao tiếp từ",
                onTap: () {
                  ref.read(giaoTiepTuCameraController).startImageStream(1);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GiaoTiepTuPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildButton(
                icon: Icons.face,
                label: "Giao tiếp câu",
                onTap: () {
                  ref.read(giaoTiepCauCameraController).startImageStream(1);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GiaoTiepCauPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ));
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
