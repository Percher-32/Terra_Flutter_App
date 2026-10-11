import 'package:nextfind/services/auth_services.dart';

class UserService {
  static List<double> userLocation = [53.7444, -0.3324];

  static bool isLoggedIn = false;
  static String? username;
  static String? email;
  static String? userId;
  static int? xp;

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
}
