
class BusinessLocation {
  BusinessLocation({
    required this.locationId,
    required this.location,
    required this.businessId,
    required this.name,
    required this.type,
    required this.address,
    required this.verified,
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
    this.imagePaths = const [],
  });

  final String locationId;
  final String businessId;
  final String name;
  final int type;
  final List location;
  final Map address;
  final bool verified;
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



  factory BusinessLocation.fromJson(Map<String, dynamic> json) {
    return BusinessLocation(
          locationId: json["business_location_id"],
          businessId: json["business_id"],
          name: json["business_name"],
          type: json["primary_type"],
          location: json["location"],
          address: json["address"],
          verified: json["verified"],
          openHours: json["open_hours"],
          averageRating: json["rating_average"],
          over18: json["over_18"],
          numRatings: json["rating_count"],
          description: json["description"] ?? "",
          website: json["website"],
          links: json["links"],
          timeZone: json["timezone"] ?? "Europe/London",
          phoneNumber: json["phone_number"]
          );
  }
  
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
      this.over18 = false,
      required this.buildingNumber});

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

  factory MiniBusinessLoc.fromJson(Map<String, dynamic> json) {
    return MiniBusinessLoc(
      locationId: json["business_location_id"],
      businessId: json["business_id"],
      name: json["business_name"],
      type: json["primary_type"],
      location: json["business_location_location"],
      address: json["address"],
      verified: json["verified"],
      distance: json["distance"] as double,
      openHours: json["open_hours"],
      averageRating: json["rating_average"],
      over18: json["over_18"],
      numRatings: json["rating_count"],
      thumbnailPath: json["thumbnail_path"],
      buildingNumber: json["building_number"],
    );
  }
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
