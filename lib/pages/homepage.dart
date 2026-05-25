import 'package:flutter/material.dart';
import 'package:nextfind/networking/apiconn.dart';
import 'package:nextfind/theme/app_theme.dart';
import 'package:nextfind/utils/businessManager.dart';
import 'package:nextfind/widgets/widgets.dart';
import 'package:nextfind/utils/arbitStore.dart';
import 'package:logger/logger.dart';
// import 'package:nextfind/theme/app_theme.dart';

final log = Logger();

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<BusinessLoc>? trendingBusinesses;
  DateTime? trendingBusinessesLastUpdate;
  late Future<dynamic> feedFuture;

  @override
  void initState() {
    super.initState();
    feedFuture = buildFeed();
  }

  Future<dynamic> buildFeed() async {
    log.i("RUNNING THE BUILD FEED TASK");
    final nearbyBus = await serverconnect.getNearbyBusinesses(
      location: arbitStore.data["userLocation"],
      sort: "RAT",
      maxdist: 500,
    );

    if (trendingBusinesses != null) {
      if ((DateTime.now().difference(trendingBusinessesLastUpdate!).inMinutes >
          5)) {
        trendingBusinesses = await serverconnect.getTrending();
        trendingBusinessesLastUpdate = DateTime.now();
      }
    } else {
      trendingBusinesses = await serverconnect.getTrending();
      trendingBusinessesLastUpdate = DateTime.now();
    }

    return nearbyBus;
  }

  Widget myBody(BuildContext context) {
    return Stack(
      children: [
        Positioned(top: 70, left: 0, right: 0, child: mainFeedBuilder()),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Container(
                height: 40 + 30,
                color: Colors.red,
                alignment: Alignment.center,
                child: const Text("Top bar above AppBar"),
              ),
              searchbar(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget trendScroll(BuildContext context) {
    return Column(
      spacing: 20,
      children: [
        const HText(
          "Trending Now",
          color: AppColors.main,
        ),
        SizedBox(
            height: 240,
            child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  BusinessLoc trendyBusiness = trendingBusinesses![index];
                  return BusinessBlock(
                    businessLoc: trendyBusiness,
                    scaleDown: 2,
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(width: 50),
                itemCount: trendingBusinesses!.length))
      ],
    );
  }

  Widget mainFeedBuilder() {
    return FutureBuilder<dynamic>(
      future: buildFeed(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            height: MediaQuery.of(context)
                .size
                .height, // or whatever height you want
            child: ListView.separated(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: 3,
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
                  meanRating: 0,
                  desc: "--------------------------",
                ),
              ),
              separatorBuilder: (context, index) => const SizedBox(height: 50),
            ),
          );
        }

        return SizedBox(
          height: MediaQuery.of(context).size.height,
          child: ListView.separated(
            controller: ScrollController(initialScrollOffset: 0),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemCount: snapshot.data!.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const SizedBox(
                  height: 50,
                );
              } else if (index == 1) {
                return trendScroll(context);
              } else {
                final BusinessLoc businesloc = snapshot.data![index - 2];
                return BusinessBlock(businessLoc: businesloc);
              }
            },
            separatorBuilder: (context, index) => const SizedBox(height: 50),
            padding: const EdgeInsets.only(top: 20, bottom: 20),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // appBar: myBody(context),
        bottomNavigationBar: bottombar(context),
        body: myBody(context));
  }
}
