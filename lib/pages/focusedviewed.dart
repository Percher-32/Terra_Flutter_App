import 'dart:math';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:nextfind/utils/businessManager.dart';
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

  Widget buildRoot(BuildContext context, AsyncSnapshot snapshot) {
    if (snapshot.hasData) {
      Widget image = SizedBox();

      BusinessLocation businessLocation = snapshot.data!;

      if (businessLocation.imagePaths.isNotEmpty) {
        image = BaseImage(url: businessLocation.imagePaths[0]);
      }

      return Column(
        children: [image],
      );
    } else if (snapshot.hasError) {
      flog.e("${snapshot.error}");
      return const CircularProgressIndicator();
    } else {
      return const CircularProgressIndicator();
    }
  }

  @override
  Widget build(BuildContext context) {
    // super.build(context);
    return Scaffold(
        bottomNavigationBar: newbottombar(context),
        body: FutureBuilder(
            future: _future,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              return buildRoot(context, snapshot);
            }));
  }
}
