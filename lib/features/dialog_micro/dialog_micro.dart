import 'package:contacts_service/contacts_service.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:nguoi_khuyet_tat/utils/app_text_style.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';

class DialogMicro extends StatefulWidget {
  const DialogMicro({super.key, required this.isCallContact});

  final bool isCallContact;

  @override
  _DialogMicroState createState() => _DialogMicroState();
}

class _DialogMicroState extends State<DialogMicro> {
  SpeechToText speechToText = SpeechToText();
  bool isListening = false;
  List<Contact> contacts = [];

  @override
  void initState() {
    super.initState();
    _fetchContacts();
    _initSpeechToText();
  }

  Future<void> _initSpeechToText() async {
    await speechToText.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isCallContact
                  ? 'Hãy đọc tên người bạn muốn gọi:'
                  : 'Hãy đọc số điện thoại bạn muốn gọi:',
              style: AppTextStyle.appBarTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                if (isListening) {
                  _stopListening();
                } else {
                  _listenToSpeech();
                }
              },
              child: CircleAvatar(
                radius: 40,
                backgroundColor: isListening ? Colors.redAccent : Colors.blueAccent,
                child: isListening
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.mic, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Đóng', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  void _listenToSpeech() async {
    setState(() => isListening = true);
    await speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          print('result speech: ${result.recognizedWords}');
          if (!widget.isCallContact) {
            makePhoneCall(result.recognizedWords);
          } else {
            makePhoneCallFromContact(result.recognizedWords);
          }
          _stopListening();
        }
      },
      listenFor: const Duration(seconds: 30),
      localeId: 'vi-VN',
    );
  }

  void _stopListening() async {
    setState(() => isListening = false);
    await speechToText.stop();
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Không thể thực hiện cuộc gọi tới $phoneNumber';
    }
  }

  Future<void> makePhoneCallFromContact(String name) async {
    String normalizedName = removeDiacritics(name.trim().toLowerCase());
    if (contacts.isNotEmpty) {
      for (var contact in contacts) {
        String normalizedContactName = removeDiacritics(contact.displayName!.toLowerCase());
        if (normalizedContactName.contains(normalizedName)) {
          await makePhoneCall(contact.phones!.first.value!);
          break;
        }
      }
    }
  }

  Future<void> _fetchContacts() async {
    if (await Permission.contacts.request().isGranted) {
      Iterable<Contact> contactList = await ContactsService.getContacts(withThumbnails: false);
      setState(() {
        contacts = contactList.toList();
      });
    } else {
      print('Không có quyền truy cập danh bạ');
    }
  }
}
