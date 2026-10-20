import 'package:nextfind/models/business_models.dart';
import 'package:nextfind/helpers/networking.dart';
import 'package:nextfind/helpers/logger.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:nextfind/helpers/debug_options.dart';
import 'package:nextfind/helpers/load_files.dart';
import 'package:nextfind/services/tag_services.dart';

const businessTypeLookup = {
  null: "All",
  0: "Food",
  1: "Home",
  2: "Health",
  3: "Shops",
  4: "Specialists",
  5: "Auto",
  6: "Beauty",
  7: "Fun",
  8: "Education",
  9: "Travel",
};

const businessIconLookup = {
  null: "assets/icons/svg_logo.png",
  0: "assets/icons/business_type_icons/food_and_dining_icon.png",
  1: "assets/icons/business_type_icons/home_services_icon.png",
  2: "assets/icons/business_type_icons/health_and_wellness_icon.png",
  3: "assets/icons/business_type_icons/shopping_and_retail_icon.png",
  4: "assets/icons/business_type_icons/proffesional_services_icon.png",
  5: "assets/icons/business_type_icons/automotive_icon.png",
  6: "assets/icons/business_type_icons/beauty_and_personal_care_icon.png",
  7: "assets/icons/business_type_icons/entertainment_and_leisure_icon.png",
  8: "assets/icons/business_type_icons/education_icon.png",
  9: "assets/icons/business_type_icons/lodging_and_travel_icon.png",
};

const businessIconLookupAlt = {
  null: "assets/icons/svg_logo.png",
  0: "assets/icons/business_type_icons/food_and_dining_icon_alt.png",
  1: "assets/icons/business_type_icons/home_services_icon_alt.png",
  2: "assets/icons/business_type_icons/health_and_wellness_icon_alt.png",
  3: "assets/icons/business_type_icons/shopping_and_retail_icon_alt.png",
  4: "assets/icons/business_type_icons/proffesional_services_icon_alt.png",
  5: "assets/icons/business_type_icons/automotive_icon_alt.png",
  6: "assets/icons/business_type_icons/beauty_and_personal_care_icon_alt.png",
  7: "assets/icons/business_type_icons/entertainment_and_leisure_icon_alt.png",
  8: "assets/icons/business_type_icons/education_icon_alt.png",
  9: "assets/icons/business_type_icons/lodging_and_travel_icon_alt.png",
};

class BusinessService {
  static Map<String, MiniBusinessLoc> miniBusinessLocLookup = {};
  static Map<String, BusinessLocation> businessLocationLookup = {};

  static List<MiniBusinessLoc>? trendingBusinesses;
  static DateTime trendingBusinessesLastUpdate =
      DateTime.fromMicrosecondsSinceEpoch(0);

  //* Mini/Full Location Functions
  static MiniBusinessLoc? addBusinessLocationMini(
      Map<String, dynamic> locationData) {
    try {
      final newMiniBusiness = MiniBusinessLoc.fromJson(locationData);

      miniBusinessLocLookup[locationData["business_location_id"]] =
          newMiniBusiness;

      return newMiniBusiness;
    } catch (e) {
      log.e(
          "Error {$e} adding minibusinesslocation || The location Data is $locationData ");
      return null;
    }
  }

  static BusinessLocation? addBusinessLocation(
      Map<String, dynamic> businessLocationData) {
    try {
      final newBusiness = BusinessLocation.fromJson(businessLocationData);

      businessLocationLookup[businessLocationData["id"]] = newBusiness;

      return newBusiness;
    } catch (e) {
      log.e(
          "Error {$e} adding businesslocation || The location Data is $businessLocationData ");
      return null;
    }
  }

  static Future<BusinessLocation> getBusinessLocation(String locationId) async {
    if (businessLocationLookup.containsKey(locationId)) {
      return businessLocationLookup[locationId]!;
    } else {
      return (await getFullLocationData(locationId))!;
    }
  }

  static Future<Map<String, MiniBusinessLoc>> getBusinessLocationMini(
      List<String> locationIds) async {
    Map<String, MiniBusinessLoc> retLookup = {};
    List<String> locationsToGet = [];

    for (var locationId in locationIds) {
      // log.d(
      // "GET MINI BUSINESS LOCATION || ABSTRACTED || LOCATION ID $locationId");

      log.t(miniBusinessLocLookup.values);
      if (miniBusinessLocLookup.containsKey(locationId)) {
        retLookup[locationId] = miniBusinessLocLookup[locationId]!;
      } else {
        locationsToGet.add(locationId);
      }
    }

    if (locationsToGet.isNotEmpty) {
      final newLocationData =
          await getBusinessLocationDataMiniApiCall(locationIds: locationsToGet);

      retLookup = {...retLookup, ...newLocationData};
    }

    return retLookup;
  }

  //*Trending Businesses Functions
  static Future<List<MiniBusinessLoc>?> _getTrendingBusinessesApiCall(
      {int limit = 30, int offset = 0}) async {
    List data;

    if (NextfindDebugOptions.useTestTrendingData) {
      data = await Loadfiles.loadJsonFile(
          "assets/testdata/trending_businesses_data.json");
    } else {
      final response = await Networking.apiGet("homepage/trending",
          params: {"limit": limit, "offset": offset});

      if (response.statusCode != 200) {
        log.e(
            "FUNCTION : GET TRENDING BUSINESSES | Error ${jsonDecode(response.body)}");
        return null;
      }

      data = jsonDecode(response.body);
    }

    List<MiniBusinessLoc> returnedTrendingBusinesses = [];
    for (Map trendingBusinessData in data) {
      final trendingBusinessId = trendingBusinessData["location_id"];
      final trendingBusinessLocation = (await getBusinessLocationMini(
          [trendingBusinessId]))[trendingBusinessId]!;
      returnedTrendingBusinesses.add(trendingBusinessLocation);
    }

    return returnedTrendingBusinesses;
  }

