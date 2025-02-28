import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../view/home_view.dart';

class RegisterController extends GetxController {
  var email = ''.obs;
  var password = ''.obs;
  var isLoading = false.obs;

  /// Registration function
  Future<void> register() async {
    isLoading.value = true;
    final url = Uri.parse('http://localhost:8000/register');

    final response = await http.post(
      url,
      body: jsonEncode(UserModel(email: email.value, password: password.value).toJson()),
      headers: {"Content-Type": "application/json"},
    );

    isLoading.value = false;

    if (response.statusCode == 200) {
      print('Registration successful');
      Get.offAll(() => HomeView());  // Navigate to home screen
    } else {
      print('Registration failed');
      Get.snackbar('Registration Failed', 'Email already registered or other error');
    }
  }
}