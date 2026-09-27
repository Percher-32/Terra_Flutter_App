import 'package:flutter/material.dart';
import 'package:nextfind/networking/newtokenmanager.dart';
import 'package:nextfind/widgets/newwidgets.dart';
// import 'package:nextfind/widgets/widgets.dart';
import 'package:nextfind/networking/apiconn.dart';
import 'package:nextfind/utils/devicemanager.dart';

class UserManager {
  static List<String>? cachedFavoriteLocations;

  static Future<void> signup(
      BuildContext context, String email, String password) async {
    final dynamic signupResponse = await serverconnect.signupUser(
      email: email,
      password: password,
    );

    final jsondata = signupResponse.$1;
    final statusCode = signupResponse.$2;

    final devicename = await getDeviceDetails();
    log.i("DVNAME -> $devicename");

    if (!context.mounted) return;
    if (statusCode != 200) {
      log.e("SIGNUP || ERROR -> $jsondata ||  $statusCode");
      showErrorMessage(context, jsondata["detail"]);
      return;
    }

    log.i("SIGNUP || MAIN -> $jsondata");
    await login(context, email, password);

    if (!context.mounted) return;
    goToHomePage(context);
  }

  static Future<void> login(
      BuildContext context, String email, String password) async {

    showDialog(
      context: context,
      builder: (context) {
        return const Dialog(
          backgroundColor: AppColors.background,
          constraints: BoxConstraints(
              minHeight: 100, minWidth: 200, maxHeight: 300),
          child: Center(
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Stack(
                    children: [
                      SizedBox(
                          // width: 200,
                          child: MyText(
                              textAlign: TextAlign.center,
                              "Performing Login",
                              size: 25)),
                      CircularProgressIndicator()
                    ]
                  ))),
        );
      });

    final loginSuccess =
        await tokenMaster.userLogin(email: email, password: password);


      if (!context.mounted) return;
    Navigator.of(context).pop();

    if (loginSuccess.$1) {
      final devicename = await getDeviceDetails();
      log.i("devicename : $devicename");
      log.i("LOGIN SUCCESS");
      if (!context.mounted) return;
      goToUserPage(context);
    } else {
      log.e("LOGIN FAILED");

      if (!context.mounted) return;
      showErrorMessage(context, loginSuccess.$2["detail"]);
    }
  }

  static bool isLoggedIn() {
    return tokenMaster.refToken != null;
  }

  static Future<List<String>?> getFavoriteLocations() async {
    if (isLoggedIn()) {
      cachedFavoriteLocations ??=
          List<String>.from((await tokenMaster.userGet("user/favorite/view")));

      return cachedFavoriteLocations;
    } else {
      return null;
    }
  }
}
