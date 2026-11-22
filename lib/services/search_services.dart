import 'package:nextfind/models/tag_models.dart';
import 'package:rapidfuzz/rapidfuzz.dart' as fuzz;
import 'package:flutter/material.dart';
import 'package:nextfind/screens/initial_searching_widget.dart';
import 'package:nextfind/widgets/main_widgets.dart';
import 'package:nextfind/services/business_services.dart';
import 'package:nextfind/helpers/networking.dart';
import 'package:nextfind/services/user_services.dart';
import 'package:nextfind/services/tag_services.dart';
import 'package:nextfind/models/business_models.dart';
import 'package:nextfind/page_moves.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as map_gl;
import 'dart:typed_data';
import 'package:go_router/go_router.dart';

enum MainSearchPageMode { map, list, choosing, thumbnail }

enum BusinessMarkerLevel { full, reduced, mini }

class SearchPageGlobals {
  static final ValueNotifier<MainSearchPageMode> mapMode =
      ValueNotifier(MainSearchPageMode.map);
  static final ValueNotifier<bool> runSearchTrigger = ValueNotifier(false);
  static final ValueNotifier<bool> reloadUserPositionTrigger =
      ValueNotifier(false);

  static bool mapReady = false;

  static final ValueNotifier<bool> isLoading = ValueNotifier(false);

  static final ValueNotifier<List<MiniBusinessLocation>> miniBusinessLocations =
      ValueNotifier([]);

  static final Map<int, Uint8List> businessMarkerIconCache = {};

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
      runSearchTrigger.value = !runSearchTrigger.value;
    }
  }

  static void reloadUserPosition() {
    reloadUserPositionTrigger.value = !reloadUserPositionTrigger.value;
  }

  static void changeMapLocation(List<double> newLocation) {
    if (mapController != null) {
      SearchPageGlobals.mapController!.animateCamera(
        map_gl.CameraUpdate.newLatLngZoom(
            map_gl.LatLng(newLocation[0], newLocation[1]), 16),
      );
    }
  }

  static void runSearch() {
    runSearchTrigger.value = !runSearchTrigger.value;
  }

  static Future<void> runSearchApiCall() async {
    if (isLoading.value || !mapReady) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      isLoading.value = true;
    });

    hasWifi = await Networking.isOnline();

    miniBusinessLocations.value = (await BusinessService.getNearbyBusinesses(
      location: UserService.userLocation,
      query: SearchServices.searchBarController.text,
      maxdist: SearchServices.searchRadius,
      type: SearchServices.categoryIndex.value,
    ))!;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      isLoading.value = false;
    });

    reloadMap();
  }
}

class SearchServices {
  static ValueNotifier<bool> isMetric = ValueNotifier(false);

  static int sortingByIndex = 1;
  static const List sortingByValues = ["Relevance", "Distance", "Rating"];

  static TextEditingController searchBarController =
      TextEditingController(text: "");

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

  static final TextEditingController locationTextController =
      TextEditingController(text: "Current Location");

  static List<dynamic> rankBusinessNamesAndTags(String query) {
    final lowerQuery = query.toLowerCase().trim();

    final scoredBusinesses = BusinessService.miniBusinessLocationLookup.values
        .map((miniBusinessLocation) {
      final name = miniBusinessLocation.name.toLowerCase();

      final r1 = fuzz.ratio(lowerQuery, name); // strict
      final r2 = fuzz.partialRatio(lowerQuery, name); // forgiving

      final score = ((r1 * 0.3) + (r2 * 0.7)).round();

      return {
        "type": "miniBusinessLocation",
        "item": miniBusinessLocation,
        "score": score
      };
    }).toList();

    final scoredTags = TagServices.tagLookup.values.map((tag) {
      final name = tag.name.toLowerCase();

      final r1 = fuzz.ratio(lowerQuery, name); // strict
      final r2 = fuzz.partialRatio(lowerQuery, name); // forgiving

      final score = ((r1 * 0.3) + (r2 * 0.7)).round();

      return {"type": "tag", "item": tag, "score": score};
    }).toList();

    final allRanked = [...scoredBusinesses, ...scoredTags];

    allRanked.sort((a, b) {
      final sb = b["score"] as int;
      final sa = a["score"] as int;
      return sb.compareTo(sa);
    });

    return allRanked
        .where((e) => (e["score"] as int) >= 40) // ← threshold here
        .map((e) {
      if (e["type"] == "miniBusinessLocation") {
        return e["item"] as MiniBusinessLocation;
      } else {
        return e["item"] as Tag;
      }
    }).toList();
  }

