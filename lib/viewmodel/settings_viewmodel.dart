import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../view/login_view.dart';

class SettingsViewModel extends GetxController {
  var email = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    email.value = prefs.getString('email') ?? '알 수 없음';
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Get.offAll(() => LoginView());
  }
}