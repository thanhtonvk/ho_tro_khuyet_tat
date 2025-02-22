import 'package:dart_ncnn_yolov8/dart_ncnn_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nguoi_khuyet_tat/providers/deaf_detection/deaf_detection_controller.dart';
import 'package:nguoi_khuyet_tat/providers/deaf_detection/deaf_merge_detection_controller.dart';
import 'package:nguoi_khuyet_tat/providers/giao_tiep_cau_camera_controller.dart';
import 'package:nguoi_khuyet_tat/providers/giao_tiep_tu_camera_controller.dart';
import '../providers/ncnn_yolo_options.dart';
import '../utils/common.dart';

// A screen that allows users to take a picture using a given camera.
class GiaoTiepCauPage extends HookConsumerWidget {
  const GiaoTiepCauPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewImage = ref.watch(DeafMergeDetectionController.previewImage);
    void showBackDialog() {
      showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Thoát'),
            content: const Text(
              'Bạn có muốn rời đi không？',
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text('KHÔNG'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text('CÓ'),
                onPressed: () {
                  ref.read(giaoTiepCauCameraController).stopImageStream();
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              showBackDialog();
            },
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Builder(
          builder: (_) {
            if (previewImage == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
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
                            results: ref.watch(deafMergeDetectionController),
                            labels: labelsDeaf,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20, // Cách đáy màn hình 20 pixel
                  left: 0,
                  right: 0,
                  child: Align(
                    alignment: Alignment.center,
                    child: ValueListenableBuilder<String>(
                      valueListenable: Common.noiDung,
                      builder: (context, value, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        resizeToAvoidBottomInset: true,
        extendBodyBehindAppBar: true,
      ),
    );
  }
}