  static Future<int> getIndexableSearchData() async {
    //! Replace this with a cutom made API call to get the most relevant businesses
    await BusinessService.getNearbyBusinesses(
      location: UserService.userLocation,
      query: SearchServices.searchBarController.text,
      maxdist: SearchServices.searchRadius,
      type: SearchServices.categoryIndex.value,
    );

    await TagServices.getAllTags();
    return 1;
  }

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
              const SubHeading(
                "Search Settings",
                color: AppColors.text,
                // size: 30,
              ),
              const SizedBox(height: 10),
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
                  parentContext.go("/search/map");
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class MySearchBar extends StatefulWidget {
  const MySearchBar({super.key, required this.tag});

  final String tag;

  @override
  State<MySearchBar> createState() => _MySearchBarState();
}

class _MySearchBarState extends State<MySearchBar> with RouteAware {
  // 1. Declare the controller locally inside the State class
  final FocusNode myFocus = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    myFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          context.push('/search/initial/${widget.tag}');
        },
        child: Hero(
            tag: widget.tag, // Must match the tag on the full screen
            child: ValueListenableBuilder(
                valueListenable: SearchServices.searchBarController,
                builder: (_, __, ___) {
                  final Widget widgetOnViewBar =
                      SearchServices.searchBarController.text.isEmpty
                          ? const Row(children: [
                              Icon(
                                Icons.search,
                                size: 25,
                              ),
                              SizedBox(width: 5),
                              Flexible(
                                  child: MyText(
                                "type of business, business name , business specialty",
                                size: 15,
                                color: AppColors.deselected,
                                overflow: TextOverflow.ellipsis,
                                maxlines: 1,
                                textAlign: TextAlign.left,
                              )),
                              SizedBox(width: 10),
                            ])
                          : Row(children: [
                              const Icon(
                                Icons.search,
                                size: 20,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                  child: MyText(
                                SearchServices.searchBarController.text,
                                size: 15,
                                color: AppColors.text,
                                overflow: TextOverflow.ellipsis,
                                maxlines: 1,
                                textAlign: TextAlign.left,
                              )),
                              // Flexible(child: SizedBox(width: 100)),
                              const SizedBox(width: 20),

                              MyText(
                                SearchServices.locationTextController.text,
                                size: 15,
                                color: AppColors.deselected,
                                overflow: TextOverflow.ellipsis,
                                maxlines: 1,
                                textAlign: TextAlign.left,
                              ),
                              const SizedBox(width: 10),
                            ]);

                  return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Container(
                        padding: const EdgeInsets.only(
                            left: 10, right: 30, top: 10, bottom: 10),
                        // height: 50,
                        decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.secondaryLeveled, width: 2)),
                        child: widgetOnViewBar,
                      ));
                })));
  }
}

class FullScreenSearchWidget extends StatefulWidget {
  const FullScreenSearchWidget({super.key, required this.tag});

  final String tag;

  @override
  State<StatefulWidget> createState() => _FullScreenSearchWidgetState();
}

class _FullScreenSearchWidgetState extends State<FullScreenSearchWidget> {
  late FocusNode searchBarFocusNode;

  @override
  void initState() {
    super.initState();
    searchBarFocusNode = FocusNode();
  }

