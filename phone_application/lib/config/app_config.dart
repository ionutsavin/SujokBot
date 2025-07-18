import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AppConfig{
  static Future<bool> isAndroidPhysicalDevice() async {
    final deviceInfoPlugin = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
      return androidInfo.isPhysicalDevice;
    }
    return false;
  }
  
  static Future<String> get baseUrl async {
    if(kIsWeb){
      return 'http://localhost:8000';
    } else{
      bool isPhysicalDevice = await isAndroidPhysicalDevice();
      return isPhysicalDevice
          ? 'https://deciding-gladly-dog.ngrok-free.app'
          : 'http://10.0.2.2:8000';
    }
  }
}