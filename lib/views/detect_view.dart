import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nguoi_khuyet_tat/pages/do_duong_page.dart';
import 'package:nguoi_khuyet_tat/providers/blind_camera_controller.dart';

import '../pages/camera_page.dart';

class DetectView extends HookConsumerWidget {
  const DetectView({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            "Detect View",
          ),
          FloatingActionButton(
              onPressed: () {
                ref.read(blindCameraController).startImageStream();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoDuongPage(),
                  ),
                );
              },
              child: const Icon(Icons.camera)),
        ],
      ),
    );
  }
}
