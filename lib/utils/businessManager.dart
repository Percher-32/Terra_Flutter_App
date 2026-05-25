// import 'dart:ffi';

import 'package:flutter/widgets.dart';
import 'package:nextfind/networking/apiconn.dart';
// import 'package:nextfind/utils/arbitStore.dart';

class BusinessLoc {
  const BusinessLoc({
    required this.locId,
    required this.name,
    required this.macroType,
    required this.locations,
    required this.bId,
    this.createdAt,
    this.website,
    this.links = const {},
    this.email,
    this.meanRating,
    this.services = const [],
    this.desc,
    this.secondaryTypes = const [],
    this.gasSafe = false,
    this.elecSafe = false,
    required this.primaryType,
    this.badges = const [],
    required this.location,
    this.openToday = false,
    this.openHours,
    this.openDays,
    required this.owneremail,
    required this.address,
    this.ratings = const [],
    this.distance = 0,
  });

  final int locId;
  final String name;
  final String? createdAt;
  final String? website;
  final Map? links;
  final String? email;
  final double? meanRating;
  final List services;
  final String? desc;
  final String macroType;
  final List secondaryTypes;
  final bool gasSafe;
  final bool elecSafe;
  final List locations;
  final int primaryType;
  final List badges;
  final int bId;
  final List location;
  final bool openToday;
  final dynamic openHours;
  final dynamic openDays;
  final String owneremail;
  final String address;
  final List ratings;
  final double distance;

  // if (distance == null){
  //   distance =
  // }
}

class Business {
  const Business({
    required this.id,
    required this.name,
    required this.macroType,
    required this.locations,
    required this.primaryType,
    required this.owneremail,
    this.createdAt,
    this.website,
    this.links = const {},
    this.email,
    this.meanRating,
    this.services = const [],
    this.desc,
    this.secondaryTypes = const [],
    this.gasSafe = false,
    this.elecSafe = false,
    this.badges = const [],
    this.openToday = false,
    this.openHours,
    this.openDays,
    this.ratings = const [],
  });

  final String name;
  final String? createdAt;
  final String? website;
  final Map? links;
  final String? email;
  final double? meanRating;
  final List services;
  final String? desc;
  final String macroType;
  final List secondaryTypes;
  final bool gasSafe;
  final bool elecSafe;
  final List locations;
  final int primaryType;
  final List badges;
  final int id;
  final bool? openToday;
  final dynamic openHours;
  final dynamic openDays;
  final String owneremail;
  final List ratings;
}

class Businessmanager {
  Map<int, BusinessLoc> businessLocationIdToData = {};
  Map<int, Business> businessIdToData = {};

  Map<int, List<String>> locationImageUrls = {};
  Map<int, List<Image>> locationImages = {};
  List<int> locationsSansPath = [];

  Map<int, DateTime> busLocDTUpdate = {};
  Map<int, DateTime> busDTUpdate = {};

  List<String> addLocationImageUrl(
      {required int locationId, required List<String> paths}) {
    if (locationImageUrls.containsKey(locationId)) {
      if (paths.length > locationImageUrls[locationId]!.length) {
        locationImageUrls[locationId] = paths;
      }
    } else {
      locationImageUrls[locationId] = paths;
    }

    return locationImageUrls[locationId]!;
  }

  Future<List<String>?> getLocationImageUrls(int locationId) async {
    // If we already have the URL cached, return it
    if (locationsSansPath.contains(locationId)) {
      return null;
    }

    if (locationImageUrls.containsKey(locationId)) {
      return locationImageUrls[locationId]!;
    }

    // Otherwise fetch it
    final Map locationPaths =
        await serverconnect.getLocationImageUrls([locationId]);

    if (!locationPaths.containsKey(locationId)) {
      locationsSansPath.add(locationId);
      return null;
    }

    final List<String> paths = [locationPaths[locationId]];

    addLocationImageUrl(
      locationId: locationId,
      paths: paths,
    );

    return paths;
  }

  List<Image> addLocationImage(
      {required int locationId, required List<Image> images}) {
    if (locationImageUrls.containsKey(locationId)) {
      if (images.length > locationImageUrls[locationId]!.length) {
        locationImages[locationId] = images;
      }
    } else {
      locationImages[locationId] = images;
    }

    return locationImages[locationId]!;
  }

  Future<List<Image>?> getLocationImages(
    int locationId, {
    loadingImage,
    errorImage,
    noImage,
    fit,
  }) async {
    if (locationImages.containsKey(locationId)) {
      return locationImages[locationId];
    }

    final paths = await getLocationImageUrls(locationId);

    if (paths == null) {
      return null;
    } else {
      List<Image> retImages = [];

      for (String path in paths) {
        final url = serverconnect.fullUrl(path);
        final image = Image.network(
          url,
          fit: null, // no fit
          width: null,
          height: null,
        );

        retImages.add(image);
      }

      locationImages[locationId] = retImages;
      log.d("NON NULL IMAGE DETECTED");
      return retImages;
    }
  }

