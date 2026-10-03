import 'package:flutter/material.dart';
import 'package:nextfind/services/business_services.dart';
import 'package:nextfind/models/business_models.dart';
import 'package:logger/logger.dart';
import 'package:nextfind/helpers/conversions.dart';
import 'package:nextfind/services/search_services.dart';
import 'package:nextfind/page_moves.dart';
import 'package:nextfind/widgets/main_widgets.dart';
import 'package:intl/intl.dart';

final log = Logger();

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
  late Future<Map<String, MiniBusinessLoc>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = BusinessService.getBusinessLocationMini([widget.locationId]);
  }

  Widget buildWidget(BuildContext context,
      AsyncSnapshot<Map<String, MiniBusinessLoc>> snapshot) {
    if (snapshot.hasData) {
      if (snapshot.data is! Map) {
        // log.i("SNAPSHOTRUNT ISNT Map ITS  : ${snapshot.data.runtimeType}");
        return const SizedBox();
      }

      log.i("SNAPSHOTRUNT : ${snapshot.data!} || ${widget.locationId} ");

      final minibusinessLocation = snapshot.data![widget.locationId]!;
      String ratings = "No Ratings";
      if (minibusinessLocation.numRatings != null) {
        ratings =
            "${minibusinessLocation.averageRating!.toStringAsFixed(2)}/10 (${minibusinessLocation.numRatings!})";
      }

      bool open = false;
      String? signTime;
      String openString = "";

      final openTimes = minibusinessLocation.openHours;

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

      if (!minibusinessLocation.verified) {
        unVerifiedBadge = Image.asset(
            "assets/icons/business_icons/unverified_badge.png",
            scale: 3);
      }

      String iconPath = "assets/icons/svg_logo.png";
      if (minibusinessLocation.type == 0) {
        iconPath =
            "assets/icons/business_type_icons/food_and_dining_icon_alt.png";
      } else if (minibusinessLocation.type == 1) {
        iconPath =
            "assets/icons/business_type_icons/home_services_icon_alt.png";
      } else if (minibusinessLocation.type == 2) {
        iconPath =
            "assets/icons/business_type_icons/health_and_wellness_icon_alt.png";
      } else if (minibusinessLocation.type == 3) {
        iconPath =
            "assets/icons/business_type_icons/shopping_and_retail_icon_alt.png";
      } else if (minibusinessLocation.type == 4) {
        iconPath =
            "assets/icons/business_type_icons/proffesional_services_icon_alt.png";
      } else if (minibusinessLocation.type == 5) {
        iconPath = "assets/icons/business_type_icons/automotive_icon_alt.png";
      } else if (minibusinessLocation.type == 6) {
        iconPath =
            "assets/icons/business_type_icons/beauty_and_personal_care_icon_alt.png";
      } else if (minibusinessLocation.type == 7) {
        iconPath =
            "assets/icons/business_type_icons/entertainment_and_leisure_icon_alt.png";
      } else if (minibusinessLocation.type == 8) {
        iconPath = "assets/icons/business_type_icons/education_icon_alt.png";
      } else if (minibusinessLocation.type == 9) {
        iconPath =
            "assets/icons/business_type_icons/lodging_and_travel_icon_alt.png";
      }

      return SizedBox(
        width: 380,
        height: 260,
        child: Stack(
          children: [
            // SHADOW ONLY
            Positioned(
              left: 0,
              top: 0,
              child: IgnorePointer(
                child: Container(
                  width: 380,
                  height: 240,
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
                borderRadius: BorderRadius.circular(30),
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  splashColor: const Color.fromARGB(255, 229, 233, 234),
                  onTap: () {
                    goToBusinessPage(context, minibusinessLocation.locationId);
                  },
                  child: SizedBox(
                    width: 380,
                    height: 240,
                    child: Stack(
                      children: [
                        // RIGHT SIDE CONTENT
                        Positioned(
                          left: 210,
                          top: 10,
                          child: SizedBox(
                            width: 150,
                            child: Column(
                              spacing: 5,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                      minWidth: 150,
                                      maxWidth: 150,
                                      minHeight: 30,
                                      maxHeight: 100),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      MyText(
                                        minibusinessLocation.name,
                                        color: AppColors.primary,
                                        size: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      SizedBox(
                                          width: 200,
                                          height: 50 - 13,
                                          child: Stack(
                                              alignment:
                                                  AlignmentGeometry.center,
                                              children: [
                                                Positioned(
                                                    left: -2,
                                                    child: Image.asset(iconPath,
                                                        width: 30, height: 30)),
                                                Positioned(
                                                    left: 30,
                                                    child: MyText(
                                                      color: AppColors.primary,
                                                      businessTypeLookup[
                                                          minibusinessLocation
                                                              .type]!,
                                                      size: 14,
                                                    )),
                                              ])),
                                    ],
                                  ),
                                ),
                                Stack(
                                    alignment: AlignmentDirectional.center,
                                    // fit: StackFit.expand,
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned(
                                          child: Image.asset(
                                              "assets/icons/business_icons/rating_star.png")),
                                      Positioned(
                                          top: -1,
                                          left: 30,
                                          child: Small(ratings))
                                    ]),
                                Stack(
                                    alignment: AlignmentDirectional.center,
                                    // fit: StackFit.expand,
                                    clipBehavior: Clip.none,
                                    children: [
                                      const Positioned(
                                          // left: 0,
                                          // top: 0,
                                          child: Icon(Icons.location_on_sharp)),
                                      Positioned(
                                          top: -1,
                                          left: 30,
                                          child: MyText(
                                            parseAddress(
                                                minibusinessLocation.address,
                                                minibusinessLocation
                                                    .buildingNumber),
                                            size: 13,
                                          ))
                                    ]),
                                const SizedBox(
                                  height: 15,
                                ),
                                Stack(
                                  alignment: AlignmentDirectional.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned(
                                        child: Image.asset(
                                            "assets/icons/business_icons/distance_icon.png")),
                                    Positioned(
                                      top: -10,
                                      left: 30,
                                      child: ValueListenableBuilder(
                                          valueListenable: SearchServices.isMetric,
                                          builder: (_, __, ___) {
                                            return Small(SearchServices.isMetric.value
                                                ? "${minibusinessLocation.distance.toStringAsFixed(2)} km"
                                                : "${kmToMiles(minibusinessLocation.distance).toStringAsFixed(2)} miles");
                                          }),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // UNVERIFIED BADGE
                        Positioned(
                            bottom: 10, right: 10, child: unVerifiedBadge),

                        // LEFT SIDE IMAGE + STATUS
                        Positioned(
                          left: 13.15,
                          top: 13.15,
                          child: Column(
                            spacing: 10,
                            children: [
                              BaseImage(
                                url: minibusinessLocation.thumbnailPath ??
                                    "No Url",
                              ),
                              Small(openString),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
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
            AsyncSnapshot<Map<String, MiniBusinessLoc>> snapshot) {
          return buildWidget(context, snapshot);
        });
  }
}
