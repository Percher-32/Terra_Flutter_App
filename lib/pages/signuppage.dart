import 'package:flutter/material.dart';
import 'package:nextfind/networking/newtokenmanager.dart';
import 'package:nextfind/widgets/newwidgets.dart';
// import 'package:nextfind/widgets/widgets.dart';
import 'package:nextfind/networking/apiconn.dart';
import 'package:nextfind/utils/devicemanager.dart';

import 'package:logger/logger.dart';

final log = Logger();

class LoginOrSignupPage extends StatelessWidget {
  const LoginOrSignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      spacing: 20,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const MyText("Next find"),
        const SizedBox(
          height: 30,
        ),
        SizedBox(
          width: 300,
          height: 80,
          child: ElevatedButton(
            onPressed: () async {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const LoginPage()));
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: AppColors.primary,
            ),
            child: const MyText("Login", size: 20),
          ),
        ),
        const MyText(
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
                      builder: (context) => const UserSignupPage(title: "Hi")));
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: AppColors.primary,
            ),
            child: const MyText("Sign Up", size: 20),
          ),
        ),
      ],
    ));
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

  Future<void> signup() async {
    final dynamic jsondata = await serverconnect.signupUser(
      email: emailcontroller.text,
      password: passwordcontroller.text,
    );

    final devicename = await getDeviceDetails();
    log.i("DVNAME -> $devicename");

    final String message = jsondata["message"];

    if (message == 'User already exists') {
      log.e("SIGNUP ERROR -> USER EXISTS");
      return;
    } else if (message == 'Successful') {
      await tokenMaster.userLogin(
        email: emailcontroller.text,
        password: passwordcontroller.text,
        device: "flutter",
      );
      if (!mounted) return;
      goToHomePage(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: newbottombar(context),
      body: Center(
        child: Column(
          spacing: 20,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Heading("SignUp Next find"),

            // MainText("Next Find", AppColors.main),
            MyInputField(
              hint: "email",
              controller: emailcontroller,
            ),
            MyInputField(
              hint: "password",
              controller: passwordcontroller,
            ),

            // ← Button now inside build()
            SizedBox(
              width: 300,
              height: 60,
              child: ElevatedButton(
                onPressed: () async {
                  await signup();
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: AppColors.primary,
                ),
                child: const MyText(
                  "Sign Up",
                  size: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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

  Future<void> login(BuildContext context) async {
    debugPrint(emailcontroller.text);
    debugPrint(passwordcontroller.text);
    final dynamic loginSuccess = await tokenMaster.userLogin(
        email: emailcontroller.text,
        password: passwordcontroller.text,
        device: await getDeviceDetails());

    if (loginSuccess) {
      final devicename = await getDeviceDetails();
      log.i("devicename : $devicename");

      log.i("LOGIN SUCCESS");
      if (mounted) {
        goToHomePage(context);
      }
    } else {
      log.e("LOGIN FAILED");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: newbottombar(context),
      body: Center(
        child: Column(
          spacing: 20,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Heading("Login"),

            // MainText("Next Find", AppColors.main),
            MyInputField(
              hint: "Email",
              controller: emailcontroller,
            ),
            MyInputField(
              hint: "Password",
              controller: passwordcontroller,
            ),

            // ← Button now inside build()
            SizedBox(
              width: 300,
              height: 60,
              child: ElevatedButton(
                onPressed: () async {
                  await login(context);
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: AppColors.primary,
                ),
                child: const MyText(
                  "Sign In",
                  size: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
