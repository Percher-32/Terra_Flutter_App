import 'package:flutter/material.dart';

import 'package:nextfind/screens/login_or_signup_page.dart';
import 'package:nextfind/services/user_services.dart';
import 'package:nextfind/widgets/main_widgets.dart';
import 'package:nextfind/services/navbar_services.dart';
import 'package:nextfind/widgets/business_widgets.dart';

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
    _future = UserService.getFavoriteLocations();
  }

  @override
  Widget build(BuildContext context) {
    // super.build(context);
    return Scaffold(
        bottomNavigationBar: const NavBar(currentPage: AppPages.favoritepage),
        body: FutureBuilder(
            future: _future,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (!UserService.isLoggedIn) {
                return const LoginOrSignupPage();
              }

              if (snapshot.hasData) {
                return FavoriteLocationsWidget(
                    miniBusinessLocationIds: snapshot.data!);
              } else if (snapshot.hasError) {
                return MyText(snapshot.error.toString());
              } else {
                return const CircularProgressIndicator();
              }
            }));
  }
}

class FavoriteLocationsWidget extends StatelessWidget {
  const FavoriteLocationsWidget(
      {super.key, required this.miniBusinessLocationIds});

  final List<String> miniBusinessLocationIds;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: ListView.separated(
        controller: ScrollController(initialScrollOffset: 0),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: miniBusinessLocationIds.length + 1,
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
                    locationId: miniBusinessLocationIds[index - 1]));
          }
        },
        separatorBuilder: (context, index) => const SizedBox(height: 20),
        padding: const EdgeInsets.only(top: 20, bottom: 20),
      ),
    );
  }
}
