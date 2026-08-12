class Post{
  const Post({required this.text,
  required this.rawtext,
  required this.createdAt,
  required this.locationId,
  this.imagePath,
  this.hashtags = const [],
  required this.likes,required this.postId});

  final String text;
  final String rawtext;
  final String createdAt;
  final String locationId;
  final String? imagePath;
  final List<String> hashtags;
  final int likes;
  final String postId;


}




class Postmanager {
  Map<String,Post> storedPosts = {};



}