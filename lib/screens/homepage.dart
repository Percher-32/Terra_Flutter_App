import 'package:flutter/material.dart';
import 'package:nextfind/helpers/networking.dart';
import 'package:nextfind/helpers/debug_options.dart';
import 'package:nextfind/helpers/logger.dart';
import 'package:nextfind/models/business_models.dart';
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
  bool _hasWifi = true;
  late List<MiniBusinessLoc>? trendingMiniBusLocs;

  @override
  void initState() {
    super.initState();
  }

  Future<dynamic> buildFeed() async {
    _hasWifi = await Networking.isOnline();

    if (!_hasWifi && !NextfindDebugOptions.useBusinessDataTestData) {
      return;
    }

    final nearbyBus = await BusinessService.getNearbyBusinesses(
        location: UserService.userLocation,
        sort: "RAT",
        maxdist: 500,
        idOnly: true);

    trendingMiniBusLocs = await BusinessService.getTrendingBusinesses();

    return nearbyBus;
  }

  Widget trendScroll(BuildContext context) {
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
                    String trendyBusinessId =
                        trendingMiniBusLocs![index - 1].businessId;
                    return BusinessLocationThumbnail(
                      locationId: trendyBusinessId,
                    );
                  }
                },
                separatorBuilder: (context, index) => const SizedBox(width: 20),
                itemCount: trendingMiniBusLocs!.length + 1))
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
        body: Stack(
          children: [
            Positioned(top: -50, left: 0, right: 0, child: mainFeedBuilder()),
          ],
        ));
  }
}
