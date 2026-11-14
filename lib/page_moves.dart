import 'package:flutter/material.dart';
import 'package:nextfind/widgets/main_widgets.dart';
import 'package:nextfind/screens/homepage.dart';
import 'package:nextfind/screens/searchpage.dart';
import 'package:nextfind/screens/userpage.dart';
import 'package:nextfind/screens/businesspage.dart';
import 'package:nextfind/screens/favorite_locations_page.dart';

void showErrorMessage(BuildContext context, dynamic message) {
  showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.background,
          constraints: const BoxConstraints(
              minHeight: 100, minWidth: 200, maxHeight: 300),
          child: Center(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox(
                      // width: 200,
                      child: MyText(
                          textAlign: TextAlign.center,
                          message.toString(),
                          size: 25)))),
        );
      });
}
