import 'package:geolocator/geolocator.dart';
import "package:nextfind/utils/arbitStore.dart";
import 'package:logger/logger.dart';

final mlog = Logger();

Future<List> getLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Check if location services are enabled
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    mlog.e('Location services are disabled.');
    return Future.error('Location services are disabled.');
  }

  // Check permission
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      mlog.e('Location permission denied.');
      return Future.error('Location permission denied.');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    mlog.e('Location permission permanently denied.');
    return Future.error('Location permission permanently denied.');
  }

  // Get the actual location
  final data = await Geolocator.getCurrentPosition();

  final List userLocation = [data.latitude, data.longitude];

  mlog.i("PLAX || OLDUSERLOC: ${arbitStore.data["userLocation"]}");
  arbitStore.data["userLocation"] = userLocation;
  mlog.i("PLAX || NEWUSERLOC: ${arbitStore.data["userLocation"]}");
  return userLocation;
}
