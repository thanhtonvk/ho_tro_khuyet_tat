import 'package:dart_ncnn_yolov8/dart_ncnn_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nguoi_khuyet_tat/providers/blind_camera_controller.dart';
import 'package:nguoi_khuyet_tat/providers/object_detection/object_detection_controller.dart';

import '../../providers/ncnn_yolo_options.dart';

final distanceProvider = StateProvider<int>((ref) => 100); // Khoảng cách mặc định là 100

class CalibPage extends HookConsumerWidget {
  const CalibPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewImage = ref.watch(ObjectDetectionController.previewImage);
    final distance = ref.watch(distanceProvider); // Lấy giá trị khoảng cách

    void showBackDialog() {
      ref.read(blindCameraController).stopImageStream();
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 28, color: Colors.white),
            onPressed: showBackDialog,
          ),
          backgroundColor: Colors.black.withOpacity(0.5),
          elevation: 0,
          centerTitle: true,
        ),
        body: Stack(
          children: [
            // Hiển thị camera
            Positioned.fill(
              child: Builder(
                builder: (_) {
                  if (previewImage == null) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  return Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: previewImage.width.toDouble(),
                            height: previewImage.height.toDouble(),
                            child: CustomPaint(
                              painter: ObjectResultPainter(
                                image: previewImage,
                                results: ref.watch(objectDetectController),
                                labels: labels,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Hiển thị khoảng cách
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "Khoảng cách: $distance cm",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // 3 nút chức năng
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(distanceProvider.notifier).state += 5; // Tăng khoảng cách +5
                    },
                    icon: const Icon(Icons.add, size: 28),
                    label: const Text("Tăng"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(distanceProvider.notifier).state -= 5; // Giảm khoảng cách -5
                    },
                    icon: const Icon(Icons.remove, size: 28),
                    label: const Text("Giảm"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Xử lý lưu khoảng cách
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Đã lưu khoảng cách: $distance cm"),
                        ),
                      );
                    },
                    icon: const Icon(Icons.save, size: 28),
                    label: const Text("Lưu"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        resizeToAvoidBottomInset: true,
        extendBodyBehindAppBar: true,
      ),
    );
  }
}
