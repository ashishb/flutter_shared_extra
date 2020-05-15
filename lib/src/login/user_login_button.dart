import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shared/flutter_shared.dart';
import 'package:flutter_shared_extras/flutter_shared_extra.dart';
import 'package:flutter_shared_extras/src/login/login_email.dart';
import 'package:flutter_shared_extras/src/login/login_phone.dart';

class UserLoginButton extends StatefulWidget {
  const UserLoginButton(
      {Key key, this.text, this.icon, this.color, this.textColor, this.type})
      : super(key: key);

  final Color color;
  final Color textColor;
  final IconData icon;
  final String text;
  final String type;

  @override
  _UserLoginButtonState createState() => _UserLoginButtonState();
}

class _UserLoginButtonState extends State<UserLoginButton> {
  void handleAuthResult(BuildContext context, SignInResult result) {
    if (result != null) {
      if (result.errorString != null && result.errorString.isNotEmpty) {
        Utils.showSnackbar(context, result.errorString, error: true);
      }

      final FirebaseUser user = result.user;

      if (user != null) {
        // save in prefs, let the caller deal with it.
      }
    }
  }

  Future<void> loginWithEmail() async {
    final LoginData data = await showEmailLoginDialog(context);

    if (data != null) {
      final AuthService auth = AuthService();

      handleAuthResult(
          context, await auth.emailSignIn(data.email, data.password));
    }
  }

  Future<void> loginWithPhone() async {
    handleAuthResult(context, await showLoginPhoneDialog(context));
  }

  Future<void> _handleOnPressed() async {
    final AuthService auth = AuthService();

    switch (widget.type) {
      case 'email':
        await loginWithEmail();
        break;
      case 'phone':
        await loginWithPhone();
        break;
      case 'google':
        handleAuthResult(context, await auth.googleSignIn());
        break;
      default:
        handleAuthResult(context, await auth.anonLogin());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.textColor;

    return ColoredButton(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      icon: Icon(widget.icon, color: textColor),
      textColor: textColor,
      color: widget.color,
      onPressed: _handleOnPressed,
      title: widget.text,
    );
  }
}
