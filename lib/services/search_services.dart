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
      query: SearchServices.searchQuery.value,
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

  static ValueNotifier<String> searchQuery = ValueNotifier("");

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

  static final List<void Function(String)> _listeners = [];
  static void registerListener(void Function(String) listener) {
    _listeners.add(listener);
  }

  static void unregisterListener(void Function(String) listener) {
    _listeners.remove(listener);
  }

  static void updateQuery(String newQuery) {
    searchQuery.value = newQuery;
    // Forcefully update every active search bar instantly
    for (var listener in _listeners) {
      listener(newQuery);
    }
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
  const MySearchBar({super.key});

  @override
  State<MySearchBar> createState() => _MySearchBarState();
}

class _MySearchBarState extends State<MySearchBar> with RouteAware {
  // 1. Declare the controller locally inside the State class
  late final SearchController _searchController;
  final FocusNode myFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController = SearchController();
    SearchServices.registerListener((_) {
      _searchController.text = SearchServices.searchQuery.value;
    });
    _searchController.text = SearchServices.searchQuery.value;
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
    _searchController.dispose();
    myFocus.dispose();

    SearchServices.unregisterListener((_) {
      _searchController.text = SearchServices.searchQuery.value;
    });

    super.dispose();
  }

  // THIS runs automatically every time you navigate back to this screen!
  @override
  void didPopNext() {
    super.didPopNext();
    // Force sync the text controller with the latest global value
    if (_searchController.text != SearchServices.searchQuery.value) {
      _searchController.text = SearchServices.searchQuery.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(10),
        child: SearchAnchor(
          
            dividerColor: Colors.transparent,
            isFullScreen: true,
            searchController: _searchController,
            viewBackgroundColor: AppColors.leveled,
            viewOnClose: () {
              SearchServices.updateQuery(_searchController.text);
            },
            viewOnChanged: (value) {
              // SearchServices.updateQuery(_searchController.text) ;
            },
            viewOnSubmitted: (value) {
              context.go("/search/map");
              SearchServices.searchQuery.value = _searchController.text;

              SearchPageGlobals.runSearch();

              _searchController.closeView(value);
            },
            builder: (context, controller) {
              return ValueListenableBuilder(
                  valueListenable: _searchController,
                  builder: (_, __, ___) {
                    final Widget widgetOnViewBar =
                        _searchController.text.isEmpty
                            ? const Row(children: [
                                Icon(
                                  Icons.search,
                                  size: 20,
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
                                SizedBox(width: 5),
                                Flexible(
                                    child: MyText(
                                  _searchController.text,
                                  size: 15,
                                  color: AppColors.text,
                                  overflow: TextOverflow.ellipsis,
                                  maxlines: 1,
                                  textAlign: TextAlign.left,
                                )),
                                // Flexible(child: SizedBox(width: 100)),
                                SizedBox(width: 20),

                                MyText(
                                  SearchServices.locationTextController.text,
                                  size: 15,
                                  color: AppColors.highlightText,
                                  overflow: TextOverflow.ellipsis,
                                  maxlines: 1,
                                  textAlign: TextAlign.left,
                                ),
                                SizedBox(width: 10),
                              ]);

                    return Container(
                      padding: const EdgeInsets.only(left: 10, right: 30),
                      height: 40,
                      decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.secondaryLeveled, width: 2)),
                      child: widgetOnViewBar,
                    );
                  });
            },
            headerTextStyle: const TextStyle(
                color: AppColors.text,
                fontFamily: "Montserrat",
                fontWeight: FontWeight.w600),
            headerHintStyle: const TextStyle(
                color: AppColors.deselected,
                fontFamily: "Montserrat",
                fontWeight: FontWeight.w600),
            viewBuilder: (Iterable<Widget> suggestions) {
              return Container(
                  color: AppColors.background,
                  child: Column(
                    children: [
                      Padding(
                          padding: EdgeInsets.only(left: 0, right: 0),
                          child: Container(
                              height: 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(0),
                                color: AppColors.leveled,
                              ),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const SizedBox(
                                      width: 10 + 10,
                                    ),
                                    const Icon(
                                      Icons.location_on_sharp,
                                      size: 30,
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(
                                        child: HeaderInput(
                                      hint:
                                          "enter a name of street, Postcode , geographical area",
                                      fontWeight: FontWeight.w600,
                                      hintFontWeight: FontWeight.w600,
                                      controller:
                                          SearchServices.locationTextController,
                                          onTap: (){
                                            // _searchController.f
                                          },
                                      size: 16,
                                    )),
                                    const SizedBox(
                                      width: 40 + 10,
                                    ),
                                  ]))),
                      Expanded(
                        child: ListView(
                          children: suggestions.toList(),
                        ),
                      ),
                    ],
                  ));
            },
            viewHintText:
                'type of business, business name , business specialty',
            viewLeading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _searchController
                  .closeView(null), // or pass your controller reference
            ),
            viewTrailing: [
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _searchController.clear(),
              ),
            ],
            suggestionsBuilder:
                (BuildContext context, SearchController controller) {
              // Get what the user is typing
              final String query = controller.text.toLowerCase();

              final allTags = TagServices.tagLookup.values.toList();

              // Filter your data list
              final filteredList = query.isEmpty
                  ? allTags
                  : TagServices.searchSimilarTags(query, allTags);

              // Build and return the list of items shown on the full page
              return filteredList.map(
                (item) {
                  return ListTile(
                      title: MyText(
                        item.name,
                        size: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      textColor: AppColors.text,
                      leading: const Icon(
                        Icons.tag,
                        color: AppColors.secondaryText,
                      ),
                      onTap: () {
                        if (_searchController.text == item.name) {
                          _searchController.closeView(item.name);
                          context.go("/search/map");

                          SearchServices.searchQuery.value =
                              _searchController.text;

                          SearchPageGlobals.runSearch();
                        }
                        _searchController.text = item.name;

                        // setState(() {});
                      });
                },
              );
            }));
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
