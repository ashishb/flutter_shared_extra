import 'package:flutter/material.dart';
import 'package:flutter_shared/flutter_shared.dart';
import 'package:flutter_shared_extra/src/firebase/auth.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({this.map});

  final Map<String, dynamic> map;

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final AuthService auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Details')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: JsonViewerWidget(widget.map),
            ),
          ),
          _userClaims(),
        ],
      ),
    );
  }

  Widget _userClaims() {
    final uid = widget.map['uid'] as String;

    // Snackbar needed a context
    return Builder(
      builder: (BuildContext context) {
        return Wrap(
          spacing: 6,
          alignment: WrapAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                final bool result = await auth.addAdminClaimToUid(uid);

                if (result) {
                  Utils.showSnackbar(context, '$uid as now an Admin');
                } else {
                  Utils.showSnackbar(context, 'An error occurred', error: true);
                }
              },
              child: const Text('Add Admin'),
            ),
            ElevatedButton(
              onPressed: () async {
                final bool result = await auth.deleteClaimForUid(uid);

                if (result) {
                  Utils.showSnackbar(
                      context, 'Admin has been removed for $uid');
                } else {
                  Utils.showSnackbar(context, 'An error occurred', error: true);
                }
              },
              child: const Text('Delete Claims'),
            ),
          ],
        );
      },
    );
  }
}
