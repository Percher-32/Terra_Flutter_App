import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

Future<String> getDeviceDetails() async {
  final deviceInfo = DeviceInfoPlugin();

  if (kIsWeb) {
    final info = await deviceInfo.webBrowserInfo;
    return info.browserName.toString();
  } 
  
  
  if (Platform.isAndroid) {
    final info = await deviceInfo.androidInfo;
    return info.model;
  } else if (Platform.isIOS) {
    final info = await deviceInfo.iosInfo;
    return info.utsname.machine;
  } else if (Platform.isWindows) {
    final info = await deviceInfo.windowsInfo;
    return info.computerName;
  } else {
    return "Flutter";
  }
}
