import 'package:flutter/material.dart';
import 'package:nextfind/widgets/main_widgets.dart';
import 'package:nextfind/screens/homepage.dart';
import 'package:nextfind/screens/searchpage.dart';
import 'package:nextfind/services/search_services.dart';
import 'package:nextfind/screens/map_view_widget.dart';
import 'package:nextfind/screens/userpage.dart';
import 'package:nextfind/screens/businesspage.dart';
import 'package:nextfind/screens/favorite_locations_page.dart';
import 'package:go_router/go_router.dart';

void showErrorMessage(BuildContext context, dynamic message) {
  showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.background,
          constraints: const BoxConstraints(
              minHeight: 100, minWidth: 200, maxHeight: 300),
          child: Center(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox(
                      // width: 200,
                      child: MyText(
                          textAlign: TextAlign.center,
                          message.toString(),
                          size: 25)))),
        );
      });
}

// Global route observer to track page visibility
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

final GoRouter router = GoRouter(initialLocation: "/home", observers: [
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
            path: "/search/map",
            builder: (context, state) => const MapSearchView(),
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
    path: "/search/initial/:tag",
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      child:  Material(
        color: Colors.transparent,
        child: FullScreenSearchWidget(tag:state.pathParameters["tag"]!),
      ),
      opaque: false,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    ),
  ),
  GoRoute(
    path: "/business-location/:id",
    builder: (context, state) {
      SearchPageGlobals.mapReady = false;

      final businessLocationId = state.pathParameters["id"]!;
      return BusinessLocationFullPage(locationId: businessLocationId);
    },
  )
]);
