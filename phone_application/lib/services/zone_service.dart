import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ZoneService {
  static final ZoneService _instance = ZoneService._internal();
  factory ZoneService() => _instance;
  ZoneService._internal();

  final _zoneController = StreamController<Map<String, String>?>.broadcast();
  Stream<Map<String, String>?> get zoneStream => _zoneController.stream;

  final _imageController = StreamController<String?>.broadcast();
  Stream<String?> get imageStream => _imageController.stream;

  String? _currentUserId;
  String? _palmImagePath;
  String? _backHandImagePath;

  Future<void> initializeUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      await _loadSavedImages();
    }
  }

  void setActiveZone(String zone, String description) {
    final zoneInfo = {'zone': zone, 'description': description};
    _zoneController.add(zoneInfo);
  }

  String _getUserSpecificKey(String handType) {
    return 'captured_${handType}_image_${_currentUserId ?? 'anonymous'}';
  }

  Future<void> _loadSavedImages() async {
    if (_currentUserId == null) return;
    
    final prefs = await SharedPreferences.getInstance();

    final savedPalmPath = prefs.getString(_getUserSpecificKey('palm'));
    if (savedPalmPath != null && File(savedPalmPath).existsSync()) {
      _palmImagePath = savedPalmPath;
    } else {
      _palmImagePath = null;
    }

    final savedBackHandPath = prefs.getString(_getUserSpecificKey('back_hand'));
    if (savedBackHandPath != null && File(savedBackHandPath).existsSync()) {
      _backHandImagePath = savedBackHandPath;
    } else {
      _backHandImagePath = null;
    }
    _imageController.add(_palmImagePath);
  }

  Future<void> saveImagePath(String handType, String path) async {
    if (_currentUserId == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getUserSpecificKey(handType), path);

    if (handType == 'palm') {
      _palmImagePath = path;
    } else if (handType == 'back_hand') {
      _backHandImagePath = path;
    }

    _imageController.add(path);
  }

  Future<void> clearImagePath(String handType) async {
    if (_currentUserId == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getUserSpecificKey(handType));

    String? imagePath;
    if (handType == 'palm') {
      imagePath = _palmImagePath;
      _palmImagePath = null;
    } else if (handType == 'back_hand') {
      imagePath = _backHandImagePath;
      _backHandImagePath = null;
    }
    
    if (imagePath != null && File(imagePath).existsSync()) {
      try {
        await File(imagePath).delete();
      } catch (e) {
        debugPrint('Error deleting image file: $e');
      }
    }

    _imageController.add(null);
  }

  String? getImagePath(String handType) {
    if (handType == 'palm') {
      return _palmImagePath;
    } else if (handType == 'back_hand') {
      return _backHandImagePath;
    }
    return null;
  }

  bool hasImage(String handType) {
    return getImagePath(handType) != null;
  }

  String? get currentUserId => _currentUserId;

  void dispose() {
    _zoneController.close();
    _imageController.close();
  }
}