import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import '../theme/app_theme.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    if (cameras.isNotEmpty) {
      _initCamera(_selectedCameraIndex);
    }
  }

  Future<void> _initCamera(int index) async {
    _controller = CameraController(
      cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print("Error inicializando cámara: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final XFile image = await _controller!.takePicture();
      Get.back(result: image);
    } catch (e) {
      print("Error capturando foto: $e");
    }
  }

  Future<void> _pickFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      Get.back(result: image);
    }
  }

  void _toggleCamera() {
    if (cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % cameras.length;
    _initCamera(_selectedCameraIndex);
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Previsualización de la cámara (ajustada para que parezca Instagram)
          Center(
            child: CameraPreview(_controller!),
          ),

          // Barra superior
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Get.back(),
            ),
          ),

          // Controles inferiores
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botón Cambiar Cámara (izquierda)
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
                  onPressed: _toggleCamera,
                ),

                // Botón Disparar (centro)
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 5),
                    ),
                    child: Center(
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),

                // Botón Galería (derecha - la "bola")
                GestureDetector(
                  onTap: _pickFromGallery,
                  child: Container(
                    height: 45,
                    width: 45,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.photo_library, color: Colors.white, size: 25),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
