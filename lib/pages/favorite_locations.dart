import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:nextfind/pages/signuppage.dart';
import 'package:nextfind/utils/user_manager.dart';
import 'package:nextfind/widgets/newwidgets.dart';

final rlog = Logger();

class FavoriteLocationsPage extends StatefulWidget {
  const FavoriteLocationsPage({super.key});

  @override
  State<FavoriteLocationsPage> createState() => FavoriteLocationsPageState();
}

class FavoriteLocationsPageState extends State<FavoriteLocationsPage> {
  late Future<List<String>?> _future;

  @override
  void initState() {
    super.initState();
    _future = UserManager.getFavoriteLocations();
  }

  Widget buildRoot(BuildContext context, AsyncSnapshot snapshot) {
    if (!UserManager.isLoggedIn()) {
      return const LoginOrSignupPage();
    }

    if (snapshot.hasData) {
      if (snapshot.data == null) {
        return const LoginOrSignupPage();
      } else {
        final List<String> miniBusinessLocationids = snapshot.data!;
        return SizedBox(
          height: MediaQuery.of(context).size.height,
          child: ListView.separated(
            controller: ScrollController(initialScrollOffset: 0),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemCount: miniBusinessLocationids.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Center(
                    child: MyText(
                  "Your Favorites",
                  size: 40,
                ));
              } else {
                return Center(
                    child: BusinessLocationThumbnail(
                        locationId: miniBusinessLocationids[index - 1]));
              }
            },
            separatorBuilder: (context, index) => const SizedBox(height: 20),
            padding: const EdgeInsets.only(top: 20, bottom: 20),
          ),
        );
      }
    } else if (snapshot.hasError) {
      return MyText(snapshot.error.toString());
    } else {
      return const CircularProgressIndicator();
    }
  }

  @override
  Widget build(BuildContext context) {
    // super.build(context);
    return Scaffold(
        bottomNavigationBar: newbottombar(context, index: 3),
        body: FutureBuilder(
            future: _future,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              return buildRoot(context, snapshot);
            }));
  }
}
