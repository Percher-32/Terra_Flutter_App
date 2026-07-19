import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:nextfind/networking/apiconn.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const FlutterSecureStorage secureStorage = FlutterSecureStorage();

class TokenMaster {
  String? accessToken;
  String? refToken;

  TokenMaster() {
    _loadStoredRefreshToken();
  }

  Future<void> _loadStoredRefreshToken() async {
    refToken = await secureStorage.read(key: 'refresh_token');
    log.i("TOKEN : GETTING REF TOKEN , REF = $refToken");
  }

  Future<bool> userLogin(
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
      await saveRefreshToken();

      log.i("LOGIN ||| SUCCESFUL -> $tokensData");
      return true;
    } else {
      log.e("LOGIN ||| UNSUCCESFUL -> ${jsonDecode(response.body)}");
      return false;
    }
  }

  Future<bool> user


  Future<(bool, dynamic)> renewTokens() async {
    refToken ??= await secureStorage.read(key: 'refresh_token');

    if (refToken != null) {
      final response = await http.post(
        Uri.parse('${serverconnect.serverUrl}/refresh'),
        body: jsonEncode({
          'refresh_token': refToken,
        }),
      );

      if (response.statusCode == 200) {
        final Map tokensData = jsonDecode(response.body);

        accessToken = tokensData["access_token"];
        refToken = tokensData["refresh_token"];
        await saveRefreshToken();

        log.i("TOKEN RENEW ||| SUCCESFUL -> $tokensData");
        return (true, tokensData);
      } else {
        log.e("TOKEN RENEW ||| UNSUCCESFUL -> ${jsonDecode(response.body)}");

        // ! [MAY HAVE TO REMOVE]
        refToken = null;
        await saveRefreshToken();
        // ! [//////////////////]

        return (false, jsonDecode(response.body));
      }
    } else {
      log.e("TOKEN RENEW ||| UNSUCCESFUL -> No Ref Token Found");
      return (false, "no refresh token found");
    }
  }

  Future<dynamic> userGet(String query) async {
    final response = await http.get(
      Uri.parse('${serverconnect.serverUrl}/$query'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 401) {
      log.e("LOGIN ENDPOINT USER ||| UNSUCCESFUL -> TOKEN EXPIRY LIKELY");
      final renewResp = await renewTokens();
      final renewWork = renewResp.$1;

      if (renewWork) {
        return await userGet(query);
      } else {
        log.e(
            "LOGIN ENDPOINT USER ||| UNSUCCESFUL -> TOKEN RENEWAL FAILED -> ${renewResp.$2}");
      }
    } else {
      log.i(
          "LOGIN ENDPOINT USER ||| SUCCESFUL -> ${jsonDecode(response.body)}");
      return jsonDecode(response.body);
    }
  }

  Future<dynamic> userPost(String query) async {
    final response = await http.post(
      Uri.parse('${serverconnect.serverUrl}$query'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 401) {
      log.e("LOGIN ENDPOINT USER ||| UNSUCCESFUL -> TOKEN EXPIRY LIKELY");
      final renewResp = await renewTokens();
      final renewWork = renewResp.$1;

      if (renewWork) {
        return await userPost(query);
      } else {
        log.e(
            "LOGIN ENDPOINT USER ||| UNSUCCESFUL -> TOKEN RENEWAL FAILED -> ${renewResp.$2}");
      }
    } else {
      log.i(
          "LOGIN ENDPOINT USER ||| SUCCESFUL -> ${jsonDecode(response.body)}");
      return jsonDecode(response.body);
    }
  }

  Future<void> saveRefreshToken() async {
    if (refToken != null) {
      await secureStorage.write(
        key: 'refresh_token',
        value: refToken,
      );
    } else {
      await secureStorage.delete(key: 'refresh_token');
    }
  }
}

final tokenMaster = TokenMaster();
