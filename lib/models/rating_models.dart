class Rating {
  const Rating(
      {required this.rating,
      required this.weight,
      required this.user,
      required this.desc,
      required this.time});

  final double rating;
  final double weight;
  final String user;
  final String desc;
  final DateTime time;
}
