import 'dart:io';
import 'dart:convert';
import 'package:nextfind/helpers/logger.dart';

class Loadfiles {
  static dynamic loadJsonFile(String path) {
    try {
      final file = File(path);

      String jsonString = file.readAsStringSync();

      var jsonData = jsonDecode(jsonString);

      return jsonData;
    } catch (e) {
      log.e("Error loading file $path || $e");
    }
  }
}
