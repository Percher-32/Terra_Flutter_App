// import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nextfind/services/business_services.dart';
import 'package:nextfind/widgets/main_widgets.dart';
import 'package:nextfind/helpers/logger.dart';
import 'package:nextfind/models/business_models.dart';

class BusinessPageGlobals {
  static ValueNotifier<int> currentIndex = ValueNotifier(0);
}

class BusinessLocationFullPage extends StatefulWidget {
  const BusinessLocationFullPage({super.key, required this.locationId});
  final String locationId;

  @override
  State<BusinessLocationFullPage> createState() =>
      BusinessLocationFullPageState();
}

class BusinessLocationFullPageState extends State<BusinessLocationFullPage> {
  late Future<BusinessLocation> _future;

  late ValueNotifier<int> currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = ValueNotifier(0);
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

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight:
              490.0, // Total height of your image + text details when at the top
          pinned: true, // Keeps the app bar pinned at the top when scrolling
          backgroundColor: AppColors.leveled,
          elevation: 0,

          title: MyText(
            businessLocation.name,
          ),
          actions: [
            unVerifiedBadge,
            const SizedBox(width: 16),
          ],

          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 390),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MyText(
                                  businessLocation.name,
                                  size: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    MyText(
                                      businessTypeLookup[
                                          businessLocation.type]!,
                                      color: AppColors.text,
                                      size: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    const SizedBox(width: 2),
                                    Image.asset(iconPath,
                                        width: 25, height: 25),
                                    const SizedBox(width: 10),
                                    ratingWidget,
                                  ],
                                ),
                              ],
                            )),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: BaseImage(
                    radius: 0,
                    url: imageUrl,
                    height: 380,
                    width: MediaQuery.of(context).size.width,
                  ),
                ),
              ],
            ),
          ),

          // 3. The OptionsNotch stays pinned right below the app bar title when scrolling
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60.0),
            child: Container(
              color: AppColors.leveled,
              child: const OptionsNotch(
                options: ["General", "Menu", "Reviews", "Photos"],
              ),
            ),
          ),
        ),

        // 4. Your Tab Content below
        SliverToBoxAdapter(
          child: ValueListenableBuilder(
            valueListenable: BusinessPageGlobals.currentIndex,
            builder: (_, currentIndex, __) {
              if (currentIndex == 0) {
                return GeneralPageWidget(businessLocation: businessLocation);
              }
              return const SizedBox();
            },
          ),
        ),
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
  @override
  void initState() {
    super.initState();
    BusinessPageGlobals.currentIndex.value = widget.startIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      // height: 60,
      decoration: BoxDecoration(
        color: AppColors.leveled,
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
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
                    valueListenable: BusinessPageGlobals.currentIndex,
                    builder: (_, __, ___) {
                      final bool isSelected =
                          BusinessPageGlobals.currentIndex.value == index;

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
                            BusinessPageGlobals.currentIndex.value = index;
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

class GeneralPageWidget extends StatelessWidget {
  const GeneralPageWidget({super.key, required this.businessLocation});

  final BusinessLocation businessLocation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 800,
    );
  }
}
