import 'package:flutter/material.dart';
import 'package:nextfind/networking/apiconn.dart';
import 'package:nextfind/networking/newtokenmanager.dart';
import 'package:nextfind/pages/signuppage.dart';
import 'package:nextfind/widgets/newwidgets.dart';
import 'package:logger/logger.dart';

final ulog = Logger();

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  Widget userPage(Map userData) {
    return Column(children: [
      MyText(userData["email"]),
      MyButton(
        width: 300,
        height: 60,
        child: const MyText("Logout", color: Colors.white),
        onPressed: () async {
          final loggedOut = await tokenMaster.userLogout();

          if (!mounted) {
            return;
          }
          if (loggedOut) {
            ulog.i("LOGOUT || SUCCESS FROM UI SIDE");
            goToHomePage(context);
          } else {
            ulog.e("LOGOUT || ERROR FROM UI SIDE");
            showErrorMessage(context, "Error In Logout");
          }
        },
      )
    ]);
  }

  Widget myBody() {
    if (tokenMaster.refToken != null) {
      return Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, color: Colors.black, size: 100),
            FutureBuilder<dynamic>(
              future: serverconnect.getUserData(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return userPage(snapshot.data!);
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
          ],
        ),
      );
    } else {
      return const LoginOrSignupPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: newbottombar(context, index: 4), body: myBody());
  }
}
