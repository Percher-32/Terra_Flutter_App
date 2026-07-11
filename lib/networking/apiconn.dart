import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:nextfind/utils/tokenmanager.dart';
import 'package:nextfind/utils/businessManager.dart';
import 'package:nextfind/utils/arbitStore.dart';
import 'package:logger/logger.dart';

final log = Logger();

class ServerConnect {
  // final serverUrl = 'http://192.168.1.106:8000';
  // final serverUrl = 'http://10.0.1.140:8000';
  // final serverUrl = 'http://10.0.1.129:8000';
  final serverUrl = 'http://10.0.1.121:8000';

  var userData;
  var timeUserDataCol;

  Future<bool> testPing() async {
    final response = await http.get(Uri.parse('$serverUrl/main'));

    return response.statusCode == 400;
  }

  Future<dynamic> getNearbyBusinesses({
    required List location,
    String macroTypes = "All",
    type,
    int maxdist = 6000,
    String sort = "RAT",
    String query = "",
    bool idOnly = false,
    bool gasSafeOnly = false,
    bool elecSafeOnly = false,
  }) async {
    String url;

    log.i("FUNCTION : getNearbyBusinesses | START");

    if (type != null) {
      url =
          '$serverUrl/nearbybusinesses?query=$query&maxdist=$maxdist&sort=$sort&gas_safe_only=$gasSafeOnly&electricity_safe_only=$elecSafeOnly&just_id=$idOnly&allow_base=$macroTypes&allow_type=$type';
    } else {
      url =
          '$serverUrl/nearbybusinesses?query=$query&maxdist=$maxdist&sort=$sort&gas_safe_only=$gasSafeOnly&electricity_safe_only=$elecSafeOnly&just_id=$idOnly&allow_base=$macroTypes';
    }

    log.d("FUNCTION : getNearbyBusinesses | URL = $url");

    url += "&location=${location[0]} , ${location[1]}";

    final response = await http.get(
      Uri.parse(url),
      // headers: {"location": "${location[0]} , ${location[1]}"},
    );

    log.d("FUNCTION : getNearbyBusinesses | DATA COLLECTION COMPLETE");

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (!idOnly) {
        List<int> returnedBusinessesLocationIds = [];
        List<MiniBusinessLoc> returnedBusinessesLocations = [];

        for (var businessData in data) {
          final newBusinessLocation =
              businessManager.addBusinessLocationMini(businessData);

          if (newBusinessLocation == null) {
            log.e(
                "FUNCTION : getNearbyBusinesses | Error creating business location class from data $newBusinessLocation");
          } else {
            returnedBusinessesLocationIds.add(businessData["id"]);
            returnedBusinessesLocations.add(newBusinessLocation);
          }
        }

        log.d(
            "FUNCTION : getNearbyBusinesses | RESULT (FULL_DATA) = $returnedBusinessesLocations");
        return returnedBusinessesLocations;
      } else {
        log.d("FUNCTION : getNearbyBusinesses | RESULT (ONlY_ID) = $data");
        return data;
      }
    } else {
      log.e("FUNCTION : getNearbyBusinesses | Error Occured $data");
      return null;
    }
  }

  Future<dynamic> getFullLocationData(String locationId) async {
    final response = await http
        .get(Uri.parse('$serverUrl/business_location?location_id=$locationId'));

    final dataFromResp = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final businessLocation =
          businessManager.addBusinessLocation(dataFromResp);

      final galleryResponse = await http.get(Uri.parse(
          '$serverUrl/location_image_paths?location_ids=$locationId'));

      final gallerydataFromResp = jsonDecode(galleryResponse.body);

      if (response.statusCode == 200) {
        businessManager.businessLocationLookup[locationId]!.imagePaths =
            gallerydataFromResp[locationId]!;
      } else {
        log.e(
            "FUNCTION : getNearbyBusinesses | GETTING PATHS | Error Occured |$gallerydataFromResp");
        return null;
      }

      return businessLocation;
    } else {
      log.e(
          "FUNCTION : getNearbyBusinesses | GETTING DATA | Error Occured $dataFromResp");
      return null;
    }
  }

  Future<dynamic> getTrendingBusinessIds(
      {int limit = 30, int offset = 0}) async {
    log.i("FUNCTION : GET TRENDING BUSINESSES | START");

    final response = await http.post(
      Uri.parse('$serverUrl/homepage/trending?limit=$limit&offset=$offset&location=${arbitStore.data["userLocation"][0]} , ${arbitStore.data["userLocation"][1]}'),
    );

    log.d(
        "FUNCTION : GET TRENDING BUSINESSES | Gotten Trending Data | RESPONSE : $response");

    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);
      List<String> trendingBusinessIds = [];
      for (Map bData in data) {
        trendingBusinessIds.add(bData["location_id"]);
      }

      log.d(
          "FUNCTION : GET TRENDING BUSINESSES | Trending Business Ids = $trendingBusinessIds");

      return trendingBusinessIds;
    } else {
      log.e(
          "FUNCTION : GET TRENDING BUSINESSES | Error ${jsonDecode(response.body)}");
    }
  }

  Future<dynamic> getBusinessLocationDataMiniApi(
      {required List<String> locationIds}) async {
    log.i(
        "FUNCTION GET BUSINESSES MINI LOCATION API || START || INPUTS $locationIds ");

    String urlquery = "";
    int counter = 0;
    for (var idval in locationIds) {
      urlquery += "location_ids=$idval";
      counter += 1;
      if (counter != locationIds.length) {
        urlquery += "&";
      }
    }

    log.d(
        "FUNCTION GET BUSINESSES MINI LOCATION API | Urlquery = $urlquery || INPUTS $locationIds ");

    final response = await http.get(
      Uri.parse(
          '$serverUrl/mini_collect/business_location?$urlquery&location=${arbitStore.data["userLocation"]}'),
    );

    final dynamic data = jsonDecode(response.body);

    log.d(
        "FUNCTION GET BUSINESSES MINI LOCATION API | respData : $data || INPUTS $locationIds ");

    if (response.statusCode == 200) {
      Map<String, MiniBusinessLoc> retrunedBusinessLocations = {};
      for (Map businessMiniData in data) {
        final newBusinessLoc =
            businessManager.addBusinessLocationMini(businessMiniData);

        if (newBusinessLoc == null) {
          log.e(
              "FUNCTION GET BUSINESSES MINI LOCATION API || Error creating business location class from data $newBusinessLoc || INPUTS $locationIds");
        } else {
          retrunedBusinessLocations[newBusinessLoc.locationId] = newBusinessLoc;
        }
      }

      log.i(
          "FUNCTION GET BUSINESSES MINI LOCATION API || SUCCESS IN PARSING ALL BUSINESSES || INPUTS $locationIds ");
      return retrunedBusinessLocations;
    } else {
      log.e(
          "FUNCTION GET BUSINESSES MINI LOCATION API || statusCode : ${response.statusCode} || respData : $data || INPUTS $locationIds ");
      return null;
    }
  }

  Future<dynamic> signupUser({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(
        '$serverUrl/login_page?email=$email&user_type=User&full_name=Dinkle',
      ),
      headers: {"password": password, "Content-Type": "application/json"},
    );
    final dynamic data = jsonDecode(response.body);
    return data;
  }

  Future<dynamic> loginUser({
    required String email,
    required String password,
    required String device,
  }) async {
    final response = await http.post(
      Uri.parse('$serverUrl/token_json'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": email,
        "password": password,
        "device": device,
      }),
    );
    final Map data = jsonDecode(response.body);

    if (data.keys.toList().contains("access_token")) {
      final String token = data["access_token"];
      final String reftoken = data["refresh_token"];

      tokenmanager.saveToken(token);
      tokenmanager.saveRefreshToken(reftoken);

      return true;
    } else {
      return false;
    }
  }

  Future<dynamic> getNewToken() async {
    final String? reftoken = await tokenmanager.getRefreshToken();

    if (reftoken != null) {
      final response = await http.post(
        Uri.parse('$serverUrl/refresh'),
        headers: {"ref-token": reftoken, "Content-Type": "application/json"},
      );
      final Map data = jsonDecode(response.body);

      if (response.statusCode == 401) {
        return data;
      } else {
        final String newtoken = data["access_token"];
        final String newreftoken = data["refresh_token"];

        tokenmanager.saveToken(newtoken);
        tokenmanager.saveRefreshToken(newreftoken);
      }
    } else {
      return "No Ref Token";
    }
  }

  Future<dynamic> performLogginTask({
    required String endpoint,
    String type = "POST",
    Map<String, dynamic> params = const {},
    Map<String, String> headers = const {},
    bool donebf = false,
  }) async {
    // FIX: build URL safely
    final uri = Uri.parse(
      "$serverUrl$endpoint",
    ).replace(queryParameters: params);
    // final entireurl = uri.toString();

    final token = await tokenmanager.getToken();

    if (token == null) return "No Token";

    // FIX: mutable headers
    final mutableHeaders = Map<String, String>.from(headers);
    mutableHeaders["Authorization"] = "Bearer $token";

    http.Response response;

    if (type == "POST") {
      response = await http.post(uri, headers: mutableHeaders);
    } else if (type == "GET") {
      response = await http.get(uri, headers: mutableHeaders);
    } else if (type == "DEL") {
      response = await http.delete(uri, headers: mutableHeaders);
    } else {
      response = await http.post(uri, headers: mutableHeaders);
    }

    final respdata = jsonDecode(response.body);

    if (response.statusCode == 401) {
      if (!donebf) {
        await getNewToken();
        return await performLogginTask(
          endpoint: endpoint,
          type: type,
          params: params,
          headers: headers,
          donebf: true,
        );
      } else {
        return "Got Tokens But It still didnt work";
      }
    }

    return respdata;
  }

  Future<bool> loggedIn() async {
    final String? tok = await tokenmanager.getToken();
    return tok != null;
  }

  Future<dynamic> getUserData() async {
    if (userData != null) {
      return userData;
    } else {
      userData = await performLogginTask(endpoint: "/me/data", type: "GET");
      return userData;
    }
  }

  Future<dynamic> getLocationImageUrls(List<String> locations,
      {bool firstOnly = false}) async {
    String urlquery = "";
    int counter = 0;
    for (var idval in locations) {
      urlquery += "location_ids=$idval";
      counter += 1;
      if (counter != locations.length) {
        urlquery += "&";
      }
    }

    final String endpoint = '$serverUrl/location_image_paths?$urlquery';
    final response = await http.get(
      Uri.parse(endpoint),
    );

    final dynamic data = jsonDecode(response.body);

    return data;
  }

  String fullUrl(String url) {
    final retStr = '$serverUrl/image/$url';

    return retStr;
  }
}

final serverconnect = ServerConnect();

Future<void> main() async {
  serverconnect.signupUser(email: "MAMBA", password: "JAMBO");
}
