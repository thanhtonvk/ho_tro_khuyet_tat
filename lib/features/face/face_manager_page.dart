import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nguoi_khuyet_tat/providers/face_recognition/face_recognition_controller.dart';
import 'package:nguoi_khuyet_tat/utils/common.dart';
import 'package:nguoi_khuyet_tat/utils/dialog_helper.dart';
import 'package:nguoi_khuyet_tat/viewmodels/face_view_model.dart';
import 'package:nguoi_khuyet_tat/models/face_data.dart';

class FaceManagerPage extends ConsumerStatefulWidget {
  const FaceManagerPage({super.key});

  @override
  _FaceManagerPageState createState() => _FaceManagerPageState();
}

class _FaceManagerPageState extends ConsumerState<FaceManagerPage> {
  final TextEditingController _nameController = TextEditingController();
  Uint8List? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final FaceViewModel _faceViewModel = FaceViewModel();

  @override
  void initState() {
    super.initState();
    _loadFaces();
    _loadModel();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _selectedImage = bytes);
    }
  }

  Future<void> _captureImage() async {
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _selectedImage = bytes);
    }
  }

  Future<void> _loadModel() async {
    await ref.read(faceRecognitionController.notifier).initialize();
  }

  Future<void> _loadFaces() async {
    await _faceViewModel.loadFaces();
    setState(() {});
  }

  Future<void> _addFace() async {
    if (_nameController.text.isNotEmpty && _selectedImage != null) {
      String imagePath = await Common.saveImageToLocal(
          _selectedImage!, "face_${DateTime.now().millisecondsSinceEpoch}");
      await ref
          .read(faceRecognitionController.notifier)
          .getEmbeddingFromPath(XFile(imagePath))
          .then((value) {
        if (value.isNotEmpty) {
          _faceViewModel.addFace(
            _nameController.text,
            imagePath,
            value,
          );
          _nameController.clear();

          setState(() {
            _faceViewModel.loadFaces();
            _selectedImage = null;
          });
        } else {
          DialogHelper.showIOSDialog(
              context, "Thông báo", "Không nhận diện được khuôn mặt");
        }
      }).catchError((error) {
        DialogHelper.showIOSDialog(
            context, "Thông báo", "Không nhận diện được khuôn mặt");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thêm người thân"),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(),
            const SizedBox(height: 10),
            _buildImagePreview(),
            const SizedBox(height: 20),
            _buildButtons(),
            const SizedBox(height: 20),
            _buildFaceList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: "Họ tên",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return _selectedImage != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              _selectedImage!,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
          )
        : const Icon(Icons.face, size: 100, color: Colors.grey);
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: _captureImage,
          child: const Text("Chụp ảnh"),
        ),
        ElevatedButton(
          onPressed: _pickImage,
          child: const Text("Mở thư viện"),
        ),
        ElevatedButton(
          onPressed: _addFace,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text("Thêm"),
        ),
      ],
    );
  }

  Widget _buildFaceList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _faceViewModel.faces.length,
        itemBuilder: (context, index) {
          FaceData face = _faceViewModel.faces[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 3,
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.file(
                  File(face.cameraImage),
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(face.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  await _faceViewModel.removeFace(face.id!);
                  setState(() {});
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
