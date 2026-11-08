import 'package:flutter/material.dart';

import 'package:nextfind/services/search_services.dart';
import 'package:nextfind/widgets/main_widgets.dart';
import 'package:nextfind/widgets/business_widgets.dart';
import 'package:nextfind/helpers/logger.dart';

class ListSearchView extends StatefulWidget {
  const ListSearchView({
    super.key,
  });

  @override
  State<ListSearchView> createState() => _ListSearchViewState();
}

class _ListSearchViewState extends State<ListSearchView> {
  late final ScrollController scrollController;
  late final ValueNotifier<double> _scrollOffset;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController(initialScrollOffset: 0);
    _scrollOffset = ValueNotifier(0);
    scrollController.addListener(() {
      _scrollOffset.value = scrollController.offset;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Stack(children: [
        RefreshIndicator(
            onRefresh: () async {
              SearchPageGlobals.runSearch();
            },
            child: ListView.separated(
              controller: scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount:
                  SearchPageGlobals.miniBusinessLocations.value.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const SizedBox(
                    height: 0,
                  );
                } else {
                  return Center(
                      child: BusinessLocationThumbnail(
                          locationId: SearchPageGlobals.miniBusinessLocations
                              .value[index - 1].locationId));
                }
              },
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              padding: const EdgeInsets.only(top: 20, bottom: 20),
            )),
        ValueListenableBuilder(
            valueListenable: _scrollOffset,
            builder: (_, scrollOffset, __) {
              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 40, // Height of the fade area
                child: IgnorePointer(
                  child: Opacity(
                    opacity: (_scrollOffset.value / 50.0).clamp(0.0, 1.0),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.background,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
      ]),
    );
  }
}
