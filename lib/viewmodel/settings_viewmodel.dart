// lib/viewmodel/settings_viewmodel.dart
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../view/auth/login_view.dart';
import '../view/home_view.dart';

class SettingsViewModel extends GetxController {
  var email = ''.obs;
  var isLoggedIn = false.obs;
  var selectedCampus = '아산'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    email.value = prefs.getString('email') ?? '알 수 없음';
    isLoggedIn.value = prefs.getBool('isLoggedIn') ?? false;
    selectedCampus.value = prefs.getString('campus') ?? '아산';
  }

  Future<void> setCampus(String campus) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('campus', campus);
    selectedCampus.value = campus;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await prefs.remove('isLoggedIn');
    email.value = '알 수 없음';
    isLoggedIn.value = false;
    Get.offAll(() => HomeView());
  }
}
