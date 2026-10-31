import 'package:flutter/material.dart';
import 'package:nextfind/models/tag_models.dart';
import 'package:nextfind/services/search_services.dart';
import 'package:nextfind/widgets/main_widgets.dart';
import 'package:rapidfuzz/rapidfuzz.dart' as fuzz;
import 'package:nextfind/helpers/networking.dart';
import 'package:nextfind/helpers/logger.dart';
import 'package:nextfind/helpers/debug_options.dart';
import 'package:nextfind/helpers/load_files.dart';

class TagServices {
  static final ValueNotifier<bool> updateTagWidget = ValueNotifier(false);
  static final ValueNotifier<bool> justExitedTagChoose = ValueNotifier(false);
  static List<int> chosenTags = [];
  static Map<int, Tag> tagLookup = {};
  static DateTime timeSinceLastRefresh = DateTime.fromMicrosecondsSinceEpoch(0);

  static Future<Map<int, Tag>> getAllTags() async {
    if (DateTime.now().difference(timeSinceLastRefresh).inMinutes >= 10) {
      final rawTagData = await getRawTagData();

      for (Map<String, dynamic> tagData in rawTagData) {
        final newTag = Tag.fromJson(tagData);
        tagLookup[tagData["id"]] = newTag;
      }
      timeSinceLastRefresh = DateTime.now();
    }

    return tagLookup;
  }

  static Future<List<dynamic>> getRawTagData() async {
    // const String tagGetEndpoint = '$serverUrl/tags/get';

    if (!NextfindDebugOptions.useTestTagData) {
      final response = await Networking.apiGet(
        "tags/get",
      );

      return Networking.toJson(response.body);
    } else {
      final data =
          await Loadfiles.loadJsonFile("assets/testdata/tag_data.json");
      return data;
    }
  }

