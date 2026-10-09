import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import "package:nextfind/utils/arbitStore.dart";
import 'package:nextfind/helpers/logger.dart';
import 'dart:io' show Platform;

class DeviceServices {
  static Future<List> getDeviceLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      log.e('Location services are disabled.');
      return Future.error('Location services are disabled.');
    }

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        log.e('Location permission denied.');
        return Future.error('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      log.e('Location permission permanently denied.');
      return Future.error('Location permission permanently denied.');
    }

    // Get the actual location
    final data = await Geolocator.getCurrentPosition();

    final List userLocation = [data.latitude, data.longitude];

    arbitStore.data["userLocation"] = userLocation;
    return userLocation;
  }

  static Future<String> getDeviceDetails() async {
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
}
