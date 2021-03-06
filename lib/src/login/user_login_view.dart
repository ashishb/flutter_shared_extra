import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_shared/flutter_shared_web.dart';
import 'package:flutter_shared_extra/src/firebase/auth.dart';
import 'package:flutter_shared_extra/src/login/user_login_button.dart';

class UserLoginView extends StatefulWidget {
  const UserLoginView({this.anonymousLogin = true});

  final bool anonymousLogin;

  @override
  State<StatefulWidget> createState() => UserLoginViewState();
}

class UserLoginViewState extends State<UserLoginView> {
  UserLoginViewState() {
    Utils.getAppName().then((name) {
      setState(() {
        appName = name;
      });
    });
  }

  AuthService auth = AuthService();
  String appName = '';

  List<Widget> _buttons() {
    final List<Widget> result = [];

    result.addAll(<Widget>[
      const UserLoginButton(
        text: 'Login with Email',
        icon: Icons.email,
        type: 'email',
      ),
      const SizedBox(height: 4),
      const UserLoginButton(
        text: 'Login with Phone',
        icon: Icons.phone,
        type: 'phone',
      ),
      const SizedBox(height: 4),
      const UserLoginButton(
        text: 'Login with Google',
        icon: FontAwesome5Brands.google,
        type: 'google',
      ),
    ]);

    if (Utils.isIOS) {
      result.addAll(<Widget>[
        const SizedBox(height: 4),
        const UserLoginButton(
          text: 'Sign in With Apple',
          icon: Icons.person, // not used
          type: 'apple',
        ),
      ]);
    }

    if (widget.anonymousLogin) {
      result.addAll(<Widget>[
        const SizedBox(height: 4),
        const UserLoginButton(
          text: 'Anonymous Login ',
          icon: Icons.person,
          type: 'anon',
        ),
      ]);
    }

    return result;
  }

  Widget loginButtons(BuildContext context) {
    // IntrinsicWidth and CrossAxisAlignment.stretch make all children equal width
    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buttons(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            Text(
              appName,
              style: Theme.of(context).textTheme.headline5,
              textAlign: TextAlign.center,
            ),
            Text('Login to get started',
                style: Theme.of(context).textTheme.subtitle1),
            const SizedBox(height: 40),
            loginButtons(context),
          ],
        ),
      ),
    );
  }
}
