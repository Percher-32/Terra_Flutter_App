import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:nextfind/networking/apiconn.dart';

class TokenMaster {
  String? accessToken;
  String? refToken;

  Future<void> userLogin(
      {required String email,
      required String password,
      String device = "None"}) async {
    final response = await http.post(
      Uri.parse('${serverconnect.serverUrl}/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": email,
        "password": password,
        "device": device,
      }),
    );

    if (response.statusCode == 200) {
      final Map tokensData = jsonDecode(response.body);

      accessToken = tokensData["access_token"];
      refToken = tokensData["refresh_token"];
      
    } else {
      log.e(jsonDecode(response.body));
    }
  }
}

final tokenMaster = TokenMaster();
