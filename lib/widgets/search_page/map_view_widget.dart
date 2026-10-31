import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as map_gl;
import 'package:nextfind/helpers/debug_options.dart';
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

String getRandomString(int length) {
  const chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final rnd = Random.secure();

  return String.fromCharCodes(Iterable.generate(
    length,
    (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
  ));
}

List<T> getUnion<T>(List<T> list1, List<T> list2) {
  // Spreads both lists into a Set, which automatically drops duplicates, then converts back to a List
  return {...list1, ...list2}.toList();
}

class MapSearchView extends StatefulWidget {
  const MapSearchView({super.key});

  @override
  State<MapSearchView> createState() => _MapSearchViewState();
}

class _MapSearchViewState extends State<MapSearchView>
    with SingleTickerProviderStateMixin {
  bool _mapReady = false;
  bool _lockCamera = false;
  bool initComplete = false;
  bool userMarkerAdded = false;

  bool userSourceAdded = false;

  bool _sourceAddedAlready = false;

  @override
  void initState() {
    initComplete = false;

    super.initState();

    SearchPageGlobals.reloadMapTrigger.addListener(() async {
      await _updateBusinessIconPotisions();
    });

    SearchPageGlobals.reloadUserPositionTrigger.addListener(() async {
      await _updateUserPointPosition(UserService.userLocation);
    });

    initComplete = true;
  }

  @override
  void dispose() {
    _mapReady = false;
    super.dispose();
  }

  Future<Uint8List?> loadAndRegisterWidgetIcon(
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
    // await Future.delayed(const Duration(milliseconds: 20));

    try {
      // 2. Capture the rendered boundary into raw PNG bytes
      final RenderRepaintBoundary? boundary = repaintKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary != null) {
        final ui.Image image =
            await boundary.toImage(pixelRatio: 2.0); // 2.0 for sharp text
        final ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        final Uint8List? imageList = byteData?.buffer.asUint8List();

        if (imageList != null) {
          // 3. Register it into MapLibre's style memory with your custom ID string

          await SearchPageGlobals.mapController?.addImage(customId, imageList);
          return imageList;
        }
      }
    } finally {
      // 4. Always remove the temporary overlay entry when finished
      overlayEntry.remove();
    }
    return null;
  }

  Future<Uint8List> registerImageToMap(
      String assetPath, String customID) async {
    final ByteData byteData = await rootBundle.load(assetPath);

    final Uint8List uint8List = byteData.buffer.asUint8List();

    SearchPageGlobals.mapController?.addImage(customID, uint8List);

    return uint8List;
  }

  /// This function removes the previous user icon from the app and adds a new one at <b>location</b>
  Future<void> _updateUserPointPosition(List<double> newLocation) async {
    final List features = [
      {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [newLocation[1], newLocation[0]]
        }
      }
    ];

    final geoJsonData = {"type": "FeatureCollection", "features": features};

    if (userSourceAdded) {
      await SearchPageGlobals.mapController!
          .setGeoJsonSource("user_marker_source", geoJsonData);
    } else {
      await registerImageToMap("assets/icons/user_marker.png", "user_marker");

      await SearchPageGlobals.mapController?.addSource(
        "user_marker_source",
        map_gl.GeojsonSourceProperties(
          data: geoJsonData,
          cluster: false,
        ),
      );

      await SearchPageGlobals.mapController?.addLayer(
        "user_marker_source",
        "user_marker_layer",
        const map_gl.SymbolLayerProperties(
          iconImage: "user_marker",
          iconSize: 2.0,
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
        ),
      );

      userSourceAdded = true;
    }
  }

  /// Register an Icon with a string using location_id
  Future<void> addIconMiniBusinessToMap(
      MiniBusinessLocation miniBusinessLocation, int index) async {
    // log.i("${SearchPageGlobals}");
    // Full Icons
    if (!mounted) return;
    if (SearchPageGlobals.businessMarkerIconCache
            .containsKey((miniBusinessLocation, BusinessMarkerLevel.full)) &
        !NextfindDebugOptions.cacheBusinessMarkerIcons) {
      log.i("ICON CACHE HIT");
      final widgetList = SearchPageGlobals.businessMarkerIconCache[(
        miniBusinessLocation,
        BusinessMarkerLevel.full
      )]!;
      await SearchPageGlobals.mapController
          ?.addImage("BUSINESSMARKERICON_INDEXFULL:$index", widgetList);
    } else {
      final Uint8List fullIconImage = (await loadAndRegisterWidgetIcon(
          context,
          BusinessMarker(
              miniBusinessLocation: miniBusinessLocation,
              businessMarkerLevel: BusinessMarkerLevel.full,
              index: index),
          "BUSINESSMARKERICON_INDEXFULL:$index"))!;

      SearchPageGlobals.businessMarkerIconCache[(
        miniBusinessLocation,
        BusinessMarkerLevel.full
      )] = fullIconImage;
    }

    // Reduced Icons
    if (!mounted) return;

    if (SearchPageGlobals.businessMarkerIconCache
            .containsKey((miniBusinessLocation, BusinessMarkerLevel.reduced)) &
        !NextfindDebugOptions.cacheBusinessMarkerIcons) {
      log.i("ICON CACHE HIT");
      final widgetList = SearchPageGlobals.businessMarkerIconCache[(
        miniBusinessLocation,
        BusinessMarkerLevel.reduced
      )]!;
      await SearchPageGlobals.mapController
          ?.addImage("BUSINESSMARKERICON_INDEXREDUCED:$index", widgetList);
    } else {
      final Uint8List reducedIconImage = (await loadAndRegisterWidgetIcon(
          context,
          BusinessMarker(
              miniBusinessLocation: miniBusinessLocation,
              businessMarkerLevel: BusinessMarkerLevel.reduced,
              index: index),
          "BUSINESSMARKERICON_INDEXREDUCED:$index"))!;

      SearchPageGlobals.businessMarkerIconCache[(
        miniBusinessLocation,
        BusinessMarkerLevel.reduced
      )] = reducedIconImage;
    }

    //Mini Icons
    if (!mounted) return;
    if (SearchPageGlobals.businessMarkerIconCache
            .containsKey((miniBusinessLocation, BusinessMarkerLevel.mini)) &
        !NextfindDebugOptions.cacheBusinessMarkerIcons) {
      log.i("ICON CACHE HIT");
      final widgetList = SearchPageGlobals.businessMarkerIconCache[(
        miniBusinessLocation,
        BusinessMarkerLevel.mini
      )]!;

      await SearchPageGlobals.mapController
          ?.addImage("BUSINESSMARKERICON_INDEXMINI:$index", widgetList);
    } else {
      final Uint8List miniIconImage = (await loadAndRegisterWidgetIcon(
          context,
          BusinessMarker(
              miniBusinessLocation: miniBusinessLocation,
              businessMarkerLevel: BusinessMarkerLevel.mini,
              index: index),
          "BUSINESSMARKERICON_INDEXMINI:$index"))!;

      SearchPageGlobals.businessMarkerIconCache[(
        miniBusinessLocation,
        BusinessMarkerLevel.mini
      )] = miniIconImage;
    }
  }

  /// This function removes all the previous icons and adds new ones.
  Future<void> _updateBusinessIconPotisions() async {
    if (!_mapReady) return;

    // This is here to allow a new add symbol to happen
    SearchPageGlobals.isLoading.value = true;

    await SearchPageGlobals.mapController?.clearSymbols();
    int index = 0;

    List<Map> features = [];
    final miniBusinessLocations = SearchPageGlobals.miniBusinessLocations.value;

    for (MiniBusinessLocation miniBusinessLocation in miniBusinessLocations) {
      await addIconMiniBusinessToMap(miniBusinessLocation, index);
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
          "iconIdFULL": "BUSINESSMARKERICON_INDEXFULL:$index",
          "iconIdREDUCED": "BUSINESSMARKERICON_INDEXREDUCED:$index",
          "iconIdMINI": "BUSINESSMARKERICON_INDEXMINI:$index",
          "name": miniBusinessLocation.name,
          "index": index
        }
      };

      features.add(feature);
      index += 1;
    }

    final geoJsonData = {"type": "FeatureCollection", "features": features};

    // String jsonGeoData = jsonEncode(geoJsonData);

    if (_sourceAddedAlready) {
      await SearchPageGlobals.mapController!
          .setGeoJsonSource("business_markers_source", geoJsonData);
      SearchPageGlobals.isLoading.value = false;

      return;
    }

    // try {
    //   await SearchPageGlobals.mapController!
    //       .removeSource("business_markers_source");
    //   await SearchPageGlobals.mapController!
    //       .removeSource("business_markers_source_mini_icons");
    //   await SearchPageGlobals.mapController!
    //       .removeLayer("unique_markers_layer");
    //   await SearchPageGlobals.mapController!
    //       .removeLayer("clustered_markers_layer");
    //   await SearchPageGlobals.mapController!.removeLayer("mini_icons_layer");
    // } finally {}

    await SearchPageGlobals.mapController!.addSource(
      "business_markers_source",
      map_gl.GeojsonSourceProperties(
        data: geoJsonData,
        cluster: true,
        clusterRadius: 70, // Distance in pixels to group points
        // clusterMaxZoom: 5, // Zoom level where clustering stops
        clusterProperties: {
          "min_index": [
            [
              'min',
              ['accumulated'],
              ['get', 'min_index']
            ],
            ['get', 'index']
          ],
        },
      ),
    );

    await SearchPageGlobals.mapController!.addSource(
      "business_markers_source_mini_icons",
      map_gl.GeojsonSourceProperties(
        data: geoJsonData,
      ),
    );

    await SearchPageGlobals.mapController!.addSymbolLayer(
      "business_markers_source_mini_icons",
      "mini_icons_layer",
      belowLayerId: "user_marker_layer",
      const map_gl.SymbolLayerProperties(
        iconImage: [
          'get',
          'iconIdMINI'
        ], // 3. Tells it to read the 'id' property from your GeoJSON
        iconSize: 1.0, // 4. Size scaling
        iconAllowOverlap:
            true, // 5. Prevents close icons from hiding each other
      ),
    );

    await SearchPageGlobals.mapController!.addSymbolLayer(
      "business_markers_source",
      "unique_markers_layer",
      belowLayerId: "user_marker_layer",
      filter: [
        '!',
        ['has', 'point_count']
      ],
      const map_gl.SymbolLayerProperties(
        iconImage: [
          'get',
          'iconIdFULL'
        ], // 3. Tells it to read the 'id' property from your GeoJSON
        iconSize: 1.2, // 4. Size scaling
        iconAllowOverlap:
            true, // 5. Prevents close icons from hiding each other
        iconOffset: [180 / 4, 0.0],
      ),
    );

    await SearchPageGlobals.mapController!.addSymbolLayer(
      "business_markers_source",
      "clustered_markers_layer",
      belowLayerId: "user_marker_layer",
      filter: ['has', 'point_count'],
      const map_gl.SymbolLayerProperties(
        iconImage: [
          "concat",
          "BUSINESSMARKERICON_INDEXREDUCED:",
          [
            'to-string',
            ['get', 'min_index']
          ]
        ], // 3. Tells it to read the 'id' property from your GeoJSON
        iconSize: 1.3,
        iconAllowOverlap: true,
      ),
    );

    SearchPageGlobals.mapController!.onFeatureTapped
        .add((point, coordinates, id, layerId, annotation) async {
      await onBusinessMarkerTapped(point, coordinates, id, layerId, annotation);
    });

    SearchPageGlobals.isLoading.value = false;

    _sourceAddedAlready = true;
  }

  Future<void> onBusinessMarkerTapped(
      Point<double> point,
      map_gl.LatLng coordinates,
      String id,
      String layerId,
      map_gl.Annotation? annotation) async {
    final List? features = await SearchPageGlobals.mapController
        ?.queryRenderedFeatures(
            point, ["clustered_markers_layer", "unique_markers_layer"], null);

    if (features != null && features.isNotEmpty) {
      final Map<String, dynamic> properties =
          features.first["properties"] as Map<String, dynamic>;

      bool isCluster = properties['cluster'] == true ||
          properties.containsKey('point_count');

      late int chosenIndex;
      if (isCluster) {
        chosenIndex = (properties["min_index"] as double).toInt();
      } else {
        chosenIndex = (properties["index"] as double).toInt();
      }

      final selectedMiniBusinessLocation =
          SearchPageGlobals.miniBusinessLocations.value[chosenIndex];

      SearchPageGlobals.setChosenBusinessLocation(selectedMiniBusinessLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!initComplete) {
      return const SizedBox();
    }

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
          },
          onStyleLoadedCallback: () async {
            if (!lifecycle.isPaused) {
              _mapReady = true;
              await SearchPageGlobals.mapController
                  ?.setSymbolIconAllowOverlap(true);
              await SearchPageGlobals.mapController
                  ?.setSymbolIconIgnorePlacement(true);
              SearchPageGlobals.reloadUserPosition();
            }
          },
          onCameraMove: (cameraPosition) async {},
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
              SearchPageGlobals.reloadUserPosition();

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
  }
}

