import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../pages/login.dart';

class LoginController extends GetxController with StateMixin<Map<String, dynamic>> {
  // Using StateMixin for better state management
  static LoginController get to => Get.find();

  // Persistent storage of login data
  final _loginData = Rx<Map<String, dynamic>>({});

  // Getters for login data
  Map<String, dynamic> get loginData => _loginData.value;

  @override
  void onInit() {
    super.onInit();
    // Initialize with empty state
    change({}, status: RxStatus.empty());
  }

  @override
  void onReady() {
    super.onReady();
    // Check if we have existing login data
    if (_loginData.value.isNotEmpty) {
      change(_loginData.value, status: RxStatus.success());
    }
  }

  bool get isLoggedIn {
    try {
      final clientData = _loginData.value['client'] as Map<String, dynamic>?;
      return clientData != null &&
          clientData['username'] != null &&
          clientData['datasource'] != null &&
          clientData['details2'] != null; // currency
    } catch (e) {
      return false;
    }
  }

  void setLoginData(dynamic response) {
    try {
      // Start loading state
      change(null, status: RxStatus.loading());

      Map<String, dynamic> parsedData;
      if (response is Map<String, dynamic>) {
        parsedData = Map<String, dynamic>.from(response);
      } else if (response is String) {
        parsedData = json.decode(response) as Map<String, dynamic>;
      } else {
        throw Exception('Invalid response format');
      }

      // Validate the data structure
      if (!_validateLoginData(parsedData)) {
        throw Exception('Invalid login data structure');
      }

      // Update the persistent storage
      _loginData.value = parsedData;

      // Update the state
      change(parsedData, status: RxStatus.success());

    } catch (e) {
      change(null, status: RxStatus.error(e.toString()));
      _loginData.value = {};
    }
  }

  bool _validateLoginData(Map<String, dynamic> data) {
    if (!data.containsKey('client')) return false;

    final clientData = data['client'] as Map<String, dynamic>?;
    if (clientData == null) return false;

    final requiredFields = [
      'username',
      'businessName',
      'datasource',
      'businessType',
      'details1',
      'details2'
    ];

    return requiredFields.every((field) =>
    clientData.containsKey(field) && clientData[field] != null);
  }

  Future<void> clearLoginData() async {
    try {
      change(null, status: RxStatus.loading());
      _loginData.value = {};
      change({}, status: RxStatus.empty());

      await Get.offAll(
              () => const LoginPage(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 300)
      );
    } catch (e) {
      change(null, status: RxStatus.error('Error clearing login data'));
    }
  }

  // Safe getters with null checking
  Map<String, dynamic>? get clientData => _loginData.value['client'] as Map<String, dynamic>?;
  String? get username => clientData?['username'] as String?;
  String? get businessName => clientData?['businessName'] as String?;
  String? get datasource => clientData?['datasource'] as String?;
  String? get businessType => clientData?['businessType'] as String?;
  String? get specialType => clientData?['details1'] as String?;
  String? get currency => clientData?['details2'] as String?;

  @override
  void onClose() {
    // Clean up if needed
    super.onClose();
  }
}