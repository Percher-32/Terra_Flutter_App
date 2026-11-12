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

import 'package:flutter/scheduler.dart';

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
  bool _lockCamera = false;
  bool initComplete = false;

  bool userSourceAdded = false;

  bool sourceAddedAlready = false;

  @override
  void initState() {
    initComplete = false;

    super.initState();

    SearchPageGlobals.mapReady = false;

    SearchPageGlobals.reloadMapTrigger.addListener(() async {
      await _updateBusinessIconPotisions();
    });

    SearchPageGlobals.reloadUserPositionTrigger.addListener(() async {
      await _updateUserPointPosition(UserService.userLocation);
    });

    initComplete = true;
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
    await SchedulerBinding.instance.endOfFrame;
    // await Future.delayed(const Duration(milliseconds: 20));

    try {
      // 1. Ensure context is valid before starting
      final BuildContext? initialContext = repaintKey.currentContext;
      if (initialContext == null || !initialContext.mounted) {
        return null;
      }

      // 2. Wait for the current frame to completely finish painting
      // This guarantees `debugNeedsPaint` is false before we call toImage()
      await WidgetsBinding.instance.endOfFrame;

      // 3. Re-verify the context and mounted state after the await gap
      final BuildContext? context = repaintKey.currentContext;
      if (context == null || !context.mounted) {
        return null;
      }

      // Double-check map state before doing expensive image processing
      if (!SearchPageGlobals.mapReady ||
          SearchPageGlobals.mapMode.value == MainSearchPageMode.list) {
        return null;
      }

      final RenderRepaintBoundary? boundary =
          context.findRenderObject() as RenderRepaintBoundary?;

      if (boundary != null && boundary.debugNeedsPaint == false) {
        final ui.Image image = await boundary.toImage(pixelRatio: 2.0);

        // Final mounted check after the image encoding gap
        if (!context.mounted) return null;

        final ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        final Uint8List? imageList = byteData?.buffer.asUint8List();

        if (imageList != null) {
          if (!SearchPageGlobals.mapReady ||
              SearchPageGlobals.mapMode.value == MainSearchPageMode.list) {
            return null;
          }

          // 4. Register it into MapLibre's style memory
          await SearchPageGlobals.mapController?.addImage(customId, imageList);
          return imageList;
        }
      }
    } finally {
      // 5. Always remove the temporary overlay entry when finished
      try {
        overlayEntry.remove();
      } catch (_) {
        // Ignore if it was already cleaned up
      }
    }
    return null;
  }

  @override
  void dispose() {
    SearchPageGlobals.mapReady = false;
    super.dispose();
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

      try {
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
      } finally {}
    }
  }

  /// Register an Icon with a string using location_id
  Future<void> addIconMiniBusinessToMap(
      MiniBusinessLocation miniBusinessLocation, int index) async {
      try{


    if (!mounted) return;
    if (SearchPageGlobals.mapMode.value == MainSearchPageMode.list ||
        !SearchPageGlobals.mapReady) {
      return;
    }

    if (SearchPageGlobals.businessMarkerIconCache
            .containsKey((miniBusinessLocation, BusinessMarkerLevel.full)) &&
        NextfindDebugOptions.cacheBusinessMarkerIcons) {
      log.i("ICON CACHE HIT");
      final widgetList = SearchPageGlobals.businessMarkerIconCache[(
        miniBusinessLocation,
        BusinessMarkerLevel.full
      )]!;
      await SearchPageGlobals.mapController
          ?.addImage("BUSINESSMARKERICON_INDEXFULL:$index", widgetList);
    } else {
      final Uint8List? fullIconImage = (await loadAndRegisterWidgetIcon(
          context,
          BusinessMarker(
              miniBusinessLocation: miniBusinessLocation,
              businessMarkerLevel: BusinessMarkerLevel.full,
              index: index),
          "BUSINESSMARKERICON_INDEXFULL:$index"));

      if (SearchPageGlobals.mapMode.value == MainSearchPageMode.list ||
          !SearchPageGlobals.mapReady) {
        return;
      }
      if (!mounted) return;
      SearchPageGlobals.businessMarkerIconCache[(
        miniBusinessLocation,
        BusinessMarkerLevel.full
      )] = fullIconImage!;
    }

    // Reduced Icons
    if (!mounted) return;
    if (SearchPageGlobals.mapMode.value == MainSearchPageMode.list ||
        !SearchPageGlobals.mapReady) {
      return;
    }
    ;
    if (SearchPageGlobals.businessMarkerIconCache
            .containsKey((miniBusinessLocation, BusinessMarkerLevel.reduced)) &&
        NextfindDebugOptions.cacheBusinessMarkerIcons) {
      log.i("ICON CACHE HIT");
      final widgetList = SearchPageGlobals.businessMarkerIconCache[(
        miniBusinessLocation,
        BusinessMarkerLevel.reduced
      )]!;
      await SearchPageGlobals.mapController
          ?.addImage("BUSINESSMARKERICON_INDEXREDUCED:$index", widgetList);
    } else {
      final Uint8List? reducedIconImage = (await loadAndRegisterWidgetIcon(
          context,
          BusinessMarker(
              miniBusinessLocation: miniBusinessLocation,
              businessMarkerLevel: BusinessMarkerLevel.reduced,
              index: index),
          "BUSINESSMARKERICON_INDEXREDUCED:$index"));

      if (SearchPageGlobals.mapMode.value == MainSearchPageMode.list ||
          !SearchPageGlobals.mapReady) {
        return;
      }
      if (!mounted) return;

      SearchPageGlobals.businessMarkerIconCache[(
        miniBusinessLocation,
        BusinessMarkerLevel.reduced
      )] = reducedIconImage!;
    }

    //Mini Icons
    if (!mounted) return;
    if (SearchPageGlobals.mapMode.value == MainSearchPageMode.list ||
        !SearchPageGlobals.mapReady) {
      return;
    }
    ;
    if (SearchPageGlobals.businessMarkerIconCache
            .containsKey((miniBusinessLocation, BusinessMarkerLevel.mini)) &&
        NextfindDebugOptions.cacheBusinessMarkerIcons) {
      log.i("ICON CACHE HIT");
      final widgetList = SearchPageGlobals.businessMarkerIconCache[(
        miniBusinessLocation,
        BusinessMarkerLevel.mini
      )]!;

      await SearchPageGlobals.mapController
          ?.addImage("BUSINESSMARKERICON_INDEXMINI:$index", widgetList);
    } else {
      final Uint8List? miniIconImage = (await loadAndRegisterWidgetIcon(
          context,
          BusinessMarker(
              miniBusinessLocation: miniBusinessLocation,
              businessMarkerLevel: BusinessMarkerLevel.mini,
              index: index),
          "BUSINESSMARKERICON_INDEXMINI:$index"));

      if (SearchPageGlobals.mapMode.value == MainSearchPageMode.list ||
          !SearchPageGlobals.mapReady) {
        return;
      }
      if (!mounted) return;

      SearchPageGlobals.businessMarkerIconCache[(
        miniBusinessLocation,
        BusinessMarkerLevel.mini
      )] = miniIconImage!;
      }
      }
      finally{

      }
    
  }

  /// This function removes all the previous icons and adds new ones.
  Future<void> _updateBusinessIconPotisions() async {
    if (!SearchPageGlobals.mapReady) return;

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

    try {
      final allSourceIds =
          await SearchPageGlobals.mapController!.getSourceIds();

      if (sourceAddedAlready) {
        await SearchPageGlobals.mapController!
            .setGeoJsonSource("business_markers_source", geoJsonData);
        SearchPageGlobals.isLoading.value = false;

        return;
      }

      await SearchPageGlobals.mapController!.addSource(
        "business_markers_source",
        map_gl.GeojsonSourceProperties(
          data: geoJsonData,
          cluster: true,
          clusterRadius: 70,
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
          iconImage: ['get', 'iconIdMINI'],
          iconSize: 1.0,
          iconAllowOverlap: true,
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
        await onBusinessMarkerTapped(
            point, coordinates, id, layerId, annotation);
      });
    } catch (e) {
      SearchPageGlobals.mapReady = false;
    } finally {
      SearchPageGlobals.isLoading.value = false;
      sourceAddedAlready = true;
    }
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

    return map_gl.MapLibreMap(
      styleString:
          "https://api.maptiler.com/maps/01a196d6-bda3-74d5-b701-fd441b3d6892/style.json?key=6qbiNDxrdNlr98KHQ1F9",
      initialCameraPosition: map_gl.CameraPosition(
        target:
            //Use the user position or the chosen location to start of with
            SearchPageGlobals.chosenBusinessLocation != null
                ? map_gl.LatLng(
                    SearchPageGlobals.chosenBusinessLocation!.location[0],
                    SearchPageGlobals.chosenBusinessLocation!.location[1],
                  )
                : map_gl.LatLng(
                    UserService.userLocation[0], UserService.userLocation[1]),
        tilt: 60,
        zoom: 16,
      ),
      trackCameraPosition: true,
      scrollGesturesEnabled: !_lockCamera,
      zoomGesturesEnabled: !_lockCamera,
      rotateGesturesEnabled: !_lockCamera,
      tiltGesturesEnabled: !_lockCamera,
      onMapCreated: (controller) async {
        SearchPageGlobals.mapReady = false;
        SearchPageGlobals.mapController = controller;
      },
      onStyleLoadedCallback: () async {
        if (!lifecycle.isPaused) {
          SearchPageGlobals.mapReady = true;
          SearchPageGlobals.reloadUserPosition();
        }
        SearchPageGlobals.reloadMap();
      },
      onCameraMove: (cameraPosition) async {
        SearchPageGlobals.mapReady = true;
      },
      onMapIdle: () async {
        SearchPageGlobals.mapReady = true;
      },
      onMapClick: (_, map_gl.LatLng latLng) {
        if (SearchPageGlobals.mapMode.value == MainSearchPageMode.choosing) {
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
                  color: AppColors.leveled,
                ),
                child: MyText(
                  ratingtext,
                  size: 9,
                  color: AppColors.text,
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
                            color: AppColors.text,
                            miniBusinessLocation.name,
                            size: 12,
                            overflow: TextOverflow.ellipsis,
                            maxlines: 1,
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: MyText(
                            color: AppColors.text,
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
