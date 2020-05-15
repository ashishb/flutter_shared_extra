import 'package:flutter/material.dart';
import 'package:flutter_shared_extras/flutter_shared_extra.dart';
import 'package:flutter_shared_extras/src/chat/chat_admin_screen_contents.dart';
import 'package:flutter_shared_extras/src/chat/chat_login_screen.dart';
import 'package:flutter_shared_extras/src/chat/chat_screen_contents.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    @required this.title,
    @required this.name,
  });

  final String title;
  final String name;

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _loggingIn = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _login() async {
    if (!_loggingIn) {
      _loggingIn = true;
      final AuthService auth = AuthService();

      await auth.anonLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<FirebaseUserProvider>(context);

    if (!userProvider.hasUser) {
      _login();
      return ChatLoginScreen();
    }

    if (userProvider.isAdmin) {
      return ChatAdminScreenContents(
        title: widget.title,
        name: widget.name,
      );
    }

    return ChatScreenContents(
      toUid: 'admin',
      stream: ChatMessageUtils.stream(
        where: [
          WhereQuery(userProvider.userId, 'admin'),
          WhereQuery('admin', userProvider.userId),
        ],
      ),
      title: widget.title,
      name: widget.name,
    );
  }
}