class BusinessMarker extends StatelessWidget {
  const BusinessMarker({
    super.key,
    required this.miniBusinessLocation,
    required this.businessMarkerLevel,
    required this.index,
  });

  final MiniBusinessLocation miniBusinessLocation;
  final BusinessMarkerLevel businessMarkerLevel;
  final int index;

  @override
  Widget build(BuildContext context) {
    String iconPath = businessIconLookupAlt[miniBusinessLocation.type] ??
        "assets/icons/svg_logo.png";
    bool verified = miniBusinessLocation.verified;
    String ratingtext = "-";

    if (miniBusinessLocation.averageRating != null) {
      ratingtext =
          "${miniBusinessLocation.averageRating!.toStringAsFixed(1)}(${miniBusinessLocation.numRatings})";
    }

    Widget veriBadge = verified
        ? const SizedBox.shrink()
        : Image.asset("assets/icons/business_icons/unverified_badge_mini.png",
            width: 15, height: 15);

    final Widget businessMarkerMain = SizedBox(
        width: 58,
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: AlignmentGeometry.center,
          children: [
            Positioned(
                left: 0,
                bottom: 0,
                child: Image.asset(
                  iconPath,
                  width: 32,
                  height: 32,
                  cacheWidth: 64,
                  cacheHeight: 64,
                )),
            Positioned(
              left: 15,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.background,
                ),
                child: MyText(
                  ratingtext,
                  size: 9,
                  color: AppColors.accent,
                ),
              ),
            ),
            Positioned(left: 32 - 8, bottom: 0, child: veriBadge),
          ],
        ));

    // Tier 1: Distance Dot
    if (businessMarkerLevel == BusinessMarkerLevel.mini) {
      return Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      );
    } else if (businessMarkerLevel == BusinessMarkerLevel.reduced) {
      return businessMarkerMain;
    } else {
      return Center(
          child: Container(
              width: 180,
              height: 65,
              decoration: const BoxDecoration(
                  // color: AppColors.background,
                  borderRadius: BorderRadius.all(Radius.circular(40))),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Stack(
                // alignment: AlignmentGeometry.centerLeft,
                children: [
                  Positioned(
                      left: 0, bottom: 65 / 4, child: businessMarkerMain),
                  Positioned(
                      left: 40,
                      bottom: 0,
                      child: Column(children: [
                        SizedBox(
                          width: 100,
                          child: MyText(
                            color: AppColors.primary,
                            miniBusinessLocation.name,
                            size: 12,
                            overflow: TextOverflow.ellipsis,
                            maxlines: 1,
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: MyText(
                            color: AppColors.primary,
                            businessTypeLookup[miniBusinessLocation.type] ?? '',
                            size: 10,
                            overflow: TextOverflow.ellipsis,
                            maxlines: 1,
                          ),
                        ),
                      ])),
                ],
              )));
    }

    //       if (businessMarkerLevel == BusinessMarkerLevel.full) ...[
    //         const SizedBox(width: 8),
    //         // Text Details
    //         Column(
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           mainAxisSize: MainAxisSize.min,
    //           children: [
    //             SizedBox(
    //               width: 100,
    //               child: MyText(
    //                 miniBusinessLocation.name,
    //                 size: 12,
    //                 overflow: TextOverflow.ellipsis,
    //                 maxlines: 1,
    //               ),
    //             ),
    //             SizedBox(
    //               width: 100,
    //               child: MyText(
    //                 businessTypeLookup[miniBusinessLocation.type] ?? '',
    //                 size: 10,
    //                 overflow: TextOverflow.ellipsis,
    //                 maxlines: 1,
    //               ),
    //             ),
    //           ],
    //         ),
    //       ],
    //     ],
    //   ),
    // );
  }
}
