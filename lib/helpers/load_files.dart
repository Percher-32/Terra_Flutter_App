import 'dart:io';
import 'dart:convert';
import 'package:nextfind/helpers/logger.dart';
import 'package:flutter/services.dart' show rootBundle;


class Loadfiles {
  static Future<dynamic> loadJsonFile(String path) async{
    try {
      final file = File(path);

      String jsonString = await rootBundle.loadString(path);

      var jsonData = jsonDecode(jsonString);

      return jsonData;
    } catch (e) {
      log.e("Error loading file $path || $e");
    }
  }
}
