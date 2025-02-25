import 'package:dart_ncnn_yolov8/dart_ncnn_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:nguoi_khuyet_tat/providers/face_camera_controller.dart';
import 'package:nguoi_khuyet_tat/providers/face_detection/face_detect_controller.dart';

import 'face_manager_page.dart';

class FaceDetectPage extends HookConsumerWidget {
  const FaceDetectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewImage = ref.watch(FaceDetectController.previewImage);

    void showBackDialog() {
      ref.read(faceCameraController).stopImageStream();
      Navigator.pop(context);
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        showBackDialog();
      },
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                ref.read(faceCameraController).stopImageStream();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FaceManagerPage()),
                );
              },
            ),
          ],
          title: const Text('Nhận diện khuôn mặt',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          centerTitle: true,
          backgroundColor: Colors.blueAccent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () {
              ref.read(faceCameraController).stopImageStream();
              showBackDialog();
            },
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blueAccent, Colors.white],
            ),
          ),
          child: Center(
            child: previewImage == null
                ? const CircularProgressIndicator()
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: previewImage.width.toDouble(),
                      height: previewImage.height.toDouble(),
                      child: CustomPaint(
                        painter: FaceResultPainter(
                          image: previewImage,
                          results: ref.watch(faceDetectController),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        resizeToAvoidBottomInset: true,
        extendBodyBehindAppBar: true,
      ),
    );
  }
}
