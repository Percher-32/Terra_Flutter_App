import 'package:flutter/material.dart';
import 'package:nextfind/utils/locationmanager.dart';
import 'package:nextfind/widgets/widgets.dart';
import 'package:nextfind/networking/apiconn.dart';
import 'package:nextfind/utils/businessManager.dart';
import 'package:logger/logger.dart';
import 'package:nextfind/utils/arbitStore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import "package:nextfind/widgets/newwidgets.dart";

final log = Logger();

class MapSearchView extends StatefulWidget {
  const MapSearchView({super.key, this.location = const [53.7446, -0.3352]});

  final List location;

  @override
  State<MapSearchView> createState() => _MapSearchViewState();
}

class _MapSearchViewState extends State<MapSearchView> {
  late List usedLocation = [0.0, 0.0];
  var scrollController = ScrollController(initialScrollOffset: 0);

  @override
  void initState() {
    super.initState();
    usedLocation = widget.location; // ✔ mutable copy
    if (arbitStore.data.containsKey("mapPointLocation")) {
      usedLocation = arbitStore.data["mapPointLocation"];
    }
  }

  FlutterMap map(AsyncSnapshot snapshot) {
    List<Marker> markers = [];
    markers.add(
      Marker(
          point: LatLng(usedLocation[0], usedLocation[1]),
          width: 40,
          height: 40,
          child: const Column(mainAxisSize: MainAxisSize.min, children: [
            // HText(bloc.name, color: AppColors.main),
            Icon(
              Icons.location_pin,
              size: 40,
              color: Colors.blue,
            ),
          ])),
    );
    if (snapshot.hasData) {
      int counter = 0;
      for (BusinessLoc bloc in snapshot.data!) {
        arbitStore.data["${bloc.name}${bloc.location} MARKER"] =
            (counter * 1).toDouble();
        markers.add(
          Marker(
              point: LatLng(bloc.location[0], bloc.location[1]),
              width: 40,
              height: 40,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // HText(bloc.name, color: AppColors.main),
                IconButton(
                  onPressed: () {
                    scrollController.animateTo(
                      arbitStore.data[
                          "${bloc.name}${bloc.location} MARKER"], // pixel offset
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                    );
                  },
                  icon: const Icon(
                    Icons.location_pin,
                    size: 40,
                    color: Colors.red,
                  ),
                )
              ])),
        );

        counter += 420;
      }
    }

    final markerLayer = MarkerLayer(markers: markers);

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(usedLocation[0], usedLocation[1]), // Hull
        initialZoom: 13,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'com.nextfind.app',
        ),
        markerLayer
      ],
    );
  }

  Widget scroll(AsyncSnapshot<dynamic> snapshot) {
    return Positioned(
      // your widget on top
      // top: 20,
      left: 0,
      right: 0,
      bottom: 20,
      child: Container(
        height: 200,
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

  Widget scrollBuildFromData(AsyncSnapshot<dynamic> snapshot) {
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
            final BusinessLoc businesloc = snapshot.data![index];
            return BusinessBlock(
              businessLoc: businesloc,
              scaleDown: 2,
            );
          },
          separatorBuilder: (context, index) => const SizedBox(width: 20),
        );
      }
    }

    // ERROR STATE
    else {
      return const Center(child: Text("Error loading businesses"));
    }
  }

  Widget locationButtonBuild(BuildContext context) {
    return Positioned(
      right: 10,
      bottom: 250,
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
              padding: const EdgeInsets.all(40),
              width: 300,
              height: 300,
              child: VertMultiToggle(
                initial: 0,
                options: const ["Your Location", "Choose Location"],
                onChanged: (id) {
                  if (id == 0) {
                    getLocation().then((pos) {
                      arbitStore.data["userLocation"] = [
                        pos.latitude,
                        pos.longitude
                      ];
                      usedLocation = arbitStore.data["userLocation"];
                      arbitStore.data["mapPointLocation"] = usedLocation;
                      rebuild(); // refresh the whole widget
                    });
                  }

                  log.d(arbitStore.data);
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
        future: serverconnect.getNearbyBusinesses(
          location: usedLocation,
          query: nameController.text,
          elecSafeOnly: arbitStore.data["electricitySafeOnly"],
          gasSafeOnly: arbitStore.data["gasSafeOnly"],
          maxdist: arbitStore.data["distance"],
          // btypes: [arbitStore.data["categoryINDEX"]],
        ),
        builder: (context, snapshot) {
          if (usedLocation.isEmpty) {
            return SizedBox();
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
  const SearchPage({super.key, required this.title});
  final String title;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: searchbar(context),
        bottomNavigationBar: bottombar(context),
        body: const MapSearchView());
  }
}
