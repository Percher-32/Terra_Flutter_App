import 'dart:math';

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


  final ScrollController scrollController = ScrollController(initialScrollOffset: 0);


  @override
  void initState() {
    super.initState();
    _future = BusinessService.getBusinessLocationMini([widget.locationId]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
        future: _future,
        builder: (BuildContext context,
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

    String iconPath = businessIconLookupAlt[miniBusinessLocation.type]!;

    double screenWidth = MediaQuery.of(context).size.width;

    double cardWidth = screenWidth > 450 ? 450 * 0.85 : screenWidth * 0.85;

    return SizedBox(
      width: cardWidth,
      height: 270,
      child: Padding(
        padding: const EdgeInsetsGeometry.only(bottom: 10),
        child: Material(
          color: AppColors.secondaryLeveled,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            splashColor: const Color.fromARGB(255, 69, 122, 0),
            onTap: () {
              goToBusinessPage(context, miniBusinessLocation.locationId);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  SizedBox(
                      width: 300,
                      child: SubSubHeading(
                        miniBusinessLocation.name,
                        color: AppColors.highlightText,
                        maxlines: 1,
                        overflow: TextOverflow.ellipsis,
                      ))
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
                    Image.asset(iconPath, width: 25, height: 25),
                    LabelText(
                      color: AppColors.text,
                      businessTypeLookup[miniBusinessLocation.type]!,
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    // Image.asset(
                    //     "assets/icons/business_icons/rating_star.png"),
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.text,
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    LabelText(
                      ratings,
                      color: AppColors.text,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Icon(
                      Icons.linear_scale_sharp,
                      color: AppColors.text,
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    RepaintBoundary(
                        child: ValueListenableBuilder(
                            valueListenable: SearchServices.isMetric,
                            builder: (_, __, ___) {
                              return BodyText(
                                "${miniBusinessLocation.distance.toStringAsFixed(2)} ${SearchServices.isMetric.value ? "km" : "mi"}",
                                color: AppColors.text,
                                maxlines: 1,
                                overflow: TextOverflow.fade,
                              );
                            })),
                    // unVerifiedBadge
                  ],
                ),
                const SizedBox(
                  height: 5,
                ),
                Row(children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: miniBusinessLocation.verified
                            ? cardWidth - 0
                            : cardWidth - 120),
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.black,
                            Colors.black,
                            Colors.transparent
                          ],
                          stops: [
                            0.80,
                            0.95,
                            1.0
                          ], // Starts fading out near the right edge
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (int tagId in miniBusinessLocation.tags) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  // color: AppColors.leveled,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: MyText(
                                  TagServices.tagLookup[tagId]!.name,
                                  size: 12,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: miniBusinessLocation.verified ? 0 : 10),
                  unVerifiedBadge
                ])
              ],
            ),
          ),
        ),
      ),
    );
  }
}
