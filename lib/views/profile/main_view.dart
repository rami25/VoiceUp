import 'package:voiceup/controllers/main_controller.dart';
import 'package:voiceup/theme/app_theme.dart';
import 'package:voiceup/views/find_people_view.dart';
import 'package:voiceup/views/profile/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainView extends GetView<MainController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: controller.pageController,
        onPageChanged: controller.onPageChanged,
        children: [
          // HomeView(),
          // FriendsView(),
          // UsersListView(),
          Container(),
          Container(),
          FindPeopleView(),
          ProfileView(),
        ],
      ),
      bottomNavigationBar: Obx(() =>
          BottomNavigationBar(
            currentIndex: controller.currentIndex,
            onTap: controller.changeTabIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: AppTheme.textSecondaryColor,
            backgroundColor: Colors.white,
            elevation: 8,
            items: [
              BottomNavigationBarItem(icon: _buildIconWithBadge(
                Icons.chat_outlined,
                controller.getUnreadCount(),
              ),
                activeIcon: _buildIconWithBadge(
                  Icons.chat,
                  controller.getUnreadCount(),
                ),
                  label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Friends',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_search_outlined),
                activeIcon: Icon(Icons.person_search),
                label: 'Find Friends',
              ),
              BottomNavigationBarItem(
                  icon: Icon(Icons.account_circle_outlined),
                activeIcon: Icon(Icons.account_circle),
                label: 'Profile',
              ),
            ],
          ),
      ),
    );
  }
  Widget _buildIconWithBadge(IconData icon, int count) {
    return Stack(
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                borderRadius: BorderRadius.circular(6),
              ),
              constraints: BoxConstraints(minWidth: 12, minHeight: 12),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: TextStyle(color: Colors.white, fontSize: 8),
                textAlign: TextAlign.center,
              ),
            ),
          )
      ],
    );
  }
}