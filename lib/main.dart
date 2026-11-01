import 'package:flutter/material.dart';
import 'package:nextfind/screens/homepage.dart';
import 'package:nextfind/widgets/main_widgets.dart';
import 'package:nextfind/helpers/networking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Next Find',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
      ),
      themeMode: ThemeMode.dark,
      home: const HomePage(),
    );
  }
}
