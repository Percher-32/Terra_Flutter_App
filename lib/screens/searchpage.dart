// import 'dart:ffi';
import 'dart:ui' as ui;
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:nextfind/services/device_services.dart';
import 'package:nextfind/services/business_services.dart';
import 'package:nextfind/services/navbar_services.dart';
import 'package:nextfind/services/user_services.dart';
import 'package:nextfind/services/tag_services.dart';
import 'package:nextfind/services/search_services.dart';
import 'package:nextfind/services/lifecycle_services.dart';
import 'package:nextfind/widgets/main_widgets.dart';
import 'package:nextfind/helpers/logger.dart';
import 'package:nextfind/helpers/networking.dart';

import 'package:nextfind/widgets/search_page/list_view_widget.dart';
import 'package:nextfind/widgets/search_page/map_view_widget.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  void initState() {

    WidgetsBinding.instance.addPostFrameCallback((_) {
    SearchPageGlobals.isLoading.value = false;
    // _counter.value = newValue; // Safe because the build phase is complete
  });

    super.initState();
    WidgetsBinding.instance.addObserver(lifecycle);

    SearchPageGlobals.hasWifi = true;

    //All the globals trigers
    SearchPageGlobals.runSearchTrigger.addListener(() async {
      await _runSearchFunction();
    });

    SearchPageGlobals.runSearch();
  }

  Future<void> _runSearchFunction() async {
    // Prevent overlapping searches

    if (SearchPageGlobals.isLoading.value) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SearchPageGlobals.isLoading.value = true;
    });

    SearchPageGlobals.hasWifi = await Networking.isOnline();

    SearchPageGlobals.miniBusinessLocations.value =
        (await BusinessService.getNearbyBusinesses(
      location: UserService.userLocation,
      query: SearchServices.controller.text,
      maxdist: SearchServices.searchRadius,
      type: SearchServices.categoryIndex.value,
    ))!;

    SearchPageGlobals.reloadMap();

    if (!mounted) return;

    SearchPageGlobals.isLoading.value = false;
    setState(() {});
  }

  void locationButtonPressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // allows full height
      backgroundColor: Colors.transparent, // optional
      builder: (sheetContext) {
        return Container(
            // color: AppColors.background,
            // padding: EdgeInsets.only(left: 10, right: 10),
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40)),
                color: AppColors.background),
            height: 250,
            child: Center(
                child: SizedBox(
              // height: 200,
              child: Column(
                spacing: 30,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MyButton(
                    width: 300,
                    height: 60,
                    onPressed: () async {
                      SearchPageGlobals.isLoading.value = true;

                      await DeviceServices.getDeviceLocation();

                      SearchPageGlobals.changeMapLocation(
                          UserService.userLocation);
                      SearchPageGlobals.isLoading.value = false;

                      if (!sheetContext.mounted) return;
                      Navigator.pop(sheetContext);
                    },
                    padding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 10),
                    child: const MyText(
                      "Use My Location",
                      color: AppColors.background,
                    ),
                  ),
                  MyButton(
                    width: 300,
                    height: 60,
                    onPressed: () {
                      SearchPageGlobals.mapMode.value =
                          MainSearchPageMode.choosing;
                      Navigator.pop(sheetContext);
                    },
                    padding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 10),
                    child: const MyText(
                      "Choose Location",
                      color: AppColors.background,
                    ),
                  ),
                ],
              ),
            )));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: SearchPageGlobals.mapMode.value !=
            MainSearchPageMode
                .thumbnail, // BLOCK back button when thumbnail is showing
        onPopInvokedWithResult: (didPop, result) {
          if (SearchPageGlobals.mapMode.value == MainSearchPageMode.thumbnail) {
            // Custom back behaviour
            SearchPageGlobals.mapMode.value = MainSearchPageMode.map;

            // DO NOT allow pop
            return;
          }
        },
        child: Scaffold(
            appBar: PreferredSize(
              preferredSize: const ui.Size.fromHeight(150),
              child: ValueListenableBuilder<MainSearchPageMode>(
                valueListenable: SearchPageGlobals.mapMode,
                builder: (_, choosing, __) {
                  if (choosing != MainSearchPageMode.list) {
                    return const SizedBox();
                  }
                  return Column(
                    children: [
                      SearchServices.createSearchBar(context),
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: TagServices.showChosenTagWidget(context))
                    ],
                  );
                },
              ),
            ),
            bottomNavigationBar: ValueListenableBuilder<MainSearchPageMode>(
              valueListenable: SearchPageGlobals.mapMode,
              builder: (_, choosing, __) {
                if (choosing != MainSearchPageMode.list) {
                  return const SizedBox(); // hide search bar
                }
                return const NavBar(
                  currentPage: AppPages.searchpage,
                );
              },
            ),
            body: Stack(children: [
              const Positioned(child: SearchPageBody()),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ValueListenableBuilder<MainSearchPageMode>(
                  valueListenable: SearchPageGlobals.mapMode,
                  builder: (_, choosing, __) {
                    if ([MainSearchPageMode.choosing, MainSearchPageMode.list]
                        .contains(choosing)) {
                      return const SizedBox(); // hide search bar
                    }
                    return const NavBar(
                      currentPage: AppPages.searchpage,
                    );
                  },
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 120,
                child: ValueListenableBuilder<MainSearchPageMode>(
                  valueListenable: SearchPageGlobals.mapMode,
                  builder: (_, choosing, __) {
                    if ([MainSearchPageMode.choosing, MainSearchPageMode.list]
                        .contains(choosing)) {
                      return const SizedBox(); // hide search bar
                    }
                    return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TagServices.showChosenTagWidget(context,
                            leveled: false));
                  },
                ),
              ),
              Positioned(
                child: ValueListenableBuilder<MainSearchPageMode>(
                  valueListenable: SearchPageGlobals.mapMode,
                  builder: (_, choosing, __) {
                    if ([MainSearchPageMode.choosing, MainSearchPageMode.list]
                        .contains(choosing)) {
                      return const SizedBox(); // hide search bar
                    }
                    return SearchServices.createSearchBar(context);
                  },
                ),
              ),
            ])));
  }
}

