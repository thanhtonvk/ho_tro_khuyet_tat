import 'package:flutter/material.dart';
import 'package:nguoi_khuyet_tat/utils/app_text_style.dart';

class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Học tập",
          style: AppTextStyle.appBarTitle,
        ),
      ),
      body: SafeArea(child: Container(
        child: Column(
          children: [
            Flexible(
              flex: 1,
              child: Column(

            )),
            Row(children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.refresh)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.mic)),
            ],)
          ],
        ),
      )),
    );
  }
}
