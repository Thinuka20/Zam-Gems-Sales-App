import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final loginData = RxMap<String, dynamic>();

  void setLoginData(dynamic response) {
    try {
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

  Map<String, dynamic>? get clientData => loginData['client'] as Map<String, dynamic>?;
  String? get username => clientData?['username'] as String?;
  String? get businessName => clientData?['businessName'] as String?;
  String? get datasource => clientData?['datasource'] as String?;
  String? get businessType => clientData?['businessType'] as String?;
}