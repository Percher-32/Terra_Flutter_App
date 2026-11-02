import 'package:flutter/material.dart';
import 'package:nextfind/widgets/main_widgets.dart';
import 'package:nextfind/services/business_services.dart';
import 'package:nextfind/services/user_services.dart';
import 'package:nextfind/services/tag_services.dart';
import 'package:nextfind/models/business_models.dart';
import 'package:nextfind/page_moves.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as map_gl;
import 'dart:typed_data';

enum MainSearchPageMode { map, list, choosing, thumbnail }

enum BusinessMarkerLevel { full, reduced, mini }

class SearchPageGlobals {
  static final ValueNotifier<MainSearchPageMode> mapMode =
      ValueNotifier(MainSearchPageMode.map);
  static final ValueNotifier<bool> reloadMapTrigger = ValueNotifier(false);
  static final ValueNotifier<bool> runSearchTrigger = ValueNotifier(false);
  static final ValueNotifier<bool> reloadUserPositionTrigger =
      ValueNotifier(false);

  static bool mapReady = false;

  static final ValueNotifier<bool> isLoading = ValueNotifier(false);

  static final ValueNotifier<List<MiniBusinessLocation>> miniBusinessLocations =
      ValueNotifier([]);

  static final Map<(MiniBusinessLocation, BusinessMarkerLevel), Uint8List>
      businessMarkerIconCache = {};

  static bool hasWifi = false;

  static MiniBusinessLocation? chosenBusinessLocation;

  static map_gl.MapLibreMapController? mapController;

  static void setChosenBusinessLocation(
      MiniBusinessLocation miniBusinessLocation) {
    chosenBusinessLocation = miniBusinessLocation;
    mapMode.value = MainSearchPageMode.thumbnail;
    changeMapLocation(miniBusinessLocation.location);
  }

  static void reloadMap() {
    if (mapMode.value == MainSearchPageMode.map) {
      reloadMapTrigger.value = !reloadMapTrigger.value;
    }
  }

  static void reloadUserPosition() {
    reloadUserPositionTrigger.value = !reloadUserPositionTrigger.value;
  }

  static void runSearch() {
    runSearchTrigger.value = !runSearchTrigger.value;
  }

  static void changeMapLocation(List<double> newLocation) {
    if (mapController != null) {
      SearchPageGlobals.mapController!.animateCamera(
        map_gl.CameraUpdate.newLatLngZoom(
            map_gl.LatLng(newLocation[0], newLocation[1]), 16),
      );
    }
  }
}

class SearchServices {
  static ValueNotifier<bool> isMetric = ValueNotifier(false);

  static int sortingByIndex = 1;
  static const List sortingByValues = ["Relevance", "Distance", "Rating"];

  static ValueNotifier<int?> categoryIndex = ValueNotifier(null);

  static const List<int> searchRadiusValues = [1, 3, 5, 10, 15, 20, 30, 50];
  static final ValueNotifier<int> searchRadiusIndex = () {
    final notifier = ValueNotifier(3);

    notifier.addListener(() {
      searchRadius = searchRadiusValues[notifier.value];
    });

    return notifier;
  }();
  static int searchRadius = searchRadiusValues[searchRadiusIndex.value];

  static final TextEditingController controller = TextEditingController();

