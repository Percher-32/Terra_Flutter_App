import 'dart:convert';
import 'package:nextfind/helpers/networking.dart';
import 'package:nextfind/helpers/logger.dart';
import 'package:nextfind/services/user_services.dart';
import 'package:nextfind/services/device_services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:nextfind/utils/devicemanager.dart';

const FlutterSecureStorage secureStorage = FlutterSecureStorage();

class AuthServices {
  static String? accessToken;
  static String? refreshToken;

  AuthServices() {
    _loadStoredRefreshToken();
  }

  static Future<void> _loadStoredRefreshToken() async {
    refreshToken = await secureStorage.read(key: 'refresh_token');
  }

  static Future<(bool, dynamic)> userSignup(
      {required String email, required String password}) async {
    ///doesnt perform login
    final response = await Networking.apiPost("auth/new_user", params: {
      "username": email,
      "password": password,
    });

    if (response.statusCode != 200) {
      log.e("LOGIN ||| UNSUCCESFUL -> ${jsonDecode(response.body)}");
      return (false, jsonDecode(response.body));
    }

    return (true, "success");
  }

  static Future<(bool, dynamic)> userLogin(
      {required String email, required String password}) async {
    ///Also updates user data
    final response = await Networking.apiPost("auth/login", params: {
      "username": email,
      "password": password,
      "device": await DeviceServices.getDeviceDetails(),
    });

    if (response.statusCode != 200) {
      log.e("LOGIN ||| UNSUCCESFUL -> ${jsonDecode(response.body)}");
      return (false, jsonDecode(response.body));
    }
    final Map tokensData = jsonDecode(response.body);

    accessToken = tokensData["access_token"];
    refreshToken = tokensData["refresh_token"];
    await saveRefreshToken();

    return (true, "success");
  }

  static Future<bool> userLogout() async {
    final response = await userPost("auth/logout", params: {
      "device": await DeviceServices.getDeviceDetails(),
    });

    if (response.statusCode != 200) {
      log.e("LOGOUT : Error Logging Out ${jsonDecode(response.body)}");
      return false;
    }
    refreshToken = null;
    accessToken = null;
    UserService.setAllUserDataToNull();
    saveRefreshToken();

    return true;
  }

  static Future<(bool, dynamic)> renewTokens() async {
    refreshToken ??= await secureStorage.read(key: 'refresh_token');

    if (refreshToken != null) {
      final response = await userPost(
        "auth/refresh",
        params: {
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final Map tokensData = jsonDecode(response.body);

        accessToken = tokensData["access_token"];
        refreshToken = tokensData["refresh_token"];
        await saveRefreshToken();

        return (true, tokensData);
      } else {
        log.e("TOKEN RENEW ||| UNSUCCESFUL -> ${jsonDecode(response.body)}");

        // ! [MAY HAVE TO REMOVE]
        refreshToken = null;
        await saveRefreshToken();
        // ! [//////////////////]

        return (false, jsonDecode(response.body));
      }
    } else {
      log.e("TOKEN RENEW ||| UNSUCCESFUL -> No Ref Token Found");
      return (false, "no refresh token found");
    }
  }

  static Future<dynamic> userGet(String endpoint,
      {Map<String, dynamic> params = const {}}) async {
    final response =
        await Networking.apiGet(endpoint, params: params, headers: {
      'Authorization': 'Bearer $accessToken',
    });

    if (response.statusCode == 401) {
      log.e("User Get ||| UNSUCCESFUL -> TOKEN EXPIRY LIKELY");
      final renewResp = await renewTokens();
      final renewWork = renewResp.$1;

      if (renewWork) {
        return await userGet(endpoint, params: params);
      } else {
        log.e(
            "User Get ||| UNSUCCESFUL -> TOKEN RENEWAL FAILED -> ${renewResp.$2}");
      }
    }
    return jsonDecode(response.body);
  }

  static Future<dynamic> userPost(String endpoint,
      {Map<String, dynamic> params = const {}}) async {
    final response = await Networking.apiPost(
      endpoint,
      params: params,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 401) {
      log.e("User Post ||| UNSUCCESFUL -> TOKEN EXPIRY LIKELY");
      final renewResp = await renewTokens();
      final renewWork = renewResp.$1;

      if (renewWork) {
        return await userPost(endpoint, params: params);
      } else {
        log.e(
            "User Post||| UNSUCCESFUL -> TOKEN RENEWAL FAILED -> ${renewResp.$2}");
      }
    } else {
      return jsonDecode(response.body);
    }
  }

  static Future<void> saveRefreshToken() async {
    if (refreshToken != null) {
      await secureStorage.write(
        key: 'refresh_token',
        value: refreshToken,
      );
    } else {
      await secureStorage.delete(key: 'refresh_token');
    }
  }
}
