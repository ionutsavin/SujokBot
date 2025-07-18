import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

class HandScannerPage extends StatefulWidget {
  final String imagePath;
  const HandScannerPage({super.key, required this.imagePath});

  @override
  State<HandScannerPage> createState() => _HandZoneScannerPageState();
}

class _HandZoneScannerPageState extends State<HandScannerPage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription>? cameras;
  bool _isCapturing = false;
  String? _capturedImagePath;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras!.isNotEmpty) {
        _controller = CameraController(
          cameras!.first,
          ResolutionPreset.high,
        );
        _initializeControllerFuture = _controller!.initialize();
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      await _initializeControllerFuture;
      final XFile image = await _controller!.takePicture();
      final directory = await getApplicationDocumentsDirectory();
      final tempImagePath = path.join(
        directory.path,
        'hand_scan_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await image.saveTo(tempImagePath);
      await _saveToAssetsFolder(image);

      setState(() {
        _capturedImagePath = tempImagePath;
        _isCapturing = false;
      });
    } catch (e) {
      setState(() {
        _isCapturing = false;
      });
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveToAssetsFolder(XFile image) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final assetsDir = Directory(path.join(appDir.parent.path, 'assets', 'images'));
      if (!await assetsDir.exists()) {
        await assetsDir.create(recursive: true);
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final assetImagePath = path.join(assetsDir.path, 'captured_hand_$timestamp.jpg');
      await image.saveTo(assetImagePath);
      debugPrint('Image saved to: $assetImagePath');
    } catch (e) {
      debugPrint('Error saving to assets folder: $e');
    }
  }

  Future<List<String>> getSavedHandScans() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final assetsDir = Directory(path.join(appDir.parent.path, 'assets', 'images'));
      
      if (await assetsDir.exists()) {
        final files = assetsDir.listSync()
            .where((file) => file.path.contains('captured_hand_') && file.path.endsWith('.jpg'))
            .map((file) => file.path)
            .toList();
        
        return files;
      }
      return [];
    } catch (e) {
      debugPrint('Error getting saved hand scans: $e');
      return [];
    }
  }

  Future<void> _retakePhoto() async {
    if (_capturedImagePath != null) {
      try {
        await File(_capturedImagePath!).delete();
      } catch (e) {
        debugPrint('Error deleting previous image: $e');
      }
    }

    setState(() {
      _capturedImagePath = null;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Your Hand'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _capturedImagePath != null
                ? _buildCapturedImageView()
                : _buildCameraView(),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: _capturedImagePath != null
                ? _buildCapturedImageActions()
                : _buildCameraActions(),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (_controller == null || _initializeControllerFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Stack(
            children: [
              Positioned.fill(
                child: CameraPreview(_controller!),
              ),
              Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final overlayWidth = constraints.maxWidth * 0.9;
                    final overlayHeight = constraints.maxHeight * 0.8;
                    return SizedBox(
                      width: overlayWidth,
                      height: overlayHeight,
                      child: Image.asset(
                        widget.imagePath,
                        fit: BoxFit.contain,
                        color: Colors.white,
                        colorBlendMode: BlendMode.modulate,
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Place your hand so it fits inside the outline',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildCapturedImageView() {
    return Positioned.fill(
      child: Image.file(
        File(_capturedImagePath!),
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildCameraActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _isCapturing ? null : _captureImage,
          icon: _isCapturing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.camera_alt),
          label: Text(_isCapturing ? 'Capturing...' : 'Capture'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildCapturedImageActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: _retakePhoto,
          icon: const Icon(Icons.refresh),
          label: const Text('Retake'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context, _capturedImagePath);
          },
          icon: const Icon(Icons.check),
          label: const Text('Use This Scan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}