import 'package:flutter/material.dart';
import 'package:nextfind/widgets/newwidgets.dart';
import 'package:nextfind/widgets/widgets.dart';
import 'package:nextfind/networking/apiconn.dart';
import 'package:nextfind/pages/homepage.dart';
import 'package:nextfind/utils/devicemanager.dart';

import 'package:logger/logger.dart';

final log = Logger();

class LoginOrSignupPage extends StatelessWidget {
  const LoginOrSignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: bottombar(context),
      body: Center(
        child: Column(
          spacing: 20,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MainText("Next find", AppColors.text),
            const SizedBox(
              height: 30,
            ),
            SizedBox(
              width: 300,
              height: 80,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()));
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: AppColors.primary,
                ),
                child: const HText("Login", size: 20),
              ),
            ),
            const HText(
              "Or",
              color: AppColors.text,
              size: 20,
            ),
            SizedBox(
              width: 300,
              height: 80,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const UserSignupPage(title: "Hi")));
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: AppColors.primary,
                ),
                child: const HText("Sign Up", size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserSignupPage extends StatefulWidget {
  const UserSignupPage({super.key, required this.title});
  final String title;

  @override
  State<UserSignupPage> createState() => _UserSignupPageState();
}

class _UserSignupPageState extends State<UserSignupPage> {
  final emailcontroller = TextEditingController();
  final passwordcontroller = TextEditingController();

  Future<void> SignupButton() async {
    debugPrint(emailcontroller.text);
    debugPrint(passwordcontroller.text);
    final dynamic jsondata = await serverconnect.signupUser(
      email: emailcontroller.text,
      password: passwordcontroller.text,
    );

    final devicename = await getDeviceDetails();
    print(devicename);

    bool userexists = true;
    try {
      final String message = jsondata["message"];

      if (message ==
          'duplicate key value violates unique constraint "[Beta]User_pkey"') {
        userexists = false;
      }
    } finally {
      if (userexists) {
        await serverconnect.loginUser(
          email: emailcontroller.text,
          password: passwordcontroller.text,
          device: "flutter",
        );
        changepage(context, () => MyHomePage(title: "Hi"));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: bottombar(context),
      body: Center(
        child: Column(
          spacing: 20,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MainText("SignUp Next find", AppColors.text),

            // MainText("Next Find", AppColors.main),
            MainInputBg(
              before: "Email",
              hint: "",
              color: Colors.black,
              controller: emailcontroller,
              bgcolor: AppColors.primary,
            ),
            MainInputBg(
              before: "Password",
              hint: "",
              controller: passwordcontroller,
              color: Colors.black,
              bgcolor: AppColors.primary,
            ),

            // ← Button now inside build()
            SizedBox(
              width: 300,
              height: 60,
              child: ElevatedButton(
                onPressed: () async {
                  await SignupButton();
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 18, horizontal: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: AppColors.primary,
                ),
                child: Text(
                  "Sign Up",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailcontroller = TextEditingController();
  final passwordcontroller = TextEditingController();

  Future<void> loginButton(BuildContext context) async {
    debugPrint(emailcontroller.text);
    debugPrint(passwordcontroller.text);
    final dynamic userexists = await serverconnect.loginUser(
        email: emailcontroller.text,
        password: passwordcontroller.text,
        device: await getDeviceDetails());

    if (userexists) {
      final devicename = await getDeviceDetails();
      log.i("devicename : $devicename");

      changepage(context, () => const MyHomePage(title: "Hi"));
    } else {
      log.e("USER DOESNT EXIST");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: bottombar(context),
      body: Center(
        child: Column(
          spacing: 20,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MainText("Login", AppColors.text),

            // MainText("Next Find", AppColors.main),
            MainInputBg(
              before: "Email",
              hint: "",
              color: Colors.black,
              controller: emailcontroller,
              bgcolor: AppColors.primary,
            ),
            MainInputBg(
              before: "Password",
              hint: "",
              controller: passwordcontroller,
              color: Colors.black,
              bgcolor: AppColors.primary,
            ),

            // ← Button now inside build()
            SizedBox(
              width: 300,
              height: 60,
              child: ElevatedButton(
                onPressed: () async {
                  await loginButton(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 18, horizontal: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  "Sign In",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
