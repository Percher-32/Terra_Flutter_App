import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nextfind/helpers/networking.dart';
import 'package:nextfind/helpers/debug_options.dart';
import 'package:nextfind/helpers/logger.dart';
import 'package:nextfind/models/business_models.dart';
import 'package:nextfind/page_moves.dart';
import 'package:nextfind/services/business_services.dart';
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
  // num scrollValue = 0;
  ScrollController scrollController = ScrollController(initialScrollOffset: 0);
  final ValueNotifier<double> _scrollOffset = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      _scrollOffset.value = scrollController.offset;
    });
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
    _scrollOffset.dispose();
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
    return (
      trendingBusinesses: trendingMiniBusLocations,
      nearbyBusinesses: nearbyBusinesses
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const PreferredSize(
            preferredSize: Size.fromHeight(80),
            child: Column(children: [
              SizedBox(height: 50),
              MySearchBar(tag: "homepagetag"),
            ])),
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
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        showErrorMessage(context, "Error ${snapshot.error}");
                      });
                      return const SizedBox();
                    } else if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    } else if (snapshot.data!.nearbyBusinesses == null) {
                      showErrorMessage(
                          context, "Error Geting Nearby Businesses");
                      return const SizedBox();
                    } else if (snapshot.data!.trendingBusinesses == null) {
                      log.i("BARK ERROR");

                      showErrorMessage(
                          context, "Error Geting Trending Businesses");
                      return const SizedBox();
                    } else {
                      final names = [
                        "Trending Now",
                        "Really Popular",
                        "Hidden Gems",
                        "Discounts"
                      ];
                      return SizedBox(
                        height: MediaQuery.of(context).size.height,
                        child: ListView.separated(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          itemCount: names.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return const SizedBox(
                                height: 0,
                              );
                            } else {
                              return TrendScrollWidget(
                                trendingBusinesses: index % 1 == 0
                                    ? snapshot.data!.trendingBusinesses!
                                    : snapshot
                                        .data!.trendingBusinesses!.reversed
                                        .toList(),
                                title: names[index - 1],
                              );
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
  const TrendScrollWidget(
      {super.key, required this.trendingBusinesses, required this.title});
  final String title;

  final List<MiniBusinessLocation> trendingBusinesses;

  @override
  Widget build(BuildContext context) {
    return Column(spacing: 20, children: [
      const SizedBox(
        width: 10,
      ),
      SubHeading(
        title,
        color: AppColors.text,
      ),
      SizedBox(
          // height: 500,
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                const SizedBox(width: 10), // Leading padding
                for (int i = 0; i < trendingBusinesses.length; i++) ...[
                  BusinessLocationThumbnail(
                    locationId: trendingBusinesses[i].locationId,
                  ),
                  // Add a separator space after every item except the last one
                  if (i < trendingBusinesses.length - 1)
                    const SizedBox(width: 20),
                ],
                const SizedBox(width: 10),
              ])))
    ]);
  }
}
