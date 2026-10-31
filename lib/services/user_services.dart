import 'package:nextfind/services/auth_services.dart';

class UserService {
  static List<double> userLocation = [51.5074 + 0.006, -0.1278];

  static bool isLoggedIn = false;
  static String? username;
  static String? email;
  static String? userId;
  static int? xp;
  static List<String>? cachedFavoriteLocations;

  static void setAllUserDataToNull() {
    username = null;
    email = null;
    userId = null;
    xp = null;

    isLoggedIn = false;
  }

  static Future<void> setUserData({bool forceReload = false}) async {
    /// gets the users data if it wasnt already loaded
    if (username == null || forceReload) {
      final userData = await AuthServices.userGet("user/data");

      username = userData["username"];
      email = userData["email"];
      userId = userData["user_id"];
      xp = userData["xp"];

      isLoggedIn = true;
    }
  }

  static Future<List<String>?> getFavoriteLocations() async {
    if (isLoggedIn) {
      cachedFavoriteLocations ??=
          List<String>.from((await AuthServices.userGet("user/favorite/view")));

      return cachedFavoriteLocations;
    } else {
      return null;
    }
  }
}
