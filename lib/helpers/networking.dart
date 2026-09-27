import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionTimeout =
        const Duration(seconds: 20); // increase wait time
    return client;
  }
}

abstract class Networking {
  static final log = Logger();

  static const serverUrl = 'http://192.168.1.107:8000';

  static Future<http.Response> apiGet(
    String endpoint, {
    Map<String, dynamic> params = const {},
  }) async {
    // 1. Clean endpoint leading slash
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;

    // 2. Parse base URI to safely extract authority and port
    final baseUri = Uri.parse(serverUrl);

    // 3. Convert query parameter values to strings or string lists
    final formattedParams = params.map((key, value) {
      if (value is List) {
        return MapEntry(key, value.map((e) => e.toString()).toList());
      }
      return MapEntry(key, value?.toString() ?? '');
    });

    // 4. Construct valid Uri
    final uri = Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.port,
      path: '/$cleanEndpoint',
      queryParameters: formattedParams.isEmpty ? null : formattedParams,
    );

    return await http.get(uri);
  }
  
  static Future<http.Response> apiPost(
    String endpoint, {
    Map<String, dynamic> params = const {},
  }) async {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final url = Uri.parse('$serverUrl/$cleanEndpoint');

    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(params),
    );
  }

  static Future<bool> testPing() async {
    final response = await apiGet("main");
    return response.statusCode == 200;
  }

  static Future<bool> hasNetwork() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  static Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isOnline() async {
    if (!await hasNetwork()) return false;
    return await hasInternet();
  }

  static String getFullImageUrl(String url) {
    final retStr = '$serverUrl/image/$url';

    return retStr;
  }
}
