import 'package:get/get.dart';

class AuthController extends GetxController {
  RxBool isAuthenticated = true.obs;
  RxBool isLoading = false.obs;

  final Rx<UserModel> currentUser = UserModel(
    displayName: 'Mohamed Amine Hattay',
    email: 'hattay112@gmail.com',
    photoURL: 'https://i.pravatar.cc/150?img=3',
  ).obs;

  get user => null;

  void signInWithEmailAndPassword(String email, String password) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 2));
    isAuthenticated.value = true;
    currentUser.value = UserModel(
      displayName: 'Mohamed Amine Hattay',
      email: email,
      photoURL: 'https://i.pravatar.cc/150?img=3',
    );
    isLoading.value = false;
    print("Login mock pour $email");
  }

  void registerWithEmailAndPassword(String email, String password, String name) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 2));
    isAuthenticated.value = true;
    currentUser.value = UserModel(
      displayName: name,
      email: email,
      photoURL: 'https://i.pravatar.cc/150?img=3',
    );
    isLoading.value = false;
    print("Register mock pour $email / $name");
  }

  void logout() {
    isAuthenticated.value = false;
    print("Logout mock");
  }

  Future<void> signOut() async {}
}

class UserModel {
  final String displayName;
  final String email;
  final String photoURL;

  UserModel({
    required this.displayName,
    required this.email,
    required this.photoURL,
  });

  bool get isOnline => true;

  get id => null;

  get lastSeen => null; // mock online status
}
