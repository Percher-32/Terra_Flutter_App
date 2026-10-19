class Tag {
  const Tag(this.id, this.category, this.name);

  final int id;
  final int category;
  final String name;

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(json["id"], json["category"], json["name"]);
  }
}