class SearchPageBody extends StatelessWidget {
  const SearchPageBody({super.key});

  void locationButtonPressed(context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // allows full height
      backgroundColor: Colors.transparent, // optional
      builder: (sheetContext) {
        return Container(
            // color: AppColors.background,
            // padding: EdgeInsets.only(left: 10, right: 10),
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40)),
                color: AppColors.background),
            height: 250,
            child: Center(
                child: SizedBox(
              // height: 200,
              child: Column(
                spacing: 30,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MyButton(
                    width: 300,
                    height: 60,
                    onPressed: () async {
                      SearchPageGlobals.isLoading.value = true;
                      await DeviceServices.getDeviceLocation();

                      SearchPageGlobals.changeMapLocation(
                          UserService.userLocation);

                      SearchPageGlobals.isLoading.value = false;
                      if (!sheetContext.mounted) return;
                      Navigator.pop(sheetContext);
                    },
                    padding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 10),
                    child: const MyText(
                      "Use My Location",
                      color: AppColors.background,
                    ),
                  ),
                  MyButton(
                    width: 300,
                    height: 60,
                    onPressed: () {
                      SearchPageGlobals.mapMode.value =
                          MainSearchPageMode.choosing;

                      Navigator.pop(sheetContext);
                    },
                    padding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 10),
                    child: const MyText(
                      "Choose Location",
                      color: AppColors.background,
                    ),
                  ),
                ],
              ),
            )));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MainSearchPageMode>(
      valueListenable: SearchPageGlobals.mapMode,
      builder: (_, mapMode, ___) {
        Widget mainSearchPageWidget = const SizedBox();

        if (!SearchPageGlobals.hasWifi) {
          mainSearchPageWidget = const Center(child: Heading("No Internet"));
        }

        if (!SearchPageGlobals.isLoading.value) {
          if (mapMode != MainSearchPageMode.list) {
            mainSearchPageWidget = const MapSearchView();
          } else if (mapMode == MainSearchPageMode.list) {
            mainSearchPageWidget = const ListSearchView();
          }
        }

        final changeLocationButton = Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            splashColor: const Color.fromARGB(111, 252, 178, 74),
            onTap: () {
              locationButtonPressed(context);
            },
            child: Ink(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Center(
                child: Icon(
                  Icons.location_on,
                  size: 35,
                  color: AppColors.background,
                ),
              ),
            ),
          ),
        );

        final anchorMapPositionButton = Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            splashColor: const Color.fromARGB(111, 252, 178, 74),
            onTap: () {
              SearchPageGlobals.changeMapLocation(UserService.userLocation);
            },
            child: Ink(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Center(
                child: Icon(
                  Icons.location_searching,
                  size: 35,
                  color: AppColors.background,
                ),
              ),
            ),
          ),
        );

        final goToListViewButton = Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            splashColor: const Color.fromARGB(111, 252, 178, 74),
            onTap: () {
              SearchPageGlobals.mapMode.value = MainSearchPageMode.list;
            },
            child: Ink(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Center(
                child: Icon(
                  Icons.list,
                  size: 35,
                  color: AppColors.background,
                ),
              ),
            ),
          ),
        );

        final mapSearchButton = Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            splashColor: const Color.fromARGB(111, 252, 178, 74),
            onTap: () {
              SearchPageGlobals.reloadMap();
            },
            child: Ink(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Center(
                child: Icon(
                  Icons.search,
                  size: 35,
                  color: AppColors.background,
                ),
              ),
            ),
          ),
        );

        final listSearchButton = Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            splashColor: const Color.fromARGB(111, 252, 178, 74),
            onTap: () {
              SearchPageGlobals.runSearch();
            },
            child: Ink(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Center(
                child: Icon(
                  Icons.search,
                  size: 35,
                  color: AppColors.background,
                ),
              ),
            ),
          ),
          // ),
        );

        final goToMapViewButton = Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            splashColor: const Color.fromARGB(111, 252, 178, 74),
            onTap: () {
              SearchPageGlobals.mapMode.value = MainSearchPageMode.map;
            },
            child: Ink(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Center(
                child: Icon(
                  Icons.map_outlined,
                  size: 35,
                  color: AppColors.background,
                ),
              ),
            ),
          ),
        );

        final locationButtonDialogue = Center(
            child: Container(
                width: MediaQuery.of(context).size.width - 20,
                height: 80,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: AppColors.primary),
                child: const Center(
                    child: MyText(
                  "Tap anywhere on the map to choose a location",
                  size: 20,
                  color: AppColors.background,
                  textAlign: TextAlign.center,
                ))));

        final choosingLocationBackButton = Center(
            child: MyButton(
          width: 300,
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.0),
          child: const MyText(
            "Back",
            color: AppColors.background,
          ),
          onPressed: () {
            SearchPageGlobals.mapMode.value = MainSearchPageMode.map;
            SearchPageGlobals.reloadMap();
          },
        ));

        return Stack(
          children: [
            //Map OR List
            mainSearchPageWidget,

            //Loading Bar
            ValueListenableBuilder<bool>(
              valueListenable: SearchPageGlobals.isLoading,
              builder: (_, choosing, __) {
                if ([MainSearchPageMode.thumbnail, MainSearchPageMode.list]
                        .contains(SearchPageGlobals.mapMode.value) ||
                    !choosing) {
                  return const SizedBox();
                }

                return const Center(
                    child: SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    strokeWidth: 14,
                    color: AppColors.primary,
                  ),
                ));
              },
            ),

            //* MAP VIW WIDGETS
            //Location Button [MAP VIEW]
            Positioned(
              bottom: 60,
              right: 10 + 70,
              child: mapMode == MainSearchPageMode.map
                  ? changeLocationButton
                  : const SizedBox(),
            ),

            //Anchor Position [MAP VIEW]
            Positioned(
              bottom: 60,
              right: 80 + 70,
              child: mapMode == MainSearchPageMode.map
                  ? anchorMapPositionButton
                  : const SizedBox(),
            ),

            //Go to list View [MAP VIEW]
            Positioned(
              bottom: 60,
              right: 10,
              child: mapMode == MainSearchPageMode.map
                  ? goToListViewButton
                  : const SizedBox(),
            ),

            //Search Button [MAP VIEW]
            Positioned(
              bottom: 60,
              left: 10,
              child: mapMode == MainSearchPageMode.map
                  ? mapSearchButton
                  : const SizedBox(),
            ),

            //* List View Widgets

            //Search Button [LIST]
            Positioned(
              bottom: 10,
              left: 10,
              child: mapMode == MainSearchPageMode.list
                  ? listSearchButton
                  : const SizedBox(),
            ),

            //Go to Map [LIST]
            Positioned(
              bottom: 60 - 50,
              right: 10,
              child: mapMode == MainSearchPageMode.list
                  ? goToMapViewButton
                  : const SizedBox(),
            ),

            //* Choosing View Widgets
            // Tap anywhere on the map to choose a location [Choosing VIEW]
            Positioned(
              top: 60,
              left: 10,
              child: mapMode == MainSearchPageMode.choosing
                  ? locationButtonDialogue
                  : const SizedBox(),
            ),

            // Back Button [Choosing VIEW]
            Positioned(
              bottom: 10,
              left: MediaQuery.of(context).size.width / 8,
              child: mapMode == MainSearchPageMode.choosing
                  ? choosingLocationBackButton
                  : const SizedBox(),
            ),
          ],
        );
      },
    );
  }
}
