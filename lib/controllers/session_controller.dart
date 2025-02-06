// lib/controllers/session_controller.dart
import 'dart:async';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';

class SessionController extends GetxController {
  Timer? _timer;
  final int timeoutDuration = 300; // 10 minutes in seconds
  final _isActive = true.obs;

  // Reference to login controller
  late final LoginController _loginController;

  bool get isActive => _isActive.value;

  @override
  void onInit() {
    super.onInit();
    _loginController = Get.find<LoginController>();
    _initializeSession();

    // Listen to login data changes
    ever(_loginController.loginData.obs, (_) { // Use the public getter
      if (_loginController.isLoggedIn) {
        _initializeSession();
      } else {
        _timer?.cancel();
      }
    });
  }


  void _initializeSession() {
    if (_loginController.isLoggedIn) {
      _isActive.value = true;
      _resetTimer();
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    if (_loginController.isLoggedIn) {
      _timer = Timer(Duration(seconds: timeoutDuration), () {
        _handleTimeout();
      });
    }
  }

  Future<void> _handleTimeout() async {
    if (_loginController.isLoggedIn) {
      _isActive.value = false;
      await _loginController.clearLoginData();
      Get.snackbar(
        'Session Expired',
        'You have been logged out due to inactivity',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void updateUserActivity() {
    if (_loginController.isLoggedIn) {
      _isActive.value = true;
      _resetTimer();
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}