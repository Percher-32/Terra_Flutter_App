import 'package:flutter/material.dart';
import 'package:nextfind/screens/homepage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionTimeout =
        const Duration(seconds: 20); // increase wait time
    return client;
  }
}

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
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.light,
      home: const HomePage(),
    );
  }
}
