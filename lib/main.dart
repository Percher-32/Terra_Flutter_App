import 'package:flutter/material.dart';
import 'package:nextfind/networking/apiconn.dart';
// import 'package:nextfind/pages/searchpage.dart';
import 'dart:io';

import 'pages/homepage.dart';
import 'package:nextfind/utils/arbitStore.dart';

void main() {
  arbitfallbacks();
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
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
      home: const MyHomePage(title: 'Next Find'),
      // home: const SearchPage(),
    );
  }
}






//[] ([he] [is] [the]) ([for][ty][forth]) ([pre][sid][dent]) ([of] [the]) ([U][NIT][ED] [STATES])
// ([ev][ery][bo][dy]) ([give][it][up][for]) ([the][one][and][only]) ([BARACK][HUSIEN])
// OBAMA ,