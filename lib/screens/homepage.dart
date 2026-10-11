import 'package:flutter/material.dart';
import 'package:nextfind/helpers/networking.dart';
import 'package:nextfind/helpers/logger.dart';
import 'package:nextfind/services/business_services.dart';
import 'package:nextfind/services/navbar_services.dart';
import 'package:nextfind/services/search_services.dart';
import 'package:nextfind/services/user_services.dart';
import 'package:nextfind/widgets/main_widgets.dart';
import 'package:nextfind/widgets/business_widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String>? trendingBusinesses;
  DateTime? trendingBusinessesLastUpdate;
  List<String>? allUrls;
  bool _hasWifi = true;

  @override
  void initState() {
    super.initState();
    _hasWifi = true;
  }

  Future<dynamic> buildFeed() async {
    _hasWifi = await Networking.isOnline();

    if (!_hasWifi) {
      return;
    }

    final nearbyBus = await BusinessService.getNearbyBusinesses(
        location: UserService.userLocation,
        sort: "RAT",
        maxdist: 500,
        idOnly: true);


    if (trendingBusinesses != null) {
      if ((DateTime.now().difference(trendingBusinessesLastUpdate!).inMinutes >
          5)) {
        trendingBusinesses = await BusinessService.getTrendingBusinessIds();
        trendingBusinessesLastUpdate = DateTime.now();
      }
    } else {
      trendingBusinesses = await BusinessService.getTrendingBusinessIds();
      trendingBusinessesLastUpdate = DateTime.now();
    }

    final allTrendyBusinesses =
        await BusinessService.getBusinessLocationMini(trendingBusinesses!);

    if (trendingBusinesses != null) {
      allUrls = trendingBusinesses!
          .map((b) => allTrendyBusinesses[b]?.thumbnailPath)
          .where((url) => url != null)
          .cast<String>()
          .toList();
    }

    return nearbyBus;
  }

  Widget myBody(BuildContext context) {
    return Stack(
      children: [
        Positioned(top: -50, left: 0, right: 0, child: mainFeedBuilder()),
      ],
    );
  }

  Widget trendScroll(BuildContext context) {
    if (allUrls != null) {
      BusinessService.startPreloadingImages(
          context, allUrls!.take(10).toList());
    }

    return Column(
      spacing: 20,
      // mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SubHeading(
          "Trending Now🔥",
          color: AppColors.text,
        ),
        SizedBox(
            height: 260,
            child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const SizedBox(width: 0);
                  } else {
                    String trendyBusinessId = trendingBusinesses![index - 1];
                    return BusinessLocationThumbnail(
                      locationId: trendyBusinessId,
                    );
                  }
                },
                separatorBuilder: (context, index) => const SizedBox(width: 20),
                itemCount: trendingBusinesses!.length + 1))
      ],
    );
  }

  Widget mainFeedBuilder() {
    return FutureBuilder<dynamic>(
      future: buildFeed(),
      builder: (context, snapshot) {
        if (!_hasWifi) {
          return const Center(
            child: Heading("No Internet "),
          );
        }

        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        } else {
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
                    height: 0,
                  );
                } else if (index == 1) {
                  return trendScroll(context);
                } else {
                  return Center(
                      child: BusinessLocationThumbnail(
                          locationId: snapshot.data[index - 2]));
                }
              },
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              padding: const EdgeInsets.only(top: 20, bottom: 20),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: SearchServices.createSearchBar(context),
        bottomNavigationBar: const NavBar(currentPage: AppPages.homepage),
        body: myBody(context));
  }
}
