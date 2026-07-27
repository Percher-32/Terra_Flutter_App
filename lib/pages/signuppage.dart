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
        MyButton(
          width: 300,
          height: 60,
          child: const MyText(
            "Login",
            size: 20,
            color: Colors.white,
          ),
          onPressed: () async {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const LoginPage()));
          },
        ),
        const MyText(
          "Or",
          color: AppColors.text,
          size: 20,
        ),
        MyButton(
          width: 300,
          height: 60,
          child: const MyText("Sign Up", size: 20),
          onPressed: () async {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const UserSignupPage(title: "Hi")));
          },
        )
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

    if (message == 'Successful') {
      log.i("SIGNUP || SUCCESSFUL");
      await tokenMaster.userLogin(
          email: emailcontroller.text, password: passwordcontroller.text);
      if (!mounted) return;
      goToHomePage(context);
    } else {
      log.e("SIGNUP || ERROR -> $message");
      if (message == 'User already exists') {
        showDialog(
          context: context,
          builder: (context) => MyText(message),
        );
      }
      return;
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
            MyButton(
                width: 300,
                height: 60,
                child: const MyText(
                  "Sign Up",
                  size: 20,
                  color: Colors.white,
                ),
                onPressed: () async {
                  await signup();
                }),
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
    final loginSuccess = await tokenMaster.userLogin(
        email: emailcontroller.text, password: passwordcontroller.text);

    if (loginSuccess.$1) {
      final devicename = await getDeviceDetails();
      log.i("devicename : $devicename");

      log.i("LOGIN SUCCESS");
      if (mounted) {
        goToHomePage(context);
      }
    } else {
      log.e("LOGIN FAILED");
      showDialog(
        context: context,
        builder: (context) => MyText(loginSuccess.$2.toString()),
      );
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

            MyButton(
                width: 300,
                height: 60,
                child: const MyText(
                  "Login",
                  size: 20,
                  color: Colors.white,
                ),
                onPressed: () async {
                  await login(context);
                }),
          ],
        ),
      ),
    );
  }
}
