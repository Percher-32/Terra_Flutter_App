import 'package:nextfind/networking/apiconn.dart';
import 'package:nextfind/models/business_models.dart';
import 'package:nextfind/helpers/networking.dart';
import 'dart:convert';

class BusinessService {
  Map<String, MiniBusinessLoc> miniBusinessLocLookup = {};
  Map<String, BusinessLocation> businessLocationLookup = {};


  MiniBusinessLoc? addBusinessLocationMini(Map<String, dynamic> locationData) {
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

  BusinessLocation? addBusinessLocation(
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


  Future<BusinessLocation> getBusinessLocation(String locationId) async {
    if (businessLocationLookup.containsKey(locationId)) {
      return businessLocationLookup[locationId]!;
    } else {
      return await serverconnect.getFullLocationData(locationId);
    }
  }

  Future<Map<String, MiniBusinessLoc>> getBusinessLocationMini(
      List<String> locationIds) async {
    Map<String, MiniBusinessLoc> retLookup = {};
    List<String> locationsToGet = [];

    log.i("GET MINI BUSINESS LOCATION || ABSTRACTED || START");
    log.d("GET MINI BUSINESS LOCATION || ABSTRACTED || INPUTS $locationIds");

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

    log.d(
        "GET MINI BUSINESS LOCATION || ABSTRACTED || EXTRACTED ALL KNOWN BUSINESS DATA || currentRetLookup $retLookup || INPUTS $locationIds");

    if (locationsToGet.isNotEmpty) {
      log.d(
          "GET MINI BUSINESS LOCATION || ABSTRACTED || EXTRACTING ALL UNKNOWN BUSINESSES DATA || locToGet $locationsToGet || INPUTS $locationIds");
      final newLocationData = await serverconnect
          .getBusinessLocationDataMiniApi(locationIds: locationsToGet);

      log.d(
          "GET MINI BUSINESS LOCATION || ABSTRACTED || EXTRACTING ALL UNKNOWN BUSINESSES DATA || newLocationData : $newLocationData || locToGet $locationsToGet || INPUTS $locationIds");

      retLookup = {...retLookup, ...newLocationData};
    }

    log.d(
        "GET MINI BUSINESS LOCATION || ABSTRACTED || LOOKUP + $retLookup || INPUTS $locationIds");

    log.i(
        "GET MINI BUSINESS LOCATION || ABSTRACTED || ENDED RETURNED : $retLookup || INPUTS $locationIds");

    return retLookup;
  }





  //* Api calling functions
  Future<dynamic> getNearbyBusinesses({
    required List location,
    String macroTypes = "All",
    int? type,
    int maxdist = 6000,
    String sort = "RAT",
    String query = "",
    bool idOnly = false,
    bool gasSafeOnly = false,
    bool elecSafeOnly = false,
    bool includeScore = false,
  }) async {
    if (type == -1) {
      type = null;
    }

    if (!(await Networking.isOnline())) {
      return null;
    }

    //! NEEDS TO IMPLEMENT
    List TAGS = [];

    Map<String, dynamic> params = {
      "query": query,
      "maxdist": maxdist,
      "sort": sort,
      "gas_safe_only": gasSafeOnly,
      "electricity_safe_only": elecSafeOnly,
      "just_id": idOnly,
      "allow_base": macroTypes,
      "tags": TAGS,
      "location": "${location[0]} , ${location[1]}"
    };

    if (type != null) {
      params["allow_type"] = type;
    }

    final response =
        await Networking.apiGet("nearby_businesses", params: params);

    if (response.statusCode != 200) {
      log.e("FUNCTION : getNearbyBusinesses | Error Occured ${response.body}");
      return null;
    }

    final data = jsonDecode(response.body);
    if (!idOnly) {
      List<int> returnedMiniBusinessesLocationIds = [];
      List<MiniBusinessLoc> returnedMiniBusinessesLocations = [];

      for (Map<String, dynamic> businessData in data) {
        final newBusinessLocation = addBusinessLocationMini(businessData);

        if (newBusinessLocation == null) {
          log.e(
              "FUNCTION : getNearbyBusinesses | Error creating business location class from data $newBusinessLocation");
        } else {
          returnedMiniBusinessesLocationIds.add(businessData["id"]);
          returnedMiniBusinessesLocations.add(newBusinessLocation);
        }
      }

      return returnedMiniBusinessesLocations;
    } else {
      if (!includeScore) {
        //Remove the score
        List<String> newData = [];
        for (List datachunk in data) {
          newData.add(datachunk[0]);
        }

        return newData;
      }

      return data;
    }
  }

  Future<BusinessLocation?> getFullLocationData(String locationId) async {
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

  Future<List<String>?> getTrendingBusinessIds(
      {int limit = 30, int offset = 0}) async {
    final response = await Networking.apiGet("homepage/trending",
        params: {"limit": limit, "offset": offset});

    if (response.statusCode != 200) {
      log.e(
          "FUNCTION : GET TRENDING BUSINESSES | Error ${jsonDecode(response.body)}");
      return null;
    }

    final dynamic data = jsonDecode(response.body);
    List<String> trendingBusinessIds = [];
    for (Map bData in data) {
      trendingBusinessIds.add(bData["location_id"]);
    }

    return trendingBusinessIds;
  }

  Future<dynamic> getBusinessLocationDataMiniApi(
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

var businessService = BusinessService();
