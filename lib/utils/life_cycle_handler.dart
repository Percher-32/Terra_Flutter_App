import 'package:flutter/material.dart';


class AppLifecycleHandler extends WidgetsBindingObserver {
  bool isPaused = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    isPaused = state == AppLifecycleState.paused ||
               state == AppLifecycleState.inactive;
  }
}

final lifecycle = AppLifecycleHandler();