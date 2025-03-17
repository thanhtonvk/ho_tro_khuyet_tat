import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> playAudio(String filePath) async {
    try {
      await _audioPlayer.stop(); // Dừng nếu có âm thanh đang phát
      await _audioPlayer.play(AssetSource(filePath));
    } catch (e) {
      print("🔴 Lỗi phát âm thanh: $e");
    }
  }
}
