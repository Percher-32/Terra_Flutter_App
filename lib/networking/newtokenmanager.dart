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

      log.i("LOGIN ||| SUCCESFUL -> $tokensData");
    } else {
      log.e("LOGIN ||| UNSUCCESFUL -> ${jsonDecode(response.body)}");
    }
  }

  Future<bool> renewTokens() async {
    final response = await http.post(
        Uri.parse('${serverconnect.serverUrl}/login?ref_token=$refToken'));

    if (response.statusCode == 200) {
      final Map tokensData = jsonDecode(response.body);

      accessToken = tokensData["access_token"];
      refToken = tokensData["refresh_token"];

      log.i("TOKEN RENEW ||| SUCCESFUL -> $tokensData");
      return true;
    } else {
      log.e("TOKEN RENEW ||| UNSUCCESFUL -> ${jsonDecode(response.body)}");
      return false;
    }
  }

  Future<dynamic> userGet(String query) async {
    final response =
        await http.get(Uri.parse('${serverconnect.serverUrl}$query'));

    if (response.statusCode == 401) {
      log.e("LOGIN ENDPOINT USER ||| UNSUCCESFUL -> TOKEN EXPIRY LIKELY");
      final renewWork = await renewTokens();

      if (renewWork) {
        return await userGet(query);
      } else {
        log.e(
            "LOGIN ENDPOINT USER ||| UNSUCCESFUL -> TOKEN RENEWAL FAILED -> UH OH");
      }
    } else {
      log.i(
          "LOGIN ENDPOINT USER ||| SUCCESFUL -> ${jsonDecode(response.body)}");
      return jsonDecode(response.body);
    }
  }

  Future<dynamic> userPost(String query) async {
    final response =
        await http.post(Uri.parse('${serverconnect.serverUrl}$query'));

    if (response.statusCode == 401) {
      log.e("LOGIN ENDPOINT USER ||| UNSUCCESFUL -> TOKEN EXPIRY LIKELY");
      final renewWork = await renewTokens();

      if (renewWork) {
        return await userPost(query);
      } else {
        log.e(
            "LOGIN ENDPOINT USER ||| UNSUCCESFUL -> TOKEN RENEWAL FAILED -> UH OH");
      }
    } else {
      log.i(
          "LOGIN ENDPOINT USER ||| SUCCESFUL -> ${jsonDecode(response.body)}");
      return jsonDecode(response.body);
    }
  }

}

final tokenMaster = TokenMaster();
