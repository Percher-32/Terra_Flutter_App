import 'package:flutter/material.dart';

import 'package:nextfind/services/search_services.dart';
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


  @override
  void initState() {
    super.initState();
    scrollController = ScrollController(initialScrollOffset: 0);
    
  }



  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: RefreshIndicator(
          onRefresh: () async {
            SearchPageGlobals.reloadMap();
          },
          child: ListView.separated(
            controller: scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemCount: SearchPageGlobals.miniBusinessLocations.value.length + 1,
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
    );
  }
}
