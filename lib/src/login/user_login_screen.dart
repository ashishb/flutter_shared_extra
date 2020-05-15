import 'package:flutter/material.dart';
import 'package:flutter_shared_extra/src/login/user_login_view.dart';

class UserLoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // without the app bar, the status bar text was white on white
      appBar: AppBar(title: const Text('')),
      body: UserLoginView(),
    );
  }
}
