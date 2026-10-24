import 'dart:io';
import 'dart:convert';
import 'package:nextfind/helpers/logger.dart';
import 'package:flutter/services.dart' show rootBundle;



class Loadfiles {
  static Map fileCache = {};

  static Future<dynamic> loadJsonFile(String path) async {
    if (fileCache.containsKey(path)) {
      log.i("FILE CACHE HIT");
      return fileCache[path];
    } else {
      // try {
      // final file = File(path);
      log.i("FILE CACHE Miss");
      String jsonString = await rootBundle.loadString(path);

      var jsonData = jsonDecode(jsonString);

      fileCache[path] = jsonData;

      return jsonData;
      // }
      // catch (e) {
      //   log.e("Error loading file $path || $e");
      // }
    }
  }
}
