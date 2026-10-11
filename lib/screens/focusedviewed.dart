import 'dart:math';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:nextfind/utils/business_manager.dart';
// import 'package:nextfind/utils/arbitStore.dart';
import 'package:nextfind/widgets/newwidgets.dart';

final flog = Logger();

class Rating {
  const Rating(
      {required this.rating,
      required this.weight,
      required this.user,
      required this.desc,
      required this.time});

  final double rating;
  final double weight;
  final String user;
  final String desc;
  final DateTime time;
}

//! FIX THE REVIEW BLOCK
class ReviewBlock extends StatelessWidget {
  const ReviewBlock({super.key, required this.rating});

  final Rating rating;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.text,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {},
        splashColor: Colors.black.withOpacity(0.05),
        highlightColor: Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 400,
          height: max(MediaQuery.of(context).size.width * 0.3, 240),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 30,
            children: [],
          ),
        ),
      ),
    );
  }
}

class BusinessLocPage extends StatefulWidget {
  const BusinessLocPage({super.key, required this.locationId});
  final String locationId;

  @override
  State<BusinessLocPage> createState() => BusinessLocPageState();
}

class BusinessLocPageState extends State<BusinessLocPage> {
  late Future<BusinessLocation> _future;

  @override
  void initState() {
    super.initState();
    _future = businessManager.getBusinessLocation(widget.locationId);
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

  Widget buildRoot(BuildContext context, AsyncSnapshot snapshot) {
    if (snapshot.hasData) {
      BusinessLocation businessLocation = snapshot.data!;

      String imageUrl = "No Url";

      if (businessLocation.imagePaths.isNotEmpty) {
        flog.i(" FOCUSVIEW || bloc-id ${businessLocation.businessId}");
        imageUrl = businessLocation.imagePaths[0];
      }

      return fullCard(context, businessLocation, imageUrl);
    } else if (snapshot.hasError) {
      flog.e("FOCUSVIEW || ${snapshot.error}");
      return ErrorWidget(snapshot.error!);
    } else {
      return const CircularProgressIndicator();
    }
  }

  @override
  Widget build(BuildContext context) {
    // super.build(context);
    return Scaffold(
        body: FutureBuilder(
            future: _future,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              return buildRoot(context, snapshot);
            }));
  }
}
