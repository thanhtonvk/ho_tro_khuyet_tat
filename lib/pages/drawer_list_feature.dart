import 'package:flutter/material.dart';
import 'package:nguoi_khuyet_tat/features/learning/learning_screen.dart';
import 'package:nguoi_khuyet_tat/features/read_text/read_text_screen.dart';

class DrawerListFeatureWidget extends StatelessWidget {
  const DrawerListFeatureWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: DrawerHeader(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Khiếm thị",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                  width: double.infinity,
                  child: DrawerItemButton(
                    onPressed: () {},
                    title: "Dò đường",
                    imagePath: "assets/images/ic_map.png",
                    icon: Icons.map,
                  )),
              SizedBox(
                width: double.infinity,
                child: DrawerItemButton(
                  onPressed: () {},
                  title: "Nhận diện người thân",
                  imagePath: "assets/images/ic_person.png",
                  icon: Icons.person,
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: DrawerItemButton(
                  onPressed: () {},
                  title: "Quay số",
                  imagePath: "assets/images/ic_keyboard.png",
                  icon: Icons.keyboard,
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: DrawerItemButton(
                      onPressed: () {},
                      title: "Gọi trong danh bạ",
                      imagePath: "assets/images/ic_contact.png",
                      icon: Icons.contact_emergency,
                    )),
              ),
              SizedBox(
                  width: double.infinity,
                  child: DrawerItemButton(
                    onPressed: () {
                      print("Đọc chữ");
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReadTextScreen(),
                          ));
                    },
                    title: "Đọc chữ",
                    imagePath: "assets/images/ic_voice.png",
                    icon: Icons.volume_up,
                  )),
              SizedBox(
                  width: double.infinity,
                  child: DrawerItemButton(
                    onPressed: () {},
                    title: "Định vị",
                    imagePath: "assets/images/ic_map.png",
                    icon: Icons.location_on,
                  )),
              SizedBox(
                width: double.infinity,
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: DrawerItemButton(
                      onPressed: () {},
                      title: "Nhận diện tiền",
                      imagePath: "assets/images/ic_money.png",
                      icon: Icons.money,
                    )),
              ),
              SizedBox(
                  width: double.infinity,
                  child: DrawerItemButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LearningScreen(),
                          ));
                    },
                    title: "Học tập",
                    imagePath: "assets/images/ic_ranking.png",
                    icon: Icons.school,
                  )),
              SizedBox(
                width: double.infinity,
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: DrawerItemButton(
                      onPressed: () {},
                      title: "Thi online",
                      imagePath: "assets/images/ic_ranking.png",
                      icon: Icons.school,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DrawerItemButton extends StatelessWidget {
  const DrawerItemButton(
      {super.key,
      required this.onPressed,
      required this.title,
      required this.imagePath,
      required this.icon});

  final VoidCallback onPressed;
  final String title;
  final String imagePath;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: onPressed,
        child: TextButton(
            onPressed: () {
              onPressed();
            },
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(icon, color: const Color(0xFF5C5C5C),),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: TextStyle(fontSize: 14, color: Color(0xFF5C5C5C)),
                  ),
                ],
              ),
            )));
  }
}
