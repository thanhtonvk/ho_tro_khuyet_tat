import 'package:dart_ncnn_yolov8/yolo_result_painter.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nguoi_khuyet_tat/utils/common.dart';

import '../../providers/deaf_detection/chat_deaf_detection_controller.dart';

final databaseProvider = Provider<DatabaseReference>((ref) {
  return FirebaseDatabase.instance.ref();
});

class ChatScreen extends HookConsumerWidget {
  final String roomId;

  const ChatScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider);
    final messageController = useTextEditingController();
    final userId = useState('user_${DateTime.now().millisecondsSinceEpoch}');
    Common.userId.value = userId.value;
    final previewImage = ref.watch(ChatDeafDetectionController.previewImage);

    void sendMessage() {
      if (messageController.text.trim().isNotEmpty) {
        String message = messageController.text.trim();
        String? messageId =
            database.child("chat_rooms/$roomId/messages").push().key;

        if (messageId != null) {
          database.child("chat_rooms/$roomId/messages/$messageId").set({
            "sender": userId.value,
            "text": message,
            "timestamp": ServerValue.timestamp,
          });
          messageController.clear();
        }
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Phòng Chat: $roomId"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
      body: Column(
        children: [
          // Khu vực hiển thị ảnh nhận diện
          if (previewImage == null)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Align(
              alignment: Alignment.topCenter,
              child: AspectRatio(
                aspectRatio: previewImage.height / previewImage.width,
                child: CustomPaint(
                  painter: YoloResultPainter(
                    image: previewImage,
                    results: ref.watch(chatDeafDetectionController),
                    labels: ref.watch(labelsChatDeafProvider),
                  ),
                ),
              ),
            ),
          SizedBox(height: 50,),
          // Danh sách tin nhắn
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: database
                  .child("chat_rooms/$roomId/messages")
                  .orderByChild("timestamp")
                  .onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("Chưa có tin nhắn nào!"));
                }

                Map<dynamic, dynamic> messages =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                List<MapEntry<dynamic, dynamic>> sortedMessages =
                    messages.entries.toList()
                      ..sort((a, b) =>
                          a.value["timestamp"].compareTo(b.value["timestamp"]));

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  itemCount: sortedMessages.length,
                  itemBuilder: (context, index) {
                    final entry = sortedMessages[index];
                    final bool isMe = entry.value["sender"] == userId.value;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMe
                                  ? "Bạn"
                                  : "Người gửi: ${entry.value["sender"]}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.value["text"],
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Ô nhập tin nhắn
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: "Nhập tin nhắn...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue, size: 28),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
