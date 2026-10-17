// import 'dart:ffi';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/scheduler.dart';

import 'package:maplibre_gl/maplibre_gl.dart' as map_gl;

import 'package:nextfind/services/device_services.dart';
import 'package:nextfind/services/business_services.dart';
import 'package:nextfind/services/navbar_services.dart';
import 'package:nextfind/services/user_services.dart';
import 'package:nextfind/services/tag_services.dart';
import 'package:nextfind/services/search_services.dart';
import 'package:nextfind/services/lifecycle_services.dart';
import 'package:nextfind/widgets/main_widgets.dart';
import 'package:nextfind/widgets/business_widgets.dart';
import 'package:nextfind/models/business_models.dart';
import 'package:nextfind/helpers/logger.dart';
import 'package:nextfind/helpers/networking.dart';

List<double> nearestDistances(List<Point> points) {
  final result = List<double>.filled(points.length, 0);

  for (int i = 0; i < points.length; i++) {
    double best = double.infinity;
    final p = points[i];

    for (int j = 0; j < points.length; j++) {
      if (i == j) continue;

      final d = dist2(p, points[j]);
      if (d < best) best = d;
    }

    result[i] = best;
  }

  return result;
}

double dist2(Point a, Point b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return (dx * dx + dy * dy).toDouble();
}

Future<Uint8List> loadMarkerImage() async {
  final data = await rootBundle.load('assets/icons/Vector.png');
  return data.buffer.asUint8List();
}

List<List<double>> generateCirclePolygon(
    double lat, double lng, double radiusMeters,
    {int points = 64}) {
  const earthRadius = 6378137.0;

  final latRad = lat * (pi / 180);
  final lngRad = lng * (pi / 180);

  final coords = <List<double>>[];

  for (int i = 0; i < points; i++) {
    final angle = (i / points) * 2 * pi;

    final dx = radiusMeters * cos(angle);
    final dy = radiusMeters * sin(angle);

    final newLat = latRad + (dy / earthRadius);
    final newLng = lngRad + (dx / (earthRadius * cos(latRad)));

    coords.add([
      newLng * (180 / pi),
      newLat * (180 / pi),
    ]);
  }

  // Close polygon
  coords.add(coords.first);

  return coords;
}


enum MainSearchPageMode {map,list,choosing,thumbnail}
class SearchpageStoredData {
  static final ValueNotifier<MainSearchPageMode> mapMode = ValueNotifier(MainSearchPageMode.list);
  static final ValueNotifier<bool> shouldReloadMap = ValueNotifier(false);
}









class MapSearchView extends StatefulWidget {
  const MapSearchView(
      {super.key,
      required this.baseMiniBusinessLocationids,
      required this.isReady,
      required this.mapMode,
      required this.shouldReloadMap,
      required this.changeMapLocation,
      required this.shouldReloadMapSearchComplete,
      required this.changeMapBool,
      required this.isSafe});

  final List<String> baseMiniBusinessLocationids;
  final bool isReady;
  final ValueNotifier<String> mapMode;
  final ValueNotifier<bool> shouldReloadMap;
  final ValueNotifier<bool> isSafe;
  final ValueNotifier<List<String>> shouldReloadMapSearchComplete;
  final ValueNotifier<List<double>> changeMapLocation;
  final ValueNotifier<bool> changeMapBool;

  @override
  State<MapSearchView> createState() => _MapSearchViewState();
}

