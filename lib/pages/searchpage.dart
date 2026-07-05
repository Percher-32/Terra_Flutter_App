import 'package:flutter/material.dart';
import 'package:nextfind/utils/locationmanager.dart';
import 'package:nextfind/widgets/widgets.dart';
import 'package:nextfind/networking/apiconn.dart';
import 'package:nextfind/utils/businessManager.dart';
import 'package:nextfind/utils/arbitStore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nextfind/widgets/newwidgets.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';

Future<Uint8List> loadMarkerImage() async {
  final data = await rootBundle.load('assets/icons/Vector.png');
  return data.buffer.asUint8List();
}

final slog = Logger();

class MapSearchView extends StatefulWidget {
  const MapSearchView(
      {super.key,
      this.location = const [53.7446, -0.3352],
      required this.query});

  final List location;
  final String query;

  @override
  State<MapSearchView> createState() => _MapSearchViewState();
}

class _MapSearchViewState extends State<MapSearchView> {
  var scrollController = ScrollController(initialScrollOffset: 0);
  Offset overlayPos = Offset.zero;
  final LatLng target = const LatLng(53.7444, -0.3324);
  final mapController = MapController();
  bool mapReady = false;
  @override
  void initState() {
    super.initState();
  }

  Widget map(AsyncSnapshot snapshot) {
    List<Marker> markers = [];
    if (snapshot.hasData) {
      int counter = 0;

      for (String blocId in snapshot.data!) {
        final bloc = businessManager.miniBusinessLocLookup[blocId]!;
        arbitStore.data["${bloc.name}${bloc.location} MARKER"] =
            counter.toDouble();
        markers.add(
          Marker(
              point: LatLng(bloc.location[0], bloc.location[1]),
              width: 80,
              height: 100,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  onPressed: () {
                    scrollController.animateTo(
                      arbitStore.data["${bloc.name}${bloc.location} MARKER"] -
                          10.0, // pixel offset
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                    );
                  },
                  icon: const Icon(
                    Icons.location_pin,
                    size: 30,
                    color: AppColors.primary,
                  ),
                ),
                MyText(
                  (bloc.numRatings ?? "No Ratings").toString(),
                  color: AppColors.primary,
                  size: 15,
                ),
              ])),
        );
        counter += 400;
      }
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: LatLng(53.7444, -0.3324),
            initialZoom: 14,
            onPositionChanged: (_, __) {
              if (mapReady) setState(() {});
            },
            interactionOptions: InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}.png?api_key=b4b489af-f45d-442e-bb7e-88ebbacb7c3e',
            ),
            MarkerLayer(markers: markers)
          ],
        ),

        // Overlay upright labels

        // Positioned(
        //   left: screenPos.x,
        //   top: screenPos.y,
        //   child: Transform.rotate(
        //     angle: -rotation, // keep upright
        //     child: Container(
        //       padding: const EdgeInsets.all(4),
        //       decoration: BoxDecoration(
        //         color: Colors.white.withOpacity(0.85),
        //         borderRadius: BorderRadius.circular(4),
        //       ),
        //       child: Text(
        //         label['name'] as String,
        //         style: const TextStyle(
        //           fontSize: 12,
        //           fontWeight: FontWeight.bold,
        //           color: Colors.black,
        //         ),
        //       ),
        //     ),
        //   ),
        // )
      ],
    );
  }

  Widget scroll(AsyncSnapshot snapshot) {
    return Positioned(
      // your widget on top
      // top: 20,
      left: 0,
      right: 0,
      bottom: 20,
      child: Container(
        height: 260,
        width: 6000,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.transparent, // ⭐ makes it visible over the map
          // borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: scrollBuildFromData(snapshot),
      ),
    );
  }

  Widget scrollBuildFromData(AsyncSnapshot snapshot) {
    // LOADING STATE
    if (snapshot.connectionState == ConnectionState.waiting) {
      return ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: 10,
        itemBuilder: (context, index) => const BusinessBlock(
          businessLoc: BusinessLoc(
            locId: 0,
            name: "---",
            macroType: "",
            locations: [],
            bId: 0,
            primaryType: 0,
            location: [0, 0],
            owneremail: "",
            address: "",
            distance: 67,
          ),
          scaleDown: 2,
        ),
        separatorBuilder: (context, index) => const SizedBox(width: 20),
      );
    }

    // DATA STATE
    else if (snapshot.hasData) {
      if (snapshot.data!.isEmpty) {
        slog.e("BUILD SCROLL VIEW || NO DATA");
        return const Center(
            child: MainText("No businesses found", AppColors.text));
      } else {
        return ListView.separated(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final String businessLocationId = snapshot.data![index];
            return BusinessLocationThumbnail(locationId: businessLocationId);
          },
          separatorBuilder: (context, index) => const SizedBox(width: 20),
        );
      }
    }

    // ERROR STATE
    else {
      slog.e(snapshot.error);
      return Center(child: Text("Error loading businesses ${snapshot.error}"));
    }
  }

  Widget locationButtonBuild(BuildContext context) {
    return Positioned(
      right: 10,
      bottom: 280,
      child: locationButton(context),
    );
  }

  Widget locationButton(BuildContext context) {
    return Material(
      color: Colors.white, // background
      shape: const CircleBorder(), // makes it round
      elevation: 6, // shadow
      child: InkWell(
        customBorder: const CircleBorder(), // ripple stays circular
        onTap: () {
          dropDown();
        },
        child: const Padding(
          padding: EdgeInsets.all(12), // size of the button
          child: Icon(
            Icons.location_searching,
            size: 28,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  void rebuild() {
    setState(() {}); // forces ENTIRE widget to rebuild
  }

  void dropDown() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "",
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Material(
            // ⭐ REQUIRED
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              width: 300,
              height: 300,
              child: MyVertMultiToggle(
                initial: 0,
                options: const ["Your Location", "Choose Location"],
                onChanged: (id) {
                  if (id == 0) {
                    getLocation().then((pos) {
                      arbitStore.data["userLocation"] = [
                        pos.latitude,
                        pos.longitude
                      ];
                      rebuild(); // refresh the whole widget
                    });
                  }

                  rebuild();
                },
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return Transform.scale(
          scale: anim.value,
          child: Opacity(
            opacity: anim.value,
            child: child,
          ),
        );
      },
    );
  }

  Future<dynamic> mapFuture() async {
    final List<String> toReturn =
        List<String>.from(await serverconnect.getNearbyBusinesses(
      location: [53.7446, -0.3352],
      query: widget.query,
      elecSafeOnly: arbitStore.data["electricitySafeOnly"],
      gasSafeOnly: arbitStore.data["gasSafeOnly"],
      maxdist: arbitStore.data["distance"],
      idOnly: true,
    ));

    await businessManager.getBusinessLocationMini(toReturn);
    return toReturn;
  }

  @override
  Widget build(BuildContext context) {
    slog.i("MY LOCATION : ${arbitStore.data["userLocation"]}");
    return FutureBuilder<dynamic>(
        future: mapFuture(),
        builder: (context, snapshot) {
          if (arbitStore.data["userLocation"].isEmpty) {
            return const SizedBox();
          } else {
            return Stack(children: [
              map(snapshot),
              scroll(snapshot),
              locationButtonBuild(context)
            ]);
          }
        });
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.query});
  final String query;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    // log.i(widget.query);
    return Scaffold(
        appBar: newsearchbar(context),
        bottomNavigationBar: newbottombar(context),
        body: MapSearchView(
          query: widget.query,
        ));
  }
}
