import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nextfind/screens/login_or_signup_page.dart';
import 'package:nextfind/services/auth_services.dart';
import 'package:nextfind/services/user_services.dart';
import 'package:nextfind/widgets/main_widgets.dart';
import 'package:nextfind/helpers/logger.dart';
import 'package:nextfind/page_moves.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  @override
  Widget build(BuildContext context) {
    return UserService.isLoggedIn
        ? Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person, color: Colors.black, size: 100),
                FutureBuilder<dynamic>(
                  future: UserService.setUserData(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return const UserWidget();
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                ),
              ],
            ),
          )
        : const LoginOrSignupPage();
  }
}

class UserWidget extends StatelessWidget {
  const UserWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      MyText(UserService.email!),
      MyButton(
        width: 300,
        height: 60,
        child: const MyText("Logout", color: Colors.white),
        onPressed: () async {
          final loggedOut = await AuthServices.userLogout();

          if (!context.mounted) {
            return;
          }
          if (loggedOut) {
            context.go("/home");
          } else {
            log.e("LOGOUT || ERROR FROM UI SIDE");
            showErrorMessage(context, "Error In Logout");
          }
        },
      )
    ]);
  }
}