  static void showChooseTagDropDown(BuildContext context) {
    final TextEditingController tagSearchBarController =
        TextEditingController();

    // double forgivingScore(String a, String b) {
    //   final r1 = fuzz.ratio(a, b);
    //   final r2 = fuzz.partialRatio(a, b);
    //   final r3 = fuzz.tokenSortRatio(a, b);
    //   final r4 = fuzz.tokenSetRatio(a, b);
    //   return [r1, r2, r3, r4].reduce((a, b) => a > b ? a : b);
    // }

    List<Tag> searchSimilarTags(String query, List<Tag> tags) {
      final lowerQuery = query.toLowerCase().trim();

      final scored = tags.map((tag) {
        final name = tag.name.toLowerCase();

        final r1 = fuzz.ratio(lowerQuery, name); // strict
        final r2 = fuzz.partialRatio(lowerQuery, name); // forgiving

        final score = ((r1 * 0.7) + (r2 * 0.3)).round();

        return {"tag": tag, "score": score};
      }).toList();

      scored.sort((a, b) {
        final sb = b["score"] as int;
        final sa = a["score"] as int;
        return sb.compareTo(sa);
      });

      return scored
          .where((e) => (e["score"] as int) >= 40) // ← threshold here
          .map((e) => e["tag"] as Tag)
          .toList();
    }

    Future<List<Tag>> getSimilarTags() async {
      await getAllTags();

      List<Tag> allTagsList = [];
      for (Tag tag in tagLookup.values) {
        if (List.from(chosenTags).contains(tag.id)) {
          if (SearchServices.categoryIndex.value != null &&
              tag.category != SearchServices.categoryIndex.value) {
            continue;
          }
          allTagsList.add(tag);
        }
      }

      for (Tag tag in tagLookup.values) {
        if (!List.from(chosenTags).contains(tag.id)) {
          if (SearchServices.categoryIndex.value != null) {
            if (tag.category != SearchServices.categoryIndex.value) {
              continue;
            }
          }
          allTagsList.add(tag);
        }
      }

      log.i("BARK : $allTagsList");

      if (tagSearchBarController.text != "") {
        allTagsList =
            searchSimilarTags(tagSearchBarController.text, allTagsList);
      } else {
        allTagsList = tagLookup.values.toList();
      }

      return allTagsList;
    }

    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
              insetPadding: const EdgeInsets.all(10),
              backgroundColor: AppColors.leveled,
              child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: ValueListenableBuilder(
                    valueListenable: tagSearchBarController,
                    builder: (_, __, ___) {
                      return FutureBuilder(
                        future: getSimilarTags(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return MyText(
                              "${snapshot.error}",
                              size: 10,
                            );
                          }
                          if (!snapshot.hasData) {
                            return const MyText("GETTING TAGS");
                          }

                          List<Widget> allTagWidgets = [];

                          for (Tag tag in snapshot.data!) {
                            final tagWidget = ValueListenableBuilder(
                                valueListenable: updateTagWidget,
                                builder: (_, __, ___) {
                                  final selected =
                                      List.from(chosenTags).contains(tag.id);

                                  return SizedBox(
                                    width: 300,
                                    height: 200,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (selected) {
                                          chosenTags.remove(tag.id);
                                        } else {
                                          chosenTags.add(tag.id);
                                        }
                                        updateTagWidget.value =
                                            !updateTagWidget.value;
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.all(10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        backgroundColor: selected
                                            ? AppColors.primary
                                            : AppColors.halfLeveled,
                                      ),
                                      child: MyText(
                                        tag.name,
                                        size: 13,
                                        textAlign: TextAlign.center,
                                        color: selected
                                            ? AppColors.background
                                            : AppColors.text,
                                      ),
                                    ),
                                  );
                                });

                            allTagWidgets.add(tagWidget);
                          }

                          return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 16),
                                MyInputField(
                                  hint: "search for tags ",
                                  textColor: AppColors.background,
                                  controller: tagSearchBarController,
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                    height: 300, // limit height
                                    // width: ,
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        // how wide each item should be
                                        const itemWidth = 110.0;

                                        // calculate how many items fit
                                        final columns =
                                            (constraints.maxWidth / itemWidth)
                                                .floor();

                                        return GridView.count(
                                          padding: const EdgeInsets.all(10),
                                          mainAxisSpacing: 10,
                                          crossAxisSpacing: 10,
                                          crossAxisCount: columns,
                                          children: allTagWidgets,
                                        );
                                      },
                                    )),
                              ]);
                        },
                      );
                    },
                  )));
        }).then((_) {
      justExitedTagChoose.value = !justExitedTagChoose.value;
    });
  }

  static Widget showTag(int tagId) {
    final Tag tag = tagLookup[tagId]!;
    return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 10, right: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 10 / 2),
              MyText(tag.name, size: 10, color: AppColors.background),
              const SizedBox(width: 20 / 2),
              IconButton(
                onPressed: () {
                  chosenTags.remove(tag.id);

                  updateTagWidget.value = !updateTagWidget.value;
                },
                icon: const Icon(Icons.cancel_outlined),
                color: Colors.white,
              ),
            ],
          ),
        ));
  }

  static Widget showChosenTagWidget(BuildContext context,
      {bool leveled = true}) {
    return ValueListenableBuilder<bool>(
      valueListenable: updateTagWidget,
      builder: (_, __, ___) {
        // setState((){});

        return Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: leveled ? AppColors.leveled : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          width: 500,
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Center(
            child: ListView.builder(
              clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              itemCount: List.from(chosenTags).length + 1,
              itemBuilder: (_, tagId) {
                if (List.from(chosenTags).length == tagId) {
                  return Padding(
                      padding:
                          const EdgeInsets.only(top: 10, bottom: 10, right: 30),
                      child: MyButton(
                        width: 60,
                        height: 30,
                        padding: const EdgeInsets.all(0),
                        onPressed: () {
                          showChooseTagDropDown(context);
                        },
                        backgroundColor: AppColors.primary,
                        child: const Center(
                            child: Icon(Icons.add_rounded,
                                // fontWeight: FontWeight(10),
                                color: Colors.white,
                                size: 40)),
                      ));
                } else {
                  final Tag tag = tagLookup[chosenTags[tagId]]!;
                  return Padding(
                      padding:
                          const EdgeInsets.only(top: 10, bottom: 10, right: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(width: 10),
                            MyText(tag.name,
                                size: 13, color: AppColors.background),
                            const SizedBox(width: 20),
                            IconButton(
                              onPressed: () {
                                chosenTags.remove(tag.id);

                                updateTagWidget.value = !updateTagWidget.value;
                              },
                              icon: const Icon(Icons.cancel_outlined),
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ));
                }
              },
            ),
          ),
        );
      },
    );
  }
}
