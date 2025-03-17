import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nguoi_khuyet_tat/providers/chatCameraController.dart';
import 'package:nguoi_khuyet_tat/utils/common.dart';
import '../../providers/giao_tiep_tu_camera_controller.dart';
import 'chat_screen.dart';

class RoomPage extends StatelessWidget {
  const RoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const RoomScreenPage(),
    );
  }
}

class RoomScreenPage extends HookConsumerWidget {
  const RoomScreenPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomController = useTextEditingController();

    void joinChatRoom() {
      String roomId = roomController.text.trim();
      if (roomId.isNotEmpty) {
        Common.roomId.value = roomId;
        ref.read(chatCameraController).startImageStream(1);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen(roomId: roomId)),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chat App')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: roomController,
                decoration: const InputDecoration(
                  labelText: 'Nhập ID phòng',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: joinChatRoom,
                child: const Text('Tham gia phòng chat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