  @override
  void dispose() {
    super.dispose();
    searchBarFocusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        child: Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
                child: Hero(
                    tag: widget.tag,
                    child: Material(
                        color: Colors.transparent,
                        child: Stack(alignment: Alignment.center, children: [
                          Column(children: [
                            const SizedBox(
                              height: 30,
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: Row(
                                children: [
                                  Expanded(
                                    // 🔑 Wrap the text input in Expanded so it doesn't overflow the Row
                                    child: MyTextInputWidget(
                                      leadingDistance: 0,
                                      hint:
                                          "type of business, business name or business specialty",
                                      padding: const EdgeInsets.only(
                                          left: 10, right: 10),
                                      startIcon: IconButton(
                                        onPressed: () {
                                          context.pop();
                                        },
                                        highlightColor: AppColors.leveled,
                                        splashColor: AppColors.leveled,
                                        icon: Icon(
                                          color: AppColors.text,
                                          Icons.arrow_back,
                                          size: 25,
                                        ),
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: AppColors.leveled, width: 3),
                                      ),
                                      height: 50,
                                      fontWeight: FontWeight.w600,
                                      focusNode: searchBarFocusNode,
                                      hintFontWeight: FontWeight.w600,
                                      controller:
                                          SearchServices.searchBarController,
                                      onSubmitted: (_) {
                                        context.go("/search/map");
                                        SearchPageGlobals.runSearch();
                                      },
                                      size: 16,
                                    ),
                                  ),
                                  IconButton(
                                      padding: EdgeInsets.all(10),
                                      style: IconButton.styleFrom(
                                          backgroundColor: AppColors.leveled,
                                          foregroundColor: AppColors
                                              .paleText, // Sets the color of the icon itself
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10))),
                                      onPressed: () {
                                        SearchServices.filterDropDown(context);
                                      },
                                      icon: Icon(
                                        Icons.tune,
                                        size: 30,
                                      )),
                                  SizedBox(width: 10)
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            MyTextInputWidget(
                                hint:
                                    "enter a name of street, Postcode , geographical area",
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                internalPadding: EdgeInsets.only(left: 10),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: AppColors.leveled, width: 3)),
                                height: 50,
                                fontWeight: FontWeight.w600,
                                hintFontWeight: FontWeight.w600,
                                startIcon: const Icon(
                                  color: AppColors.text,
                                  Icons.location_on_sharp,
                                  size: 25,
                                ),
                                controller:
                                    SearchServices.locationTextController,
                                onTap: () {},
                                onSubmitted: (_) {
                                  searchBarFocusNode.requestFocus();
                                },
                                size: 16),
                            FutureBuilder(
                                future: SearchServices.getIndexableSearchData(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return ValueListenableBuilder(
                                        valueListenable:
                                            SearchServices.searchBarController,
                                        builder: (_, __, ___) {
                                          final List rankedItems =
                                              SearchServices
                                                  .rankBusinessNamesAndTags(
                                                      SearchServices
                                                          .searchBarController
                                                          .text);
                                          return Expanded(
                                              child: ListView.separated(
                                            separatorBuilder: (_, __) {
                                              return const Divider(
                                                color: AppColors.leveled,
                                                height: 2,
                                                thickness: 1,
                                              );
                                            },
                                            itemBuilder: (BuildContext context,
                                                int index) {
                                              final searchItem =
                                                  rankedItems[index];
                                              return searchItem.runtimeType ==
                                                      Tag
                                                  ? ListTile(
                                                      title: MyText(
                                                        searchItem.name,
                                                        size: 15,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      textColor: AppColors.text,
                                                      leading: Image.asset(
                                                        businessIconLookup[
                                                            searchItem
                                                                .category]!,
                                                        width: 45,
                                                        height: 45,
                                                      ),
                                                      onTap: () {
                                                        if (SearchServices
                                                                .searchBarController
                                                                .text ==
                                                            searchItem.name) {
                                                          context.go(
                                                              "/search/map");
                                                          SearchPageGlobals
                                                              .runSearch();
                                                        }
                                                        SearchServices
                                                            .searchBarController
                                                            .text = searchItem.name;
                                                        // setState(() {});
                                                      })
                                                  : ListTile(
                                                      title: MyText(
                                                        "${searchItem.name} ${searchItem.address["road"] ?? searchItem.address["locality"] ?? searchItem.address["postcode"]}",
                                                        size: 15,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      textColor: AppColors.text,
                                                      leading: BaseImage(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                          width: 45,
                                                          height: 45,
                                                          url: searchItem
                                                                  .thumbnailPath ??
                                                              "No Url"),
                                                      onTap: () {
                                                        context.push(
                                                            "/business-location/${searchItem.locationId}");
                                                        // setState(() {});
                                                      });
                                            },
                                            // shrinkWrap: true,
                                            scrollDirection: Axis.vertical,
                                            itemCount: rankedItems.length,
                                          ));
                                        });
                                  } else if (snapshot.hasError) {
                                    showErrorMessage(
                                        context, snapshot.error.toString());
                                    return SizedBox();
                                  } else {
                                    return CircularProgressIndicator(
                                      color: AppColors.text,
                                    );
                                  }
                                })
                          ]),
                          Positioned(
                              bottom: 10,
                              left: MediaQuery.of(context).size.width / 8,
                              child: Material(
                                  color: AppColors.secondaryLeveled,
                                  borderRadius: BorderRadius.circular(10),
                                  clipBehavior: Clip.hardEdge,
                                  child: InkWell(
                                    splashColor: AppColors.primary,
                                    highlightColor: AppColors.primary,
                                    onTap: () {
                                      context.go("/search/map");

                                      SearchPageGlobals.runSearch();
                                    },
                                    child: const SizedBox(
                                        width: 300,
                                        height: 50,
                                        child: Center(
                                            child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                              MyText(
                                                "Go To Map",
                                                size: 20,
                                                color: AppColors.paleText,
                                              ),
                                              SizedBox(width: 10),
                                              Icon(
                                                Icons.map_rounded,
                                                size: 30,
                                                color: AppColors.paleText,
                                              )
                                            ]))),
                                  )))
                        ]))))));
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
                fontWeight: isChosen ? FontWeight.w700 : FontWeight.w600,
                textAlign: TextAlign.center,
                size: 12,
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
                padding: const EdgeInsets.all(2),
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
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
                // crossAxisAlignment: CrossAxisAlignment.center,
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      width: 200,
                      child: LabelText(
                        businessTypeLookup[SearchServices.categoryIndex.value]
                            .toString(),
                        textAlign: TextAlign.left,
                        color: AppColors.text,
                      )),
                  const SizedBox(width: 25),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                ]),
            onPressed: () {
              showOptionPicker();
            },
          );
        });
  }
}
