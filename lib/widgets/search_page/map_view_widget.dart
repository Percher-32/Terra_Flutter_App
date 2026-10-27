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
import 'dart:convert';

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

  bool _sourceAddedAlready = false;

  List<(MiniBusinessLoc, Offset)> markerObjects = [];

  List<double> markerDist = [];

  @override
  void initState() {
    initComplete = false;

    super.initState();

    SearchPageGlobals.miniBusinessLocations.addListener(() async {
      _updateBusinessIconPotisions();
    });

    SearchPageGlobals.reloadUserPositionTrigger.addListener(() async {
      _updateUserPointPosition(UserService.userLocation);
    });

    initComplete = true;
  }

  @override
  void dispose() {
    _mapReady = false;
    super.dispose();
  }

  Future<void> _refreshHitboxPositions() async {
    // return;
    if (_mapReady &&
        SearchPageGlobals.mapController != null &&
        !SearchPageGlobals.isLoading.value) {
      if (!lifecycle.isPaused) {
        final miniBusinessLocations =
            SearchPageGlobals.miniBusinessLocations.value;

        final controller = SearchPageGlobals.mapController;

        if (!_mapReady ||
            controller == null ||
            SearchPageGlobals.isLoading.value) {
          return;
        }

        if (lifecycle.isPaused) return;

        _frameCount += 1;

        if (_frameCount > 10000) _frameCount = 0;

        final List<map_gl.LatLng> markerPositions = [
          for (MiniBusinessLoc miniBusinessLocation in miniBusinessLocations)
            map_gl.LatLng(miniBusinessLocation.location[0],
                miniBusinessLocation.location[1])
        ];

        final points = await controller.toScreenLocationBatch(markerPositions);

        List<Point> listOffALlPoints = [];

        if (mounted) {
          // try {
          final dpr = MediaQuery.of(context).devicePixelRatio;
          final screenSize = MediaQuery.sizeOf(context);

          final double screenWidth = screenSize.width;
          final double screenHeight = screenSize.height;

          return;
          // markerObjects = [];

          // for (int i = 0; i < points.length; i++) {
          //   final mapPoint = points[i];

          // if (i >= _markerOffsets.lenght)
          //   final List position = [
          //     mapPoint.x.toDouble() / dpr,
          //     mapPoint.y.toDouble() / dpr
          //   ];
          //   final bool inView = position[0] >= -50 &&
          //       position[0] <= screenWidth + 50 &&
          //       position[1] >= -50 &&
          //       position[1] <= screenHeight + 50;

          //   if (!inView) continue;

          //   markerObjects.add(
          //       (miniBusinessLocations[i], Offset(position[0], position[1])));

          //   listOffALlPoints.add(Point(position[0], position[1]));
          // }
          // SearchPageGlobals.reloadMapPoints();
        }
      }
    }
  }

  /// This function removes the previous user icon from the app and adds a new one at <b>location</b>
  void _updateUserPointPosition(List<double> newLocation) {}

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
      final RenderRepaintBoundary? boundary = repaintKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;

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

  /// Register an Icon with a string using location_id
  Future<void> addIconMiniBusinessToMap(
      MiniBusinessLoc miniBusinessLoc, int index) async {
    await loadAndRegisterWidgetIcon(
        context,
        BusinessMarker(
            miniBusinessLocation: miniBusinessLoc,
            nearestDist: double.infinity,
            index: index),
        "BUSINESSMARKERICON_INDEX:$index");
  }

  /// This function removes all the previous icons and adds new ones.
  Future<void> _updateBusinessIconPotisions() async {
    if (!_mapReady) return;

    await SearchPageGlobals.mapController?.clearSymbols();
    int index = 0;

    List<Map> features = [];
    final miniBusinessLocations = SearchPageGlobals.miniBusinessLocations.value;
    if (miniBusinessLocations.isEmpty) {
      log.i(
          "DEBUG WARNING: The list is empty, so no features are being created!");
    } else {
      log.i("DEBUG WARNING: The list is $miniBusinessLocations");
    }
    for (MiniBusinessLoc miniBusinessLocation in miniBusinessLocations) {
      final feature = {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [
            miniBusinessLocation.location[1],
            miniBusinessLocation.location[0]
          ]
        },
        "properties": {
          "iconId":
              "BUSINESSMARKERICON_INDEX:$index", // Any custom data you want to attach
          "name": miniBusinessLocation.name,
          "index": index
        }
      };

      features.add(feature);
      index += 1;
    }

    features.add({
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [-0.1278, 51.5074]
      },
      "properties": {
        "iconId":
            "BUSINESSMARKERICON_INDEX:1", // Any custom data you want to attach
        "name": "KAKA",
        "index": index
      }
    });

    final geoJsonData = {"type": "FeatureCollection", "features": features};

    String jsonGeoData = jsonEncode(geoJsonData);

    if (_sourceAddedAlready) {
      await SearchPageGlobals.mapController!
          .setGeoJsonSource("business_markers_source", geoJsonData);
      return;
    }

    await SearchPageGlobals.mapController!.addSource(
      "business_markers_source",
      map_gl.GeojsonSourceProperties(
        data: jsonGeoData,
        cluster: true,
        clusterRadius: 50000, // Distance in pixels to group points
        clusterMaxZoom: 1, // Zoom level where clustering stops
        clusterProperties: {
          "max_index": [
            [
              'max',
              ['accumulated'],
              ['get', 'max_index']
            ],
            ['get', 'index']
          ],
        },
      ),
    );

    await SearchPageGlobals.mapController!.addCircleLayer(
      "business_markers_source", // 1. The ID of the data source it connects to
      "unique_markers_layer", // 2. A unique ID for this layer itself
      // filter: [
        // '!',
        // ['has', 'point_count']
      // ],
      map_gl.CircleLayerProperties(
        circleRadius: 800.0,
        circleColor: '#3b82f6', // Blue dots for individual businesses
        circleStrokeWidth: 2.0,
        circleStrokeColor: '#ffffff',
      ),
      // const map_gl.SymbolLayerProperties(
      //   iconImage: [
      //     'get',
      //     'iconId'
      //   ], // 3. Tells it to read the 'id' property from your GeoJSON
      //   iconSize: 1.0, // 4. Size scaling
      //   iconAllowOverlap:
      //       true, // 5. Prevents close icons from hiding each other
      // ),
    );

    await SearchPageGlobals.mapController!.addCircleLayer(
      "business_markers_source", // 1. The ID of the data source it connects to
      "clustered_markers_layer", // 2. A unique ID for this layer itself
      // filter: ['has', 'point_count'],
      map_gl.CircleLayerProperties(
        circleRadius: 1800.0,
        circleColor: '#ef4444', // Red bubbles for clusters
        circleStrokeWidth: 2.0,
        circleStrokeColor: '#ffffff',
      ),
      // const map_gl.SymbolLayerProperties(
      //   iconImage: [
      //     "concat",
      //     "BUSINESSMARKERICON_INDEX:",
      //     [
      //       'to-string',
      //       ['get', 'max_index']
      //     ]
      //   ], // 3. Tells it to read the 'id' property from your GeoJSON
      //   iconSize: 1.0, // 4. Size scaling
      //   iconAllowOverlap:
      //       true, // 5. Prevents close icons from hiding each other
      // ),
    );

    _sourceAddedAlready = true;
  }

  @override
  Widget build(BuildContext context) {
    if (!initComplete) {
      return const SizedBox();
    }

    // return LayoutBuilder(
    //   builder: (context, constraints) {
    // final size = constraints.biggest;

    return Stack(
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
                        SearchPageGlobals.chosenBusinessLocation!.location[0],
                        SearchPageGlobals.chosenBusinessLocation!.location[1],
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
            await _refreshHitboxPositions();
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

              SearchPageGlobals.changeMapLocation(UserService.userLocation);

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
                  locationId:
                      SearchPageGlobals.chosenBusinessLocation!.locationId),
            );
          },
        ),
      ],
    );
    // },
    // );
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
