// import 'dart:ffi';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:nextfind/networking/apiconn.dart';
import 'package:nextfind/utils/business_manager.dart';
import 'package:nextfind/utils/arbitStore.dart';
import 'package:nextfind/widgets/newwidgets.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as map_gl;
import 'package:nextfind/utils/location_manager.dart';
import 'package:nextfind/utils/life_cycle_handler.dart';
import 'package:flutter/foundation.dart';

import 'package:logger/logger.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import 'package:flutter/scheduler.dart';

import 'dart:math';
// import 'dart:typed_data';

Future<Uint8List> loadMarkerImage() async {
  final data = await rootBundle.load('assets/icons/Vector.png');
  return data.buffer.asUint8List();
}

final slog = Logger();

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
      required this.isSafe,
      required this.userLocation});

  final List<String> baseMiniBusinessLocationids;
  final bool isReady;
  final ValueNotifier<String> mapMode;
  final ValueNotifier<bool> shouldReloadMap;
  final ValueNotifier<bool> isSafe;
  final ValueNotifier<List<String>> shouldReloadMapSearchComplete;
  final ValueNotifier<List<double>> changeMapLocation;
  final ValueNotifier<bool> changeMapBool;
  final ValueNotifier<List<double>> userLocation;

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

  double _mapZoom = 16.0;
  double _mapBearing = 0.0;
  bool _radiusSourceAdded = false;

  @override
  void initState() {
    log.i("SEARCHPAGELOG : INITSTATE STARTED");
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
      log.i(
          "SEARCHPAGELOG : MOVING TO NEW LOCATION -> ${widget.changeMapLocation.value}");
      log.d(
          "SEARCHPAGELOG : MOVING TO NEW LOCATION -> ${widget.changeMapLocation.value}");
      log.t(
          "SEARCHPAGELOG : MOVING TO NEW LOCATION -> ${widget.changeMapLocation.value}");
      moveToNewLocation(widget.changeMapLocation.value);
    });

    widget.userLocation.addListener(() {
      moveToNewLocation(widget.userLocation.value);
    });

    _ticker.start();

    initComplete = true;
    log.i("SEARCHPAGELOG : INITSTATE COMPLETE");
  }

  Future<void> updatBusinessPositions(
      List<String> newMiniBusinessLocationids) async {
    log.d("SEARCHPAGELOG : UPDATING MARKER POSITIONS");
    widget.isSafe.value = false;

    miniBusinessLocationids = newMiniBusinessLocationids;

    await businessManager.getBusinessLocationMini(miniBusinessLocationids);

    syncMarkers(miniBusinessLocationids);

    widget.isSafe.value = true;
    log.i("SEARCHPAGELOG : UPDATING MARKER POSITIONS -> $_markerPositions");
    log.i("SEARCHPAGELOG : UPDATING MARKER OFFSTES -> $_markerOffsets");
    log.i("SEARCHPAGELOG : UPDATING MARKER OFFSTES -> $_markerDist");

    log.i("SEARCHPAGELOG : UPDATING MARKER POSITIONS END");
  }

  void syncMarkers(List<String> newMiniBusinessLocationids) {
    _markerPositions = [
      for (String miniBusinessLocId in newMiniBusinessLocationids)
        map_gl.LatLng(
            businessManager
                .miniBusinessLocLookup[miniBusinessLocId]!.location[0],
            businessManager
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
              widget.userLocation.value[0], widget.userLocation.value[1]));
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

    widget.mapMode.value = "Thumbnail";
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

    if (verified) {
      normDist += 0.2 / 2;
      veriBadge = Positioned(
          right: -5,
          bottom: -5,
          child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color.fromARGB(255, 0, 255, 110)),
              child: const Center(
                  child: Icon(
                Icons.check,
                color: Colors.white,
                size: 12,
                weight: 400,
                fontWeight: FontWeight.w900,
              ))));
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
    log.i("SEARCHPAGELOG : BUILDPAGERUNNING -> INITCOMPLETE -> $initComplete");

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
                          businessManager
                              .miniBusinessLocLookup[
                                  miniBusinessLocationids[0]]!
                              .location[0],
                          businessManager
                              .miniBusinessLocLookup[
                                  miniBusinessLocationids[0]]!
                              .location[1])
                      : map_gl.LatLng(arbitStore.data["userLocation"][0],
                          arbitStore.data["userLocation"][1]),
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
                onCameraMove: (cameraPosition) {
                  _mapZoom = cameraPosition.zoom;
                  _mapBearing = cameraPosition.bearing;
                },
                onMapClick: (_, map_gl.LatLng latLng) {
                  log.i("SEARCHPAGELOG : MAP TAPPED");
                  if (widget.mapMode.value == "Choosing") {
                    final tappedLat = latLng.latitude;
                    final tappedLng = latLng.longitude;

                    // Example: update your userLocation
                    arbitStore.data["userLocation"] = [tappedLat, tappedLng];
                    widget.userLocation.value = arbitStore.data["userLocation"];

                    log.i("SEARCHPAGELOG : MAP TAPPED RELOADING MARKERS");

                    widget.mapMode.value = "Base";
                  } else {
                    _lockCamera = false;

                    widget.mapMode.value = "Base";
                  }
                },
                onMapIdle: () {},
                compassEnabled: false,
              ),

              // OVERLAY (same size as map)
              RepaintBoundary(
                child: ValueListenableBuilder(
                  valueListenable: widget.shouldReloadMapSearchComplete,
                  builder: (_, __, ___) {
                    log.d("SEARCHPAGELOG : VALUELISTENABLE RELOAD HIT");
                    log.d("SEARCHPAGELOG : markerPos -> $_markerPositions");
                    log.d("SEARCHPAGELOG : markerOff -> $_markerOffsets");
                    log.d("SEARCHPAGELOG : markerDist -> $_markerDist");

                    // Safety check: only build overlay if lists are synced
                    if (_markerOffsets.length !=
                        miniBusinessLocationids.length) {
                      return const SizedBox();
                    }

                    return Positioned(
                      left: 0,
                      top: 0,
                      width: size.width,
                      height: size.height,
                      child: Stack(
                        children: List.generate(miniBusinessLocationids.length,
                            (index) {
                          final miniBusLoc =
                              businessManager.miniBusinessLocLookup[
                                  miniBusinessLocationids[index]]!;

                          return ValueListenableBuilder<Offset>(
                            valueListenable: _markerOffsets[index],
                            builder: (_, offset, __) {
                              final nearestDist = _markerDist[index];

                              return Positioned(
                                left: offset.dx - 20,
                                top: offset.dy - 20,
                                child: RepaintBoundary(
                                  child:
                                      getIcon(miniBusLoc, nearestDist, index),
                                ),
                              );
                            },
                          );
                        }),
                      ),
                    );
                  },
                ),
              ),

              // RepaintBoundary(
              ValueListenableBuilder(
                valueListenable: userOffset,
                builder: (_, __, ___) {
                  log.i("REBUILDING THE POSITION");
                  return Positioned(
                      left: 0,
                      top: 0,
                      width: size.width,
                      height: size.height,
                      child: Positioned(
                        left: userOffset.value.dx - 20,
                        top: userOffset.value.dy - 20,
                        child: const RepaintBoundary(
                            child: Icon(
                          Icons.location_pin,
                          color: AppColors.primary,
                          size: 40,
                        )),
                      ));
                },
              ),
              // ),

              //Thumbnial Overlay
              ValueListenableBuilder<String>(
                valueListenable: widget.mapMode,
                builder: (_, choosing, __) {
                  if (choosing != "Thumbnail") return const SizedBox();
                  if (miniBusinessId == null) return const SizedBox();
                  return Positioned(
                      bottom: 40,
                      left: 20,
                      child: BusinessLocationThumbnail(
                          locationId: miniBusinessId!));
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

  // log.i("SEARCHPAGELOG : INIT STATE RAN");
  late final ValueNotifier<String> mapMode;
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
    log.i("SEARCHPAGELOG : INIT STATE RAN");

    super.initState();
    WidgetsBinding.instance.addObserver(lifecycle);

    mapMode = ValueNotifier("List");
    shouldReloadMap = ValueNotifier(false);
    isSafe = ValueNotifier(false);
    changeMapBool = ValueNotifier(false);
    isRunningSearch = ValueNotifier(false);
    shouldReloadMapSearchComplete = ValueNotifier([]);
    changeMapLocation = ValueNotifier(arbitStore.data["userLocation"]);
    userLocationForMap = ValueNotifier(arbitStore.data["userLocation"]);

    log.i("SEARCHPAGELOG : INIT STATE LATE INITIALISED");

    shouldReloadMap.addListener(() {
      log.i("SEARCHPAGELOG : Should RELOADING MAP");
      if (mapMode.value != "List") {
        _reloadMapOnly();
      }
    });

    mapMode.addListener(() {
      log.i("SEARCHPAGELOG : mapMode set to ${mapMode.value}");
    });

    _hasWifi = true;
    hasMapModeValue = true;

    _runSearchFunction();
  }

  Future<void> _reloadMapOnly() async {
    log.i("SEARCHPAGELOG : RELOAD MAP - START");
    await _runSearchFunction(); // refresh business markers
    log.i("SEARCHPAGELOG : RELOAD MAP - END");

    mapMode.value = "Base";
  }

  Future<void> _runSearchFunction() async {
    log.i("SEARCHPAGELOG : RUNNING SEARCH START");

    // Prevent overlapping searches
    if (isRunningSearch.value) return;
    isRunningSearch.value = true;

    // Pause map overlay updates
    isSafe.value = false;

    // Check connectivity (async, non-blocking)
    _hasWifi = await serverconnect.isOnline();

    // 1. NETWORK CALL (async, cheap)
    final ids = List<String>.from(
      await serverconnect.getNearbyBusinesses(
        location: arbitStore.data["userLocation"],
        query: SearchBarController.controller.text,
        elecSafeOnly: arbitStore.data["electricitySafeOnly"],
        gasSafeOnly: arbitStore.data["gasSafeOnly"],
        maxdist: arbitStore.data["distance"],
        type: arbitStore.data["categoryINDEX"],
        idOnly: true,
      ),
    );

    // 2. MINI-LOCATION LOAD (async, heavy but non-blocking)
    await businessManager.getBusinessLocationMini(ids);

    // 3. MARKER SYNC (sync, cheap)
    _miniBusinessLocationids = ids;
    isReady = true;

    if (!mounted) return;

    // Resume map overlay updates
    isSafe.value = true;

    // Allow UI to update
    isRunningSearch.value = false;
    setState(() {});

    log.i("SEARCHPAGELOG : RUNNING SEARCH END");

    // Only reload map if map is visible
    if (mapMode.value != "List") {
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
                      await getLocation();
                      log.i("PLAX : GOTTEN USER LOCATION");
                      userLocationForMap.value =
                          List<double>.from(arbitStore.data["userLocation"]);
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
                      mapMode.value = "Choosing";
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
    log.i("SEARCHPAGELOG : Search Hub BUILDPAGE RAN");
    Widget mapViewWidget = const Center(child: Heading("Loading Map..."));

    if (!_hasWifi) {
      mapViewWidget = const Center(child: Heading("No Internet"));
    }

    log.i("SEARCHPAGELOG : Search Hub  MAP RELOAD OCCURING");
    if (isReady) {
      if (mapMode.value == "Base") {
        log.i("SEARCHPAGELOG : Search Hub BUILDPAGE ADDED MAP ");
        mapViewWidget = MapSearchView(
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
        log.i("SEARCHPAGELOG : Search Hub BUILDPAGE ADDED COMPLETE");
      } else if (mapMode.value == "List") {
        mapViewWidget = ListSearchView(
            key: ValueKey([
              arbitStore.data["userLocation"].toString(),
              _miniBusinessLocationids
            ]),
            miniBusinessLocationids: _miniBusinessLocationids);
      }
    }

    final suppposedMap = mapViewWidget;

    return Stack(
      children: [
        //Map OR List
        suppposedMap,

        //Location Popup [MAP]
        ValueListenableBuilder<String>(
          valueListenable: mapMode,
          builder: (_, choosing, __) {
            if (["Thumbnail", "Choosing", "List"].contains(choosing))
              return const SizedBox(); // hide search bar
            return Positioned(
              bottom: 60,
              right: 10 + 70,
              child: Material(
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
              ),
            );
          },
        ),

        //Anchor Position [MAP]
        ValueListenableBuilder<String>(
          valueListenable: mapMode,
          builder: (_, choosing, __) {
            if (["Thumbnail", "Choosing", "List"].contains(choosing))
              return const SizedBox(); // hide search bar
            return Positioned(
              bottom: 60,
              right: 80 + 70,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  splashColor: const Color.fromARGB(111, 252, 178, 74),
                  onTap: () {
                    changeMapLocation.value =
                        List<double>.from(arbitStore.data["userLocation"]);
                    // userLocationForMap.value =
                    //     List<double>.from(arbitStore.data["userLocation"]);
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
              ),
            );
          },
        ),

        //Go to list View [MAP]
        ValueListenableBuilder<String>(
          valueListenable: mapMode,
          builder: (_, choosing, __) {
            if (["Thumbnail", "Choosing", "List"].contains(choosing)) {
              return const SizedBox(); // hide search bar
            }
            return Positioned(
              bottom: 60,
              right: 10,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  splashColor: const Color.fromARGB(111, 252, 178, 74),
                  onTap: () {
                    mapMode.value = "List";
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
              ),
            );
          },
        ),

        //Search Button [MAP]
        ValueListenableBuilder<String>(
          valueListenable: mapMode,
          builder: (_, choosing, __) {
            if (["Thumbnail", "Choosing", "List"].contains(choosing)) {
              return const SizedBox(); // hide search bar
            }
            return Positioned(
              bottom: 60,
              left: 10,
              child: Material(
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
              ),
            );
          },
        ),

        //Loading Bar
        ValueListenableBuilder<bool>(
          valueListenable: isRunningSearch,
          builder: (_, choosing, __) {
            if (["Thumbnail", "Choosing"].contains(mapMode.value) ||
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

        //Search Button [LIST]
        ValueListenableBuilder<String>(
          valueListenable: mapMode,
          builder: (_, choosing, __) {
            if (["Thumbnail", "Choosing", "Base"].contains(choosing)) {
              return const SizedBox(); // hide search bar
            }
            return Positioned(
              bottom: 10,
              left: 10,
              child: Material(
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
              ),
            );
          },
        ),

        //Go to Map [LIST]
        ValueListenableBuilder<String>(
          valueListenable: mapMode,
          builder: (_, choosing, __) {
            if (choosing != "List") return const SizedBox(); // hide search bar
            return Positioned(
              bottom: 60 - 50,
              right: 10,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  splashColor: const Color.fromARGB(111, 252, 178, 74),
                  onTap: () {
                    mapMode.value = "Base";
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
              ),
            );
          },
        ),

        // Tap anywhere on the map to choose a location [Choosing]
        ValueListenableBuilder<String>(
          valueListenable: mapMode,
          builder: (_, choosing, __) {
            if (choosing != "Choosing") return const SizedBox();

            return Positioned(
                top: 60,
                left: 10,
                child: Center(
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
                        )))));
          },
        ),

        // Back Button [Choosing]
        ValueListenableBuilder<String>(
          valueListenable: mapMode,
          builder: (_, choosing, __) {
            if (choosing != "Choosing") return const SizedBox();

            return Positioned(
                bottom: 10,
                left: MediaQuery.of(context).size.width / 8,
                child: Center(
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
                    mapMode.value = "Base";
                    shouldReloadMap.value = !shouldReloadMap.value;
                  },
                )));
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    log.i("SEARCHPAGELOG : RUNNING BUILD FUNCTION");

    log.i("SEARCHPAGELOG : mapModeFound $hasMapModeValue");
    log.i("SEARCHPAGELOG : RUNNING BUILD FUNCTION -> HAS MADMODE VALUE");
    return PopScope(
        canPop: mapMode.value !=
            "Thumbnail", // BLOCK back when thumbnail is showing
        onPopInvokedWithResult: (didPop, result) {
          if (mapMode.value == "Thumbnail") {
            // Custom back behaviour
            mapMode.value = "Base";

            // DO NOT allow pop
            return;
          }

          // If didPop == true → the page already popped
          // If didPop == false → canPop prevented the pop
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
                      SearchBarController.createSearchBar(context),
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: TagController.showChosenTagWidget(context))
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
                return Positioned(child: newbottombar(context, index: 0));
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
                    return Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: newbottombar(context, index: 0));
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
                    return Positioned(
                        left: 0,
                        right: 0,
                        top: 120,
                        child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: TagController.showChosenTagWidget(context,
                                leveled: false)));
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
                    return Positioned(
                        child: SearchBarController.createSearchBar(context));
                  },
                ),
              ),
            ])));

    // return;
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
