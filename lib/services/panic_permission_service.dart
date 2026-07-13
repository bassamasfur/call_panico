import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PanicPermissionService {
  bool get _requiresAndroidPermissions =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> requestEssentialPermissions() async {
    if (!_requiresAndroidPermissions) {
      return true;
    }

    final microphoneStatus = await Permission.microphone.request();
    final smsStatus = await Permission.sms.request();
    return microphoneStatus.isGranted && smsStatus.isGranted;
  }

  Future<bool> requestMicrophonePermission() async {
    if (!_requiresAndroidPermissions) {
      return true;
    }

    final microphoneStatus = await Permission.microphone.request();
    return microphoneStatus.isGranted;
  }
}
