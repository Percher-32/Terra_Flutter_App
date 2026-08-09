// import 'dart:ffi';

import 'package:flutter/widgets.dart';
import 'package:nextfind/networking/apiconn.dart';

// import 'package:nextfind/utils/arbitStore.dart';
const businessTypeLookup = {
  -1: "All",
  0: "Food",
  1: "Home",
  2: "Health",
  3: "Shops",
  4: "Specialists",
  5: "Auto",
  6: "Beauty",
  7: "Fun",
  8: "Education",
  9: "Travel",
};

List<T> intersection<T>(List<T> a, List<T> b) {
  return a.toSet().intersection(b.toSet()).toList();
}

class BusinessLocation {
  BusinessLocation(
      {required this.locationId,
      required this.location,
      required this.businessId,
      required this.name,
      required this.type,
      required this.address,
      required this.verified,
      // required this.distance,
      this.openHours,
      this.averageRating,
      this.thumbnailPath,
      this.numRatings,
      this.over18 = false,
      this.website,
      this.links,
      this.description,
      this.phoneNumber,
      this.timeZone = "Europe/London",
      this.imagePaths = const [],});

  final String locationId;
  final String businessId;
  final String name;
  final int type;
  final List location;
  final Map address;
  final bool verified;
  // final double distance;
  final Map? openHours;
  final num? averageRating;
  final int? numRatings;
  final String? thumbnailPath;
  final bool over18;
  final String? website;
  final Map? links;
  final String? description;
  final String? phoneNumber;
  final String timeZone;
  List<String> imagePaths;
}

class MiniBusinessLoc {
  const MiniBusinessLoc(
      {required this.locationId,
      required this.businessId,
      required this.name,
      required this.type,
      required this.location,
      required this.address,
      required this.verified,
      required this.distance,
      this.openHours,
      this.averageRating,
      this.thumbnailPath,
      this.numRatings,
      this.over18 = false,required this.buildingNumber});

  final String locationId;
  final String businessId;
  final String name;
  final int type;
  final List location;
  final Map address;
  final bool verified;
  final double distance;
  final Map? openHours;
  final num? averageRating;
  final int? numRatings;
  final String? thumbnailPath;
  final bool over18;
  
  final int buildingNumber;
}

const abc = {
  "Location": [53.744845999999995, -0.334524],
  "created_at": "2026-05-24T07:59:07.875844+00:00",
  "Open_Hours": {
    "1": ["09:30", "22:30"],
    "2": ["09:30", "22:30"],
    "3": ["09:30", "22:30"],
    "4": ["09:30", "22:30"],
    "5": ["09:30", "22:30"],
    "6": ["09:30", "22:30"],
    "7": ["09:30", "22:30"]
  },
  "max_capacity": 1,
  "last_time_location_changed": "2026-05-24T07:59:07.875844+00:00",
  "shutdown_days": [],
  "id": "64c5c3d0-f566-4a89-a43c-fb2eb15a0c9d",
  "website": null,
  "links": {
    "Maps": "Maps/locations/RideRight Bike School.com",
    "Uber": "User/businesses/RideRight Bike School.com",
    "Venmo": "Vemno/App/traders/RideRight Bike School.org.uk"
  },
  "Business_Id": "660959d1-5c68-4e05-b0d6-6b44dc2e4f51",
  "address": {
    "city": "Hull",
    "road": "Guildhall Road",
    "type": "unclassified",
    "class": "highway",
    "state": "England",
    "county": "Kingston upon Hull",
    "suburb": "Old Town",
    "country": "United Kingdom",
    "quarter": "Garrison Side",
    "postcode": "HU9 9SA",
    "country_code": "gb",
    "display_name":
        "Guildhall Road, Garrison Side, Old Town, Hull, Kingston upon Hull, Hull and East Yorkshire, England, HU9 9SA, United Kingdom",
    "ISO3166-2-lvl4": "GB-ENG",
    "ISO3166-2-lvl6": "GB-KHL",
    "state_district": "Hull and East Yorkshire"
  },
  "description": "Cycling lessons for all ages.THIS IS DESC FOR THIS LOCATIOn",
  "last_time_desc_changed": "2026-05-24T07:59:07.875844+00:00",
  "phone_number": null,
  "timezone": null,
  "verified": false,
  "search_occurances": {},
  "schedule": {},
  "rating_average": null,
  "rating_count": null,
  "rating_distribution": null,
  "Business_Name": "RideRight Bike School",
  "Business_created_at": "2026-05-24T07:59:07.674941+00:00",
  "Business_Website": "RideRight Bike School.co.uk",
  "Business_Mean_Rating": null,
  "Business_description": "Cycling lessons for all ages.",
  "Business_Btype": "Business",
  "Business_secondary_types": [],
  "Business_Gas-Safe": false,
  "Business_Electricity-Safe": false,
  "Business_primary_type": 8,
  "Business_pro": false,
  "Business_last_time_name_changed": null,
  "Business_last_time_desc_changed": null,
  "Business_last_time_primary_type_changed": null,
  "Business_id": "660959d1-5c68-4e05-b0d6-6b44dc2e4f51",
  "Business_owner_id": "12a1b239-c493-40e0-aa06-03eb6de291f3",
  "Business_over_18": false
};

