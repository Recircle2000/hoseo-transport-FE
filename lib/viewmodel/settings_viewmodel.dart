// lib/viewmodel/settings_viewmodel.dart
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsViewModel extends GetxController {
  var selectedCampus = '아산'.obs;
  var selectedSubwayStation = '천안'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    selectedCampus.value = prefs.getString('campus') ?? '아산';
    selectedSubwayStation.value = prefs.getString('subwayStation') ?? '천안';
  }

  Future<void> setCampus(String campus) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('campus', campus);
    selectedCampus.value = campus;
  }

  Future<void> setSubwayStation(String station) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subwayStation', station);
    selectedSubwayStation.value = station;
  }
}
