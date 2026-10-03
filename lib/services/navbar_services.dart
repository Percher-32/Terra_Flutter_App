import 'package:flutter/material.dart';
import 'package:nextfind/widgets/main_widgets.dart';
import 'package:nextfind/page_moves.dart';
import 'package:nextfind/helpers/logger.dart';

enum AppPages { homepage, searchpage, userpage, favoritepage, leaderboardpage }

class NavbarServices {
  static AppPages currentPage = AppPages.homepage;

  static void homePageButtonLogic(BuildContext context) {
    currentPage = AppPages.homepage;
    goToHomePage(context);
  }

  static void searchButtonLogic(BuildContext context) {
    currentPage = AppPages.searchpage;
    goToSearchPage(context);
  }

  static Future<void> userButtonLogic(BuildContext context) async {
    currentPage = AppPages.userpage;
    goToUserPage(context);
  }

  static defaultNavBarButtonLogic(AppPages page, BuildContext context) async {
    if (page == AppPages.homepage) {
      homePageButtonLogic(context);
    } else if (page == AppPages.searchpage) {
      searchButtonLogic(context);
    } else if (page == AppPages.userpage) {
      await userButtonLogic(context);
    }
  }
}

class NavBar extends StatelessWidget {
  final AppPages currentPage;
  final Function(AppPages, BuildContext) onTabSelected;

  const NavBar({
    super.key,
    required this.currentPage,
    this.onTabSelected = NavbarServices.defaultNavBarButtonLogic,
  });

  @override
  Widget build(BuildContext context) {
    // final midColor = Color.lerp(AppColors.background, AppColors.primary, 0.5)!;

    return Padding(
      padding: const EdgeInsets.all(0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(0),
        child: Container(
          height: 50,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            color: AppColors.primary,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildIconButton(
                context,
                icon: Icons.search,
                page: AppPages.searchpage,
                label: "search",
              ),
              _buildIconButton(
                context,
                icon: Icons.leaderboard_outlined,
                page: AppPages.leaderboardpage,
                label: "leaderboard",
              ),
              _buildIconButton(
                context,
                icon: Icons.home_outlined,
                page: AppPages.homepage,
                label: "home",
              ),
              _buildIconButton(
                context,
                icon: Icons.favorite_border_rounded,
                page: AppPages.favoritepage,
                label: "favorites",
              ),
              _buildIconButton(
                context,
                icon: Icons.person_outline,
                page: AppPages.userpage,
                label: "user",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required AppPages page,
    required String label,
  }) {
    final isSelected = currentPage == page;
    final midColor = Color.lerp(AppColors.background, AppColors.primary, 0.5)!;

    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? Colors.white : midColor,
        size: 35,
      ),
      iconSize: 35,
      onPressed: () {
        log.d("User tapped bottom nav button: $label");
        onTabSelected(page, context);
      },
    );
  }
}
