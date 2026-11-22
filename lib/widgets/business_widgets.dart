import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  final ScrollController scrollController =
      ScrollController(initialScrollOffset: 0);

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
          "${miniBusinessLocation.averageRating!.toStringAsFixed(2)} (${miniBusinessLocation.numRatings!})";
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
    // miniBusinessLocation.verified = true;
    if (!miniBusinessLocation.verified) {
      unVerifiedBadge = Image.asset(
          "assets/icons/business_icons/unverified_badge.png",
          scale: 3);
    }

    String iconPath = businessIconLookupAlt[miniBusinessLocation.type]!;

    double screenWidth = MediaQuery.of(context).size.width;

    // double cardWidth = screenWidth > 450 ? 450 * 0.85 : screenWidth * 0.75;

    return Container(
      width: 270,
      // height: 360,
      // padding: EdgeInsets.all(2),
      // clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
          // color: AppColors.background,
          border: BoxBorder.all(color: AppColors.secondaryLeveled, width: 2),
          borderRadius: BorderRadius.circular(10)),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: AppColors.background,
            child: InkWell(
              splashColor: AppColors.leveled.withAlpha(80),
              highlightColor: AppColors.leveled.withAlpha(30),
              onTap: () {
                context.push(
                    "/business-location/${miniBusinessLocation.locationId}");
                // goToBusinessPage(context, miniBusinessLocation.locationId);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                      width: 270,
                      height: 180,
                      child: Stack(children: [
                        Positioned(
                            top: 0,
                            left: 0,
                            child: BaseImage(
                                borderRadius: BorderRadius.circular(0),
                                width: 270,
                                height: 180,
                                url: miniBusinessLocation.thumbnailPath ??
                                    "No Url")),
                        Positioned(
                            right: 0,
                            child: IconButton(
                                onPressed: () {},
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.leveled.withValues(
                                      alpha:
                                          1), // Sets the background color of the button
                                  foregroundColor: AppColors
                                      .paleText, // Sets the color of the icon itself
                                ),
                                icon: const Icon(Icons.favorite_outline)))
                      ])),
                  const SizedBox(
                    height: 4,
                  ),
                  Row(children: [
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                        child: SubSubHeading(
                      miniBusinessLocation.name,
                      color: AppColors.text,
                      maxlines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                    )),
                    Column(children: [
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(5)),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.text,
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            LabelText(
                              "${miniBusinessLocation.averageRating?.toStringAsFixed(2) ?? "-"}",
                              color: AppColors.text,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                          width: 63,
                          child: Align(
                              alignment: Alignment.centerRight,
                              child: LabelText(
                                "(${miniBusinessLocation.numRatings ?? "-"})",
                                color: AppColors.paleText,
                              ))),
                    ]),
                    const SizedBox(
                      width: 5,
                    )
                  ]),
                  const SizedBox(
                    height: 5,
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
                        const Expanded(child: SizedBox()),
                        unVerifiedBadge,
                        const SizedBox(width: 5)
                      ]),
                  const SizedBox(
                    height: 2,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 10,
                      ),
                      MyText(
                        size: 14,
                        color: AppColors.text,
                        "${miniBusinessLocation.address["road"] ?? miniBusinessLocation.address["locality"] ?? miniBusinessLocation.address["suburb"]}",
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      const Icon(
                        Icons.linear_scale_sharp,
                        color: AppColors.paleText,
                      ),
                      RepaintBoundary(
                          child: ValueListenableBuilder(
                              valueListenable: SearchServices.isMetric,
                              builder: (_, __, ___) {
                                return BodyText(
                                  "${miniBusinessLocation.distance.toStringAsFixed(2)} ${SearchServices.isMetric.value ? "km" : "mi"}",
                                  color: AppColors.paleText,
                                  maxlines: 1,
                                  overflow: TextOverflow.fade,
                                );
                              })),
                      const SizedBox(
                        width: 10,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Row(children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 260),
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
                                      horizontal: 4, vertical: 0),
                                  decoration: BoxDecoration(
                                    // color: AppColors.leveled,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Material(
                                      color: AppColors.leveled,
                                      borderRadius: BorderRadius.circular(10),
                                      clipBehavior: Clip.hardEdge,
                                      child: InkWell(
                                        splashColor: AppColors.secondaryLeveled,
                                        highlightColor:
                                            AppColors.secondaryLeveled,
                                        onTap: () {
                                          SearchServices
                                                  .searchBarController.text =
                                              TagServices
                                                  .tagLookup[tagId]!.name;
                                          context.push(
                                              '/search/initial/homepagetag');
                                        },
                                        child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 5),
                                            child: MyText(
                                              TagServices
                                                  .tagLookup[tagId]!.name,
                                              size: 12,
                                              color: AppColors.text,
                                            )),
                                      )),
                                ),
                                const SizedBox(width: 0),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
                  SizedBox(
                    height: 10,
                  )
                ],
              ),
            ),
          )),
    );
  }
}
