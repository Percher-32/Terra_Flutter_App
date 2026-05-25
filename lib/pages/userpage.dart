import 'package:flutter/material.dart';
import 'package:nextfind/networking/apiconn.dart';
import 'package:nextfind/widgets/widgets.dart';
// import 'package:nextfind/theme/app_theme.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key, required this.title});
  final String title;

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: searchbar(context),
      bottomNavigationBar: bottombar(context),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, color: Colors.black, size: 100),
            FutureBuilder<dynamic>(
              future: serverconnect.getUserData(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return MainText(snapshot.data!["email"], Colors.black);
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
