import 'package:flutter/material.dart';
import 'package:nextfind/models/rating_models.dart';
import 'package:nextfind/widgets/main_widgets.dart';
import 'dart:math';

//! FIX THE REVIEW BLOCK
class RatingBlock extends StatelessWidget {
  const RatingBlock({super.key, required this.rating});

  final Rating rating;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.text,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {},
        splashColor: Colors.black.withValues(alpha: 0.05),
        highlightColor: Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 400,
          height: max(MediaQuery.of(context).size.width * 0.3, 240),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          child: const Column(
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
