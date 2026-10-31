import 'package:flutter/material.dart';
import 'package:nextfind/services/business_services.dart';
import 'package:nextfind/models/business_models.dart';
import 'package:nextfind/helpers/conversions.dart';
import 'package:nextfind/helpers/logger.dart';
import 'package:nextfind/services/search_services.dart';
import 'package:nextfind/page_moves.dart';
import 'package:nextfind/services/tag_services.dart';
import 'package:nextfind/widgets/main_widgets.dart';
import 'package:intl/intl.dart';

bool isBetween(DateTime start, DateTime end, DateTime now) {
  return now.isAfter(start) && now.isBefore(end);
}

String parseAddress(Map address, int houseNumber) {
  String addressString = "";

  addressString += houseNumber.toString();

  addressString += " ${address["road"] ?? "INVALID POSITION"}";

  addressString += "\n${address["postcode"] ?? "INVALID POSITION"}";

  return addressString;
}

class BusinessLocationThumbnail extends StatefulWidget {
  const BusinessLocationThumbnail(
      {required this.locationId, super.key, this.scale = 1});
  final String locationId;
  final double scale;

  @override
  State<BusinessLocationThumbnail> createState() =>
      _BusinessLocationThumbnailState();
}

class _BusinessLocationThumbnailState extends State<BusinessLocationThumbnail>
    with AutomaticKeepAliveClientMixin {
  late Future<Map<String, MiniBusinessLocation>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = BusinessService.getBusinessLocationMini([widget.locationId]);
  }

  Widget buildWidget(BuildContext context,
      AsyncSnapshot<Map<String, MiniBusinessLocation>> snapshot) {
    if (snapshot.hasData) {
      if (snapshot.data is! Map) {
        return const SizedBox();
      }

      final miniBusinessLocation = snapshot.data![widget.locationId]!;
      return BusinessLocationThumbnailBodyWidget(
          miniBusinessLocation: miniBusinessLocation);
    } else if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    } else {
      return const CircularProgressIndicator();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
        future: _future,
        builder: (BuildContext context,
            AsyncSnapshot<Map<String, MiniBusinessLocation>> snapshot) {
          return buildWidget(context, snapshot);
        });
  }
}

class BusinessLocationThumbnailBodyWidget extends StatelessWidget {
  const BusinessLocationThumbnailBodyWidget(
      {super.key, required this.miniBusinessLocation});
  final MiniBusinessLocation miniBusinessLocation;

