import 'package:flutter/material.dart';
import 'package:nextfind/helpers/networking.dart';
import 'package:nextfind/helpers/debug_options.dart';
import 'package:nextfind/helpers/logger.dart';
import 'package:nextfind/models/business_models.dart';
import 'package:nextfind/page_moves.dart';
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

  @override
  void initState() {
    super.initState();
  }

  Future<
      ({
        List<MiniBusinessLocation>? trendingBusinesses,
        List<MiniBusinessLocation>? nearbyBusinesses
      })?> buildFeed() async {
    _hasWifi = await Networking.isOnline();

    if (!_hasWifi && !NextfindDebugOptions.useBusinessDataTestData) {
      log.d("No Wifi Found -> TERMINATING BUILD");
      return null;
    }

    final nearbyBusinesses = await BusinessService.getNearbyBusinesses(
        location: UserService.userLocation, sort: "RAT", maxdist: 500);

    final trendingMiniBusLocations =
        await BusinessService.getTrendingBusinesses();
    log.i("BARK BUILT PAGE");
    return (
      trendingBusinesses: trendingMiniBusLocations,
      nearbyBusinesses: nearbyBusinesses
    );
  }

  @override
  Widget build(BuildContext context) {
    log.i("BARK HOMEPAGE");
    return Scaffold(
        appBar: SearchServices.createSearchBar(context),
        bottomNavigationBar: const NavBar(currentPage: AppPages.homepage),
        body: Stack(
          children: [
            Positioned(
                top: -50,
                left: 0,
                right: 0,
                child: FutureBuilder<
                    ({
                      List<MiniBusinessLocation>? trendingBusinesses,
                      List<MiniBusinessLocation>? nearbyBusinesses
                    })?>(
                  future: buildFeed(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      log.i("BARK Error");
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        showErrorMessage(context, "Error ${snapshot.error}");
                      });
                      return const SizedBox();
                    } else if (!snapshot.hasData) {
                      log.i("BARK WIAT");
                      return const LinearProgressIndicator();
                    } else if (snapshot.data!.nearbyBusinesses == null) {
                      log.i("BARK ERROR");

                      showErrorMessage(
                          context, "Error Geting Nearby Businesses");
                      return const SizedBox();
                    } else if (snapshot.data!.trendingBusinesses == null) {
                      log.i("BARK ERROR");

                      showErrorMessage(
                          context, "Error Geting Trending Businesses");
                      return const SizedBox();
                    } else {
                      log.i("BARK SHOWING TRENDIN BAR");
                      return SizedBox(
                        height: MediaQuery.of(context).size.height,
                        child: ListView.separated(
                          controller: ScrollController(initialScrollOffset: 0),
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          itemCount:
                              snapshot.data!.nearbyBusinesses!.length + 2,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return const SizedBox(
                                height: 0,
                              );
                            } else if (index == 1) {
                              return TrendScrollWidget(
                                  trendingBusinesses:
                                      snapshot.data!.trendingBusinesses!);
                            } else {
                              return Center(
                                  child: BusinessLocationThumbnail(
                                      locationId: snapshot
                                          .data!
                                          .nearbyBusinesses![index - 2]
                                          .locationId));
                            }
                          },
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 20),
                          padding: const EdgeInsets.only(top: 20, bottom: 20),
                        ),
                      );
                    }
                  },
                )),
          ],
        ));
  }
}

class TrendScrollWidget extends StatelessWidget {
  const TrendScrollWidget({super.key, required this.trendingBusinesses});

  final List<MiniBusinessLocation> trendingBusinesses;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 20,
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
                    String trendyBusinessLocationId =
                        trendingBusinesses[index - 1].locationId;
                    return BusinessLocationThumbnail(
                      locationId: trendyBusinessLocationId,
                    );
                  }
                },
                separatorBuilder: (context, index) => const SizedBox(width: 20),
                itemCount: trendingBusinesses.length + 1))
      ],
    );
  }
}