const json = {
  "business_id": "660959d1-5c68-4e05-b0d6-6b44dc2e4f51",
  "business_name": "RideRight Bike School",
  "business_description":
      "Cycling lessons for all ages.Cycling lessons for all ages.THIS IS DESC FOR THIS LOCATIOn",
  "gas_safe": false,
  "elec_safe": false,
  "btype": "Business",
  "primary_type": 8,
  "secondary_types": [],
  "business_location_id": "64c5c3d0-f566-4a89-a43c-fb2eb15a0c9d",
  "business_location_location":
      "0101000020E610000038471D1D57DF4A40DF88EE59D768D5BF",
  "distance": 0.07960646572,
  "over_18": false,
  "rating_average": null,
  "rating_count": null,
  "phone_number": null,
  "website": null,
  "address": {
    "city": "Hull",
    "road": "Guildhall Road",
    "type": "unclassified",
    "class": "highway",
    "state": "England",
    "county": "Kingston upon Hull",
    "suburb": "Old Town",
    "country": "United Kingdom",
    "quarter": "Garrison Side",
    "postcode": "HU9 9SA",
    "country_code": "gb",
    "display_name":
        "Guildhall Road, Garrison Side, Old Town, Hull, Kingston upon Hull, Hull and East Yorkshire, England, HU9 9SA, United Kingdom",
    "ISO3166-2-lvl4": "GB-ENG",
    "ISO3166-2-lvl6": "GB-KHL",
    "state_district": "Hull and East Yorkshire"
  },
  "open_hours": {
    "1": ["09:30", "22:30"],
    "2": ["09:30", "22:30"],
    "3": ["09:30", "22:30"],
    "4": ["09:30", "22:30"],
    "5": ["09:30", "22:30"],
    "6": ["09:30", "22:30"],
    "7": ["09:30", "22:30"]
  },
  "shutdown_days": [],
  "timezone": null,
  "Location": [53.744845999999995, -0.334524]
};

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
  Map<String, MiniBusinessLoc> miniBusinessLocLookup = {};
  Map<String, BusinessLocation> businessLocationLookup = {};

  Map<int, BusinessLoc> businessLocationIdToData = {};
  Map<int, Business> businessIdToData = {};

  Map<int, List<String>> locationImageUrls = {};
  Map<int, List<Image>> locationImages = {};
  List<int> locationsSansPath = [];

  Map<int, DateTime> busLocDTUpdate = {};
  Map<int, DateTime> busDTUpdate = {};

  MiniBusinessLoc? addBusinessLocationMini(Map locationData) {
    try {
      log.d(
          "ADD BUSINESS LOCATION || INPUTS [${locationData["business_location_id"]}] || data : $locationData ");

      final newMiniBusiness = MiniBusinessLoc(
          locationId: locationData["business_location_id"],
          businessId: locationData["business_id"],
          name: locationData["business_name"],
          type: locationData["primary_type"],
          location: locationData["Location"],
          address: locationData["address"],
          verified: locationData["verified"],
          distance: locationData["distance"] + 0.0,
          openHours: locationData["open_hours"],
          averageRating: locationData["rating_average"],
          over18: locationData["over_18"],
          numRatings: locationData["rating_count"],
          thumbnailPath: locationData["thumbnail_path"],buildingNumber: locationData["building_number"]);

      miniBusinessLocLookup[locationData["business_location_id"]] =
          newMiniBusiness;

      if (locationData["thumbnail_path"] != null) {
        log.i(
            "ADD BUSINESS LOCATION || [IMAGE] HELLO HI YEAH THE URL IS ACTUALLY ${locationData["thumbnail_path"]} || INPUTS [${locationData["business_location_id"]}]");
      }
      log.i(
          "ADD BUSINESS LOCATION || [IMAGE] URL = ${locationData["thumbnail_path"]} || INPUTS [${locationData["business_location_id"]}]");

      return newMiniBusiness;
    } catch (e) {
      // {business_id: 660959d1-5c68-4e05-b0d6-6b44dc2e4f51, business_name: RideRight Bike School, business_description: Cycling lessons for all ages.Cycling lessons for all ages.THIS IS DESC FOR THIS LOCATIOn, gas_safe: false, elec_safe: false, btype: Business, primary_type: 8, secondary_types: [], business_location_id: 64c5c3d0-f566-4a89-a43c-fb2eb15a0c9d, business_location_location: 0101000020E610000038471D1D57DF4A40DF88EE59D768D5BF, distance: 0.07960646572, over_18: false, rating_average: null, rating_count: null, rating_distribution: null, phone_number: null, website: null, open_hours: {1: [09:30, 22:30], 2: [09:30, 22:30], 3: [09:30, 22:30], 4: [09:30, 22:30], 5: [09:30, 22:30], 6: [09:30, 22:30], 7: [09:30, 22:30]}, shutdown_days: [], timezone: null, verified: false}
      log.e(
          "ADD BUSINESS LOCATION || $e || INPUTS [${locationData["business_location_id"]}]");
      log.e(
          "ADD BUSINESS LOCATION || The location DATA IS ${locationData["Location"]} || INPUTS [${locationData["business_location_id"]}]");
      log.e(
          "ADD BUSINESS LOCATION || The location Data is $locationData || INPUTS [${locationData["business_location_id"]}]");
      return null;
    }
  }

  BusinessLocation? addBusinessLocation(Map businessLocationData) {
    try {
      log.d(
          "ADD FULL BUSINESS LOCATION || INPUTS [${businessLocationData["id"]}] || data : $businessLocationData ");

      final newBusiness = BusinessLocation(
          locationId: businessLocationData["id"],
          businessId: businessLocationData["Business_id"],
          name: businessLocationData["Business_Name"],
          type: businessLocationData["Business_primary_type"],
          location: businessLocationData["Location"],
          address: businessLocationData["address"],
          verified: businessLocationData["verified"],
          // distance: businessLocationData["distance"] + 0.0,
          openHours: businessLocationData["open_hours"],
          averageRating: businessLocationData["rating_average"],
          over18: businessLocationData["Business_over_18"],
          numRatings: businessLocationData["rating_count"],
          description: businessLocationData["description"] ?? "",
          website: businessLocationData["Business_Website"],
          links: businessLocationData["links"],
          timeZone: businessLocationData["timezone"] ?? "Europe/London",
          phoneNumber: businessLocationData["phone_number"]);

      businessLocationLookup[businessLocationData["id"]] = newBusiness;

      return newBusiness;
    } catch (e) {
      // {business_id: 660959d1-5c68-4e05-b0d6-6b44dc2e4f51, business_name: RideRight Bike School, business_description: Cycling lessons for all ages.Cycling lessons for all ages.THIS IS DESC FOR THIS LOCATIOn, gas_safe: false, elec_safe: false, btype: Business, primary_type: 8, secondary_types: [], business_location_id: 64c5c3d0-f566-4a89-a43c-fb2eb15a0c9d, business_location_location: 0101000020E610000038471D1D57DF4A40DF88EE59D768D5BF, distance: 0.07960646572, over_18: false, rating_average: null, rating_count: null, rating_distribution: null, phone_number: null, website: null, open_hours: {1: [09:30, 22:30], 2: [09:30, 22:30], 3: [09:30, 22:30], 4: [09:30, 22:30], 5: [09:30, 22:30], 6: [09:30, 22:30], 7: [09:30, 22:30]}, shutdown_days: [], timezone: null, verified: false}
      log.e("addBusinessLocation || ERROR -> $e");
      return null;
    }
  }

  Future<BusinessLocation> getBusinessLocation(String locationId) async {
    if (businessLocationLookup.containsKey(locationId)) {
      return businessLocationLookup[locationId]!;
    } else {
      return await serverconnect.getFullLocationData(locationId);
    }
  }

  Future<Map<String, MiniBusinessLoc>> getBusinessLocationMini(
      List<String> locationIds) async {
    Map<String, MiniBusinessLoc> retLookup = {};
    List<String> locationsToGet = [];

    log.i("GET MINI BUSINESS LOCATION || ABSTRACTED || START");
    log.d("GET MINI BUSINESS LOCATION || ABSTRACTED || INPUTS $locationIds");

    for (var locationId in locationIds) {
      // log.d(
      // "GET MINI BUSINESS LOCATION || ABSTRACTED || LOCATION ID $locationId");

      log.t(miniBusinessLocLookup.values);
      if (miniBusinessLocLookup.containsKey(locationId)) {
        retLookup[locationId] = miniBusinessLocLookup[locationId]!;
      } else {
        locationsToGet.add(locationId);
      }
    }

    log.d(
        "GET MINI BUSINESS LOCATION || ABSTRACTED || EXTRACTED ALL KNOWN BUSINESS DATA || currentRetLookup $retLookup || INPUTS $locationIds");

    if (locationsToGet.isNotEmpty) {
      log.d(
          "GET MINI BUSINESS LOCATION || ABSTRACTED || EXTRACTING ALL UNKNOWN BUSINESSES DATA || locToGet $locationsToGet || INPUTS $locationIds");
      final newLocationData = await serverconnect
          .getBusinessLocationDataMiniApi(locationIds: locationsToGet);

      log.d(
          "GET MINI BUSINESS LOCATION || ABSTRACTED || EXTRACTING ALL UNKNOWN BUSINESSES DATA || newLocationData : $newLocationData || locToGet $locationsToGet || INPUTS $locationIds");

      retLookup = {...retLookup, ...newLocationData};
    }

    log.d(
        "GET MINI BUSINESS LOCATION || ABSTRACTED || LOOKUP + $retLookup || INPUTS $locationIds");

    log.i(
        "GET MINI BUSINESS LOCATION || ABSTRACTED || ENDED RETURNED : $retLookup || INPUTS $locationIds");

    return retLookup;
  }
}

var businessManager = Businessmanager();

Future<void> main() async {
  print("HI");
}




//flutter test test/runner_test.dart