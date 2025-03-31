import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../view/login_view.dart';

class SettingsViewModel extends GetxController {
  var email = ''.obs;
  var isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    email.value = prefs.getString('email') ?? '알 수 없음';
    isLoggedIn.value = prefs.getBool('isLoggedIn') ?? false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    email.value = '알 수 없음';
    isLoggedIn.value = false;
    Get.offAll(() => LoginView());
  }
}