  @override
  Widget build(BuildContext context) {
    String ratings = "No Ratings";
    if (miniBusinessLocation.numRatings != null) {
      ratings =
          "${miniBusinessLocation.averageRating!.toStringAsFixed(2)}/10 (${miniBusinessLocation.numRatings!})";
    }

    bool open = false;
    String? signTime;
    String openString = "";

    final openTimes = miniBusinessLocation.openHours;

    if (openTimes != null) {
      final weekday = DateTime.now().weekday.toString();

      if (openTimes.containsKey(weekday)) {
        List<dynamic> times = openTimes[weekday];

        final openTime = DateFormat("HH:mm").parse(times[0]);
        final closeTime = DateFormat("HH:mm").parse(times[1]);
        final timeNow =
            DateTime(1970, 1, 1, DateTime.now().hour, DateTime.now().minute);

        if (isBetween(openTime, closeTime, timeNow) == true) {
          open = true;
          signTime = times[1];
        } else {
          signTime = times[0];
        }
      }

      if (signTime == null) {
        openString = "Closed Forever";
      } else {
        if (open) {
          openString = "Open - Closes $signTime";
        } else {
          openString = "Closed - Opens $signTime";
        }
      }
    }

    Widget unVerifiedBadge = const SizedBox();

    if (!miniBusinessLocation.verified) {
      unVerifiedBadge = Image.asset(
          "assets/icons/business_icons/unverified_badge.png",
          scale: 3);
    }

    String iconPath = "assets/icons/svg_logo.png";
    if (miniBusinessLocation.type == 0) {
      iconPath =
          "assets/icons/business_type_icons/food_and_dining_icon_alt.png";
    } else if (miniBusinessLocation.type == 1) {
      iconPath = "assets/icons/business_type_icons/home_services_icon_alt.png";
    } else if (miniBusinessLocation.type == 2) {
      iconPath =
          "assets/icons/business_type_icons/health_and_wellness_icon_alt.png";
    } else if (miniBusinessLocation.type == 3) {
      iconPath =
          "assets/icons/business_type_icons/shopping_and_retail_icon_alt.png";
    } else if (miniBusinessLocation.type == 4) {
      iconPath =
          "assets/icons/business_type_icons/proffesional_services_icon_alt.png";
    } else if (miniBusinessLocation.type == 5) {
      iconPath = "assets/icons/business_type_icons/automotive_icon_alt.png";
    } else if (miniBusinessLocation.type == 6) {
      iconPath =
          "assets/icons/business_type_icons/beauty_and_personal_care_icon_alt.png";
    } else if (miniBusinessLocation.type == 7) {
      iconPath =
          "assets/icons/business_type_icons/entertainment_and_leisure_icon_alt.png";
    } else if (miniBusinessLocation.type == 8) {
      iconPath = "assets/icons/business_type_icons/education_icon_alt.png";
    } else if (miniBusinessLocation.type == 9) {
      iconPath =
          "assets/icons/business_type_icons/lodging_and_travel_icon_alt.png";
    }

    return SizedBox(
      width: 380,
      height: 260 + 20,
      child: Stack(
        children: [
          // SHADOW ONLY
          Positioned(
            left: 0,
            top: 0,
            child: IgnorePointer(
              child: Container(
                width: 380,
                height: 260,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromARGB(62, 101, 101, 101),
                      blurRadius: 10,
                      offset: Offset(-7, 10),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ACTUAL CARD (Material + InkWell)
          Positioned(
            left: 0,
            top: 0,
            child: Material(
              color: Colors.white,
              // surfaceTintColor: app,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.hardEdge,
              child: InkWell(
                splashColor: const Color.fromARGB(255, 229, 233, 234),
                onTap: () {
                  goToBusinessPage(context, miniBusinessLocation.locationId);
                },
                child: SizedBox(
                  width: 380,
                  height: 260,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BaseImage(
                          radius: 10,
                          width: 380,
                          height: 165,
                          url: miniBusinessLocation.thumbnailPath ?? "No Url"),
                      Row(children: [
                        const SizedBox(
                          width: 10,
                        ),
                        MyText(
                          miniBusinessLocation.name,
                          color: AppColors.primary,
                          size: 17,
                          fontWeight: FontWeight.w200,
                          maxlines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      ]),
                      const SizedBox(
                        height: 0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 10,
                          ),
                          Image.asset(
                              "assets/icons/business_icons/rating_star.png"),
                          const SizedBox(
                            width: 5,
                          ),
                          MyText(
                            ratings,
                            color: AppColors.primary,
                            size: 15,
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          Image.asset(iconPath, width: 25, height: 25),
                          MyText(
                            color: AppColors.primary,
                            businessTypeLookup[miniBusinessLocation.type]!,
                            size: 15,
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          RepaintBoundary(
                              child: ValueListenableBuilder(
                                  valueListenable: SearchServices.isMetric,
                                  builder: (_, __, ___) {
                                    return MyText(
                                      "${miniBusinessLocation.distance.toStringAsFixed(2)} ${SearchServices.isMetric.value ? "km" : "mi"}",
                                      size: 15,
                                      color: AppColors.primary,
                                    );
                                  })),
                          // unVerifiedBadge
                        ],
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Row(children: [
                        const SizedBox(
                          width: 10,
                        ),
                        ...[
                          for (int tagId in miniBusinessLocation.tags)
                            Row(children: [
                              MyText(
                                  "${TagServices.tagLookup[tagId]!.name}  ${(tagId == miniBusinessLocation.tags.last) ? "" : "•"}",
                                  size: 12,
                                  maxlines: 1,
                                  overflow: TextOverflow.clip,
                                  color: AppColors.primary),
                              const SizedBox(
                                width: 4,
                              )
                            ])
                        ],
                      ])
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            right: 10,
            top: 10,
            child: unVerifiedBadge,
          ),
        ],
      ),
    );
  }
}
