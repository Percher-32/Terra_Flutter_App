import 'package:flutter/material.dart';
import 'package:nextfind/models/business_models.dart';
import 'package:nextfind/screens/homepage.dart';
import 'package:nextfind/screens/searchpage.dart';
import 'package:nextfind/screens/userpage.dart';
import 'package:nextfind/screens/businesspage.dart';
import 'package:nextfind/services/search_services.dart';
import 'package:nextfind/widgets/main_widgets.dart';
import 'package:nextfind/helpers/networking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';

// Global route observer to track page visibility
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

final GoRouter _router = GoRouter(initialLocation: "/home", observers: [
  routeObserver
], routes: [
  StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        // return ScaffoldWithNavBar(navigationShell: navigationShell);
        return Scaffold(
            body: navigationShell,
            bottomNavigationBar: NavigationBar(
                indicatorShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      12.0), // Adjust corner roundness here
                ),
                backgroundColor: AppColors.background,
                height: 50.0,
                indicatorColor: AppColors.background,
                overlayColor: WidgetStateProperty.resolveWith((states) {
                  // Color and style when the tab is NOT selected
                  return const Color.fromARGB(81, 163, 222, 0);
                }),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    // Color and style when the tab IS selected
                    return const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      height: 0.1,
                    );
                  }
                  // Color and style when the tab is NOT selected
                  return const TextStyle(
                    color: AppColors.deselected,
                    fontSize: 12,
                    height: 0.1,
                  );
                }),
                selectedIndex: navigationShell.currentIndex,
                labelPadding: const EdgeInsets.only(bottom: 10),
                onDestinationSelected: (index) {
                  if (index != 1) {
                    SearchPageGlobals.mapReady = false;
                  }

                  navigationShell.goBranch(
                    index,
                    initialLocation: index == navigationShell.currentIndex,
                  );
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(
                      Icons.home_outlined,
                      color: AppColors.deselected,
                    ),
                    selectedIcon: Icon(
                      Icons.home,
                      color: AppColors.text,
                    ),
                    label: 'Home',
                    tooltip: "homepage",
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.search,
                      color: AppColors.deselected,
                    ),
                    selectedIcon: Icon(
                      Icons.search,
                      color: AppColors.text,
                    ),
                    label: 'Search',
                    tooltip: "Search for businesses",
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.person_outline,
                      color: AppColors.deselected,
                    ),
                    selectedIcon: Icon(
                      Icons.person,
                      color: AppColors.text,
                    ),
                    label: 'Profile',
                    tooltip: "view Profile and Settings",
                  ),
                ]));
      },
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: "/home",
            builder: (context, state) => const HomePage(),
          )
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: "/search",
            builder: (context, state) => const SearchPage(),
          )
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: "/profile",
            builder: (context, state) => const UserPage(),
          )
        ]),
        
      ]),
          GoRoute(
            path: "/business-location/:id",
            builder: (context, state) {
                    SearchPageGlobals.mapReady = false;

              final businessLocationId = state.pathParameters["id"]!;
              return BusinessLocationFullPage(
                  locationId: businessLocationId);
            },
          )
        
]);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Next Find',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        tooltipTheme: TooltipThemeData(
          showDuration: Duration(seconds: 10),
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
      routerConfig: _router,
    );
  }
}
