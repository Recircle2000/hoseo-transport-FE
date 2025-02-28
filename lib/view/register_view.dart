import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../viewmodel/register_viewmodel.dart';

class RegisterView extends StatelessWidget {
  final RegisterController _registerController = Get.put(RegisterController()); // Register controller

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Email input field
            TextField(
              decoration: InputDecoration(labelText: 'Email'),
              onChanged: (value) => _registerController.email.value = value,
            ),
            // Password input field
            TextField(
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
              onChanged: (value) => _registerController.password.value = value,
            ),
            SizedBox(height: 20),
            // Register button
            Obx(() => _registerController.isLoading.value
                ? CircularProgressIndicator() // Show spinner while loading
                : ElevatedButton(
              onPressed: _registerController.register,
              child: Text('Register'),
            )),
          ],
        ),
      ),
    );
  }
}