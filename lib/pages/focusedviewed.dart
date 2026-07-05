import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nextfind/utils/businessManager.dart';
import 'package:nextfind/widgets/widgets.dart';
import 'package:nextfind/utils/arbitStore.dart';
import 'package:nextfind/widgets/newwidgets.dart';


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
  const BusinessLocPage({super.key, required this.businessLoc, this.image});
  final BusinessLoc businessLoc;
  final Widget? image;

  @override
  State<BusinessLocPage> createState() => BusinessLocPageState();
}

class BusinessLocPageState extends State<BusinessLocPage> {
  Widget buildMain(BusinessLocPage widget, BuildContext context) {
    Widget businessimage = widget.image ??
        Image.asset(
          "assets/img/kde.png",
          width: 200,
          height: max(MediaQuery.of(context).size.width * 0.3, 200) * 1,
          fit: BoxFit.cover,
        );

    businessimage = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: AssetImage("assets/img/kde.png"),
          fit: BoxFit.cover,
        ),
      ),
      width: 200,
      height: max(MediaQuery.of(context).size.width * 0.3, 200) * 1,
    );

    const box = SizedBox(
      height: 10,
    );

    Widget nameText = HText(
      widget.businessLoc.name,
      color: AppColors.text,
      size: 20,
    );

    Widget typeText = HText(
      base_types[widget.businessLoc.primaryType]!,
      color: const Color.fromARGB(255, 66, 66, 66),
      size: 15,
    );

    String ratingString = "No ratings";
    if (widget.businessLoc.meanRating != null) {
      ratingString = "Rating : ${widget.businessLoc.meanRating.toString()}";
    }

    Widget descText = HText(
      widget.businessLoc.desc ?? "No description Provided",
      color: const Color.fromARGB(255, 66, 66, 66),
      size: 15,
      // bold: FontWeight.w300,
    );

    Widget ratingText = HText(
      ratingString,
      color: const Color.fromARGB(255, 36, 85, 99),
      size: 15,
    );

    Widget distanceText = HText(
      "${KmTomiles((widget.businessLoc.distance * 1000)).toStringAsPrecision(4)} miles from you",
      color: const Color.fromARGB(255, 36, 85, 99),
      size: 15,
    );

    // const Widget favButton = RoundIconButton(
    //   icon: Icons.favorite,
    // );

    // const Widget reviewButton = RoundIconButton(
    //   icon: Icons.reviews,
    // );

    // const Widget visitButton = SizedBox(
    //   width: 200,
    //   child: RoundButton(
    //     bgColor: Color.fromARGB(255, 73, 201, 255),
    //     text: "visit",
    //   ),
    // );

    // const rowButtons = Row(
    //   spacing: 30,
    //   children: [
    //     SizedBox(
    //       width: 0,
    //     ),
    //     favButton,
    //     reviewButton,
    //     visitButton,
    //   ],
    // );

    List<Widget> widgets = [
      box,
      businessimage,
      box,
      nameText,
      typeText,
      box,
      descText,
      box,
      box,
      distanceText,
      ratingText,
      box,
      box,
      // rowButtons
    ];

    return ListView.separated(
        itemBuilder: itemBuilder(context, widgets, [20]),
        separatorBuilder: itemBuilder(context, widgets, [10], builder: false),
        itemCount: widgets.length);
  }

  Widget Function(BuildContext, int) itemBuilder(
      BuildContext context, List<Widget> widgets, List<double> spacings,
      {bool builder = true}) {
    if (builder) {
      return (context, index) {
        return widgets[index];
      };
    } else {
      return (context, index) {
        return SizedBox(
          height: spacings.elementAtOrNull(index) ?? spacings[0],
        );
      };
    }
  }

  Widget topBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.primary),
      height: 70,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    log.d("BUSINESSLOC ID : ${widget.businessLoc.locId}");
    return Scaffold(
        appBar: PreferredSize(
            preferredSize: const Size.fromHeight(120), child: topBar(context)),
        bottomNavigationBar: bottombar(context),
        body: buildMain(widget, context));
  }
}
