import 'package:get/get.dart';
import 'package:voiceup/controllers/main_controller.dart';
import 'package:voiceup/controllers/profile_controller.dart';
import 'package:voiceup/routes/app_routes.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:voiceup/views/auth/forgot_password_view.dart';
import 'package:voiceup/views/auth/login_view.dart';
import 'package:voiceup/views/profile/main_view.dart';
import 'package:voiceup/views/profile/profile_view.dart';
import 'package:voiceup/views/auth/register_view.dart';
import 'package:voiceup/views/profile/change_password_view.dart';
import 'package:voiceup/views/splash_view.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(
       name: AppRoutes.splash,
       page: () => const SplashView()),
     GetPage(
       name: AppRoutes.login,
       page: () => const LoginView(),
     ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterView(),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordView(),
    ),
    GetPage(
      name: AppRoutes.changePassword,
      page: () => const ChangePasswordView(),
    ),
    GetPage(
      name: AppRoutes.main,
      page: () =>  MainView(),
      binding: BindingsBuilder(() {
        Get.put(MainController());
      }),
    ),

    // GetPage(
    //   name: AppRoutes.home,
    //   page: () => const HomeView(),
    //   binding: BindingsBuilder(() {
    //     Get.put(HomeController());
    //   }),
    // ),

    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileView(),
      binding: BindingsBuilder(() {
        Get.put(ProfileController());
      }),
    ),
    // GetPage(
    //   name: AppRoutes.chat,
    //   page: () => const ChatView(),
    //   binding: BindingsBuilder(() {
    //     Get.put(ChatController());
    //   }),
    // ),
    // GetPage(
    //   name: AppRoutes.usersList,
    //   page: () => const UsersListView(),
    // ),
    // GetPage(
    //   name: AppRoutes.friends,
    //   page: () => const FriendsView(),
    //   binding: BindingsBuilder(() {
    //     Get.put(FriendsController());
    //   }),
    // ),
    // GetPage(
    //   name: AppRoutes.friendRequests,
    //   page: () => const FriendRequestsView(),
    //   binding: BindingsBuilder(() {
    //     Get.put(FriendRequestsController());
    //   }),
    // ),
    // GetPage(
    //   name: AppRoutes.notifications,
    //   page: () => const NotificationsView(),
    //   binding: BindingsBuilder(() {
    //     Get.put(NotificationsController());
    //   }),
    // ),
  ];
}