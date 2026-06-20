import 'dart:io';

import 'package:nextfind/networking/apiconn.dart';
import 'package:nextfind/utils/businessManager.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

final mlog = Logger();

class AppColors {
  static const background = Color.fromARGB(255, 255, 255, 255);
  static const text = Color.fromARGB(255, 0, 0, 0);
  static const primary = Color.fromARGB(255, 252, 130, 74);
  static const secondary = Color.fromARGB(255, 101, 44, 145);
  static const accent = Color.fromARGB(255, 34, 139, 219);
}

class Heading extends StatelessWidget {
  const Heading(this.text, {super.key, this.color = AppColors.text});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
          color: color,
          fontSize: 50,
          fontFamily: "LilitaOne",
          fontWeight: FontWeight.w400),
    );
  }
}

class SubHeading extends StatelessWidget {
  const SubHeading(this.text, {super.key, this.color = AppColors.text});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
          color: color,
          fontSize: 40,
          fontFamily: "LilitaOne",
          fontWeight: FontWeight.w400),
    );
  }
}

class Body extends StatelessWidget {
  const Body(this.text, {super.key, this.color = AppColors.text});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
          color: color,
          fontSize: 20,
          fontFamily: "LilitaOne",
          fontWeight: FontWeight.w400),
    );
  }
}

class Small extends StatelessWidget {
  const Small(this.text, {super.key, this.color = AppColors.text});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
          color: color,
          fontSize: 15,
          fontFamily: "LilitaOne",
          fontWeight: FontWeight.w400),
    );
  }
}

class BaseImage extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final double radius;
  final BoxFit fit;

  const BaseImage({
    required this.url,
    this.width = 180,
    this.height = 150,
    this.radius = 18,
    this.fit = BoxFit.cover,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider myImage = FileImage(File("assets/img/kde.png"));
    String trueUrl = url;
    if (url != "No Url") {
      trueUrl = "${serverconnect.serverUrl}/image/$url";
      log.f("The URL IS $trueUrl");
      myImage = NetworkImage(trueUrl);
    }

    mlog.d("HELLO YES HI THE URL S ||||||||||||||||||||| $trueUrl");

    return Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(
        image: DecorationImage(
          image: myImage,
          fit: fit,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
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
    _future = businessManager.getBusinessLocationMini([widget.locationId]);
  }

  Widget buildWidget(BuildContext context,
      AsyncSnapshot<Map<String, MiniBusinessLoc>> snapshot) {
    if (snapshot.hasData) {
      final minibusinessLocation = snapshot.data![widget.locationId]!;

      return SizedBox(
        width: 377.42,
        height: 214,
        child: Stack(
          children: [
            //shadow
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 377.07,
                height: 214,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  shadows: const [
                    BoxShadow(
                      color: Color(0x3F000000),
                      blurRadius: 10,
                      offset: Offset(-7, 10),
                      spreadRadius: 0,
                    )
                  ],
                ),
              ),
            ),

            //Opening time
            const Positioned(
              left: 37,
              top: 181,
              child: SizedBox(
                width: 156,
                height: 22,
                child: Small('CLOSED - Opens 16:00 '),
              ),
            ),

            //Address
            const Positioned(
              left: 229,
              top: 115,
              child: SizedBox(
                width: 119,
                height: 46,
                child: Small(
                  // '67 ${minibusinessLocation.address["road"]!}\n${minibusinessLocation.address["postcode"]}',
                  '67',
                ),
              ),
            ),

            //distance
            Positioned(
              left: 230,
              top: 161,
              child: SizedBox(
                width: 46,
                height: 20,
                child: Small(
                  '${minibusinessLocation.distance} km',
                ),
              ),
            ),

            //average ratings
            Positioned(
              left: 230,
              top: 80,
              child: SizedBox(
                width: 35.82,
                height: 34.85,
                child: Small(
                  '${minibusinessLocation.averageRating}',
                ),
              ),
            ),

            // Num ratings
            Positioned(
              left: 256,
              top: 91,
              child: SizedBox(
                width: 53,
                height: 12,
                child: Small(
                  '(${minibusinessLocation.numRatings})',
                ),
              ),
            ),

            // Type Bar
            Positioned(
              left: 231,
              top: 47,
              child: SizedBox(
                width: 146.42,
                height: 24.13,
                child: Small(
                  minibusinessLocation.type.toString(),
                ),
              ),
            ),

            // Title
            Positioned(
              left: 202,
              top: 13,
              child: SizedBox(
                width: 122,
                height: 24,
                child: Small(
                  minibusinessLocation.name,
                ),
              ),
            ),

            //Decoration
            Positioned(
              left: 331,
              top: 13,
              child: Container(
                width: 30.69,
                height: 30.69,
                decoration: ShapeDecoration(
                  image: DecorationImage(
                    image: NetworkImage("https://placehold.co/31x31"),
                    fit: BoxFit.cover,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            // CachedNetworkImage(imageUrl: )

            //Image
            Positioned(
                left: 13.15,
                top: 13.15,
                child: BaseImage(
                    url: minibusinessLocation.thumbnailPath ?? "No Url")),

            //Logo
            Positioned(
              left: 202,
              top: 174,
              child: Container(
                width: 23,
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 4,
                      strokeAlign: BorderSide.strokeAlignCenter,
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
