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
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

import 'package:flutter/services.dart';
import 'dart:ui' as ui;

Future<void> loadAndRegisterWidgetIcon(
  BuildContext context,
  Widget widget,
  String customId,
) async {
  final GlobalKey repaintKey = GlobalKey();

  // 1. Temporarily mount the widget off-screen so Flutter can layout & paint it
  late OverlayEntry overlayEntry;
  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      left: -9999,
      top: -9999,
      child: Material(
        color: Colors.transparent,
        child: RepaintBoundary(
          key: repaintKey,
          child: widget,
        ),
      ),
    ),
  );

  Overlay.of(context).insert(overlayEntry);

  // Wait for the next frame so the widget is fully rendered
  await WidgetsBinding.instance.endOfFrame;

  try {
    // 2. Capture the rendered boundary into raw PNG bytes
    final RenderRepaintBoundary? boundary =
        repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (boundary != null) {
      final ui.Image image =
          await boundary.toImage(pixelRatio: 2.0); // 2.0 for sharp text
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List? list = byteData?.buffer.asUint8List();

      if (list != null) {
        // 3. Register it into MapLibre's style memory with your custom ID string
        await SearchPageGlobals.mapController?.addImage(customId, list);
      }
    }
  } finally {
    // 4. Always remove the temporary overlay entry when finished
    overlayEntry.remove();
  }
}

Future<void> loadAndRegisterAssetIcon(MiniBusinessLoc miniBusinessLoc) async {
  // 1. Load the image bytes from your assets folder
  final ByteData bytes =
      await rootBundle.load(businessIconLookup[miniBusinessLoc.type]!);
  final Uint8List list = bytes.buffer.asUint8List();

  // 2. Register it into MapLibre's style memory with a unique name
  await SearchPageGlobals.mapController
      ?.addImage('MARKERIMAGE${miniBusinessLoc.type}', list);
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

  late Ticker _ticker;

  List<(MiniBusinessLoc, Offset)> markerObjects = [];
  ValueNotifier<Offset> userOffset = ValueNotifier(Offset.zero);

  List<double> markerDist = [];

  Future<void> addIconMarkerToMap(MiniBusinessLoc miniBusinessLoc) async {
    await SearchPageGlobals.mapController?.addSymbol(
      map_gl.SymbolOptions(
        geometry: map_gl.LatLng(
            miniBusinessLoc.location[0], miniBusinessLoc.location[1]),
        iconImage:
            'BUSINESSMARKER${miniBusinessLoc.name}', // Matches the key registered above
        iconSize: 1.0, // Scale the icon if needed
        iconAnchor: 'bottom', // Anchors the bottom of the pin to the coordinate
      ),
    );
  }

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

        if (dx2 >= best || dy >= 100 || dx >= 100) continue;

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

    SearchPageGlobals.miniBusinessLocations.addListener(() async {
      await SearchPageGlobals.mapController?.clearSymbols();
      int index = 0;
      for (final miniBusLoc in SearchPageGlobals.miniBusinessLocations.value) {
        // SearchPageGlobals.mapController?.removeSymbol(symbol);
        if (!mounted) return;
        await loadAndRegisterWidgetIcon(
            context,
            BusinessMarker(
                miniBusinessLocation: miniBusLoc,
                nearestDist: double.infinity,
                index: index),
            "BUSINESSMARKER${miniBusLoc.name}");
        await addIconMarkerToMap(miniBusLoc);

        index += 1;
      }
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
    // return;
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

        List<Point> listOffALlPoints = [];

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
          return;
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

            listOffALlPoints.add(Point(position[0], position[1]));
          }
          markerDist = nearestDistances(listOffALlPoints);
          // markerDist = List.filled(markerDist.length, 0);

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
                  // await _refreshOverlayPositions();
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

              // Icons
              // ValueListenableBuilder(
              //   valueListenable: SearchPageGlobals.reloadMapPointsTrigger,
              //   builder: (_, __, ___) {
              //     return Stack(
              //       children: List.generate(markerObjects.length, (index) {
              //         final markerObject = markerObjects[index];
              //         final offset = markerObject.$2;
              //         final miniBusinessLocation = markerObject.$1;
              //         final nearestDist = markerDist[index];

              //         // final dpr = MediaQuery.of(context).devicePixelRatio;

              //         return Transform.translate(
              //           offset: Offset(offset.dx, offset.dy),
              //           child: RepaintBoundary(
              //               child: BusinessMarker(
              //                   miniBusinessLocation: miniBusinessLocation,
              //                   nearestDist: nearestDist,
              //                   index: index)),
              //         );
              //       }),
              //     );
              //   },
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
  const BusinessMarker({
    super.key,
    required this.miniBusinessLocation,
    required this.nearestDist,
    required this.index,
  });

  final MiniBusinessLoc miniBusinessLocation;
  final double nearestDist;
  final int index;

  @override
  Widget build(BuildContext context) {
    double normDist = ((nearestDist) * 0.00015).clamp(0, 1);
    String iconPath = businessIconLookup[miniBusinessLocation.type] ??
        "assets/icons/svg_logo.png";
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

    Widget veriBadge = verified
        ? const SizedBox.shrink()
        : Image.asset("assets/icons/business_icons/unverified_badge_mini.png",
            width: 15, height: 15);

    // Tier 1: Distance Dot
    if (normDist <= 0.4) {
      return Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      );
    }

    // Tier 2 & 3: Rich Icon + Text Card (Using Row/Column to prevent clipping)
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon & Rating Stack
          Stack(
            clipBehavior: Clip.none,
            children: [
              Image.asset(
                iconPath,
                width: 32,
                height: 32,
                cacheWidth: 64,
                cacheHeight: 64,
              ),
              Positioned(
                right: -15,
                top: -8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.secondary,
                  ),
                  child: MyText(
                    ratingtext,
                    size: 9,
                    color: AppColors.background,
                  ),
                ),
              ),
            ],
          ),

          if (normDist > 0.9) ...[
            const SizedBox(width: 8),
            // Text Details
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 100,
                  child: MyText(
                    miniBusinessLocation.name,
                    size: 12,
                    overflow: TextOverflow.ellipsis,
                    maxlines: 1,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: MyText(
                    businessTypeLookup[miniBusinessLocation.type] ?? '',
                    size: 10,
                    overflow: TextOverflow.ellipsis,
                    maxlines: 1,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
