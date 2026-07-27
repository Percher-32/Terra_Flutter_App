import 'package:flutter/material.dart';
import 'package:nextfind/utils/locationmanager.dart';
import 'package:nextfind/networking/apiconn.dart';
import 'package:nextfind/utils/businessManager.dart';
import 'package:nextfind/utils/arbitStore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nextfind/widgets/newwidgets.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as map_gl;
import 'package:logger/logger.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'dart:math' as math;
import 'dart:typed_data';

Future<Uint8List> loadMarkerImage() async {
  final data = await rootBundle.load('assets/icons/Vector.png');
  return data.buffer.asUint8List();
}

final slog = Logger();

class MapSearchView extends StatefulWidget {
  const MapSearchView(
      {super.key,
      required this.miniBusinessLocationids,
      required this.isReady,
      this.location = const [53.7446, -0.3352]});

  final List location;
  final List<String> miniBusinessLocationids;
  final bool isReady;

  @override
  State<MapSearchView> createState() => _MapSearchViewState();
}

class _MapSearchViewState extends State<MapSearchView>
    with SingleTickerProviderStateMixin {
  map_gl.MapLibreMapController? _mapController;
  bool _mapReady = false;
  late final Ticker _ticker;

  final List<map_gl.LatLng> _markerPositions = List.generate(30, (index) {
    final int row = index ~/ 20;
    final int col = index % 20;
    final double minLat = 53.744 + 0.001;
    final double maxLat = 53.744 - 0.001;
    final double minLng = -0.335 + 0.001;
    final double maxLng = -0.335 - 0.001;
    final double lat = minLat + (col / 19) * (maxLat - minLat);
    final double lng = minLng + (row / 9) * (maxLng - minLng);
    return map_gl.LatLng(lat, lng);
  });

  late final List<ValueNotifier<Offset>> _markerOffsets;

  double _mapZoom = 16.0;
  double _mapBearing = 0.0;

  @override
  void initState() {
    super.initState();
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
    if (!_mapReady || _mapController == null) return;

    final points =
        await _mapController!.toScreenLocationBatch(_markerPositions);

    final dpr = MediaQuery.of(context).devicePixelRatio;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      _markerOffsets[i].value = Offset(
        p.x.toDouble() / dpr,
        p.y.toDouble() / dpr,
      );
    }
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
                styleString:
                    "https://api.maptiler.com/maps/019fa3e4-e15f-7004-817f-b2c8f21d06d9/style.json?key=6qbiNDxrdNlr98KHQ1F9",
                initialCameraPosition: const map_gl.CameraPosition(
                  target: map_gl.LatLng(53.7443, -0.33515),
                  zoom: 16,
                ),
                tiltGesturesEnabled: true,
                onMapCreated: (controller) {
                  _mapController = controller;
                  _mapReady = true;
                  _refreshOverlayPositions();
                },
                onStyleLoadedCallback: () {
                  _mapReady = true;
                  _refreshOverlayPositions();
                },
                onCameraMove: (cameraPosition) {
                  _mapZoom = cameraPosition.zoom ?? _mapZoom;
                  _mapBearing = cameraPosition.bearing ?? _mapBearing;
                  _refreshOverlayPositions();
                },
                onMapIdle: () {
                  _refreshOverlayPositions();
                },
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
                              (40.0 * (16.0 / math.max(_mapZoom, 1.0)))
                                  .clamp(20.0, 60.0);

                          return Positioned(
                            left: offset.dx - dynamicSize / 2,
                            top: offset.dy - dynamicSize / 2,
                            child: RepaintBoundary(
                              child: Transform.rotate(
                                  angle: _mapBearing * math.pi / 180,
                                  child: Icon(Icons.abc)),
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
      idOnly: true,
    ));

    await businessManager.getBusinessLocationMini(_miniBusinessLocationids);

    isReady = true;

    setState(() {});
  }

  Widget buildPage(BuildContext context) {
    return Stack(
      children: [
        isReady
            ? MapSearchView(
                miniBusinessLocationids: _miniBusinessLocationids,
                isReady: isReady,
              )
            : const Center(child: Text("Loading map..."))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: newsearchbar(context),
        bottomNavigationBar: newbottombar(context),
        body: buildPage(context));
  }
}
