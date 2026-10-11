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
    MaterialPageRoute(builder: (context) => const MyHomePage()),
  );
}

void goToBusinessPage(BuildContext context, String locationId,
    {bool canGoBack = true}) {
  final router = PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => BusinessLocationFullPage(locationId: locationId),
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

void filterDropDown(BuildContext context) {
  Map<dynamic, Widget> allIcons = {};
  Map<dynamic, Widget> allIconsAlt = {};

  for (int? index in businessIconLookup.keys) {
    Widget widget = const SizedBox();
    Widget widgetAlt = const SizedBox();
    if (index != null) {
      widget = Image.asset(
        businessIconLookup[index]!,
        width: 32,
        height: 32,
      );

      widgetAlt = Image.asset(
        businessIconLookupAlt[index]!,
        width: 32,
        height: 32,
      );
    }

    allIcons[index] = widget;
    allIconsAlt[index] = widgetAlt;
  }

  showModalBottomSheet(
    context: context,
    // backgroundColor: Colors.deepPurple.shade50,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          spacing: 0,
          mainAxisSize: MainAxisSize.min,
          children: [
            const MyText(
              "Search Settings",
              color: AppColors.text,
              size: 30,
            ),
            const SizedBox(height: 30),
            //TTILE DONE

            Container(
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: HeaderInput(
                  hint: "find a business",
                  controller: SearchServices.controller,
                  onSubmitted: (value) => goToSearchPage(context),
                )),

            const SizedBox(height: 20),

            ValueListenableBuilder(
              valueListenable: SearchServices.searchRadiusIndex,
              builder: (_, __, ___) {
                return MyMainSlider(
                  distances: SearchServices.searchRadiusValues,
                  onChanged: (distanceIndex) {
                    SearchServices.searchRadiusIndex.value = distanceIndex;
                  },
                  startValue: SearchServices.searchRadiusIndex.value,
                );
              },
            ),
            const SizedBox(height: 10),
            //TTILE SLIDER DONE

            MyMultiToggle(
              initial: SearchServices.isMetric.value ? 0 : 1,
              options: const [
                "Kilometers",
                "Miles",
              ],
              onChanged: (val) {
                SearchServices.isMetric.value = !SearchServices.isMetric.value;
              },
            ),
            const SizedBox(height: 20),
            //Choose Units Done

            const Body(
              "Category",
              color: AppColors.text,
            ),
            const SizedBox(height: 10),
            CustomDropDown(
              values: businessTypeLookup,
              onChanged: (value) {
                SearchServices.categoryIndex = value;
              },
              startIndex: SearchServices.categoryIndex,
              widgetAppend: allIconsAlt,
              selectedWidgetAppend: allIcons,
            ),
            const SizedBox(height: 20),
            //Category DROPDOWN DONE

            const Body(
              "Sort By",
              color: AppColors.text,
            ),
            const SizedBox(height: 10),
            MyMultiToggle(
              initial: SearchServices.sortingByIndex,
              options: SearchServices.sortingByValues,
              onChanged: (val) {
                SearchServices.sortingByIndex = val;
              },
            ),
            const SizedBox(height: 20),
            //TTILE SEARCH POWER DONE

            const Body(
              "Tags",
              color: AppColors.text,
            ),
            const SizedBox(height: 10),
            TagServices.showChosenTagWidget(context),
            const SizedBox(height: 40),
            //Tag Chooser Done

            MyButton(
              height: 60,
              width: 300,
              child: const Body("Search", color: AppColors.background),
              onPressed: () {
                goToSearchPage(context);
              },
            ),
          ],
        ),
      );
    },
  );
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
