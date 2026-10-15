import 'package:intl/intl.dart';

class Rating {
  const Rating(
      {required this.id,
      required this.rating,
      required this.weight,
      required this.userId,
      required this.time,
      this.review});

  final double rating;
  final double weight;
  final String userId;
  final DateTime time;
  final int id;
  final String? review;

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
        id: json["id"],
        rating: json["rating"],
        weight: json["weight"],
        userId: json["userId"],
        time: DateTime.parse(json["time"]),
        review: json["review"]);
  }
}
