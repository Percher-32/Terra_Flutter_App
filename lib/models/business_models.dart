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
        phoneNumber: json["phone_number"]);
  }
}

class MiniBusinessLocation {
  const MiniBusinessLocation(
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
  final List<double> location;
  final Map address;
  final bool verified;
  final double distance;
  final Map? openHours;
  final num? averageRating;
  final int? numRatings;
  final String? thumbnailPath;
  final bool over18;
  final int buildingNumber;

  @override
  bool operator ==(Object other) {
    // 1. Check if they are the exact same instance in memory
    if (identical(this, other)) return true;

    // 2. Check if 'other' is of the same type
    return other is MiniBusinessLocation &&
        // 3. Compare all the fields you care about
        other.locationId == locationId &&
        other.businessId == businessId &&
        other.name == name &&
        other.type == type &&
        other.location == location &&
        other.address == address &&
        other.verified == verified &&
        other.distance == distance &&
        other.openHours == openHours &&
        other.averageRating == averageRating &&
        other.over18 == over18 &&
        other.numRatings == numRatings &&
        other.thumbnailPath == thumbnailPath &&
        other.buildingNumber == buildingNumber;
  }

  @override
  int get hashCode => Object.hash(
        locationId,
        businessId,
        name,
        type,
        location,
        address,
        verified,
        distance,
        openHours,
        averageRating,
        over18,
        numRatings,
        thumbnailPath,
        buildingNumber,
      );

  factory MiniBusinessLocation.fromJson(Map<String, dynamic> json) {
    return MiniBusinessLocation(
      locationId: json["business_location_id"],
      businessId: json["business_id"],
      name: json["business_name"],
      type: json["primary_type"],
      location: List<double>.from(json["business_location_location"]) ,
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