  static Future<List<MiniBusinessLoc>?> getTrendingBusinesses() async {
    if (trendingBusinesses == null ||
        (DateTime.now().difference(trendingBusinessesLastUpdate).inMinutes >
            5)) {
      trendingBusinesses = await _getTrendingBusinessesApiCall();
    }
    return trendingBusinesses;
  }

  //* Business Image Functions
  static void startPreloadingLocationThumbnail(
    List<MiniBusinessLoc> locations,
    BuildContext context,
  ) {
    _runPreloadLocationThumbnailTask(locations, context);
  }

  static Future<void> _runPreloadLocationThumbnailTask(
      List<MiniBusinessLoc> locations, BuildContext context) async {
    for (final MiniBusinessLoc location in locations) {
      Future.microtask(() async {
        if (!context.mounted) return;
        final String? locationThumbnailPath = location.thumbnailPath;

        if (locationThumbnailPath != null) {
          await precacheImage(
              NetworkImage(Networking.getFullImageUrl(locationThumbnailPath)),
              context);
        }
      });

      await Future.delayed(const Duration(milliseconds: 30)); // throttle
    }
  }

  //* Api calling Functions
  static Future<List<MiniBusinessLoc>?> getNearbyBusinesses({
    required List location,
    String macroTypes = "All",
    int? type,
    int maxdist = 6000,
    String sort = "RAT",
    String query = "",
    bool gasSafeOnly = false,
    bool elecSafeOnly = false,
    bool includeScore = false,
  }) async {
    // log.i("Getting Nearby Businesses");
    dynamic data;
    if (NextfindDebugOptions.useBusinessDataTestData) {
      data = await Loadfiles.loadJsonFile(
          "assets/testdata/nearby_business_data.json");
    } else {
      if (type == -1) {
        type = null;
      }

      if (!(await Networking.isOnline())) {
        return null;
      }

      Map<String, dynamic> params = {
        "query": query,
        "maxdist": maxdist,
        "sort": sort,
        "gas_safe_only": gasSafeOnly,
        "electricity_safe_only": elecSafeOnly,
        "allow_base": macroTypes,
        "tags": TagServices.chosenTags,
        "location": "${location[0]} , ${location[1]}"
      };

      if (type != null) {
        params["allow_type"] = type;
      }

      final response =
          await Networking.apiGet("nearby_businesses", params: params);

      if (response.statusCode != 200) {
        log.e(
            "FUNCTION : getNearbyBusinesses | Error Occured ${response.body}");
        return null;
      }

      data = jsonDecode(response.body);
    }

    List<MiniBusinessLoc> returnedMiniBusinessesLocations = [];

    for (Map<String, dynamic> businessData in data) {
      final newBusinessLocation = addBusinessLocationMini(businessData);

      if (newBusinessLocation == null) {
        log.e(
            "FUNCTION : getNearbyBusinesses | Error creating business location class from data $newBusinessLocation");
      } else {
        returnedMiniBusinessesLocations.add(newBusinessLocation);
      }
    }

    return returnedMiniBusinessesLocations;
  }

  static Future<BusinessLocation?> getFullLocationData(
      String locationId) async {
    final response = await Networking.apiGet("business_location",
        params: {"location_id": locationId});

    final businessLocationResponseData = jsonDecode(response.body);

    if (response.statusCode != 200) {
      log.e(
          "FUNCTION : getFullLocationData | GETTING DATA | Error Occured $businessLocationResponseData");
      return null;
    }

    final businessLocation = addBusinessLocation(businessLocationResponseData);

    final galleryResponse = await Networking.apiGet("location_image_paths",
        params: {"location_id": locationId});

    final Map gallerydataFromResp = jsonDecode(galleryResponse.body);

    if (galleryResponse.statusCode != 200) {
      log.e(
          "FUNCTION : getFullLocationData | GETTING PATHS | Error Occured |$gallerydataFromResp");
    }

    // adding business image apth
    if (gallerydataFromResp.containsKey(locationId)) {
      businessLocationLookup[locationId]!.imagePaths =
          List<String>.from(gallerydataFromResp[locationId]);
    }

    return businessLocation;
  }

  static Future<dynamic> getBusinessLocationDataMiniApiCall(
      {required List<String> locationIds}) async {
    final response = await Networking.apiGet("mini_collect/business_location",
        params: {"location_ids": locationIds});

    final dynamic data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      log.e(
          "FUNCTION GET BUSINESSES MINI LOCATION API || statusCode : ${response.statusCode} || respData : $data || INPUTS $locationIds ");
      return null;
    }
    Map<String, MiniBusinessLoc> retrunedBusinessLocations = {};
    for (Map<String, dynamic> businessMiniData in data) {
      final newBusinessLoc = addBusinessLocationMini(businessMiniData);

      if (newBusinessLoc == null) {
        log.e(
            "FUNCTION GET BUSINESSES MINI LOCATION API || Error creating business location class from data $newBusinessLoc || INPUTS $locationIds");
      } else {
        retrunedBusinessLocations[newBusinessLoc.locationId] = newBusinessLoc;
      }
    }

    return retrunedBusinessLocations;
  }
}
