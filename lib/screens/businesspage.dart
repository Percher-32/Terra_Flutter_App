// import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nextfind/services/business_services.dart';
import 'package:nextfind/widgets/main_widgets.dart';
import 'package:nextfind/helpers/logger.dart';
import 'package:nextfind/models/business_models.dart';

class BusinessLocationFullPage extends StatefulWidget {
  const BusinessLocationFullPage({super.key, required this.locationId});
  final String locationId;

  @override
  State<BusinessLocationFullPage> createState() =>
      BusinessLocationFullPageState();
}

class BusinessLocationFullPageState extends State<BusinessLocationFullPage> {
  late Future<BusinessLocation> _future;

  @override
  void initState() {
    super.initState();
    _future = BusinessService.getBusinessLocation(widget.locationId);
  }

  @override
  Widget build(BuildContext context) {
    // super.build(context);
    return Scaffold(
        body: FutureBuilder(
            future: _future,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                BusinessLocation businessLocation = snapshot.data!;

                String imageUrl = "No Url";

                if (businessLocation.imagePaths.isNotEmpty) {
                  imageUrl = businessLocation.imagePaths[0];
                }

                return BusinessLocationPageWidget(
                    businessLocation: businessLocation, imageUrl: imageUrl);
              } else if (snapshot.hasError) {
                log.e(
                    "BusinessLocationFullPage || Error Getting Location Data || ${snapshot.error}");
                return ErrorWidget(snapshot.error!);
              } else {
                return const CircularProgressIndicator();
              }
            }));
  }
}

class BusinessLocationPageWidget extends StatelessWidget {
  const BusinessLocationPageWidget(
      {super.key, required this.businessLocation, required this.imageUrl});

  final BusinessLocation businessLocation;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    String ratingsText = "No Ratings";
    if (businessLocation.numRatings != null) {
      ratingsText =
          "${businessLocation.averageRating!.toStringAsFixed(2)}/10 (${businessLocation.numRatings!})";
    }

    String iconPath = businessIconLookupAlt[businessLocation.type]!;

    final Widget ratingWidget = businessLocation.numRatings != null
        ? Row(children: [
            MyText(
              (businessLocation.averageRating! / 2).toStringAsFixed(2),
              fontWeight: FontWeight.w600,
              color: AppColors.text,
              size: 17,
            ),
            const SizedBox(
              width: 5,
            ),
            Row(
              children: [
                ...List.generate(5, (starIndex) {
                  final scaledStarIndex = ((starIndex + 1) * 2).toDouble();

                  if (scaledStarIndex <=
                      businessLocation.averageRating! + 0.00001) {
                    return const Icon(
                      Icons.star_rounded,
                      color: AppColors.highlightText,
                      size: 30,
                    );
                  } else if (scaledStarIndex - businessLocation.averageRating! <
                      0.5) {
                    return const Icon(
                      Icons.star_half_rounded,
                      color: AppColors.highlightText,
                      size: 30,
                    );
                  } else {
                    return const Icon(
                      Icons.star_border_rounded,
                      color: AppColors.highlightText,
                      size: 30,
                    );
                  }
                })
              ],
            ),
            const SizedBox(
              width: 5,
            ),
            MyText(
              "(${businessLocation.numRatings!})",
              fontWeight: FontWeight.w600,
              color: AppColors.text,
              size: 17,
            ),
          ])
        : MyText(
            ratingsText,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
            size: 17,
          );

    Widget unVerifiedBadge = const SizedBox();

    if (!businessLocation.verified) {
      unVerifiedBadge = Image.asset(
          "assets/icons/business_icons/unverified_badge.png",
          scale: 2.5);
    }

    return Stack(
      children: [
        Positioned(
            top: 0,
            child: BaseImage(
              radius: 0,
              url: imageUrl,
              height: 380,
              width: MediaQuery.of(context).size.width,
            )),
        Positioned(
            top: 350,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                  color: AppColors.leveled,
                  borderRadius: BorderRadius.circular(30)),
              child: Column(
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  //* TiTLE and Type
                  Row(
                    children: [
                      const SizedBox(
                        width: 20,
                      ),
                      SizedBox(
                          width: 250,
                          child: MyText(
                            businessLocation.name,
                            size: 20,
                            fontWeight: FontWeight.w800,
                          )),
                      const SizedBox(
                        width: 1,
                      ),
                      unVerifiedBadge
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      const SizedBox(
                        width: 20,
                      ),
                      SizedBox(
                          width: 100,
                          child: Row(children: [
                            MyText(
                              businessTypeLookup[businessLocation.type]!,
                              color: AppColors.text,
                              size: 17,
                              fontWeight: FontWeight.w700,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Image.asset(iconPath, width: 25, height: 25),
                          ])),
                      const SizedBox(
                        width: 20,
                      ),
                      ratingWidget
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const OptionsNotch(
                      options: ["General", "Menu", "Reviews", "Photos"])
                ],
              ),
            ))
      ],
    );
  }
}

class OptionsNotch extends StatefulWidget {
  const OptionsNotch({super.key, required this.options, this.startIndex = 0});

  final List<String> options;
  final int startIndex;

  @override
  State<StatefulWidget> createState() => OptionsNotchState();
}

class OptionsNotchState extends State<OptionsNotch> {
  late ValueNotifier<int> currentIndex;

  @override
  void initState() {
    currentIndex = ValueNotifier(widget.startIndex);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      // height: 60,
      decoration: BoxDecoration(
        color: AppColors.leveled,
        borderRadius: BorderRadius.circular(12), // Optional: rounds the corners
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.2), // Shadow color and opacity
            spreadRadius: 4, // How much the shadow spreads
            blurRadius: 8, // Softness of the shadow
            offset: Offset(0, 20), // Changes position of shadow (x, y)
          ),
        ],
      ),
      child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 20,
            children: [
              SizedBox(width: 0),
              ...List.generate(widget.options.length, (index) {
                return ValueListenableBuilder(
                    valueListenable: currentIndex,
                    builder: (_, __, ___) {
                      final bool isSelected = currentIndex.value == index;

                      return Material(
                        color: isSelected
                            ? AppColors.secondaryLeveled
                            : AppColors.leveled,
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20)),
                        child: InkWell(
                          borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20)),
                          onTap: () {
                            currentIndex.value = index;
                          },
                          splashColor: const Color.fromARGB(67, 93, 115, 63),
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              child: MyText(
                                widget.options[index],
                                color: isSelected
                                    ? AppColors.text
                                    : AppColors.secondaryText,
                                size: 17,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              )),
                        ),
                      );
                    });

                //
              })
            ],
          )),
    );
  }
}
