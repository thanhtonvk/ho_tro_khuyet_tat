import 'package:flutter/material.dart';
import 'package:nguoi_khuyet_tat/pages/drawer_list_feature.dart';

import '../views/detect_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentPageIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      drawer: const DrawerListFeatureWidget(),
      body: switch (currentPageIndex) {
        0 => const DetectView(),
        int() => throw UnimplementedError(),
      },
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.camera_alt),
            label: 'Phát hiện thời gian thực',
          ),
          NavigationDestination(
            icon: Icon(Icons.play_arrow),
            label: 'Kiểm tra ảnh',
          ),
        ],
      )
    );
  }
}
