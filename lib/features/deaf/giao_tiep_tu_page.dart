import 'package:dart_ncnn_yolov8/dart_ncnn_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nguoi_khuyet_tat/providers/deaf_detection/deaf_detection_controller.dart';
import 'package:nguoi_khuyet_tat/providers/giao_tiep_tu_camera_controller.dart';

import '../../providers/ncnn_yolo_options.dart';
import '../../utils/common.dart';

class GiaoTiepTuPage extends HookConsumerWidget {
  const GiaoTiepTuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewImage = ref.watch(DeafDetectionController.previewImage);

    void showBackDialog() {
      showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text(
              'Thoát',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text('Bạn có muốn rời đi không？'),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
                child: const Text('KHÔNG'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('CÓ'),
                onPressed: () {
                  ref.read(giaoTiepTuCameraController).stopImageStream();
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        showBackDialog();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: showBackDialog,
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: Builder(
          builder: (_) {
            if (previewImage == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return Stack(
              children: [
                Center(
                  child: SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: previewImage.width.toDouble(),
                        height: previewImage.height.toDouble(),
                        child: CustomPaint(
                          painter: YoloResultPainter(
                            image: previewImage,
                            results: ref.watch(deafDetectionController),
                            labels: labelsDeaf,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: ValueListenableBuilder<String>(
                    valueListenable: Common.noiDung,
                    builder: (context, value, child) {
                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: value.isNotEmpty ? 1.0 : 0.0,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            value,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
        extendBodyBehindAppBar: true,
      ),
    );
  }
}
