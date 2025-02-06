// lib/widgets/user_activity_wrapper.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/session_controller.dart';
import '../controllers/login_controller.dart';

class UserActivityWrapper extends StatelessWidget {
  final Widget child;

  UserActivityWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  final SessionController _sessionController = Get.find<SessionController>();
  final LoginController _loginController = Get.find<LoginController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!_loginController.isLoggedIn) {
        return child;
      }

      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) => _sessionController.updateUserActivity(),
        onPanDown: (_) => _sessionController.updateUserActivity(),
        onScaleStart: (_) => _sessionController.updateUserActivity(),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            _sessionController.updateUserActivity();
            return true;
          },
          child: child,
        ),
      );
    });
  }
}