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

  Widget fullCard(BuildContext context, BusinessLocation businessLocation,
      String imageUrl) {
    String ratings = "No Ratings";
    if (businessLocation.numRatings != null) {
      ratings =
          "${businessLocation.averageRating!.toStringAsFixed(2)}/10 (${businessLocation.numRatings!})";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 5,
      children: [
        BaseImage(
          url: imageUrl,
          height: 380,
          width: MediaQuery.of(context).size.width,
        ),
        Row(children: [
          const SizedBox(width: 9),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width / 1.7,
            ),
            child: MyText(
              businessLocation.name,
              color: Colors.grey.shade800,
              size: 35,
            ),
          ),
        ]),
        Row(children: [
          const SizedBox(width: 10),
          MyText(
            businessTypeLookup[businessLocation.type]!,
            color: Colors.grey.shade800,
            size: 22,
          ),
        ]),
        Row(children: [
          const SizedBox(width: 10),
          MyText(
            ratings,
            color: Colors.grey.shade800,
            size: 22,
          ),
          const Icon(
            Icons.star_rounded,
            size: 40,
          ),
        ]),
      ],
    );
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
    String ratings = "No Ratings";
    if (businessLocation.numRatings != null) {
      ratings =
          "${businessLocation.averageRating!.toStringAsFixed(2)}/10 (${businessLocation.numRatings!})";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 5,
      children: [
        BaseImage(
          url: imageUrl,
          height: 380,
          width: MediaQuery.of(context).size.width,
        ),
        Row(children: [
          const SizedBox(width: 9),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width / 1.7,
            ),
            child: MyText(
              businessLocation.name,
              color: Colors.grey.shade800,
              size: 35,
            ),
          ),
        ]),
        Row(children: [
          const SizedBox(width: 10),
          MyText(
            businessTypeLookup[businessLocation.type]!,
            color: Colors.grey.shade800,
            size: 22,
          ),
        ]),
        Row(children: [
          const SizedBox(width: 10),
          MyText(
            ratings,
            color: Colors.grey.shade800,
            size: 22,
          ),
          const Icon(
            Icons.star_rounded,
            size: 40,
          ),
        ]),
      ],
    );
  }
}
