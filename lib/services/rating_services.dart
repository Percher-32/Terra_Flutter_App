import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:nextfind/helpers/networking.dart';
import 'package:nextfind/helpers/logger.dart';
import 'package:nextfind/helpers/debug_options.dart';
import 'package:nextfind/helpers/load_files.dart';
import 'package:nextfind/services/tag_services.dart';
import 'package:nextfind/services/business_services.dart';
import 'package:nextfind/models/business_models.dart';
import 'package:nextfind/models/rating_models.dart';

class RatingServices {
  static Map<int, Rating> cachedRatings = {};

  static Future<Rating> getRatingFromId(int id) async {
    if (cachedRatings.containsKey(id)) {
      return cachedRatings[id]!;
    } else {
      final rating = await getRatingRequest([id]);

      cachedRatings[rating.id] = rating;

      return rating;
    }
  }

  //* Api calling functions
  static Future<Rating> getRatingRequest(List<int> ids) async {
    final response = await Networking.apiGet("ENPODINT UNIMPLEMETED");

    if (response.statusCode != 200) {
      log.e("Error getting rating ids $ids , ${response.body}");
    }

    final data = jsonDecode(response.body);

    return Rating.fromJson(data);
  }
}
