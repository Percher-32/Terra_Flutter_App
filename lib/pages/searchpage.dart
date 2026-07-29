import 'package:flutter/material.dart';
import 'package:nextfind/networking/apiconn.dart';
import 'package:nextfind/utils/businessManager.dart';
import 'package:nextfind/utils/arbitStore.dart';
import 'package:nextfind/widgets/newwidgets.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as map_gl;
import 'package:nextfind/utils/locationmanager.dart';

import 'package:logger/logger.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import 'package:flutter/scheduler.dart';

import 'dart:math';
import 'dart:typed_data';

map_gl.MapLibreMapController? _mapController;

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
  late final Ticker _ticker;

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
    // log.i("FRM : ${_frameCount % 4 == 0}");
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

  Widget createBusinessMapIcon(BuildContext context, MiniBusinessLoc miniBusLoc,
      double nearestDist, int index) {
    double normDist = ((nearestDist) * 0.00015).clamp(0, 1);

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

    if (index <= 10) {
      normDist += 0.1;
    }
    if (verified) {
      normDist += 0.2;
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
      trueWidget = Stack(clipBehavior: Clip.none, children: [
        Image.asset(
          'assets/icons/svg_logo.png',
          width: 32,
          height: 32,
        ),
        Positioned(
            right: -10,
            top: -5,
            child: Container(
                width: 20,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: AppColors.secondary),
                child: Center(
                    child: MyText(
                  (miniBusLoc.averageRating ?? "-").toString(),
                  size: 10,
                  color: AppColors.background,
                )))),
        veriBadge
      ]);
    } else {
      trueWidget = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 15,
        children: [
          Stack(clipBehavior: Clip.none, children: [
            Image.asset(
              'assets/icons/svg_logo.png',
              width: 32,
              height: 32,
            ),
            Positioned(
                right: -10,
                top: -5,
                child: Container(
                    width: 20,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: AppColors.secondary),
                    child: Center(
                        child: MyText(
                      (miniBusLoc.averageRating ?? "-").toString(),
                      size: 10,
                      color: AppColors.background,
                    )))),
            veriBadge
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
                width: 100,
                // height: 30,
                child: MyText(
                  miniBusLoc.name,
                  size: 12,
                  overflow: TextOverflow.ellipsis,
                  maxlines: 1,
                )),
            MyText(
              businessTypeLookup[miniBusLoc.type]!,
              size: 12,
              overflow: TextOverflow.ellipsis,
              maxlines: 1,
            )
          ])
        ],
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
                tiltGesturesEnabled: true,
                onMapCreated: (controller) async {
                  _mapController = controller;
                  // _mapReady = true;

                  // _refreshOverlayPositions();
                },
                onStyleLoadedCallback: () async {
                  _mapReady = true;

                  // await _addSearchRadiusPolygon();

                  if (_radiusSourceAdded) {
                    _refreshOverlayPositions();
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

                  _refreshOverlayPositions();
                },
                onCameraMove: (cameraPosition) {
                  _mapZoom = cameraPosition.zoom ?? _mapZoom;
                  _mapBearing = cameraPosition.bearing ?? _mapBearing;
                  _refreshOverlayPositions();
                },
                onMapClick: (map_gl.Point<double> point, map_gl.LatLng latLng) {
                  final tappedLat = latLng.latitude;
                  final tappedLng = latLng.longitude;

                  print("User tapped at: $tappedLat, $tappedLng");

                  // Example: update your userLocation
                  arbitStore.data["userLocation"] = [tappedLat, tappedLng];

                  // Example: reload markers
                  setState(() {});
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
                child: IgnorePointer(
                  child: Stack(
                    children: List.generate(
                        widget.miniBusinessLocationids.length, (index) {
                      MiniBusinessLoc miniBusLoc =
                          businessManager.miniBusinessLocLookup[
                              widget.miniBusinessLocationids[index]]!;

                      return ValueListenableBuilder<Offset>(
                        valueListenable: _markerOffsets[index],
                        builder: (_, offset, __) {
                          final dynamicSize =
                              (40.0 * (16.0 / max(_mapZoom, 1.0)))
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

  @override
  void initState() {
    super.initState();
    _getLocations();
  }

  Future<void> _getLocations() async {
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

    setState(() {});
  }

  void locationButtonPressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // allows full height
      backgroundColor: Colors.transparent, // optional
      builder: (context) {
        return Container(
            // color: AppColors.background,
            padding: EdgeInsets.only(left: 10, right: 10),
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40)),
                color: AppColors.background),
            height: 200,
            child: Center(
                child: SizedBox(
                    height: 100,
                    child: MyMultiToggle(
                        initial: 1,
                        options: ["My Location", "Choose Location"],
                        onChanged: (p0) async {
                          if (p0 == 0) {
                            await getLocation();
                            log.i("GOTTEN USER LOCATION");
                            await _getLocations();
                            setState(() {});
                          }
                        }))));
      },
    );
  }

  Widget buildPage(BuildContext context) {
    return Stack(
      children: [
        isReady
            ? MapSearchView(
                key: UniqueKey(),
                miniBusinessLocationids: _miniBusinessLocationids,
                isReady: isReady,
              )
            : MyText("Loading Map..."),
        Positioned(
          top: 120,
          right: 10,
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
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: newbottombar(context, index: 0),
        body: Stack(children: [
          Positioned(child: buildPage(context)),
          Positioned(child: newsearchbar(context)),
        ]));
  }
}
