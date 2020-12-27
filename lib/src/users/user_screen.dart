import 'package:flutter/material.dart';
import 'package:flutter_shared/flutter_shared.dart';

class UserScreen extends StatelessWidget {
  const UserScreen({this.userMap});

  final Map<String, dynamic> userMap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User')),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: JsonViewerWidget(userMap),
      ),
    );
  }
}
