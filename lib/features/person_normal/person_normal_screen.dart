import 'package:flutter/cupertino.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:video_player/video_player.dart';

class PersonNormalScreen extends StatefulWidget {
  const PersonNormalScreen({super.key});

  @override
  _PersonNormalScreenState createState() => _PersonNormalScreenState();
}

class _PersonNormalScreenState extends State<PersonNormalScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText speech = stt.SpeechToText();
  TextEditingController textController = TextEditingController();
  VideoPlayerController? _videoController;
  bool isListening = false;
  static final Map<String, String> keywordToVideoMap = {};

  static void createChuCaiDict() {
    keywordToVideoMap.clear();
    keywordToVideoMap.addAll({
      "chấm": "dau_cham.mp4",
      "hỏi": "dau_hoi.mp4",
      "huyền": "dau_huyen.mp4",
      "ngã": "dau_nga.mp4",
      "sắc": "dau_sac.mp4",
      "a": "chu_a.mp4",
      "ă": "chu_aw.mp4",
      "â": "chu_aa.mp4",
      "b": "chu_b.mp4",
      "c": "chu_c.mp4",
      "d": "chu_d.mp4",
      "đ": "chu_dd.mp4",
      "e": "chu_e.mp4",
      "ê": "chu_ee.mp4",
      "g": "chu_g.mp4",
      "h": "chu_h.mp4",
      "i": "chu_i.mp4",
      "k": "chu_k.mp4",
      "l": "chu_l.mp4",
      "m": "chu_m.mp4",
      "n": "chu_n.mp4",
      "o": "chu_o.mp4",
      "ô": "chu_oo.mp4",
      "ơ": "chu_ow.mp4",
      "p": "chu_p.mp4",
      "q": "chu_q.mp4",
      "r": "chu_r.mp4",
      "s": "chu_s.mp4",
      "t": "chu_t.mp4",
      "u": "chu_u.mp4",
      "ư": "chu_uw.mp4",
      "v": "chu_v.mp4",
      "x": "chu_x.mp4",
      "y": "chu_y.mp4",
    });
  }

  static void createCauDict() {
    keywordToVideoMap.clear();
    keywordToVideoMap.addAll({
      "xin chào": "xin_chao_vid.mp4",
      "cảm ơn": "cam_on_vid.mp4",
      "đánh vần ngón tay": "danh_van_ngon_tay.mp4",
      "bạn khỏe không": "ban_khoe_khong.mp4",
      "bạn thật tuyệt vời": "ban_that_tuyet_voi.mp4",
      "hẹn gặp lại": "hen_gap_lai_vid.mp4",
      "rất vui được gặp bạn": "rat_vui_duoc_gap_ban_vid.mp4",
      "tên tôi là": "ten_toi_la.mp4",
      "vỗ tay": "vo_tay.mp4",
      "xin lỗi": "xin_loi_vid.mp4",
      "bất ngờ": "bat_ngo.mp4",
      "buồn": "buon_vid.mp4",
      "thất vọng": "that_vong.mp4",
      "tức giận": "tuc_gian.mp4",
      "vui": "vui.mp4",
      "biết": "biet.mp4",
      "chấp nhận": "chap_nhan.mp4",
      "ghen": "ghen.mp4",
      "ghét": "ghet.mp4",
      "hiểu": "hieu.mp4",
      "hồi hộp": "hoi_hop.mp4",
      "không biết": "khong_biet.mp4",
      "không hiểu": "khong_hieu.mp4",
      "không thích": "khong_thich_vid.mp4",
      "mắc cở": "mac_co.mp4",
      "nhớ": "nho.mp4",
      "sợ": "so_vid.mp4",
      "bạn thích không": "thich_vid.mp4",
      "thông cảm": "thong_cam.mp4",
      "tình cảm": "tinh_cam.mp4",
      "tò mò": "to_mo.mp4",
      "xấu hổ": "xau_ho.mp4",
      "yên tâm": "yen_tam.mp4",
      "yêu": "yeu.mp4",
      "anh trai": "anh_trai.mp4",
      "chị gái": "chi_gai.mp4",
      "con": "con01.mp4",
      "cha": "cha.mp4",
      "mẹ": "me.mp4",
      "nhà": "nha.mp4",
      "gia đình": "gia_dinh.mp4",
      "con trai": "con_trai.mp4",
      "con gái": "con_gai.mp4",
      "yêu thương": "yeu_thuong.mp4",
      "biết ơn": "biet_on.mp4",
      "hạnh phúc": "hanh_phuc.mp4",
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void speakText(String text) async {
    await flutterTts.speak(text);
  }

  void startListening() async {
    bool available = await speech.initialize();
    if (available) {
      setState(() => isListening = true);
      speech.listen(onResult: (result) {
        setState(() {
          textController.text = result.recognizedWords;
        });
      });
    }
  }

  void stopListening() {
    setState(() => isListening = false);
    speech.stop();
  }

  void playVideo(String keyword) {
    if (_videoController != null) {
      _videoController!.dispose();
    }
    print('keyword $keyword');
    _videoController = VideoPlayerController.asset('assets/videos/$keyword')
      ..initialize().then((_) {
        setState(() {});
        _videoController!.play();
      });
  }

  int change = 0;

  void changeDict() {
    setState(() {
      if (change == 0) {
        createCauDict();

        change = 1;
      } else {
        createChuCaiDict();
        change = 0;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    createChuCaiDict(); // Khởi tạo danh sách ban đầu
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Người bình thường',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_right),
            onPressed: changeDict,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_videoController != null && _videoController!.value.isInitialized)
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 5)
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ),

          // Danh sách video (GridView)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 2 cột
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: keywordToVideoMap.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () =>
                      playVideo(keywordToVideoMap.values.elementAt(index)),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    color: Colors.blueAccent.shade100,
                    child: Center(
                      child: Text(
                        keywordToVideoMap.keys.elementAt(index),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: 'Nhập nội dung',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.volume_up, color: Colors.blueAccent),
                  onPressed: () => speakText(textController.text),
                ),
              ),
            ),
          ),

          // Nút Microphone (Speech to Text)
          GestureDetector(
            onTap: isListening ? stopListening : startListening,
            child: CircleAvatar(
              radius: 30,
              backgroundColor: isListening ? Colors.red : Colors.blueAccent,
              child: Icon(
                isListening ? Icons.mic_off : Icons.mic,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
