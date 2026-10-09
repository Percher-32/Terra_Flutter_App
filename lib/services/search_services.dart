import 'package:nextfind/widgets/main_widgets.dart';
import 'package:flutter/material.dart';
import 'package:nextfind/page_moves.dart';

class SearchServices {
  static ValueNotifier<bool> isMetric = ValueNotifier(false);

  static int sortingByIndex = 1;
  static const List  sortingByValues = ["Relevance","Distance","Rating"];

  static int? categoryIndex;
  static const List<int> searchRadiusValues = [1, 3, 5, 10, 15, 20, 30, 50];
  static final ValueNotifier<int> searchRadiusIndex = () {
    final notifier = ValueNotifier(3);

    // Make the search radius value auto-update
    notifier.addListener(() {
      searchRadius = searchRadiusValues[notifier.value];
    });

    return notifier;
  }();
  static int searchRadius = searchRadiusValues[searchRadiusIndex.value];


  static final TextEditingController controller = TextEditingController();

  static PreferredSize createSearchBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(84),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.all(10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: AppColors.primary,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  // mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 10),
                    const Icon(Icons.search, color: Colors.white, size: 40),
                    Expanded(
                      child: HeaderInput(
                        hint: "find a business",
                        controller: controller,
                        onSubmitted: (value) => goToSearchPage(context),
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.tune, color: Colors.white, size: 40),
                      iconSize: 35,
                      onPressed: () => filterDropDown(context),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
