import 'package:nextfind/pages/homepage.dart';
import 'package:nextfind/widgets/main_widgets.dart';
import 'package:nextfind/helpers/logger.dart';
import 'package:nextfind/helpers/conversions.dart';
import 'package:nextfind/pages/searchpage.dart';
import 'package:nextfind/pages/userpage.dart';
import 'package:flutter/material.dart';
import 'package:nextfind/pages/focusedviewed.dart';
import 'package:nextfind/pages/favorite_locations.dart';

Widget newbottombar(BuildContext context, {int index = 2}) {
  void homePageButtonLogic(BuildContext context) {
    goToHomePage(context);
  }

  void searchButtonLogic(BuildContext context) {
    goToSearchPage(context);
  }

  Future<void> userButtonLogic(BuildContext context) async {
    goToUserPage(context);
  }

  final midColor = Color.lerp(AppColors.background, AppColors.primary, 0.5);

  Widget searchIcon = Icon(Icons.search, color: midColor, size: 35);
  Widget leaderboardIcon =
      Icon(Icons.leaderboard_outlined, color: midColor, size: 35);
  Widget homeIcon = Icon(Icons.home_outlined, color: midColor, size: 35);
  Widget favoriteIcon =
      Icon(Icons.favorite_border_rounded, color: midColor, size: 35);
  Widget userIcon = Icon(Icons.person_outline, color: midColor, size: 35);

  if (index == 0) {
    searchIcon = const Icon(Icons.search, color: Colors.white, size: 35);
  } else if (index == 1) {
    leaderboardIcon =
        const Icon(Icons.leaderboard_outlined, color: Colors.white, size: 35);
  } else if (index == 2) {
    homeIcon = const Icon(Icons.home_outlined, color: Colors.white, size: 35);
  } else if (index == 3) {
    favoriteIcon = const Icon(Icons.favorite_border_rounded,
        color: Colors.white, size: 35);
  } else if (index == 4) {
    userIcon = const Icon(Icons.person_outline, color: Colors.white, size: 35);
  }

  return Padding(
    padding: const EdgeInsets.all(0),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: Container(
        height: 50,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10), topRight: Radius.circular(10)),
          color: AppColors.primary,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: searchIcon,
              iconSize: 35,
              onPressed: () {
                log.d("User tapped bottom nav button : search");
                searchButtonLogic(context);
              },
            ),
            IconButton(
              icon: leaderboardIcon,
              iconSize: 35,
              onPressed: () {
                log.d("User tapped bottom nav button leader :board");
              },
            ),
            IconButton(
              icon: homeIcon,
              iconSize: 35,
              onPressed: () {
                log.d("User tapped bottom nav button : home");
                homePageButtonLogic(context);
              },
            ),
            IconButton(
              icon: favoriteIcon,
              iconSize: 35,
              onPressed: () {
                goToFavoritesPage(context);
              },
            ),
            IconButton(
              icon: userIcon,
              iconSize: 35,
              onPressed: () async {
                log.d("User tapped bottom nav button : user");
                await userButtonLogic(context);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

void goToSearchPage(BuildContext context) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => SearchPage()),
  );
}

void goToHomePage(BuildContext context) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const MyHomePage(title: "HI")),
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

void goToBusinessPage(BuildContext context, String locationId,
    {bool canGoBack = true}) {
  final router = PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => BusinessLocPage(locationId: locationId),
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
  arbitfallbacks();
  final distances = [1, 3, 5, 10, 15, 20, 30, 50];

  List<Widget> allIcons = [];
  List<Widget> allIconsAlt = [];

  for (int index in businessIconLookup.keys) {
    Widget widget = const SizedBox();
    Widget widgetAlt = const SizedBox();
    if (index != -1) {
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

    allIcons.add(widget);
    allIconsAlt.add(widgetAlt);
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
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: HeaderInput(
                  hint: "find a business",
                  controller: SearchBarController.controller,
                  onSubmitted: (value) => goToSearchPage(context),
                )),

            const SizedBox(height: 20),

            ValueListenableBuilder(
              valueListenable:
                  DistanceMeasurmentChangedHolder.distanceMeasurmentChanged,
              builder: (_, __, ___) {
                return MyMainSlider(
                  distances: distances,
                  onChanged: (distance) {
                    arbitStore.data["distance_index"] =
                        distances.indexOf(distance);
                    arbitStore.data["distance"] = milesToKm(
                      distance.toDouble(),
                    ).toInt();
                  },
                  startValue: arbitStore.data["distance_index"],
                );
              },
            ),
            const SizedBox(height: 10),
            //TTILE SLIDER DONE

            // const Body(
            //   "Measure",
            //   color: AppColors.text,
            // ),
            // const SizedBox(height: 10),
            MyMultiToggle(
              initial: arbitStore.data["metric?"] ? 0 : 1,
              options: const [
                "Kilometers",
                "Miles",
              ],
              onChanged: (val) {
                DistanceMeasurmentChangedHolder
                        .distanceMeasurmentChanged.value =
                    !DistanceMeasurmentChangedHolder
                        .distanceMeasurmentChanged.value;
                if (val == 0) {
                  arbitStore.data["metric?"] = true;
                }
                if (val == 1) {
                  arbitStore.data["metric?"] = false;
                }
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
              values: businessTypeLookup.values.toList(),
              onChanged: (value) {
                log.i(
                    "CATEGORY CHANGE : BEFORE -> ${arbitStore.data["categoryINDEX"]}");
                arbitStore.data["categoryINDEX"] = value - 1;
                log.i(
                    "CATEGORY CHANGE : AFTER -> ${arbitStore.data["categoryINDEX"]}");
              },
              startIndex: arbitStore.data["categoryINDEX"] + 1,
              widgetAppend: allIconsAlt,
              selectedWidgetAppend: allIcons,
            ),
            const SizedBox(height: 20),
            //TTILE DROPDOWN DONE

            const Body(
              "Sort By",
              color: AppColors.text,
            ),
            const SizedBox(height: 10),
            MyMultiToggle(
              initial: arbitStore.data["sortingINDEX"],
              options: const [
                "Relevance",
                "Distance",
                "Rating",
              ],
              onChanged: (val) {
                arbitStore.data["sortingINDEX"] = val;
                if (val == 1) {
                  arbitStore.data["sorting"] = "DST";
                }
                if (val == 2) {
                  arbitStore.data["sorting"] = "RAT";
                }
                if (val == 0) {
                  arbitStore.data["sorting"] = "";
                }
              },
            ),
            const SizedBox(height: 20),
            //TTILE SEARCH POWER DONE

            const Body(
              "Tags",
              color: AppColors.text,
            ),
            const SizedBox(height: 10),
            TagController.showChosenTagWidget(context),
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