class _MapSearchViewState extends State<MapSearchView>
    with SingleTickerProviderStateMixin {
  bool _mapReady = false;
  int _frameCount = 0;
  bool _lockCamera = false;
  late final Ticker _ticker;
  String? miniBusinessId;

  void moveToNewLocation(List<double> location) {
    mapController?.animateCamera(
      map_gl.CameraUpdate.newLatLngZoom(
          map_gl.LatLng(location[0], location[1]), 16),
    );
  }

  late List<ValueNotifier<Offset>> _markerOffsets;
  late ValueNotifier<Offset> userOffset;

  late List<double> _markerDist;

  late List<map_gl.LatLng> _markerPositions;

  bool initComplete = false;

  late List<String> miniBusinessLocationids;

  late map_gl.MapLibreMapController? mapController;

  final _iconCache = <String, Widget>{};

  @override
  void initState() {
    initComplete = false;

    super.initState();

    userOffset = ValueNotifier<Offset>(Offset.zero);
    miniBusinessLocationids = widget.baseMiniBusinessLocationids;

    syncMarkers(miniBusinessLocationids);

    widget.shouldReloadMapSearchComplete.addListener(() async {
      await updatBusinessPositions(widget.shouldReloadMapSearchComplete.value);
    });

    _ticker = createTicker((_) {
      if (_mapReady && mapController != null && widget.isSafe.value) {
        scheduleMicrotask(() {
          _refreshOverlayPositions();
        }); // runs every frame
      }
    });

    widget.changeMapBool.addListener(() {
      moveToNewLocation(widget.changeMapLocation.value);
    });


    _ticker.start();

    initComplete = true;
  }

  Future<void> updatBusinessPositions(
      List<String> newMiniBusinessLocationids) async {
    log.d("SEARCHPAGELOG : UPDATING MARKER POSITIONS");
    widget.isSafe.value = false;

    miniBusinessLocationids = newMiniBusinessLocationids;

    await BusinessService.getBusinessLocationMini(miniBusinessLocationids);

    syncMarkers(miniBusinessLocationids);

    widget.isSafe.value = true;
  }

  void syncMarkers(List<String> newMiniBusinessLocationids) {
    _markerPositions = [
      for (String miniBusinessLocId in newMiniBusinessLocationids)
        map_gl.LatLng(
            BusinessService
                .miniBusinessLocLookup[miniBusinessLocId]!.location[0],
            BusinessService
                .miniBusinessLocLookup[miniBusinessLocId]!.location[1])
    ];
    if (initComplete) {
      for (final n in _markerOffsets) {
        n.dispose();
      }
    }
    _markerOffsets = List.generate(
      _markerPositions.length,
      (_) => ValueNotifier<Offset>(Offset.zero),
    );

    _markerDist = List.generate(
      _markerPositions.length,
      (_) => 1 * 10000000000,
    );
  }

  Widget getIcon(MiniBusinessLoc loc, double nearestDist, int index) {
    return _iconCache.putIfAbsent((loc.locationId, nearestDist).toString(), () {
      return createBusinessMapIcon(context, loc, nearestDist, index);
    });
  }

  @override
  void dispose() {
    for (final n in _markerOffsets) {
      n.dispose();
    }

    _ticker.stop();
    _ticker.dispose();
    _mapReady = false;
    super.dispose();
  }

  Future<void> _refreshOverlayPositions() async {
    if (_mapReady && mapController != null && widget.isSafe.value) {
      if (!lifecycle.isPaused) {
        _frameCount += 1;

        if (_frameCount > 10000) _frameCount = 0;

        if (!_mapReady || mapController == null) return;

        final points =
            await mapController!.toScreenLocationBatch(_markerPositions);

        if (mounted) {
          // try {
          final dpr = MediaQuery.of(context).devicePixelRatio;
          List<Point> dummyList = [];

          final len = min(points.length, _markerOffsets.length);

          for (int i = 0; i < len; i++) {
            final p = points[i];

            // if (i >= _markerOffsets.lenght)

            _markerOffsets[i].value = Offset(
              p.x.toDouble() / dpr,
              p.y.toDouble() / dpr,
            );

            // if (_frameCount % 4 == 0) {
            dummyList.add(Point(
              p.x.toDouble() / dpr,
              p.y.toDouble() / dpr,
            ));
            // }
          }

          final userPoint = await mapController!.toScreenLocation(map_gl.LatLng(
              UserService.userLocation[0], UserService.userLocation[1]));
          userOffset.value = Offset(
            userPoint.x.toDouble() / dpr,
            userPoint.y.toDouble() / dpr,
          );

          if (_frameCount % 10 == 0) {
            _markerDist = nearestDistances(dummyList);
          }
        }
      }
    }
  }

  void onIconClicked(MiniBusinessLoc miniBusLoc) {
    mapController?.animateCamera(
      map_gl.CameraUpdate.newLatLngZoom(
        map_gl.LatLng(miniBusLoc.location[0], miniBusLoc.location[1]),
        16.0, // zoom level
      ),
    );

    // _lockCamera = true;

    widget.mapMode.value = MainSearchPageMode.thumbnail;
    miniBusinessId = miniBusLoc.locationId;
  }

  Widget createBusinessMapIcon(BuildContext context, MiniBusinessLoc miniBusLoc,
      double nearestDist, int index) {
    double normDist = ((nearestDist) * 0.00015).clamp(0, 1);

    String iconPath = "assets/icons/svg_logo.png";
    if (miniBusLoc.type == 0) {
      iconPath = "assets/icons/business_type_icons/food_and_dining_icon.png";
    } else if (miniBusLoc.type == 1) {
      iconPath = "assets/icons/business_type_icons/home_services_icon.png";
    } else if (miniBusLoc.type == 2) {
      iconPath =
          "assets/icons/business_type_icons/health_and_wellness_icon.png";
    } else if (miniBusLoc.type == 3) {
      iconPath =
          "assets/icons/business_type_icons/shopping_and_retail_icon.png";
    } else if (miniBusLoc.type == 4) {
      iconPath =
          "assets/icons/business_type_icons/proffesional_services_icon.png";
    } else if (miniBusLoc.type == 5) {
      iconPath = "assets/icons/business_type_icons/automotive_icon.png";
    } else if (miniBusLoc.type == 6) {
      iconPath =
          "assets/icons/business_type_icons/beauty_and_personal_care_icon.png";
    } else if (miniBusLoc.type == 7) {
      iconPath =
          "assets/icons/business_type_icons/entertainment_and_leisure_icon.png";
    } else if (miniBusLoc.type == 8) {
      iconPath = "assets/icons/business_type_icons/education_icon.png";
    } else if (miniBusLoc.type == 9) {
      iconPath = "assets/icons/business_type_icons/lodging_and_travel_icon.png";
    }

    Widget trueWidget = const SizedBox();

    Widget veriBadge = const SizedBox();

    bool verified = miniBusLoc.verified;

    // verified = [
    //   'a',
    //   'b',
    //   'c',
    //   'd',
    //   'e',
    //   'f',
    //   'g',
    //   'h',
    //   'i',
    //   'j',
    //   'k',
    //   'l',
    //   'm',
    //   'n',
    //   's'
    // ].contains(miniBusLoc.name[0].toLowerCase());

    String ratingtext = "-";

    if (miniBusLoc.averageRating != null) {
      ratingtext =
          "${miniBusLoc.averageRating!.toStringAsFixed(1)}(${miniBusLoc.numRatings})";
    }

    if (index <= 3) {
      normDist += 0.2 / 2;
    } else if (index <= 10) {
      normDist += 0.1 / 2;
    }

    if (!verified) {
      normDist += 0.2 / 2;
      veriBadge = Positioned(
        right: -5,
        bottom: -5,
        child: Image.asset(
          "assets/icons/business_icons/unverified_badge_mini.png",
          width: 15,
          height: 15,
        ),
      );
    }

    if (normDist <= 0.4) {
      trueWidget = Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      );
    } else if (normDist > 0.4 && normDist <= 0.8) {
      trueWidget = Material(
        color: const Color.fromARGB(0, 163, 73, 73),
        child: InkWell(
          onTap: () {
            onIconClicked(miniBusLoc);
          },
          child: Stack(clipBehavior: Clip.none, children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  iconPath,
                  width: 32,
                  height: 32,
                ),
                Positioned(
                  right: -10 - 20,
                  top: -5,
                  child: Container(
                    width: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: AppColors.secondary,
                    ),
                    child: Center(
                      child: MyText(
                        (ratingtext).toString(),
                        size: 10,
                        color: AppColors.background,
                      ),
                    ),
                  ),
                ),
                veriBadge,
              ],
            ),
          ]),
        ),
      );
    } else {
      trueWidget = GestureDetector(
        onTap: () {
          onIconClicked(miniBusLoc);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 30,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  iconPath,
                  width: 32,
                  height: 32,
                ),
                Positioned(
                  right: -10 - 20,
                  top: -5,
                  child: Container(
                    width: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: AppColors.secondary,
                    ),
                    child: Center(
                      child: MyText(
                        (ratingtext).toString(),
                        size: 10,
                        color: AppColors.background,
                      ),
                    ),
                  ),
                ),
                veriBadge,
                Positioned(
                  left: 40,
                  top: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 0,
                      ),
                      SizedBox(
                        width: 100,
                        // height: 100,
                        child: MyText(
                          miniBusLoc.name,
                          size: 12,
                          overflow: TextOverflow.ellipsis,
                          maxlines: 1,
                        ),
                      ),
                      MyText(
                        businessTypeLookup[miniBusLoc.type]!,
                        size: 12,
                        overflow: TextOverflow.ellipsis,
                        maxlines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return trueWidget;
  }

  @override
  Widget build(BuildContext context) {
    if (!initComplete) {
      return const SizedBox();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;

        return SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            children: [
              // MAP
              map_gl.MapLibreMap(
                // styleString:
                //     "https://api.maptiler.com/maps/019fa3e4-e15f-7004-817f-b2c8f21d06d9/style.json?key=6qbiNDxrdNlr98KHQ1F9",

                styleString:
                    "https://api.maptiler.com/maps/019fa3e4-e15f-7004-817f-b2c8f21d06d9/style.json?key=6qbiNDxrdNlr98KHQ1F9",
                initialCameraPosition: map_gl.CameraPosition(
                  target: miniBusinessLocationids.isNotEmpty
                      ? map_gl.LatLng(
                          BusinessService
                              .miniBusinessLocLookup[
                                  miniBusinessLocationids[0]]!
                              .location[0],
                          BusinessService
                              .miniBusinessLocLookup[
                                  miniBusinessLocationids[0]]!
                              .location[1])
                      : map_gl.LatLng(UserService.userLocation[0],
                          UserService.userLocation[1]),
                  tilt: 60,
                  zoom: 16,
                ),
                scrollGesturesEnabled: !_lockCamera,
                zoomGesturesEnabled: !_lockCamera,
                rotateGesturesEnabled: !_lockCamera,
                tiltGesturesEnabled: !_lockCamera,
                onMapCreated: (controller) async {
                  mapController = controller;
                  // _mapReady = true;
                  await Future.delayed(const Duration(milliseconds: 200));
                  // _refreshOverlayPositions();
                },
                onStyleLoadedCallback: () async {
                  if (!lifecycle.isPaused) {
                    _mapReady = true;
                  }
                },
                onCameraMove: (cameraPosition) {},
                onMapClick: (_, map_gl.LatLng latLng) {
                  if (widget.mapMode.value == "Choosing") {
                    final tappedLat = latLng.latitude;
                    final tappedLng = latLng.longitude;

                    // Example: update your userLocation
                    UserService.userLocation = [tappedLat, tappedLng];
                    UserService.userLocation = UserService.userLocation;

                    widget.mapMode.value = "Base";
                  } else {
                    _lockCamera = false;

                    widget.mapMode.value = "Base";
                  }
                },
                onMapIdle: () {},
                compassEnabled: false,
              ),

              RepaintBoundary(
                child: ValueListenableBuilder(
                  valueListenable: widget.shouldReloadMapSearchComplete,
                  builder: (_, __, ___) {
                    if (_markerOffsets.length !=
                        miniBusinessLocationids.length) {
                      return const SizedBox();
                    }

                    return Stack(
                      // ✔ now Positioned children are legal
                      children: List.generate(miniBusinessLocationids.length,
                          (index) {
                        final miniBusLoc =
                            BusinessService.miniBusinessLocLookup[
                                miniBusinessLocationids[index]]!;

                        return ValueListenableBuilder<Offset>(
                          valueListenable: _markerOffsets[index],
                          builder: (_, offset, __) {
                            final nearestDist = _markerDist[index];

                            return Positioned(
                              left: offset.dx - 20,
                              top: offset.dy - 20,
                              child: RepaintBoundary(
                                child: getIcon(miniBusLoc, nearestDist, index),
                              ),
                            );
                          },
                        );
                      }),
                    );
                  },
                ),
              ),

              // USER LOCATION PIN
              ValueListenableBuilder(
                valueListenable: userOffset,
                builder: (_, __, ___) {
                  return Positioned(
                    left: userOffset.value.dx - 20,
                    top: userOffset.value.dy - 20,
                    child: const RepaintBoundary(
                      child: Icon(
                        Icons.location_pin,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),

              // THUMBNAIL OVERLAY
              ValueListenableBuilder<String>(
                valueListenable: widget.mapMode,
                builder: (_, choosing, __) {
                  if (choosing != "Thumbnail") return const SizedBox();
                  if (miniBusinessId == null) return const SizedBox();

                  return Positioned(
                    bottom: 40,
                    left: 20,
                    child:
                        BusinessLocationThumbnail(locationId: miniBusinessId!),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}



class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late List<String> _miniBusinessLocationids;

  bool hasMapModeValue = false;

  late final ValueNotifier<MainSearchPageMode> mapMode;
  late final ValueNotifier<bool> shouldReloadMap;
  late final ValueNotifier<List<double>> changeMapLocation;
  late final ValueNotifier<bool> changeMapBool;
  late final ValueNotifier<List<String>> shouldReloadMapSearchComplete;
  late final ValueNotifier<bool> isSafe;
  late final ValueNotifier<List<double>> userLocationForMap;

  late final ValueNotifier<bool> isRunningSearch;

  bool isReady = false;
  bool _hasWifi = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(lifecycle);

    mapMode = ValueNotifier(MainSearchPageMode.list);
    shouldReloadMap = ValueNotifier(false);
    isSafe = ValueNotifier(false);
    changeMapBool = ValueNotifier(false);
    isRunningSearch = ValueNotifier(false);
    shouldReloadMapSearchComplete = ValueNotifier([]);
    changeMapLocation = ValueNotifier(UserService.userLocation);
    userLocationForMap = ValueNotifier(UserService.userLocation);

    shouldReloadMap.addListener(() {
      if (mapMode.value != MainSearchPageMode.list) {
        _reloadMapOnly();
      }
    });

    mapMode.addListener(() {});

    _hasWifi = true;
    hasMapModeValue = true;

    _runSearchFunction();
  }

  Future<void> _reloadMapOnly() async {
    await _runSearchFunction(); // refresh business markers

    mapMode.value = MainSearchPageMode.map;
  }

  Future<void> _runSearchFunction() async {
    // Prevent overlapping searches
    if (isRunningSearch.value) return;
    isRunningSearch.value = true;

    // Pause map overlay updates
    isSafe.value = false;

    // Check connectivity (async, non-blocking)
    _hasWifi = await Networking.isOnline();

    // 1. NETWORK CALL (async, cheap)
    final ids = List<String>.from(
      await BusinessService.getNearbyBusinesses(
        location: UserService.userLocation,
        query: SearchServices.controller.text,
        maxdist: SearchServices.searchRadius,
        type: SearchServices.categoryIndex.value,
        idOnly: true,
      ),
    );

    // 2. MINI-LOCATION LOAD (async, heavy but non-blocking)
    // await BusinessService.getBusinessLocationMini(ids);

    // 3. MARKER SYNC (sync, cheap)
    _miniBusinessLocationids = ids;
    isReady = true;

    if (!mounted) return;

    // Resume map overlay updates
    isSafe.value = true;

    // Allow UI to update
    isRunningSearch.value = false;
    setState(() {});

    // Only reload map if map is visible
    if (mapMode.value != MainSearchPageMode.list) {
      shouldReloadMapSearchComplete.value = ids;
    }
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
                      isReady = false;
                      await DeviceServices.getDeviceLocation();
                      userLocationForMap.value =
                          List<double>.from(UserService.userLocation);
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
                      isReady = false;
                      mapMode.value = MainSearchPageMode.choosing;
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

  Widget buildPage(BuildContext context) {
    Widget mainSearchPageWidget = const Center(child: Heading("Loading Map..."));

    if (!_hasWifi) {
      mainSearchPageWidget = const Center(child: Heading("No Internet"));
    }

    if (isReady) {
      if (mapMode.value == MainSearchPageMode.map) {
        mainSearchPageWidget = MapSearchView(
          // key : ValueKey(_miniBusinessLocationids.toString()),
          baseMiniBusinessLocationids: _miniBusinessLocationids,
          shouldReloadMapSearchComplete: shouldReloadMapSearchComplete,
          isReady: isReady,
          mapMode: mapMode,
          userLocation: userLocationForMap,
          isSafe: isSafe,
          shouldReloadMap: shouldReloadMap,
          changeMapBool: changeMapBool,
          changeMapLocation: changeMapLocation,
        );
        // log.i("SEARCHPAGELOG : Search Hub BUILDPAGE ADDED COMPLETE");
      } else if (mapMode.value == MainSearchPageMode.list) {
        mainSearchPageWidget = ListSearchView(
            key: ValueKey([
              UserService.userLocation.toString(),
              _miniBusinessLocationids
            ]),
            miniBusinessLocationids: _miniBusinessLocationids);
      }
    }

    return Stack(
      children: [
        //Map OR List
        mainSearchPageWidget,

        //Loading Bar
        ValueListenableBuilder<bool>(
          valueListenable: isRunningSearch,
          builder: (_, choosing, __) {
            if ([MainSearchPageMode.thumbnail, MainSearchPageMode.list].contains(mapMode.value) ||
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

        //Location Popup [MAP VIEW]
        Positioned(
          bottom: 60,
          right: 10 + 70,
          child: ValueListenableBuilder<String>(
            valueListenable: mapMode,
            builder: (_, choosing, __) {
              if (["Thumbnail", "Choosing", "List"].contains(choosing)) {
                return const SizedBox(); // hide search bar
              }
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  splashColor: const Color.fromARGB(111, 252, 178, 74),
                  onTap: () {
                    locationButtonPressed();
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
              // );
            },
          ),
        ),

        //Anchor Position [MAP VIEW]
        Positioned(
            bottom: 60,
            right: 80 + 70,
            child: ValueListenableBuilder<String>(
              valueListenable: mapMode,
              builder: (_, choosing, __) {
                if (["Thumbnail", "Choosing", "List"].contains(choosing)) {
                  return const SizedBox(); // hide search bar
                }
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    splashColor: const Color.fromARGB(111, 252, 178, 74),
                    onTap: () {
                      changeMapLocation.value =
                          List<double>.from(UserService.userLocation);
                      // userLocationForMap.value =
                      //     List<double>.from(UserService.userLocation);
                      changeMapBool.value = !changeMapBool.value;
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
              },
            )),

        //Go to list View [MAP VIEW]
        Positioned(
            bottom: 60,
            right: 10,
            child: ValueListenableBuilder<String>(
              valueListenable: mapMode,
              builder: (_, choosing, __) {
                if (["Thumbnail", "Choosing", "List"].contains(choosing)) {
                  return const SizedBox(); // hide search bar
                }
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    splashColor: const Color.fromARGB(111, 252, 178, 74),
                    onTap: () {
                      mapMode.value = MainSearchPageMode.list;
                      setState(() {});
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
              },
            )),

        //Search Button [MAP VIEW]
        Positioned(
            bottom: 60,
            left: 10,
            child: ValueListenableBuilder<String>(
              valueListenable: mapMode,
              builder: (_, choosing, __) {
                if (["Thumbnail", "Choosing", "List"].contains(choosing)) {
                  return const SizedBox(); // hide search bar
                }
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    splashColor: const Color.fromARGB(111, 252, 178, 74),
                    onTap: () {
                      shouldReloadMap.value = !shouldReloadMap.value;
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
                ;
              },
            )),

        //Search Button [LIST]
        Positioned(
            bottom: 10,
            left: 10,
            child: ValueListenableBuilder<String>(
              valueListenable: mapMode,
              builder: (_, choosing, __) {
                if (["Thumbnail", "Choosing", "Base"].contains(choosing)) {
                  return const SizedBox(); // hide search bar
                }
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    splashColor: const Color.fromARGB(111, 252, 178, 74),
                    onTap: () {
                      _runSearchFunction();
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
              },
            )),

        //Go to Map [LIST]
        Positioned(
            bottom: 60 - 50,
            right: 10,
            child: ValueListenableBuilder<String>(
              valueListenable: mapMode,
              builder: (_, choosing, __) {
                if (choosing != "List")
                  return const SizedBox(); // hide search bar
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    splashColor: const Color.fromARGB(111, 252, 178, 74),
                    onTap: () {
                      mapMode.value = MainSearchPageMode.map;
                      setState(() {});
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
              },
            )),

        // Tap anywhere on the map to choose a location [Choosing VIEW]
        Positioned(
            top: 60,
            left: 10,
            child: ValueListenableBuilder<String>(
              valueListenable: mapMode,
              builder: (_, choosing, __) {
                if (choosing != "Choosing") return const SizedBox();

                return Center(
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
              },
            )),

        // Back Button [Choosing VIEW]
        Positioned(
            bottom: 10,
            left: MediaQuery.of(context).size.width / 8,
            child: ValueListenableBuilder<String>(
              valueListenable: mapMode,
              builder: (_, choosing, __) {
                if (choosing != "Choosing") return const SizedBox();

                return Center(
                    child: MyButton(
                  width: 300,
                  height: 60,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8.0),
                  child: const MyText(
                    "Back",
                    color: AppColors.background,
                  ),
                  onPressed: () {
                    mapMode.value = MainSearchPageMode.map;
                    shouldReloadMap.value = !shouldReloadMap.value;
                  },
                ));
              },
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: mapMode.value !=
           MainSearchPageMode.thumbnail, // BLOCK back button when thumbnail is showing
        onPopInvokedWithResult: (didPop, result) {
          if (mapMode.value == MainSearchPageMode.thumbnail) {
            // Custom back behaviour
            mapMode.value = MainSearchPageMode.map;

            // DO NOT allow pop
            return;
          }
        },
        child: Scaffold(
            appBar: PreferredSize(
              preferredSize: const ui.Size.fromHeight(150),
              child: ValueListenableBuilder<String>(
                valueListenable: mapMode,
                builder: (_, choosing, __) {
                  if (choosing != "List") {
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
            bottomNavigationBar: ValueListenableBuilder<String>(
              valueListenable: mapMode,
              builder: (_, choosing, __) {
                if (choosing != "List") {
                  return const SizedBox(); // hide search bar
                }
                return const NavBar(
                  currentPage: AppPages.searchpage,
                );
              },
            ),
            body: Stack(children: [
              Positioned(child: buildPage(context)),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ValueListenableBuilder<String>(
                  valueListenable: mapMode,
                  builder: (_, choosing, __) {
                    if (["Choosing", "List"].contains(choosing)) {
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
                child: ValueListenableBuilder<String>(
                  valueListenable: mapMode,
                  builder: (_, choosing, __) {
                    if (["Choosing", "List"].contains(choosing)) {
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
                child: ValueListenableBuilder<String>(
                  valueListenable: mapMode,
                  builder: (_, choosing, __) {
                    if (["Choosing", "List"].contains(choosing)) {
                      return const SizedBox(); // hide search bar
                    }
                    return SearchServices.createSearchBar(context);
                  },
                ),
              ),
            ])));
  }
}

class ListSearchView extends StatefulWidget {
  const ListSearchView({
    super.key,
    required this.miniBusinessLocationids,
  });

  final List<String> miniBusinessLocationids;
  @override
  State<ListSearchView> createState() => _ListSearchViewState();
}

class _ListSearchViewState extends State<ListSearchView> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: ListView.separated(
        controller: ScrollController(initialScrollOffset: 0),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: widget.miniBusinessLocationids.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return const SizedBox(
              height: 0,
            );
          } else {
            return Center(
                child: BusinessLocationThumbnail(
                    locationId: widget.miniBusinessLocationids[index - 1]));
          }
        },
        separatorBuilder: (context, index) => const SizedBox(height: 20),
        padding: const EdgeInsets.only(top: 20, bottom: 20),
      ),
    );
  }
}