  BusinessLoc addBusiness(Map businessData) {
    try {
      if (!businessData.containsKey("Distance")) {
        businessData["Distance"] = 67.0;
      }
      final newbusloc = BusinessLoc(
        locId: businessData["id"],
        name: businessData["Name"],
        createdAt: businessData["created_at"],
        links: businessData["Links"],
        website: businessData["Website"],
        email: businessData["email"],
        meanRating: businessData["Mean_Rating"],
        services: businessData["Services"],
        desc: businessData["description"],
        macroType: businessData["Btype"],
        secondaryTypes: businessData["secondary_types"],
        gasSafe: businessData["Gas-Safe"],
        elecSafe: businessData["Electricity-Safe"],
        locations: businessData["locations"],
        primaryType: businessData["primary_type"],
        ratings: businessData["ratings"],
        badges: businessData["Badges"],
        bId: businessData["Business_Id"],
        location: businessData["Location"],
        openToday: businessData["Open_Today"],
        openHours: businessData["Open_Hours"],
        openDays: businessData["Open_Days"],
        owneremail: businessData["owner_id"],
        address: businessData["address"],
        distance: businessData["Distance"],
      );

      final newbus = Business(
        name: businessData["Name"],
        macroType: businessData["Btype"],
        locations: businessData["locations"],
        id: businessData["Business_Id"],
        primaryType: businessData["primary_type"],
        owneremail: businessData["owner_id"],
        secondaryTypes: businessData["secondary_types"],
        services: businessData["Services"],
        meanRating: businessData["Mean_Rating"],
        desc: businessData["description"],
        gasSafe: businessData["Gas-Safe"],
        elecSafe: businessData["Electricity-Safe"],
        badges: businessData["Badges"],
        links: businessData["Links"],
        openDays: businessData["Open_Days"],
        openToday: businessData["Open_Today"],
        openHours: businessData["Open_Hours"],
      );

      businessLocationIdToData[businessData["id"]] = newbusloc;
      busLocDTUpdate[businessData["id"]] = DateTime.now();

      businessIdToData[businessData["Business_Id"]] = newbus;
      busDTUpdate[businessData["Business_Id"]] = DateTime.now();

      return newbusloc;
    } catch (e, st) {
      log.e(st);
      return BusinessLoc(
        locId: 0,
        name: "ERROR BUSINESS",
        macroType: "bus",
        location: [0, 0],
        bId: 0,
        locations: [],
        primaryType: 2,
        owneremail: "s",
        address: "D",
        distance: 3,
      );
    }
  }

  Business addONLYBusiness(Map businessData) {
    final newbus = Business(
      name: businessData["Name"],
      macroType: businessData["Btype"],
      locations: businessData["locations"],
      id: businessData["id"],
      primaryType: businessData["primary_type"],
      owneremail: businessData["owner_id"],
      secondaryTypes: businessData["secondary_types"],
      services: businessData["Services"],
      meanRating: businessData["Mean_Rating"].toDouble(),
      desc: businessData["description"],
      gasSafe: businessData["Gas-Safe"],
      elecSafe: businessData["Electricity-Safe"],
      badges: businessData["Badges"],
      links: businessData["Links"],
      openDays: businessData["Open_Days"],
      openToday: businessData["Open_Today"],
      openHours: businessData["Open_Hours"],
    );

    businessIdToData[businessData["id"]] = newbus;
    busDTUpdate[businessData["id"]] = DateTime.now();

    return newbus;
  }

  Future<List<Business>> getBusinessData(List<int> businessIds) async {
    List<int> idsToUpdate = List.from(businessIds);
    List<int> idsKnown = [];

    for (int businessId in businessIds) {
      if (businessIdToData.containsKey(businessId)) {
        final DateTime? dateupdate = busDTUpdate[businessId];
        if (!(dateupdate!.difference(DateTime.now()).inHours > 1)) {
          idsToUpdate.removeWhere((item) => item == businessId);
          idsKnown.add(businessId);
        }
      }
    }

    List<Business> retrunedBusinesses = [];

    if (idsToUpdate.isNotEmpty) {
      List<dynamic> newBusiness = await serverconnect.getBusinessData(
        id: idsToUpdate,
      );

      for (Map businesLocationData in newBusiness) {
        Business addedBus = addONLYBusiness(businesLocationData);
        retrunedBusinesses.add(addedBus);
      }
    }

    for (int idKnown in idsKnown) {
      retrunedBusinesses.add(businessIdToData[idKnown]!);
    }

    return retrunedBusinesses;
  }

  Future<List<BusinessLoc>> getBusinessLocationData(
      List<int> businessLocationIds) async {
    try {
      List<int> idsToUpdate = List.from(businessLocationIds);
      List<int> idsKnown = [];

      for (int businessLocationId in businessLocationIds) {
        if (businessLocationIdToData.containsKey(businessLocationId)) {
          final DateTime? dateupdate = busLocDTUpdate[businessLocationId];
          if (!(dateupdate!.difference(DateTime.now()).inHours > 1)) {
            idsToUpdate.remove(businessLocationId);
            idsKnown.add(businessLocationId);
          }
        }
      }

      List<BusinessLoc> retrunedBusinesses = [];

      if (idsToUpdate.isNotEmpty) {
        List<dynamic> newBusiness = await serverconnect.getBusinessLocationData(
          id: idsToUpdate,
        );

        for (Map businesLocationData in newBusiness) {
          BusinessLoc addedBus = addBusiness(businesLocationData);
          retrunedBusinesses.add(addedBus);
          // busDTUpdate[businesLocationData["id"]] = DateTime.now();
        }
      }

      for (int idKnown in idsKnown) {
        retrunedBusinesses.add(businessLocationIdToData[idKnown]!);
      }

      return retrunedBusinesses;
    } catch (e, st) {
      log.e("ERROR IN GETTING BUSINESS LOCATION");
      log.e(st);
      return [
        BusinessLoc(
          locId: 0,
          name: "ERROR BUSINESS",
          macroType: "bus",
          location: [0, 0],
          bId: 0,
          locations: [],
          primaryType: 2,
          owneremail: "s",
          address: "D",
          distance: 3,
        )
      ];
    }
  }
}

var businessManager = Businessmanager();

Future<void> main() async {
  print("HI");
  await businessManager.getBusinessLocationData([2, 3, 4, 5]);
  await businessManager.getBusinessLocationData([4, 5, 10, 13]);
}




//flutter test test/runner_test.dart