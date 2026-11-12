import 'package:flutter/material.dart';
import 'package:nextfind/screens/homepage.dart';
import 'package:nextfind/screens/searchpage.dart';
import 'package:nextfind/services/search_services.dart';
import 'package:nextfind/widgets/main_widgets.dart';
import 'package:nextfind/services/navbar_services.dart';
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
            backgroundColor: AppColors.leveled,
            indicatorColor : AppColors.leveled,
            
            selectedIndex: navigationShell.currentIndex,
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
              NavigationDestination(icon: Icon(Icons.home,color: AppColors.secondaryText,),selectedIcon: Icon(Icons.home,color: AppColors.text,) , label: 'Home',),
              NavigationDestination(icon: Icon(Icons.search,color: AppColors.secondaryText,),selectedIcon: Icon(Icons.search,color: AppColors.text,) , label: 'Search',),
            ],
          ),
        );
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
      ])
]);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Next Find',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
      ),
      themeMode: ThemeMode.dark,
      // home: const HomePage(),
      routerConfig: _router,
    );
  }
}