  static void filterDropDown(BuildContext parentContext) {
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
      context: parentContext,
      backgroundColor: AppColors.leveled,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (builderContext) {
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
              Container(
                  decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: HeaderInput(
                    hint: "find a business",
                    controller: SearchServices.controller,
                    onSubmitted: (value) => goToSearchPage(parentContext),
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
              MyMultiToggle(
                initial: SearchServices.isMetric.value ? 0 : 1,
                options: const [
                  "Kilometers",
                  "Miles",
                ],
                onChanged: (val) {
                  SearchServices.isMetric.value =
                      !SearchServices.isMetric.value;
                },
              ),
              const SizedBox(height: 20),
              const LabelText(
                "Category",
                color: AppColors.text,
              ),
              const SizedBox(height: 10),
              const CategoryDropDown(),
              const SizedBox(height: 20),
              const LabelText(
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
              const LabelText(
                "Tags",
                color: AppColors.text,
              ),
              const SizedBox(height: 10),
              TagServices.showChosenTagWidget(parentContext),
              const SizedBox(height: 40),
              MyButton(
                height: 60,
                width: 300,
                child: const MyText("Search", color: AppColors.text),
                onPressed: () {
                  goToSearchPage(parentContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static PreferredSize createSearchBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(84),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.all(10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: AppColors.primary,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 10),
                    const Icon(Icons.search, color: Colors.white, size: 40),
                    Expanded(
                      child: HeaderInput(
                        hint: "find a business",
                        controller: controller,
                        color: AppColors.text,
                        size: 25,
                        onSubmitted: (value) => goToSearchPage(context),
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.tune, color: Colors.white, size: 40),
                      iconSize: 35,
                      onPressed: () => filterDropDown(context),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryDropDown extends StatefulWidget {
  const CategoryDropDown({super.key});

  @override
  State<CategoryDropDown> createState() => CategoryDropDownState();
}

class CategoryDropDownState extends State<CategoryDropDown> {
  Map<dynamic, Widget> widgetIcon = {};
  Map<dynamic, Widget> widgetIconSelected = {};
  List<Widget> gridItems = [];
  @override
  void initState() {
    super.initState();

    for (int? itemCategoryIndex in businessIconLookup.keys) {
      if (itemCategoryIndex != null) {
        Widget widget = Image.asset(
          businessIconLookup[itemCategoryIndex]!,
          width: 32,
          height: 32,
        );

        Widget widgetAlt = Image.asset(
          businessIconLookupAlt[itemCategoryIndex]!,
          width: 32,
          height: 32,
        );

        widgetIcon[itemCategoryIndex] = widget;
        widgetIconSelected[itemCategoryIndex] = widgetAlt;
      }

      final itemValue = businessTypeLookup[itemCategoryIndex];

      final bool isChosen =
          SearchServices.categoryIndex.value == itemCategoryIndex;

      Widget itemWidget = const SizedBox();
      if (itemCategoryIndex != null) {
        if (isChosen) {
          itemWidget = widgetIcon[itemCategoryIndex]!;
        } else {
          itemWidget = widgetIconSelected[itemCategoryIndex]!;
        }
      }

      final gridWidget = SizedBox(
        width: 300,
        height: 60,
        child: ElevatedButton(
          onPressed: () {
            SearchServices.categoryIndex.value = itemCategoryIndex;
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor:
                isChosen ? AppColors.primary : AppColors.background,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              itemWidget,
              MyText(
                itemValue.toString(),
                color: isChosen ? AppColors.background : AppColors.text,
                textAlign: TextAlign.center,
                size: 13,
              ),
            ],
          ),
        ),
      );

      gridItems.add(gridWidget);
    }
  }

  void showOptionPicker() {
    List<Widget> gridItems = [];

    for (int? itemCategoryIndex in businessTypeLookup.keys) {
      final itemValue = businessTypeLookup[itemCategoryIndex];

      final bool isChosen =
          SearchServices.categoryIndex.value == itemCategoryIndex;

      Widget itemWidget = const SizedBox();
      if (itemCategoryIndex != null) {
        if (isChosen) {
          itemWidget = widgetIcon[itemCategoryIndex]!;
        } else {
          itemWidget = widgetIconSelected[itemCategoryIndex]!;
        }
      }

      final gridWidget = SizedBox(
        width: 300,
        height: 60,
        child: ElevatedButton(
          onPressed: () {
            SearchServices.categoryIndex.value = itemCategoryIndex;
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor:
                isChosen ? AppColors.primary : AppColors.secondaryLeveled,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              itemWidget,
              MyText(
                itemValue.toString(),
                color: isChosen ? AppColors.text : AppColors.secondaryText,
                textAlign: TextAlign.center,
                size: 13,
              ),
            ],
          ),
        ),
      );

      gridItems.add(gridWidget);
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
            insetPadding: const EdgeInsets.all(10),
            backgroundColor: AppColors.leveled,
            child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(height: 16),
                  const MyText(
                    "Choose a category",
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                      height: 500,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const itemWidth = 110.0;

                          final columns =
                              (constraints.maxWidth / itemWidth).floor();

                          return GridView.count(
                            padding: const EdgeInsets.all(10),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            crossAxisCount: columns,
                            children: gridItems,
                          );
                        },
                      )),
                ])));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: SearchServices.categoryIndex,
        builder: (_, index, __) {
          return MyButton(
            width: 300,
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                left: 0,
                top: 15,
                child: MyText(
                  businessTypeLookup[SearchServices.categoryIndex.value]
                      .toString(),
                  textAlign: TextAlign.center,
                  color: AppColors.text,
                ),
              ),
              const Positioned(
                right: 0,
                top: 10,
                child: Icon(
                  Icons.arrow_drop_down,
                  size: 40,
                  color: Colors.white,
                ),
              )
            ]),
            onPressed: () {
              showOptionPicker();
            },
          );
        });
  }
}
