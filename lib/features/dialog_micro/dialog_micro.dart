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
      child: Container(
        height: 300,
        width: double.infinity,
        child: Column(
          children: [
             Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    widget.isCallContact ? 'Hãy đọc tên người bạn muốn gọi:' : 'Hãy đọc số điện thoại bạn muốn gọi:',
                    style: AppTextStyle.appBarTitle,
                  ),
                )),
            SizedBox(height: 20),
            IconButton(
              onPressed: () {
                if (isListening) {
                  _stopListening();
                } else {
                  _listenToSpeech();
                }
              },
              icon: Image.asset('assets/images/ic_mic.png'),
            ),
          ],
        ),
      ),
    );
  }

  void _listenToSpeech() async {
    isListening = true;
    await speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          print('result speech: ${result.recognizedWords}');
          if (!widget.isCallContact) {
            makePhoneCall(result.recognizedWords);
          } else {
            makePhoneCallFromContact(result.recognizedWords);
          }
        }
      },
      listenFor: Duration(seconds: 30),
      localeId: 'vi-VN',
    );
  }

  void _stopListening() async {
    isListening = false;
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
    // Xin quyền truy cập danh bạ
    if (await Permission.contacts.request().isGranted) {
      Iterable<Contact> contactList =
          await ContactsService.getContacts(withThumbnails: false);
      setState(() {
        contacts = contactList.toList();
        print(contacts);
      });
    } else {
      print('Không có quyền truy cập danh bạ');
    }
  }
}
