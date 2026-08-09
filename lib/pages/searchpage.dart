import 'package:flutter/material.dart';
import 'package:nextfind/networking/apiconn.dart';
import 'package:nextfind/utils/businessManager.dart';
import 'package:nextfind/utils/arbitStore.dart';
import 'package:nextfind/widgets/newwidgets.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as map_gl;
import 'package:nextfind/utils/locationmanager.dart';
import 'package:nextfind/utils/life_cycle_handler.dart';

import 'package:logger/logger.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import 'package:flutter/scheduler.dart';

import 'dart:math';
import 'dart:typed_data';

map_gl.MapLibreMapController? _mapController;

ValueNotifier<String> mapMode = ValueNotifier("Base");
// ValueNotifier<bool> _isShowingThumbnail = ValueNotifier(false);
// ValueNotifier<bool> isCheckingForTap = ValueNotifier(false);
// final ValueNotifier<bool> cleanUi = ValueNotifier(false);
ValueNotifier<bool> shouldReloadMarkers = ValueNotifier(false);

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
      required this.miniBusinessLocationids,
      required this.isReady});

  final List<String> miniBusinessLocationids;
  final bool isReady;

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

  // List.generate(30, (index) {
  //   final int row = index ~/ 20;
  //   final int col = index % 20;
  //   final double minLat = 53.744 + 0.001;
  //   final double maxLat = 53.744 - 0.001;
  //   final double minLng = -0.335 + 0.001;
  //   final double maxLng = -0.335 - 0.001;
  //   final double lat = minLat + (col / 19) * (maxLat - minLat);
  //   final double lng = minLng + (row / 9) * (maxLng - minLng);
  //   return map_gl.LatLng(lat, lng);
  // });

  void moveToNewLocation(List location) {
    _mapController?.animateCamera(
      map_gl.CameraUpdate.newLatLng(
        map_gl.LatLng(location[0], location[1]),
      ),
    );
  }

  late final List<ValueNotifier<Offset>> _markerOffsets;

  late List<double> _markerDist;

  late List<map_gl.LatLng> _markerPositions;

  double _mapZoom = 16.0;
  double _mapBearing = 0.0;
  bool _radiusSourceAdded = false;

  @override
  void initState() {
    super.initState();

    _markerPositions = [
      for (String miniBusinessLocId in widget.miniBusinessLocationids)
        map_gl.LatLng(
            businessManager
                .miniBusinessLocLookup[miniBusinessLocId]!.location[0],
            businessManager
                .miniBusinessLocLookup[miniBusinessLocId]!.location[1])
    ];

    _markerDist = List.generate(
      _markerPositions.length,
      (_) => 100,
    );

    _markerOffsets = List.generate(
      _markerPositions.length,
      (_) => ValueNotifier<Offset>(Offset.zero),
    );

    _ticker = createTicker((_) {
      if (_mapReady && _mapController != null) {
        _refreshOverlayPositions(); // runs every frame
      }
    });

    _ticker.start();
  }

  @override
  void dispose() {
    for (final n in _markerOffsets) {
      n.dispose();
    }

    _ticker.stop();
    _ticker.dispose();
    super.dispose();
  }

  Future<void> _refreshOverlayPositions() async {
    if (_mapReady && _mapController != null) {
      if (!lifecycle.isPaused) {
        _frameCount += 1;

        if (_frameCount > 10000) _frameCount = 0;

        if (!_mapReady || _mapController == null) return;

        final points =
            await _mapController!.toScreenLocationBatch(_markerPositions);

        if (mounted) {
          final dpr = MediaQuery.of(context).devicePixelRatio;
          List<Point> dummyList = [];

          for (int i = 0; i < points.length; i++) {
            final p = points[i];
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

          if (_frameCount % 10 == 0) {
            _markerDist = nearestDistances(dummyList);
            // log.i("FRM : AAAAAAAAAAAAAAAAAAAAHHHHHHHHHHHHHHHH");
          }
        }
      }
    }
  }

  void onIconClicked(MiniBusinessLoc miniBusLoc) {
    _mapController?.animateCamera(
      map_gl.CameraUpdate.newLatLngZoom(
        map_gl.LatLng(miniBusLoc.location[0], miniBusLoc.location[1]),
        16.0, // zoom level
      ),
    );

    // _lockCamera = true;

    mapMode.value = "Thumbnail";
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

    verified = [
      'a',
      'b',
      'c',
      'd',
      'e',
      'f',
      'g',
      'h',
      'i',
      'j',
      'k',
      'l',
      'm',
      'n',
      's'
    ].contains(miniBusLoc.name[0].toLowerCase());

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
                    "https://api.maptiler.com/maps/streets/style.json?key=6qbiNDxrdNlr98KHQ1F9",
                initialCameraPosition: map_gl.CameraPosition(
                  target: map_gl.LatLng(arbitStore.data["userLocation"][0],
                      arbitStore.data["userLocation"][1]),
                  tilt: 60,
                  zoom: 16,
                ),

                scrollGesturesEnabled: !_lockCamera,
                zoomGesturesEnabled: !_lockCamera,
                rotateGesturesEnabled: !_lockCamera,
                tiltGesturesEnabled: !_lockCamera,
                onMapCreated: (controller) async {
                  _mapController = controller;
                  // _mapReady = true;

                  // _refreshOverlayPositions();
                },
                onStyleLoadedCallback: () async {
                  if (!lifecycle.isPaused) {
                    _mapReady = true;

                    // await _addSearchRadiusPolygon();

                    if (_radiusSourceAdded) {
                      // _refreshOverlayPositions();
                      return;
                    }

                    // final polygon = generateCirclePolygon(
                    //   53.7443,
                    //   -0.33515,
                    //   100,
                    // );
                    log.i(
                        "PLAX : BUILD MAP ULOC -> ${arbitStore.data["userLocation"]}");
                    _mapController!.addCircle(
                      map_gl.CircleOptions(
                        geometry: map_gl.LatLng(
                            arbitStore.data["userLocation"][0],
                            arbitStore.data["userLocation"][1]),
                        circleRadius: 13.0,
                        circleColor: AppColors.primary.toHexStringRGB(),
                        circleOpacity: 1,
                      ),
                    );

                    _mapController!.addCircle(
                      map_gl.CircleOptions(
                        geometry: map_gl.LatLng(
                            arbitStore.data["userLocation"][0],
                            arbitStore.data["userLocation"][1]),
                        circleRadius: 7.0,
                        circleColor: AppColors.background.toHexStringRGB(),
                        circleOpacity: 1,
                      ),
                    );

                    // await _mapController!.addSource(
                    //   "search-radius-source",
                    //   map_gl.GeojsonSourceProperties(
                    //     data: {
                    //       "type": "Feature",
                    //       "geometry": {
                    //         "type": "Polygon",
                    //         "coordinates": [polygon],
                    //       }
                    //     },
                    //   ),
                    // );

                    // await _mapController!.addLayer(
                    //   "search-radius-source",
                    //   "search-radius-layer",
                    //   const map_gl.FillLayerProperties(
                    //     fillColor: "#296CA8",
                    //     fillOpacity: 0.2,
                    //     fillOutlineColor: "#296CA8",
                    //   ),
                    // );

                    _radiusSourceAdded = true;
                  }
                  // _refreshOverlayPositions();
                },
                onCameraMove: (cameraPosition) {
                  _mapZoom = cameraPosition.zoom;
                  _mapBearing = cameraPosition.bearing;
                  _refreshOverlayPositions();
                },
                onMapClick: (_, map_gl.LatLng latLng) {
                  if (mapMode.value == "Choosing") {
                    final tappedLat = latLng.latitude;
                    final tappedLng = latLng.longitude;

                    // Example: update your userLocation
                    arbitStore.data["userLocation"] = [tappedLat, tappedLng];

                    log.i("ABABAABABABAB");
                    shouldReloadMarkers.value = true;

                    mapMode.value = "Base";
                  } else {
                    _lockCamera = false;

                    mapMode.value = "Base";
                  }
                },
                onMapIdle: () {
                  _refreshOverlayPositions();
                },
                compassEnabled: false,
              ),

              // OVERLAY (same size as map)
              Positioned(
                left: 0,
                top: 0,
                width: size.width,
                height: size.height,
                child: Stack(
                  children: List.generate(widget.miniBusinessLocationids.length,
                      (index) {
                    MiniBusinessLoc miniBusLoc =
                        businessManager.miniBusinessLocLookup[
                            widget.miniBusinessLocationids[index]]!;

                    return ValueListenableBuilder<Offset>(
                      valueListenable: _markerOffsets[index],
                      builder: (_, offset, __) {
                        final dynamicSize = (40.0 * (16.0 / max(_mapZoom, 1.0)))
                            .clamp(20.0, 60.0);

                        final nearestDist = _markerDist[index];

                        return Positioned(
                          left: offset.dx - 20,
                          top: offset.dy - 20,
                          child: RepaintBoundary(
                            child: Transform.rotate(
                              angle: _mapBearing * pi / 180,
                              child: Transform.scale(
                                scale: 16.0 / max(_mapZoom, 1.0),
                                child: createBusinessMapIcon(
                                    context, miniBusLoc, nearestDist, index),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),

              ValueListenableBuilder<String>(
                valueListenable: mapMode,
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
  bool isReady = false;
  bool _hasWifi = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(lifecycle);
    shouldReloadMarkers.addListener(() {
      if (shouldReloadMarkers.value) {
        _reloadMapOnly();
        shouldReloadMarkers.value = false;
      }
    });

    _hasWifi = true;

    // isCheckingForTap.addListener(_updateHideState);
    // isCheckingForTap.addListener(() {
    //   _isShowingThumbnail.value = false;
    // });
    // _isShowingThumbnail.addListener(_updateHideState);

    _getLocations();
  }

  // void _updateHideState() {
  //   cleanUi.value = isCheckingForTap.value || _isShowingThumbnail.value;
  // }

  Future<void> _reloadMapOnly() async {
    log.i("ABABAABABABAB : reloading map");
    await _getLocations(); // refresh business markers

    log.i("ABABAABABABAB : reloading Done");
    mapMode.value = "Base";
  }

  Future<void> _getLocations() async {
    _hasWifi = await serverconnect.isOnline();

    _miniBusinessLocationids =
        List<String>.from(await serverconnect.getNearbyBusinesses(
      location: arbitStore.data["userLocation"],
      query: searchBarTextController.text,
      elecSafeOnly: arbitStore.data["electricitySafeOnly"],
      gasSafeOnly: arbitStore.data["gasSafeOnly"],
      maxdist: arbitStore.data["distance"],
      type: arbitStore.data["categoryINDEX"],
      idOnly: true,
    ));

    await businessManager.getBusinessLocationMini(_miniBusinessLocationids);

    isReady = true;

    if (!mounted) return;
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
                    width: 50,
                    height: 80,
                    onPressed: () async {
                      isReady = false;
                      await getLocation();
                      log.i("PLAX : GOTTEN USER LOCATION");
                      await _reloadMapOnly();
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
                    width: 50,
                    height: 80,
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
    Widget suppposedMap = const Center(child: Heading("Loading Map..."));

    if (!_hasWifi) {
      suppposedMap = const Center(child: Heading("No Internet"));
    }

    if (isReady) {
      if (mapMode.value == "Base") {
        suppposedMap = MapSearchView(
          key: ValueKey(arbitStore.data["userLocation"].toString()),
          miniBusinessLocationids: _miniBusinessLocationids,
          isReady: isReady,
        );
      } else if (mapMode.value == "List") {
        suppposedMap = ListSearchView(
            key: ValueKey(arbitStore.data["userLocation"].toString()),
            miniBusinessLocationids: _miniBusinessLocationids);
      }
    }

    return Stack(
      children: [
        suppposedMap,
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
                    _mapController?.animateCamera(
                      map_gl.CameraUpdate.newLatLngZoom(
                        map_gl.LatLng(arbitStore.data["userLocation"][0],
                            arbitStore.data["userLocation"][1]),
                        16.0, // zoom level
                      ),
                    );
                    ;
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
        ValueListenableBuilder<String>(
          valueListenable: mapMode,
          builder: (_, choosing, __) {
            if (choosing != "Choosing") return const SizedBox();

            return Positioned(
                bottom: 10,
                left: MediaQuery.of(context).size.width / 8,
                child: Center(
                    child: MyButton(
                  width: 20,
                  height: 40,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8.0),
                  child: const MyText(
                    "Back",
                    color: AppColors.background,
                  ),
                  onPressed: () {
                    mapMode.value = "Base";
                  },
                )));
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
                preferredSize: const Size.fromHeight(84),
                child: Positioned(
                  child: ValueListenableBuilder<String>(
                    valueListenable: mapMode,
                    builder: (_, choosing, __) {
                      if (choosing != "List") {
                        return const SizedBox(); // hide search bar
                      }
                      return Positioned(child: newsearchbar(context));
                    },
                  ),
                )),
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
                child: ValueListenableBuilder<String>(
                  valueListenable: mapMode,
                  builder: (_, choosing, __) {
                    if (["Choosing", "List"].contains(choosing)) {
                      return const SizedBox(); // hide search bar
                    }
                    return Positioned(child: newsearchbar(context));
                  },
                ),
              ),
            ])));

    // return;
  }
}

class ListSearchView extends StatefulWidget {
  const ListSearchView({super.key, required this.miniBusinessLocationids});

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
