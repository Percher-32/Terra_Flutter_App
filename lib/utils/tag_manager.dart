
import 'package:nextfind/networking/apiconn.dart';

class TagManager {
  Map<int, Tag> tagLookup = {};
  DateTime timeSinceLastRefresh = DateTime.utc(2000);

  Future<Map<int, Tag>> getAllTags() async {
    if (DateTime.now().difference(timeSinceLastRefresh).inMinutes >= 10) {
      final rawTagData = await serverconnect.getRawTagData();

      for (Map tagData in rawTagData) {
        final newTag = Tag(tagData["id"], tagData["category"], tagData["name"]);
        tagLookup[tagData["id"]] = newTag;
      }
    }

    return tagLookup;
  }
}

final TagManager tagManager = TagManager();

class Tag {
  const Tag(this.id, this.category, this.name);

  final int id;
  final int category;
  final String name;
}
