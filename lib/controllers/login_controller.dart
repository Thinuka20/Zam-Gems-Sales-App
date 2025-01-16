import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../pages/login.dart';

class LoginController extends GetxController {
  final loginData = RxMap<String, dynamic>();

  bool get isLoggedIn {
    // Check if we have the necessary login data
    return currency != null && datasource != null;
  }

  void setLoginData(dynamic response) {
    try {
      // Clear existing data
      loginData.clear();

      // Process and set new login data
      if (response is Map<String, dynamic>) {
        loginData.value = response;
      } else if (response is String) {
        loginData.value = json.decode(response);
      }

      if (kDebugMode) {
        print('Login data set to: ${loginData.value}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting login data: $e');
      }
      loginData.value = {};
    }
  }


  Future<void> clearLoginData() async {
    try {
      // Clear the RxMap
      loginData.value = {};

      if (kDebugMode) {
        print('Login data cleared successfully');
      }

      // Navigate to login page
      Get.offAll(() => LoginPage(), transition: Transition.fade);

    } catch (e) {
      if (kDebugMode) {
        print('Error clearing login data: $e');
      }
    }
  }

  Map<String, dynamic>? get clientData => loginData['client'] as Map<String, dynamic>?;
  String? get username => clientData?['username'] as String?;
  String? get businessName => clientData?['businessName'] as String?;
  String? get datasource => clientData?['datasource'] as String?;
  String? get businessType => clientData?['businessType'] as String?;
  String? get specialType => clientData?['details1'] as String?;
  String? get currency => clientData?['details2'] as String?;
}