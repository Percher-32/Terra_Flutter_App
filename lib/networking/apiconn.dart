import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:nextfind/utils/tokenmanager.dart';
import 'package:nextfind/utils/businessManager.dart';
// import 'package:nextfind/utils/widgets.dart';
import 'package:logger/logger.dart';
final log = Logger();

class ServerConnect {
  // final serverUrl = 'http://192.168.1.106:8000';
  final serverUrl = 'http://10.0.1.140:8000';
  
  var userData;
  var timeUserDataCol;

  Future<dynamic> getNearbyBusinesses({
    required List location,
    String macroTypes = "All",
    type,
    int maxdist = 6000,
    String sort = "RAT",
    String query = "",
    bool gasSafeOnly = false,
    bool elecSafeOnly = false,
  }) async {



    final String url;

    if (type.length != null) {
      url =
          '$serverUrl/NearbyBusinesses?query=$query&maxdist=$maxdist&sort=$sort&gas_safe_only=$gasSafeOnly&electricity_safe_only=$elecSafeOnly&allow_base=$macroTypes&allow_type=$type';
    } else {
      url =
          '$serverUrl/NearbyBusinesses?query=$query&maxdist=$maxdist&sort=$sort&gas_safe_only=$gasSafeOnly&electricity_safe_only=$elecSafeOnly&allow_base=$macroTypes';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {"x-location": "${location[0]} , ${location[1]}"},
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      List<int> returnedBusinessesLocationIds = [];
      List<BusinessLoc> returnedBusinessesLocations = [];
      for (var businessData in data) {
        final newBusinessLocation = businessManager.addBusiness(businessData);

        returnedBusinessesLocationIds.add(businessData["id"]);
        returnedBusinessesLocations.add(newBusinessLocation);
      }
      return returnedBusinessesLocations;
    } else {
      return data;
    }
  }

  Future<bool> testPing() async {
    final response = await http.get(Uri.parse('$serverUrl/main'));


    return response.statusCode == 400;
  }

  Future<dynamic> getTrending() async {
    final response = await http.get(Uri.parse('$serverUrl/trending'));

    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);

      // List<int> returnedBusinessesLocationIds = [];
      // List<BusinessLoc> returnedBusinessesLocations = [];
      List<int> trendingBusinessIds = [];
      for (Map trendingData in data) {
        trendingBusinessIds.add(trendingData["location_id"]);
      }

      final returnedBusinessesLocations =
          await businessManager.getBusinessLocationData(trendingBusinessIds);

      return returnedBusinessesLocations;
    }
  }

  Future<dynamic> getBusinessData({required List id}) async {
    String urlquery = "";
    int counter = 0;
    for (var idval in id) {
      urlquery += "id=$idval";
      counter += 1;
      if (counter != id.length) {
        urlquery += "&";
      }
    }


    final response = await http.get(
      Uri.parse('$serverUrl/Business?$urlquery'),
    );

    final dynamic data = jsonDecode(response.body);
    return data;
  }

  Future<dynamic> getBusinessLocationData({required List id}) async {
    String urlquery = "";
    int counter = 0;
    for (var idval in id) {
      urlquery += "id=$idval";
      counter += 1;
      if (counter != id.length) {
        urlquery += "&";
      }
    }

    final response = await http.get(
      Uri.parse('$serverUrl/Business_Location?$urlquery'),
    );
    final dynamic data = jsonDecode(response.body);

    return data;
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

  Future<bool> LoggedIn() async {
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

  Future<dynamic> getLocationImageUrls(List<int> locations) async {
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
