import 'package:flutter/material.dart';
import 'package:nextfind/services/navbar_services.dart';
import 'package:nextfind/services/auth_services.dart';
import 'package:nextfind/widgets/main_widgets.dart';
import 'package:nextfind/page_moves.dart';
import 'package:nextfind/helpers/logger.dart';

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
        const MyText("Next find", size: 40),
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
          child: const MyText("Sign Up", size: 20, color: AppColors.background),
          onPressed: () async {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const UserSignupPage()));
          },
        )
      ],
    ));
  }
}

class UserSignupPage extends StatefulWidget {
  const UserSignupPage({super.key});

  @override
  State<UserSignupPage> createState() => _UserSignupPageState();
}

class _UserSignupPageState extends State<UserSignupPage> {
  final emailcontroller = TextEditingController();
  final passwordcontroller = TextEditingController();

  Future<void> onSignupButtonPressed() async {
    /// also performs login
    await AuthServices.userSignup(
      email: emailcontroller.text,
      password: passwordcontroller.text,
    );

    await AuthServices.userLogin(
      email: emailcontroller.text,
      password: passwordcontroller.text,
    );
    if (!mounted) return;
    goToUserPage(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const NavBar(currentPage: AppPages.userpage),
      body: Center(
        child: Column(
          spacing: 20,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Heading("SignUp Next find"),
            MyInputField(
              hint: "email",
              controller: emailcontroller,
            ),
            MyInputField(
              hint: "password",
              controller: passwordcontroller,
            ),
            MyButton(
                width: 300,
                height: 60,
                child: const MyText(
                  "Sign Up",
                  size: 20,
                  color: Colors.white,
                ),
                onPressed: () async {
                  await onSignupButtonPressed();
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

  Future<void> onLoginButtonPressed() async {
    await AuthServices.userLogin(
      email: emailcontroller.text,
      password: passwordcontroller.text,
    );

    if (!mounted) return;

    goToUserPage(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const NavBar(currentPage: AppPages.userpage),
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
                  await onLoginButtonPressed();
                }),
          ],
        ),
      ),
    );
  }
}
