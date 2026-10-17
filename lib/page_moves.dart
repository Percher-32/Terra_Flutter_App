import 'package:flutter/material.dart';
import 'package:nextfind/widgets/main_widgets.dart';
import 'package:nextfind/services/business_services.dart';
import 'package:nextfind/services/search_services.dart';
import 'package:nextfind/services/tag_services.dart';
import 'package:nextfind/screens/homepage.dart';
import 'package:nextfind/screens/searchpage.dart';
import 'package:nextfind/screens/userpage.dart';
import 'package:nextfind/screens/businesspage.dart';
import 'package:nextfind/screens/favorite_locations_page.dart';

void goToSearchPage(BuildContext context) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const SearchPage()),
  );
}

void goToHomePage(BuildContext context) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const HomePage()),
  );
}

void goToBusinessPage(BuildContext context, String locationId,
    {bool canGoBack = true}) {
  final router = PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) =>
        BusinessLocationFullPage(locationId: locationId),
    transitionsBuilder: (_, animation, __, child) {
      final offsetAnimation = Tween(
        begin: const Offset(0, 1), // start below screen
        end: Offset.zero, // end at normal position
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ));

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );

  if (canGoBack) {
    Navigator.push(
      context,
      router,
    );
  } else {
    Navigator.pushReplacement(
      context,
      router,
    );
  }
}

void goToFavoritesPage(BuildContext context, {bool canGoBack = true}) {
  if (canGoBack) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FavoriteLocationsPage()),
    );
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const FavoriteLocationsPage()),
    );
  }
}

void goToUserPage(BuildContext context, {bool canGoBack = true}) {
  if (canGoBack) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserPage()),
    );
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const UserPage()),
    );
  }
}

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
