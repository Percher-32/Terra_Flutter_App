import 'package:flutter/material.dart';

import 'package:nextfind/services/search_services.dart';
import 'package:nextfind/widgets/main_widgets.dart';
import 'package:nextfind/widgets/business_widgets.dart';
import 'package:nextfind/helpers/logger.dart';

class InitialSearchingWidget extends StatefulWidget {
  const InitialSearchingWidget({
    super.key,
  });

  @override
  State<InitialSearchingWidget> createState() => _InitialSearchingWidgetState();
}

class _InitialSearchingWidgetState extends State<InitialSearchingWidget> {
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
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(200),
          child: Container(
            width: MediaQuery.widthOf(context),
            height: 200,
            decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20)),
          )),
    );
  }
}
