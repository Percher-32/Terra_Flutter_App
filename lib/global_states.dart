import 'package:flutter/material.dart';


class GlobalStates {
  static int categoryIndex = -1;
  static List<int> chosenTags = [];
  static bool isMetric = true;

  static final ValueNotifier<bool> distanceMeasurmentChanged =
      ValueNotifier(false);
}
