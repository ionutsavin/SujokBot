import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:phone_application/services/zone_service.dart';
import 'package:phone_application/pages/hand_scanner_page.dart';

mixin CameraFunctionality<T extends StatefulWidget> on State<T> {
  String? _capturedImagePath;
  StreamSubscription<String?>? _imageSubscription;
  late ZoneService _zoneService;
  bool _isInitialized = false;

  String get handType;
  String get defaultAssetPath;
  String get scannerAssetPath;

  @override
  void initState() {
    super.initState();
    _zoneService = ZoneService();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _zoneService.initializeUser();
    
    _capturedImagePath = _zoneService.getImagePath(handType);
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
    
    _imageSubscription = _zoneService.imageStream.listen((imagePath) {
      if (mounted) {
        setState(() {
          _capturedImagePath = imagePath;
        });
      }
    });
  }

  Future<void> handleCapturedImage(String? imagePath) async {
    if (imagePath != null && _zoneService.currentUserId != null) {
      await _zoneService.saveImagePath(handType, imagePath);
    }
  }

  Future<void> clearCapturedImage() async {
    if (_zoneService.currentUserId != null) {
      await _zoneService.clearImagePath(handType);
    }
  }

  Widget buildCameraControls({
    VoidCallback? onRetake,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              if (_capturedImagePath != null) ...[
                ElevatedButton.icon(
                  onPressed: clearCapturedImage,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              ElevatedButton.icon(
                onPressed: _zoneService.currentUserId != null ? () async {
                  final result = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HandScannerPage(imagePath: scannerAssetPath),
                    ),
                  );
                  await handleCapturedImage(result);
                  onRetake?.call();
                } : null,
                icon: const Icon(Icons.camera_alt),
                label: Text(_capturedImagePath != null ? 'Retake' : 'Scan Your Hand'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildImageView({
    required List<Widget> overlayWidgets,
    double width = 300,
    double height = 350,
  }) {
    if (!_isInitialized) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          border: Border.all(
            color: Colors.black,
            width: 5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return GestureDetector(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.black,
                width: 5,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: _capturedImagePath != null
                ? Image.file(
                    File(_capturedImagePath!),
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        defaultAssetPath,
                        width: width - 50,
                        height: height - 50,
                        fit: BoxFit.contain,
                      );
                    },
                  )
                : Image.asset(
                    defaultAssetPath,
                    width: width - 50,
                    height: height - 50,
                    fit: BoxFit.contain,
                  ),
          ),
          ...overlayWidgets,
        ],
      ),
    );
  }

  @override
  void dispose() {
    _imageSubscription?.cancel();
    super.dispose();
  }
}