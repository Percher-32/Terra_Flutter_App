import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/scheduler.dart';

import 'package:maplibre_gl/maplibre_gl.dart' as map_gl;
import 'package:nextfind/services/business_services.dart';
import 'package:nextfind/services/user_services.dart';
import 'package:nextfind/services/search_services.dart';
import 'package:nextfind/services/lifecycle_services.dart';
import 'package:nextfind/widgets/main_widgets.dart';
import 'package:nextfind/widgets/business_widgets.dart';
import 'package:nextfind/models/business_models.dart';
import 'package:nextfind/helpers/logger.dart';

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

class MapSearchView extends StatefulWidget {
  const MapSearchView({super.key});

  @override
  State<MapSearchView> createState() => _MapSearchViewState();
}

class _MapSearchViewState extends State<MapSearchView>
    with SingleTickerProviderStateMixin {
  bool _mapReady = false;
  int _frameCount = 0;
  bool _lockCamera = false;
  bool initComplete = false;

  List<(MiniBusinessLoc, Offset)> markerObjects = [];
  ValueNotifier<Offset> userOffset = ValueNotifier(Offset.zero);

  List<double> markerDist = [];

  List<double> nearestDistances(List<Point> points) {
    final int length = points.length;
    final result = List<double>.filled(length, 0);

    for (int i = 0; i < length; i++) {
      double best = double.infinity;
      final p = points[i];

      for (int j = 0; j < length; j++) {
        if (i == j) continue;
        final p2 = points[j];

        final dx = p.x - p2.x;
        final dy = p.y - p2.y;
        final dx2 = dx * dx;

        if (dx2 >= best || dy >= 10 || dx >= 10) continue;

        final d = dx2 + (dy * dy);

        if (d < best) {
          best = d.toDouble();
        }
      }

      result[i] = best;
    }

    return result;
  }

  @override
  void initState() {
    initComplete = false;

    super.initState();

    //Change the map locations after the changeMapLocationTrigger is changed
    SearchPageGlobals.changeMapLocationTrigger.addListener(() {
      moveToNewLocation(SearchPageGlobals.changeMapLocationTrigger.value);
    });

    initComplete = true;
  }

  void moveToNewLocation(List<double> location) {
    // log.i("")
    SearchPageGlobals.mapController?.animateCamera(
      map_gl.CameraUpdate.newLatLngZoom(
          map_gl.LatLng(location[0], location[1]), 16),
    );
  }

  @override
  void dispose() {
    // markerObjects.dispose();

    _mapReady = false;
    super.dispose();
  }

  void scheduleRefreshTask() {
    scheduleMicrotask(() {
      log.i("RUNNING MICROTASK");
      _refreshOverlayPositions();
    }); // runs every frame
  }

  Future<void> _refreshOverlayPositions() async {
    if (_mapReady &&
        SearchPageGlobals.mapController != null &&
        !SearchPageGlobals.isLoading.value) {
      if (!lifecycle.isPaused) {
        final miniBusinessLocations =
            SearchPageGlobals.miniBusinessLocations.value;

        _frameCount += 1;

        if (_frameCount > 10000) _frameCount = 0;

        final List<map_gl.LatLng> markerPositions = [
          for (MiniBusinessLoc miniBusinessLocation in miniBusinessLocations)
            map_gl.LatLng(miniBusinessLocation.location[0],
                miniBusinessLocation.location[1])
        ];

        final points = await SearchPageGlobals.mapController!
            .toScreenLocationBatch(markerPositions);

        if (mounted) {
          // try {
          final dpr = MediaQuery.of(context).devicePixelRatio;
          final screenSize = MediaQuery.sizeOf(context);

          final double screenWidth = screenSize.width;
          final double screenHeight = screenSize.height;

          final userPoint = await SearchPageGlobals.mapController!
              .toScreenLocation(map_gl.LatLng(
                  UserService.userLocation[0], UserService.userLocation[1]));

          userOffset.value = Offset(
            userPoint.x.toDouble() / dpr,
            userPoint.y.toDouble() / dpr,
          );

          List<Point> dummyList = [];
          markerObjects = [];

          for (int i = 0; i < points.length; i++) {
            final mapPoint = points[i];

            // if (i >= _markerOffsets.lenght)
            final List position = [
              mapPoint.x.toDouble() / dpr,
              mapPoint.y.toDouble() / dpr
            ];
            final bool inView = position[0] >= -50 &&
                position[0] <= screenWidth + 50 &&
                position[1] >= -50 &&
                position[1] <= screenHeight + 50;

            if (!inView) continue;

            markerObjects.add(
                (miniBusinessLocations[i], Offset(position[0], position[1])));

            dummyList.add(Point(position[0], position[1]));
          }

          if (_frameCount % 10 == 0 ||
              markerDist.length != markerObjects.length) {
            markerDist = nearestDistances(dummyList);
          } else if (markerDist.isEmpty) {
            markerDist = List.generate(markerObjects.length, (index) => 0);
          }

          SearchPageGlobals.reloadMapPoints();
        }
      }
    }
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
                styleString:
                    "https://api.maptiler.com/maps/019fa3e4-e15f-7004-817f-b2c8f21d06d9/style.json?key=6qbiNDxrdNlr98KHQ1F9",
                initialCameraPosition: map_gl.CameraPosition(
                  target:
                      //Use the user position or the chosen location to start of with
                      SearchPageGlobals.chosenBusinessLocation != null
                          ? map_gl.LatLng(
                              SearchPageGlobals
                                  .chosenBusinessLocation!.location[0],
                              SearchPageGlobals
                                  .chosenBusinessLocation!.location[1],
                            )
                          : map_gl.LatLng(UserService.userLocation[0],
                              UserService.userLocation[1]),
                  tilt: 60,
                  zoom: 16,
                ),
                trackCameraPosition: true,
                scrollGesturesEnabled: !_lockCamera,
                zoomGesturesEnabled: !_lockCamera,
                rotateGesturesEnabled: !_lockCamera,
                tiltGesturesEnabled: !_lockCamera,
                onMapCreated: (controller) async {
                  SearchPageGlobals.mapController = controller;
                  // _mapReady = true;
                  await Future.delayed(const Duration(milliseconds: 200));
                  // _refreshOverlayPositions();
                },
                onStyleLoadedCallback: () async {
                  if (!lifecycle.isPaused) {
                    _mapReady = true;
                  }
                },
                onCameraMove: (cameraPosition) async {
                  await _refreshOverlayPositions();
                },
                onMapIdle: () async {
                  await _refreshOverlayPositions();
                },
                onMapClick: (_, map_gl.LatLng latLng) {
                  if (SearchPageGlobals.mapMode.value ==
                      MainSearchPageMode.choosing) {
                    final tappedLat = latLng.latitude;
                    final tappedLng = latLng.longitude;

                    UserService.userLocation = [tappedLat, tappedLng];
                    UserService.userLocation = UserService.userLocation;

                    SearchPageGlobals.changeMapLocation(
                        UserService.userLocation);

                    SearchPageGlobals.mapMode.value = MainSearchPageMode.map;
                  } else {
                    _lockCamera = false;

                    SearchPageGlobals.mapMode.value = MainSearchPageMode.map;
                  }
                },
                compassEnabled: false,
              ),

              //Icons
              // RepaintBoundary(
              ValueListenableBuilder(
                valueListenable: SearchPageGlobals.reloadMapPointsTrigger,
                builder: (_, __, ___) {
                  return Stack(
                    children: List.generate(markerObjects.length, (index) {
                      final markerObject = markerObjects[index];
                      final offset = markerObject.$2;
                      final miniBusinessLocation = markerObject.$1;
                      final nearestDist = markerDist[index];

                      // final dpr = MediaQuery.of(context).devicePixelRatio;

                      return Transform.translate(
                        offset: Offset(offset.dx, offset.dy),
                        child: RepaintBoundary(
                            child: BusinessMarker(
                                miniBusinessLocation: miniBusinessLocation,
                                nearestDist: nearestDist,
                                index: index)),
                      );
                    }),
                  );
                },
              ),
              // ),

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
              ValueListenableBuilder<MainSearchPageMode>(
                valueListenable: SearchPageGlobals.mapMode,
                builder: (_, choosing, __) {
                  if (choosing != MainSearchPageMode.thumbnail) {
                    return const SizedBox();
                  }
                  if (SearchPageGlobals.chosenBusinessLocation == null) {
                    return const SizedBox();
                  }

                  return Positioned(
                    bottom: 40,
                    left: 20,
                    child: BusinessLocationThumbnail(
                        locationId: SearchPageGlobals
                            .chosenBusinessLocation!.locationId),
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

class BusinessMarker extends StatelessWidget {
  const BusinessMarker(
      {super.key,
      required this.miniBusinessLocation,
      required this.nearestDist,
      required this.index});

  final MiniBusinessLoc miniBusinessLocation;
  final double nearestDist;
  final int index;

  void onIconClicked() {
    SearchPageGlobals.mapController?.animateCamera(
      map_gl.CameraUpdate.newLatLngZoom(
        map_gl.LatLng(
            miniBusinessLocation.location[0], miniBusinessLocation.location[1]),
        16.0, // zoom level
      ),
    );

    SearchPageGlobals.mapMode.value = MainSearchPageMode.thumbnail;
    SearchPageGlobals.chosenBusinessLocation = miniBusinessLocation;
  }

  @override
  Widget build(BuildContext context) {
    double normDist = ((nearestDist) * 0.00015).clamp(0, 1);

    String iconPath = "assets/icons/svg_logo.png";

    iconPath = businessIconLookup[miniBusinessLocation.type]!;

    Widget trueWidget = const SizedBox();

    Widget veriBadge = const SizedBox();

    bool verified = miniBusinessLocation.verified;

    String ratingtext = "-";

    if (miniBusinessLocation.averageRating != null) {
      ratingtext =
          "${miniBusinessLocation.averageRating!.toStringAsFixed(1)}(${miniBusinessLocation.numRatings})";
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

    // normDist = 0.5;
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
            onIconClicked();
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
          onIconClicked();
        },
        child: Row(
          // crossAxisAlignment: CrossAxisAlignment.center,
          // mainAxisAlignment: MainAxisAlignment.center,
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
                          miniBusinessLocation.name,
                          size: 12,
                          overflow: TextOverflow.ellipsis,
                          maxlines: 1,
                        ),
                      ),
                      MyText(
                        businessTypeLookup[miniBusinessLocation.type]!,
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
}
