import 'package:flutter/material.dart';
import 'package:nextfind/models/business_models.dart';
import 'package:nextfind/screens/homepage.dart';
import 'package:nextfind/screens/initial_searching_widget.dart';
import 'package:nextfind/screens/map_view_widget.dart';
import 'package:nextfind/screens/searchpage.dart';
import 'package:nextfind/screens/userpage.dart';
import 'package:nextfind/screens/businesspage.dart';
import 'package:nextfind/services/search_services.dart';
import 'package:nextfind/widgets/main_widgets.dart';
import 'package:nextfind/helpers/networking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nextfind/page_moves.dart';

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Next Find',

      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Montserrat',
        iconTheme: const IconThemeData(
          color: AppColors.text, // Changes back arrow color globally
        ),
        tooltipTheme: TooltipThemeData(
          showDuration: const Duration(seconds: 3),
          decoration: BoxDecoration(
            color: AppColors.text, // Background color of the tooltip bubble
            borderRadius: BorderRadius.circular(8.0), // Rounded corners
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: "Montserrat",
            color: AppColors.background, // Text color inside the tooltip
            fontSize: 15.0, // Font size
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          preferBelow: false, // Decides whether it shows above or below the bar
        ),
      ),
      themeMode: ThemeMode.dark,
      // home: const HomePage(),
      routerConfig: router,
    );
  }
}
