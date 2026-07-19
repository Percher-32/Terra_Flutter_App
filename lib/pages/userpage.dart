import 'package:flutter/material.dart';
import 'package:nextfind/networking/apiconn.dart';
import 'package:nextfind/networking/newtokenmanager.dart';
import 'package:nextfind/pages/signuppage.dart';
import 'package:nextfind/widgets/newwidgets.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
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
                  return MyText(snapshot.data!["email"]);
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
        bottomNavigationBar: newbottombar(context),
        body: myBody());
  }
}
