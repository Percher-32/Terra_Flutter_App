import 'package:nextfind/widgets/main_widgets.dart';
import 'package:flutter/material.dart';

class Heading extends StatelessWidget {
  const Heading(this.text,
      {super.key,
      this.color = AppColors.text,
      this.overflow = TextOverflow.visible,
      this.maxlines = 2,
      this.textAlign = TextAlign.left});

  final String text;
  final Color color;
  final int maxlines;
  final TextOverflow overflow;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxlines,
      softWrap: true,
      textAlign: textAlign,
      style: TextStyle(
          color: color,
          fontSize: 30,
          fontFamily: "Montserrat",
          overflow: overflow,
          fontWeight: FontWeight.w800),
    );
  }
}

class SubHeading extends StatelessWidget {
  const SubHeading(this.text,
      {super.key,
      this.color = AppColors.text,
      this.overflow = TextOverflow.visible,
      this.maxlines = 2,
      this.textAlign = TextAlign.left});

  final String text;
  final Color color;
  final int maxlines;
  final TextOverflow overflow;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxlines,
      softWrap: true,
      textAlign: textAlign,
      style: TextStyle(
          color: color,
          fontSize: 20,
          fontFamily: "Montserrat",
          overflow: overflow,
          fontWeight: FontWeight.w700),
    );
  }
}

class SubSubHeading extends StatelessWidget {
  const SubSubHeading(this.text,
      {super.key,
      this.color = AppColors.text,
      this.overflow = TextOverflow.visible,
      this.maxlines = 2,
      this.textAlign = TextAlign.left});

  final String text;
  final Color color;
  final int maxlines;
  final TextOverflow overflow;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxlines,
      softWrap: true,
      textAlign: textAlign,
      style: TextStyle(
          color: color,
          fontSize: 18,
          fontFamily: "Montserrat",
          overflow: overflow,
          fontWeight: FontWeight.w700),
    );
  }
}

class LabelText extends StatelessWidget {
  const LabelText(this.text,
      {super.key,
      this.color = AppColors.text,
      this.overflow = TextOverflow.visible,
      this.maxlines = 2,
      this.textAlign = TextAlign.left});

  final String text;
  final Color color;
  final int maxlines;
  final TextOverflow overflow;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxlines,
      softWrap: true,
      textAlign: textAlign,
      style: TextStyle(
          color: color,
          fontSize: 15,
          fontFamily: "Montserrat",
          overflow: overflow,
          fontWeight: FontWeight.w600),
    );
  }
}

class BodyText extends StatelessWidget {
  const BodyText(this.text,
      {super.key,
      this.color = AppColors.text,
      this.overflow = TextOverflow.visible,
      this.maxlines = 2,
      this.textAlign = TextAlign.left});

  final String text;
  final Color color;
  final int maxlines;
  final TextOverflow overflow;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxlines,
      softWrap: true,
      textAlign: textAlign,
      style: TextStyle(
          color: color,
          fontSize: 15,
          fontFamily: "Montserrat",
          overflow: overflow,
          fontWeight: FontWeight(530)),
    );
  }
}

class MyText extends StatelessWidget {
  const MyText(this.text,
      {super.key,
      this.color = AppColors.text,
      this.size = 20,
      this.fontWeight = FontWeight.w600,
      this.overflow = TextOverflow.visible,
      this.maxlines = 2,
      this.textAlign = TextAlign.left});

  final String text;
  final Color color;
  final double size;
  final int maxlines;
  final FontWeight fontWeight;
  final TextOverflow overflow;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxlines,
      softWrap: true,
      textAlign: textAlign,
      style: TextStyle(
          color: color,
          fontSize: size,
          fontFamily: "Montserrat",
          overflow: overflow,
          fontWeight: fontWeight),
    );
  }
}
